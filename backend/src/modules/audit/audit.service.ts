import { prisma } from '../../utils/prisma';

export interface CreateAuditLogParams {
  adminId?: string;
  adminEmail: string;
  action: string;
  entityType: string;
  entityId: string;
  details?: Record<string, any>;
  ipAddress?: string;
  userAgent?: string;
}

export class AuditService {
  static async log(params: CreateAuditLogParams) {
    try {
      return await prisma.auditLog.create({
        data: {
          adminId: params.adminId,
          adminEmail: params.adminEmail,
          action: params.action,
          entityType: params.entityType,
          entityId: params.entityId,
          details: params.details ? JSON.stringify(params.details) : undefined,
          ipAddress: params.ipAddress,
          userAgent: params.userAgent,
        },
      });
    } catch (err) {
      console.error('Failed to write audit log:', err);
    }
  }

  static async getLogs(page = 1, limit = 50, entityType?: string) {
    const skip = (page - 1) * limit;
    const where = entityType ? { entityType } : {};

    const [logs, total] = await Promise.all([
      prisma.auditLog.findMany({
        where,
        skip,
        take: limit,
        orderBy: { createdAt: 'desc' },
      }),
      prisma.auditLog.count({ where }),
    ]);

    return {
      logs: logs.map(l => ({
        ...l,
        details: l.details ? JSON.parse(l.details) : null,
      })),
      total,
      page,
      totalPages: Math.ceil(total / limit),
    };
  }
}
