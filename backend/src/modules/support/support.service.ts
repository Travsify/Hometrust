import { prisma } from '../../utils/prisma';

export class SupportService {
  /** User: open a new support ticket */
  static async createTicket(userId: string, data: {
    subject: string;
    category?: string;
    message: string;
    priority?: string;
  }) {
    const ticket = await prisma.supportTicket.create({
      data: {
        userId,
        subject: data.subject.trim(),
        category: data.category || 'GENERAL',
        message: data.message.trim(),
        priority: data.priority || 'NORMAL',
        status: 'OPEN',
      },
      include: { user: { select: { firstName: true, lastName: true, email: true } } },
    });

    // Notify admin via audit log
    await prisma.auditLog.create({
      data: {
        adminEmail: 'support@hometrustng.com',
        action: 'SUPPORT_TICKET_OPENED',
        entityType: 'SUPPORT_TICKET',
        entityId: ticket.id,
        details: JSON.stringify({ subject: ticket.subject, category: ticket.category, userId }),
      },
    });

    return ticket;
  }

  /** User: list my tickets */
  static async getUserTickets(userId: string) {
    return prisma.supportTicket.findMany({
      where: { userId },
      orderBy: { createdAt: 'desc' },
    });
  }

  /** User: get single ticket */
  static async getTicket(ticketId: string, userId: string) {
    const ticket = await prisma.supportTicket.findFirst({
      where: { id: ticketId, userId },
    });
    if (!ticket) throw new Error('Ticket not found');
    return ticket;
  }

  /** Admin: get all tickets with filters */
  static async adminGetTickets(filters?: {
    status?: string;
    category?: string;
    priority?: string;
    search?: string;
    page?: number;
    limit?: number;
  }) {
    const page = filters?.page || 1;
    const limit = filters?.limit || 50;
    const skip = (page - 1) * limit;

    const where: any = {};
    if (filters?.status) where.status = filters.status;
    if (filters?.category) where.category = filters.category;
    if (filters?.priority) where.priority = filters.priority;
    if (filters?.search) {
      where.OR = [
        { subject: { contains: filters.search, mode: 'insensitive' } },
        { message: { contains: filters.search, mode: 'insensitive' } },
        { user: { email: { contains: filters.search, mode: 'insensitive' } } },
        { user: { firstName: { contains: filters.search, mode: 'insensitive' } } },
      ];
    }

    const [tickets, total] = await Promise.all([
      prisma.supportTicket.findMany({
        where,
        skip,
        take: limit,
        orderBy: [{ status: 'asc' }, { createdAt: 'desc' }],
        include: {
          user: { select: { id: true, firstName: true, lastName: true, email: true, phone: true } },
        },
      }),
      prisma.supportTicket.count({ where }),
    ]);

    return { tickets, total, page, totalPages: Math.ceil(total / limit) };
  }

  /** Admin: reply to a ticket */
  static async adminReplyTicket(ticketId: string, adminUser: any, reply: string) {
    const ticket = await prisma.supportTicket.update({
      where: { id: ticketId },
      data: {
        adminReply: reply.trim(),
        repliedAt: new Date(),
        status: 'IN_PROGRESS',
      },
      include: { user: { select: { firstName: true, lastName: true, email: true } } },
    });

    // In-app notification to the user
    await prisma.notification.create({
      data: {
        userId: ticket.userId,
        title: `Support Reply: ${ticket.subject}`,
        message: `Hometrust Support has replied to your ticket. Reply: "${reply.trim().substring(0, 100)}${reply.length > 100 ? '...' : ''}"`,
        type: 'SYSTEM',
      },
    }).catch(() => {});

    await prisma.auditLog.create({
      data: {
        adminEmail: adminUser.email,
        action: 'SUPPORT_TICKET_REPLIED',
        entityType: 'SUPPORT_TICKET',
        entityId: ticketId,
        details: JSON.stringify({ reply: reply.trim().substring(0, 200) }),
      },
    });

    return ticket;
  }

  /** Admin: update ticket status (OPEN → IN_PROGRESS → RESOLVED → CLOSED) */
  static async adminUpdateStatus(ticketId: string, adminUser: any, status: string) {
    const validStatuses = ['OPEN', 'IN_PROGRESS', 'RESOLVED', 'CLOSED'];
    if (!validStatuses.includes(status)) throw new Error('Invalid status');

    const ticket = await prisma.supportTicket.update({
      where: { id: ticketId },
      data: {
        status,
        closedAt: status === 'CLOSED' || status === 'RESOLVED' ? new Date() : undefined,
      },
    });

    // Notify user when ticket is resolved/closed
    if (status === 'RESOLVED' || status === 'CLOSED') {
      await prisma.notification.create({
        data: {
          userId: ticket.userId,
          title: `Ticket ${status === 'RESOLVED' ? 'Resolved ✅' : 'Closed'}`,
          message: `Your support ticket "${ticket.subject}" has been marked as ${status.toLowerCase()}.`,
          type: 'SYSTEM',
        },
      }).catch(() => {});
    }

    await prisma.auditLog.create({
      data: {
        adminEmail: adminUser.email,
        action: `SUPPORT_TICKET_${status}`,
        entityType: 'SUPPORT_TICKET',
        entityId: ticketId,
        details: JSON.stringify({ status }),
      },
    });

    return ticket;
  }
}
