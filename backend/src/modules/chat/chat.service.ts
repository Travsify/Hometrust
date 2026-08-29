import { prisma } from '../../utils/prisma';

export class ChatService {
  static async getOrCreateConversation(user1Id: string, user2Id: string, propertyId?: string, projectId?: string) {
    let conversation = await prisma.conversation.findFirst({
      where: {
        OR: [
          { user1Id, user2Id },
          { user1Id: user2Id, user2Id: user1Id },
        ],
      },
      include: {
        messages: {
          orderBy: { createdAt: 'asc' },
        },
      },
    });

    if (!conversation) {
      conversation = await prisma.conversation.create({
        data: {
          user1Id,
          user2Id,
          propertyId,
          projectId,
        },
        include: {
          messages: true,
        },
      });
    }

    return conversation;
  }

  static async getUserConversations(userId: string) {
    return prisma.conversation.findMany({
      where: {
        OR: [{ user1Id: userId }, { user2Id: userId }],
      },
      orderBy: { lastMessageAt: 'desc' },
      include: {
        messages: {
          take: 1,
          orderBy: { createdAt: 'desc' },
        },
      },
    });
  }

  static async sendMessage(params: {
    conversationId: string;
    senderId: string;
    content: string;
    attachmentUrl?: string;
    attachmentType?: string;
  }) {
    const message = await prisma.message.create({
      data: {
        conversationId: params.conversationId,
        senderId: params.senderId,
        content: params.content,
        attachmentUrl: params.attachmentUrl,
        attachmentType: params.attachmentType,
      },
    });

    await prisma.conversation.update({
      where: { id: params.conversationId },
      data: { lastMessageAt: new Date() },
    });

    return message;
  }
}
