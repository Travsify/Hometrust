import { prisma } from '../../utils/prisma';
import { AuditService } from '../audit/audit.service';

export interface CreateLegalRequestParams {
  userId: string;
  documentCategory: string;
  title: string;
  requirements: string;
  supportingDocuments?: string[];
}

export class LegalService {
  static async create(params: CreateLegalRequestParams) {
    const requestCode = `EV-LEG-${Math.floor(10000 + Math.random() * 90000)}`;

    const request = await prisma.legalRequest.create({
      data: {
        requestCode,
        userId: params.userId,
        documentCategory: params.documentCategory,
        title: params.title,
        requirements: params.requirements,
        supportingDocuments: params.supportingDocuments ? JSON.stringify(params.supportingDocuments) : undefined,
        feeAmount: 45000,
        status: 'REQUESTED',
        isPaid: false,
      },
    });

    return request;
  }

  static async getById(idOrCode: string) {
    const request = await prisma.legalRequest.findFirst({
      where: {
        OR: [{ id: idOrCode }, { requestCode: idOrCode }],
      },
      include: {
        user: {
          select: {
            id: true,
            firstName: true,
            lastName: true,
            email: true,
            phone: true,
          },
        },
        payments: true,
      },
    });

    if (!request) {
      throw new Error('Legal request not found');
    }

    return {
      ...request,
      supportingDocuments: request.supportingDocuments ? JSON.parse(request.supportingDocuments) : [],
    };
  }

  static async getUserRequests(userId: string) {
    const requests = await prisma.legalRequest.findMany({
      where: { userId },
      orderBy: { createdAt: 'desc' },
    });

    return requests.map(r => ({
      ...r,
      supportingDocuments: r.supportingDocuments ? JSON.parse(r.supportingDocuments) : [],
    }));
  }

  static async getAll(filters: { status?: string; page?: number; limit?: number }) {
    const page = filters.page || 1;
    const limit = filters.limit || 20;
    const skip = (page - 1) * limit;

    const where: any = {};
    if (filters.status) where.status = filters.status;

    const [requests, total] = await Promise.all([
      prisma.legalRequest.findMany({
        where,
        skip,
        take: limit,
        orderBy: { createdAt: 'desc' },
        include: {
          user: {
            select: {
              id: true,
              firstName: true,
              lastName: true,
              email: true,
            },
          },
        },
      }),
      prisma.legalRequest.count({ where }),
    ]);

    return {
      requests: requests.map(r => ({
        ...r,
        supportingDocuments: r.supportingDocuments ? JSON.parse(r.supportingDocuments) : [],
      })),
      total,
      page,
      totalPages: Math.ceil(total / limit),
    };
  }

  static async updateStatus(
    id: string,
    data: {
      status: string;
      draftDocumentUrl?: string;
      finalDocumentUrl?: string;
      customerFeedback?: string;
    },
    adminUser: any
  ) {
    const request = await prisma.legalRequest.findUnique({
      where: { id },
      include: { user: true },
    });

    if (!request) {
      throw new Error('Legal request not found');
    }

    const updated = await prisma.legalRequest.update({
      where: { id },
      data: {
        status: data.status,
        draftDocumentUrl: data.draftDocumentUrl || request.draftDocumentUrl,
        finalDocumentUrl: data.finalDocumentUrl || request.finalDocumentUrl,
        customerFeedback: data.customerFeedback || request.customerFeedback,
      },
    });

    await AuditService.log({
      adminId: adminUser.id,
      adminEmail: adminUser.email,
      action: 'LEGAL_REQUEST_STATUS_UPDATED',
      entityType: 'LEGAL_REQUEST',
      entityId: id,
      details: {
        code: request.requestCode,
        status: data.status,
        hasFinalDoc: !!data.finalDocumentUrl,
      },
    });

    await prisma.notification.create({
      data: {
        userId: request.userId,
        title: `Legal Document Update: ${request.title}`,
        message: `Your legal request (${request.requestCode}) status has moved to ${data.status}.`,
        type: 'LEGAL',
        linkUrl: data.finalDocumentUrl || data.draftDocumentUrl || undefined,
      },
    });

    return updated;
  }
}
