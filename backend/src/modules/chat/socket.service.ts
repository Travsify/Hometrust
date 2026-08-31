import { Server as HttpServer } from 'http';
import { Server, Socket } from 'socket.io';
import jwt from 'jsonwebtoken';
import { config } from '../../config';
import { prisma } from '../../utils/prisma';
import { NotificationsService } from '../notifications/notifications.service';

export interface AuthenticatedSocket extends Socket {
  userId?: string;
  userRole?: string;
  userName?: string;
}

export class SocketService {
  private static io: Server | null = null;
  // Map of userId -> Set of active socket IDs
  private static userSockets: Map<string, Set<string>> = new Map();

  public static init(httpServer: HttpServer): Server {
    this.io = new Server(httpServer, {
      cors: {
        origin: '*',
        methods: ['GET', 'POST'],
      },
      pingTimeout: 30000,
      pingInterval: 10000,
    });

    // 1. Authentication Middleware
    this.io.use((socket: AuthenticatedSocket, next) => {
      const token = socket.handshake.auth?.token || (socket.handshake.query?.token as string);
      const explicitUserId = socket.handshake.auth?.userId || (socket.handshake.query?.userId as string);

      if (token) {
        try {
          const secret = config.jwtSecret || 'estateverify_super_secure_jwt_secret_dev_2026';
          const decoded: any = jwt.verify(token.replace(/^Bearer\s+/i, ''), secret);
          socket.userId = decoded.id || decoded.userId;
          socket.userRole = decoded.role;
          socket.userName = `${decoded.firstName || ''} ${decoded.lastName || ''}`.trim() || 'User';
          return next();
        } catch (err) {
          console.warn('[SOCKET] Invalid JWT token on connection, attempting fallback to explicit userId...');
        }
      }

      if (explicitUserId) {
        socket.userId = explicitUserId;
        socket.userName = (socket.handshake.auth?.userName as string) || 'User';
        return next();
      }

      // Allow anonymous connection with auto-generated guest ID
      socket.userId = `guest_${socket.id}`;
      socket.userName = 'Guest Buyer';
      return next();
    });

    // 2. Connection Handler
    this.io.on('connection', (socket: AuthenticatedSocket) => {
      const userId = socket.userId!;
      console.log(`[SOCKET] User connected: ${userId} (${socket.userName}) on socket ${socket.id}`);

      // Register user in active socket registry
      if (!this.userSockets.has(userId)) {
        this.userSockets.set(userId, new Set());
      }
      this.userSockets.get(userId)!.add(socket.id);

      // Join private user notification/call room
      socket.join(`user_${userId}`);

      // ─── CHAT EVENTS ────────────────────────────────────────────────────────

      // Join a conversation room
      socket.on('join_conversation', ({ conversationId }: { conversationId: string }) => {
        if (conversationId) {
          socket.join(`conv_${conversationId}`);
          console.log(`[SOCKET] Socket ${socket.id} joined conversation: conv_${conversationId}`);
        }
      });

      // Leave a conversation room
      socket.on('leave_conversation', ({ conversationId }: { conversationId: string }) => {
        if (conversationId) {
          socket.leave(`conv_${conversationId}`);
        }
      });

      // Send Message (Real-Time Human Message)
      socket.on(
        'send_message',
        async (data: {
          conversationId: string;
          recipientId?: string;
          content: string;
          attachmentUrl?: string;
          attachmentType?: string;
        }) => {
          try {
            const { conversationId, content, attachmentUrl, attachmentType, recipientId } = data;
            if (!conversationId || !content?.trim()) return;

            // Save to PostgreSQL Database via Prisma
            const savedMessage = await prisma.message.create({
              data: {
                conversationId,
                senderId: userId,
                content: content.trim(),
                attachmentUrl: attachmentUrl || null,
                attachmentType: attachmentType || null,
                isRead: false,
              },
              include: {
                sender: {
                  select: {
                    id: true,
                    firstName: true,
                    lastName: true,
                    email: true,
                    role: true,
                    avatarUrl: true,
                  },
                },
              },
            });

            // Update conversation lastMessageAt
            await prisma.conversation.update({
              where: { id: conversationId },
              data: { lastMessageAt: new Date() },
            });

            const formattedMsg = {
              id: savedMessage.id,
              conversationId,
              senderId: userId,
              senderName: `${savedMessage.sender.firstName} ${savedMessage.sender.lastName}`.trim(),
              senderRole: savedMessage.sender.role,
              senderAvatar: savedMessage.sender.avatarUrl,
              content: savedMessage.content,
              attachmentUrl: savedMessage.attachmentUrl,
              attachmentType: savedMessage.attachmentType,
              isRead: false,
              createdAt: savedMessage.createdAt.toISOString(),
            };

            // Broadcast to all active participants in the conversation room
            this.io?.to(`conv_${conversationId}`).emit('new_message', formattedMsg);

            // Also emit directly to recipient's personal room in case they aren't on the chat screen
            if (recipientId) {
              this.io?.to(`user_${recipientId}`).emit('message_notification', {
                ...formattedMsg,
                unread: true,
              });
            }
          } catch (err: any) {
            console.error('[SOCKET] Error saving/broadcasting message:', err.message);
            socket.emit('error', { message: 'Failed to send message' });
          }
        }
      );

      // Typing Indicator
      socket.on('typing', ({ conversationId, isTyping }: { conversationId: string; isTyping: boolean }) => {
        socket.to(`conv_${conversationId}`).emit('user_typing', {
          conversationId,
          userId,
          userName: socket.userName,
          isTyping,
        });
      });

      // Mark Message as Read
      socket.on('mark_as_read', async ({ conversationId, messageId }: { conversationId: string; messageId?: string }) => {
        try {
          if (messageId) {
            await prisma.message.updateMany({
              where: { id: messageId, conversationId, senderId: { not: userId } },
              data: { isRead: true },
            });
          } else {
            await prisma.message.updateMany({
              where: { conversationId, senderId: { not: userId } },
              data: { isRead: true },
            });
          }

          socket.to(`conv_${conversationId}`).emit('messages_read', {
            conversationId,
            readBy: userId,
          });
        } catch (err: any) {
          console.warn('[SOCKET] Mark as read notice:', err.message);
        }
      });

      // ─── IN-APP CALLING SIGNALING EVENTS ───────────────────────────────────

      // 1. Initiate Call (Buyer -> Developer or Developer -> Buyer)
      socket.on(
        'call_initiate',
        (data: {
          callId: string;
          recipientId: string;
          callerName: string;
          callerRole?: string;
          callerAvatar?: string;
          propertyTitle?: string;
          isVideo?: boolean;
          channelId?: string;
        }) => {
          const { callId, recipientId, callerName, callerRole, callerAvatar, propertyTitle, isVideo, channelId } = data;
          console.log(`[CALL] Call initiated from ${userId} (${callerName}) to recipient ${recipientId}`);

          const callPayload = {
            callId: callId || `call_${Date.now()}`,
            callerId: userId,
            callerName: callerName || socket.userName || 'Hometrust Caller',
            callerRole: callerRole || socket.userRole || 'Verified User',
            callerAvatar: callerAvatar || null,
            propertyTitle: propertyTitle || null,
            isVideo: !!isVideo,
            channelId: channelId || `ht_room_${Date.now()}`,
            timestamp: new Date().toISOString(),
          };

          // Deliver incoming call to recipient's device
          this.io?.to(`user_${recipientId}`).emit('incoming_call', callPayload);

          // Dispatch high-priority Push Notification to ring recipient's phone even if app is backgrounded
          NotificationsService.createAndDispatch({
            userId: recipientId,
            title: `📞 Incoming Voice Call: ${callPayload.callerName}`,
            message: propertyTitle ? `Inquiry regarding: ${propertyTitle}` : 'Tap to answer in Hometrust',
            type: 'CHAT',
            linkUrl: `/call/${callPayload.callId}`,
          }).catch((err: any) => console.warn('[CALL PUSH NOTIFICATION NOTICE]', err?.message));
        }
      );

      // 2. Ringing Acknowledged by recipient's device
      socket.on('call_ringing', ({ callId, callerId }: { callId: string; callerId: string }) => {
        console.log(`[CALL] Call ringing acknowledged for caller: ${callerId}`);
        this.io?.to(`user_${callerId}`).emit('call_ringing', { callId, status: 'RINGING' });
      });

      // 3. Call Accepted / Answered
      socket.on(
        'call_accept',
        ({ callId, callerId, channelId }: { callId: string; callerId: string; channelId: string }) => {
          console.log(`[CALL] Call accepted by ${userId} for caller ${callerId}`);
          this.io?.to(`user_${callerId}`).emit('call_accepted', {
            callId,
            channelId,
            acceptedBy: userId,
            timestamp: new Date().toISOString(),
          });
        }
      );

      // 4. Call Rejected / Declined
      socket.on(
        'call_reject',
        ({ callId, callerId, reason }: { callId: string; callerId: string; reason?: string }) => {
          console.log(`[CALL] Call rejected by ${userId} for caller ${callerId}`);
          this.io?.to(`user_${callerId}`).emit('call_rejected', {
            callId,
            rejectedBy: userId,
            reason: reason || 'Call declined',
          });
        }
      );

      // 5. Call Ended / Hang Up
      socket.on(
        'call_end',
        ({ callId, peerId, durationSeconds }: { callId: string; peerId: string; durationSeconds?: number }) => {
          console.log(`[CALL] Call ended between ${userId} and ${peerId} (Duration: ${durationSeconds || 0}s)`);
          this.io?.to(`user_${peerId}`).emit('call_ended', {
            callId,
            endedBy: userId,
            durationSeconds: durationSeconds || 0,
          });
        }
      );

      // 6. WebRTC P2P Signaling Relay (Offer, Answer, ICE Candidates)
      socket.on(
        'webrtc_signal',
        (data: { to: string; type: 'offer' | 'answer' | 'candidate'; payload: any }) => {
          const { to, type, payload } = data;
          this.io?.to(`user_${to}`).emit('webrtc_signal', {
            from: userId,
            type,
            payload,
          });
        }
      );

      // ─── DISCONNECT ────────────────────────────────────────────────────────
      socket.on('disconnect', () => {
        console.log(`[SOCKET] User disconnected: ${userId} on socket ${socket.id}`);
        const userSet = this.userSockets.get(userId);
        if (userSet) {
          userSet.delete(socket.id);
          if (userSet.size === 0) {
            this.userSockets.delete(userId);
          }
        }
      });
    });

    console.log('✅ [SOCKET.IO] Real-Time Chat & In-App Calling Signaling Server Initialized');
    return this.io;
  }

  /**
   * Check if a specific user is currently online
   */
  public static isUserOnline(userId: string): boolean {
    return this.userSockets.has(userId) && this.userSockets.get(userId)!.size > 0;
  }

  /**
   * Send notification/message to a user directly from any backend service
   */
  public static emitToUser(userId: string, event: string, data: any): boolean {
    if (!this.io) return false;
    this.io.to(`user_${userId}`).emit(event, data);
    return true;
  }
}
