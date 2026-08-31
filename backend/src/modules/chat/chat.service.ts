import { prisma } from '../../utils/prisma';
import { SocketService } from './socket.service';
import { NotificationsService } from '../notifications/notifications.service';

export class ChatService {
  /**
   * Get or create an inquiry-based conversation between two users
   */
  static async getOrCreateConversation(user1Id: string, user2Id: string, propertyId?: string, projectId?: string) {
    const whereClause: any = {
      OR: [
        { user1Id, user2Id },
        { user1Id: user2Id, user2Id: user1Id },
      ],
    };

    if (propertyId) {
      whereClause.propertyId = propertyId;
    } else if (projectId) {
      whereClause.projectId = projectId;
    }

    let conversation = await prisma.conversation.findFirst({
      where: whereClause,
      include: {
        messages: {
          orderBy: { createdAt: 'asc' },
          include: {
            sender: {
              select: {
                id: true,
                firstName: true,
                lastName: true,
                avatarUrl: true,
                role: true,
              },
            },
          },
        },
      },
    });

    if (!conversation) {
      conversation = await prisma.conversation.create({
        data: {
          user1Id,
          user2Id,
          propertyId: propertyId || null,
          projectId: projectId || null,
        },
        include: {
          messages: {
            include: {
              sender: {
                select: {
                  id: true,
                  firstName: true,
                  lastName: true,
                  avatarUrl: true,
                  role: true,
                },
              },
            },
          },
        },
      });
    }

    // Record engagement for the buyer
    if (propertyId) {
      await (prisma as any).propertyEngagement.upsert({
        where: { userId_propertyId: { userId: user1Id, propertyId } },
        create: { userId: user1Id, propertyId, engagementType: 'CHAT_STARTED' },
        update: { engagementType: 'CHAT_STARTED', updatedAt: new Date() },
      }).catch(console.error);
    }

    // Attach rich property/project context
    let propertyContext: any = null;
    if (conversation.propertyId) {
      const prop = await prisma.property.findUnique({
        where: { id: conversation.propertyId },
        select: {
          id: true,
          title: true,
          price: true,
          images: true,
          city: true,
          state: true,
        },
      });
      if (prop) {
        propertyContext = {
          id: prop.id,
          type: 'PROPERTY',
          title: prop.title,
          price: prop.price,
          location: `${prop.city}, ${prop.state}`,
          imageUrl: prop.images?.[0] || null,
        };
      }
    } else if (conversation.projectId) {
      const proj = await prisma.project.findUnique({
        where: { id: conversation.projectId },
        select: {
          id: true,
          name: true,
          city: true,
          state: true,
          images: true,
          units: { take: 1, select: { price: true } },
        },
      });
      if (proj) {
        propertyContext = {
          id: proj.id,
          type: 'PROJECT',
          title: proj.name,
          price: proj.units?.[0]?.price || 0,
          location: `${proj.city}, ${proj.state}`,
          imageUrl: proj.images?.[0] || null,
        };
      }
    }

    return {
      ...conversation,
      propertyContext,
    };
  }

  /**
   * Start a conversation with a developer anchored to a property inquiry
   */
  static async startWithDeveloper(buyerId: string, developerId: string, propertyId?: string, projectId?: string, initialMessage?: string) {
    // Find developer's user account
    const developer = await prisma.developer.findUnique({
      where: { id: developerId },
      include: { user: true },
    });

    if (!developer) {
      throw new Error('Developer not found');
    }

    const devUserId = developer.userId || developer.user?.id;
    if (!devUserId) {
      throw new Error('Developer user account is not active');
    }

    const conversation: any = await this.getOrCreateConversation(buyerId, devUserId, propertyId, projectId);

    // If conversation is brand new (0 messages), inject initial inquiry message from buyer
    if (!conversation.messages || conversation.messages.length === 0) {
      let inquiryText = initialMessage;
      if (!inquiryText || !inquiryText.trim()) {
        const listingTitle = conversation.propertyContext?.title || 'this listing';
        inquiryText = `Hello, I am interested in ${listingTitle}. Can you provide more details regarding milestone schedules and site inspection?`;
      }

      await this.sendMessage({
        conversationId: conversation.id,
        senderId: buyerId,
        content: inquiryText.trim(),
      });
    }

    const devPhone = developer.phone || developer.user?.phone || null;

    return {
      ...conversation,
      developerPhone: devPhone,
      peerPhone: devPhone,
    };
  }

  /**
   * Start a conversation with Hometrust Human Support
   */
  static async startWithSupport(userId: string, initialMessage?: string) {
    // Find an active admin or support agent
    const supportUser = await prisma.user.findFirst({
      where: { role: { in: ['SUPER_ADMIN', 'ADMIN', 'SUPPORT_AGENT'] } },
      orderBy: { createdAt: 'asc' },
    });

    const supportUserId = supportUser?.id || 'admin-system';
    const conversation = await this.getOrCreateConversation(userId, supportUserId);

    if (initialMessage && initialMessage.trim()) {
      await this.sendMessage({
        conversationId: conversation.id,
        senderId: userId,
        content: initialMessage.trim(),
      });
    }

    return conversation;
  }

  /**
   * Get all conversations for a user with full peer profiles and unread counts
   */
  static async getUserConversations(userId: string) {
    const conversations = await prisma.conversation.findMany({
      where: {
        OR: [{ user1Id: userId }, { user2Id: userId }],
      },
      orderBy: { lastMessageAt: 'desc' },
      include: {
        messages: {
          take: 1,
          orderBy: { createdAt: 'desc' },
          include: {
            sender: {
              select: {
                id: true,
                firstName: true,
                lastName: true,
              },
            },
          },
        },
      },
    });

    // Fetch user IDs for peers
    const peerIds = conversations.map((c) => (c.user1Id === userId ? c.user2Id : c.user1Id));
    const peers = await prisma.user.findMany({
      where: { id: { in: peerIds } },
      select: {
        id: true,
        firstName: true,
        lastName: true,
        phone: true,
        avatarUrl: true,
        role: true,
        developer: {
          select: {
            id: true,
            companyName: true,
            phone: true,
            isVerified: true,
          },
        },
      },
    });

    const peerMap = new Map(peers.map((p) => [p.id, p]));

    // Batch fetch associated properties and projects
    const propIds = conversations.map((c) => c.propertyId).filter(Boolean) as string[];
    const projIds = conversations.map((c) => c.projectId).filter(Boolean) as string[];

    const [properties, projects] = await Promise.all([
      propIds.length > 0
        ? prisma.property.findMany({
            where: { id: { in: propIds } },
            select: { id: true, title: true, price: true, images: true, city: true, state: true },
          })
        : [],
      projIds.length > 0
        ? prisma.project.findMany({
            where: { id: { in: projIds } },
            select: { id: true, name: true, city: true, state: true, images: true, units: { take: 1, select: { price: true } } },
          })
        : [],
    ]);

    const propMap = new Map(properties.map((p) => [p.id, p]));
    const projMap = new Map(projects.map((p) => [p.id, p]));

    // Calculate unread counts per conversation
    const result = await Promise.all(
      conversations.map(async (c) => {
        const peerId = c.user1Id === userId ? c.user2Id : c.user1Id;
        const peer = peerMap.get(peerId);

        const unreadCount = await prisma.message.count({
          where: {
            conversationId: c.id,
            senderId: { not: userId },
            isRead: false,
          },
        });

        const isPeerOnline = SocketService.isUserOnline(peerId);
        const lastMsg = c.messages[0];

        // Format peer display name and role
        let displayName = peer ? `${peer.firstName} ${peer.lastName}`.trim() : 'Hometrust Support';
        let role = peer?.role || 'SUPPORT';
        if (peer?.developer?.companyName) {
          displayName = peer.developer.companyName;
          role = 'VERIFIED_DEVELOPER';
        }

        let propertyContext: any = null;
        if (c.propertyId && propMap.has(c.propertyId)) {
          const p = propMap.get(c.propertyId)!;
          propertyContext = {
            id: p.id,
            type: 'PROPERTY',
            title: p.title,
            price: p.price,
            location: `${p.city}, ${p.state}`,
            imageUrl: p.images?.[0] || null,
          };
        } else if (c.projectId && projMap.has(c.projectId)) {
          const pr = projMap.get(c.projectId)!;
          propertyContext = {
            id: pr.id,
            type: 'PROJECT',
            title: pr.name,
            price: pr.units?.[0]?.price || 0,
            location: `${pr.city}, ${pr.state}`,
            imageUrl: pr.images?.[0] || null,
          };
        }

        const peerPhone = peer?.developer?.phone || peer?.phone || null;

        return {
          id: c.id,
          peerId,
          peerName: displayName,
          peerRole: role,
          peerAvatar: peer?.avatarUrl || null,
          peerPhone,
          isPeerOnline,
          isVerified: peer?.developer?.isVerified ?? (peer?.role === 'ADMIN' || peer?.role === 'SUPER_ADMIN'),
          propertyId: c.propertyId,
          projectId: c.projectId,
          propertyContext,
          unreadCount,
          lastMessage: lastMsg
            ? {
                id: lastMsg.id,
                content: lastMsg.content,
                senderId: lastMsg.senderId,
                createdAt: lastMsg.createdAt,
                isRead: lastMsg.isRead,
              }
            : null,
          lastMessageAt: c.lastMessageAt,
          createdAt: c.createdAt,
        };
      })
    );

    return result;
  }

  /**
   * Get all messages in a conversation and mark as read
   */
  static async getConversationMessages(conversationId: string, userId: string) {
    const conversation = await prisma.conversation.findUnique({
      where: { id: conversationId },
    });

    if (!conversation) {
      throw new Error('Conversation not found');
    }

    if (conversation.user1Id !== userId && conversation.user2Id !== userId) {
      throw new Error('Access denied to this conversation');
    }

    // Mark unread messages as read
    await prisma.message.updateMany({
      where: {
        conversationId,
        senderId: { not: userId },
        isRead: false,
      },
      data: { isRead: true },
    });

    const peerId = conversation.user1Id === userId ? conversation.user2Id : conversation.user1Id;
    const peer = await prisma.user.findUnique({
      where: { id: peerId },
      select: {
        id: true,
        firstName: true,
        lastName: true,
        phone: true,
        avatarUrl: true,
        role: true,
        developer: {
          select: {
            id: true,
            companyName: true,
            phone: true,
            isVerified: true,
          },
        },
      },
    });

    let propertyContext: any = null;
    if (conversation.propertyId) {
      const prop = await prisma.property.findUnique({
        where: { id: conversation.propertyId },
        select: { id: true, title: true, price: true, images: true, city: true, state: true },
      });
      if (prop) {
        propertyContext = {
          id: prop.id,
          type: 'PROPERTY',
          title: prop.title,
          price: prop.price,
          location: `${prop.city}, ${prop.state}`,
          imageUrl: prop.images?.[0] || null,
        };
      }
    } else if (conversation.projectId) {
      const proj = await prisma.project.findUnique({
        where: { id: conversation.projectId },
        select: { id: true, name: true, city: true, state: true, images: true, units: { take: 1, select: { price: true } } },
      });
      if (proj) {
        propertyContext = {
          id: proj.id,
          type: 'PROJECT',
          title: proj.name,
          price: proj.units?.[0]?.price || 0,
          location: `${proj.city}, ${proj.state}`,
          imageUrl: proj.images?.[0] || null,
        };
      }
    }

    const messages = await prisma.message.findMany({
      where: { conversationId },
      orderBy: { createdAt: 'asc' },
      include: {
        sender: {
          select: {
            id: true,
            firstName: true,
            lastName: true,
            avatarUrl: true,
            role: true,
            developer: {
              select: {
                companyName: true,
              },
            },
          },
        },
      },
    });

    const formattedMessages = messages.map((m) => {
      const isSenderMe = m.senderId === userId;
      const senderName = m.sender.developer?.companyName || `${m.sender.firstName} ${m.sender.lastName}`.trim();

      return {
        id: m.id,
        conversationId: m.conversationId,
        senderId: m.senderId,
        senderName,
        senderRole: m.sender.role,
        senderAvatar: m.sender.avatarUrl,
        content: m.content,
        attachmentUrl: m.attachmentUrl,
        attachmentType: m.attachmentType,
        isMe: isSenderMe,
        isRead: m.isRead,
        createdAt: m.createdAt.toISOString(),
      };
    });

    return {
      conversationId,
      propertyContext,
      peerPhone: peer?.developer?.phone || peer?.phone || null,
      messages: formattedMessages,
    };
  }

  /**
   * Send a real-time human message
   */
  static async sendMessage(params: {
    conversationId: string;
    senderId: string;
    content: string;
    attachmentUrl?: string;
    attachmentType?: string;
  }) {
    const conversation = await prisma.conversation.findUnique({
      where: { id: params.conversationId },
    });

    if (!conversation) {
      throw new Error('Conversation not found');
    }

    const message = await prisma.message.create({
      data: {
        conversationId: params.conversationId,
        senderId: params.senderId,
        content: params.content.trim(),
        attachmentUrl: params.attachmentUrl,
        attachmentType: params.attachmentType,
      },
      include: {
        sender: {
          select: {
            id: true,
            firstName: true,
            lastName: true,
            avatarUrl: true,
            role: true,
            developer: {
              select: {
                companyName: true,
              },
            },
          },
        },
      },
    });

    await prisma.conversation.update({
      where: { id: params.conversationId },
      data: { lastMessageAt: new Date() },
    });

    const recipientId = conversation.user1Id === params.senderId ? conversation.user2Id : conversation.user1Id;
    const senderName = message.sender.developer?.companyName || `${message.sender.firstName} ${message.sender.lastName}`.trim();

    const formattedMsg = {
      id: message.id,
      conversationId: message.conversationId,
      senderId: message.senderId,
      senderName,
      senderRole: message.sender.role,
      senderAvatar: message.sender.avatarUrl,
      content: message.content,
      attachmentUrl: message.attachmentUrl,
      attachmentType: message.attachmentType,
      isRead: false,
      createdAt: message.createdAt.toISOString(),
    };

    // Emit via Socket.io
    SocketService.emitToUser(recipientId, 'new_message', formattedMsg);
    SocketService.emitToUser(recipientId, 'message_notification', {
      ...formattedMsg,
      unread: true,
    });

    // Create DB in-app notification + push toast + send email notification
    NotificationsService.createAndDispatch({
      userId: recipientId,
      title: `💬 New Message from ${senderName}`,
      message: params.content.length > 120 ? `${params.content.substring(0, 117)}...` : params.content,
      type: 'CHAT',
      linkUrl: `/chat/${params.conversationId}`,
      actionDetails: [
        { label: 'Sender', value: senderName },
        { label: 'Message Preview', value: params.content.length > 80 ? `${params.content.substring(0, 77)}...` : params.content },
      ],
    }).catch(err => console.warn('[CHAT NOTIFICATION ERROR]', err.message));

    return formattedMsg;
  }

  /**
   * Get total unread message count for a user
   */
  static async getUnreadCount(userId: string) {
    const count = await prisma.message.count({
      where: {
        conversation: {
          OR: [{ user1Id: userId }, { user2Id: userId }],
        },
        senderId: { not: userId },
        isRead: false,
      },
    });
    return { unreadCount: count };
  }
}
