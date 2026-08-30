import { prisma } from '../../utils/prisma';
import { SocketService } from '../chat/socket.service';
import { ResendService } from './resend.service';

export interface DispatchNotificationParams {
  userId: string;
  title: string;
  message: string;
  type?: 'PAYMENT' | 'VERIFICATION' | 'LEGAL' | 'MILESTONE' | 'INSPECTION' | 'CHAT' | 'SYSTEM' | 'SECURITY';
  linkUrl?: string;
  deviceName?: string;
  ipAddress?: string;
  sendEmail?: boolean;
  actionDetails?: Array<{ label: string; value: string }>;
}

export class NotificationsService {
  /**
   * Create DB notification, emit real-time push to mobile client, and send activity email with Device + IP
   */
  static async createAndDispatch(params: DispatchNotificationParams) {
    const {
      userId,
      title,
      message,
      type = 'SYSTEM',
      linkUrl,
      deviceName = 'Hometrust Mobile Client',
      ipAddress = '102.89.45.12',
      sendEmail = true,
      actionDetails,
    } = params;

    // 1. Create in PostgreSQL database
    const notification = await prisma.notification.create({
      data: {
        userId,
        title,
        message,
        type,
        linkUrl,
        isRead: false,
      },
    });

    // 2. Real-Time In-App Push Notification via Socket.io
    SocketService.emitToUser(userId, 'notification_push', {
      id: notification.id,
      title,
      message,
      type,
      linkUrl,
      createdAt: notification.createdAt.toISOString(),
      isRead: false,
    });

    // 3. Automated Activity Email with Device Name & IP Address
    if (sendEmail) {
      const user = await prisma.user.findUnique({
        where: { id: userId },
        select: { email: true, firstName: true, lastName: true },
      });

      if (user && user.email) {
        const userName = `${user.firstName} ${user.lastName}`.trim() || 'Hometrust User';
        ResendService.sendActivityAuditEmail({
          to: user.email,
          userName,
          activityTitle: title,
          activitySummary: message,
          deviceName,
          ipAddress,
          actionDetails,
        }).catch((err) => {
          console.warn('[NOTIFICATIONS] Email dispatch warning:', err.message);
        });
      }
    }

    return notification;
  }

  /**
   * Send Activity Email with Device Name & IP to any recipient directly
   */
  static async dispatchActivityEmail(params: {
    email: string;
    userName: string;
    activityTitle: string;
    activitySummary: string;
    deviceName?: string;
    ipAddress?: string;
    actionDetails?: Array<{ label: string; value: string }>;
  }) {
    return ResendService.sendActivityAuditEmail(params);
  }

  static async getUserNotifications(userId: string) {
    return prisma.notification.findMany({
      where: { userId },
      orderBy: { createdAt: 'desc' },
      take: 50,
    });
  }

  static async markAsRead(id: string) {
    return prisma.notification.update({
      where: { id },
      data: { isRead: true },
    });
  }

  static async markAllAsRead(userId: string) {
    return prisma.notification.updateMany({
      where: { userId, isRead: false },
      data: { isRead: true },
    });
  }
}
