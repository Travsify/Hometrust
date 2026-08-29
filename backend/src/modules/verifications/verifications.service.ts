import { prisma } from '../../utils/prisma';
import { AiDocumentAnalyzer } from './ai_analyzer.service';
import { PdfReportService } from './pdf_report.service';
import { AuditService } from '../audit/audit.service';

export interface CreateVerificationRequestParams {
  userId: string;
  propertyName: string;
  propertyAddress: string;
  state: string;
  city: string;
  documentType: string;
  urgency?: 'STANDARD' | 'EXPRESS';
  documents: { fileName: string; fileUrl: string; fileType?: string; fileSize?: number }[];
}

export class VerificationsService {
  static async create(params: CreateVerificationRequestParams) {
    const verificationCode = `EV-VER-${Math.floor(100000 + Math.random() * 900000)}`;
    const feeAmount = params.urgency === 'EXPRESS' ? 45000 : 25000;

    const request = await prisma.verificationRequest.create({
      data: {
        verificationCode,
        userId: params.userId,
        propertyName: params.propertyName,
        propertyAddress: params.propertyAddress,
        state: params.state,
        city: params.city,
        documentType: params.documentType,
        urgency: params.urgency || 'STANDARD',
        feeAmount,
        status: 'SUBMITTED',
        isPaid: false,
      },
    });

    // Save uploaded documents and run preliminary AI analysis
    for (const doc of params.documents) {
      const aiAnalysis = await AiDocumentAnalyzer.analyzeDocument(doc.fileName, params.documentType, params.propertyAddress);

      await prisma.verificationDocument.create({
        data: {
          verificationRequestId: request.id,
          fileName: doc.fileName,
          fileUrl: doc.fileUrl,
          fileType: doc.fileType,
          fileSize: doc.fileSize,
          aiScanSummary: aiAnalysis.summary,
          aiInconsistencies: JSON.stringify(aiAnalysis.potentialInconsistencies),
          aiExtractedFields: JSON.stringify(aiAnalysis.extractedFields),
        },
      });

      // Populate default verification checklist items from AI scan
      for (const chk of aiAnalysis.checks) {
        await prisma.verificationCheckItem.create({
          data: {
            verificationRequestId: request.id,
            checkName: chk.name,
            category: 'TITLE',
            status: chk.status,
            notes: chk.details,
          },
        });
      }
    }

    return this.getById(request.id);
  }

  static async getById(idOrCode: string) {
    const request = await prisma.verificationRequest.findFirst({
      where: {
        OR: [{ id: idOrCode }, { verificationCode: idOrCode }],
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
        documents: true,
        checks: true,
        payments: true,
      },
    });

    if (!request) {
      throw new Error('Verification request not found');
    }

    return {
      ...request,
      documents: request.documents.map((d) => ({
        ...d,
        aiInconsistencies: d.aiInconsistencies ? JSON.parse(d.aiInconsistencies) : [],
        aiExtractedFields: d.aiExtractedFields ? JSON.parse(d.aiExtractedFields) : {},
      })),
    };
  }

  static async getUserRequests(userId: string) {
    const requests = await prisma.verificationRequest.findMany({
      where: { userId },
      orderBy: { createdAt: 'desc' },
      include: {
        documents: true,
        checks: true,
      },
    });

    return requests.map((r) => ({
      ...r,
      documents: r.documents.map((d) => ({
        ...d,
        aiInconsistencies: d.aiInconsistencies ? JSON.parse(d.aiInconsistencies) : [],
      })),
    }));
  }

  static async getAll(filters: { status?: string; search?: string; page?: number; limit?: number }) {
    const page = filters.page || 1;
    const limit = filters.limit || 20;
    const skip = (page - 1) * limit;

    const where: any = {};
    if (filters.status) where.status = filters.status;
    if (filters.search) {
      where.OR = [
        { verificationCode: { contains: filters.search } },
        { propertyName: { contains: filters.search } },
        { propertyAddress: { contains: filters.search } },
      ];
    }

    const [requests, total] = await Promise.all([
      prisma.verificationRequest.findMany({
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
          documents: true,
          checks: true,
        },
      }),
      prisma.verificationRequest.count({ where }),
    ]);

    return {
      requests,
      total,
      page,
      totalPages: Math.ceil(total / limit),
    };
  }

  static async updateStatus(
    id: string,
    data: {
      status: string;
      finalFindings?: string;
      externalRegistryChecked?: boolean;
      externalRegistryNotes?: string;
      assignedTo?: string;
    },
    adminUser: any
  ) {
    const request = await prisma.verificationRequest.findUnique({
      where: { id },
      include: {
        user: true,
        documents: true,
        checks: true,
      },
    });

    if (!request) {
      throw new Error('Verification request not found');
    }

    let reportUrl = request.reportUrl;

    // If marked as VERIFIED, VERIFIED_WITH_ISSUES, or COMPLETED, generate official PDF report
    if (['VERIFIED', 'VERIFIED_WITH_ISSUES', 'COMPLETED', 'REJECTED'].includes(data.status)) {
      reportUrl = await PdfReportService.generateVerificationReport({
        verificationCode: request.verificationCode,
        customerName: `${request.user.firstName} ${request.user.lastName}`,
        customerEmail: request.user.email,
        propertyName: request.propertyName,
        propertyAddress: request.propertyAddress,
        state: request.state,
        city: request.city,
        documentType: request.documentType,
        status: data.status,
        assignedTo: data.assignedTo || 'EstateVerify Legal Team',
        externalRegistryChecked: data.externalRegistryChecked ?? request.externalRegistryChecked,
        externalRegistryNotes: data.externalRegistryNotes || request.externalRegistryNotes || undefined,
        finalFindings: data.finalFindings || request.finalFindings || undefined,
        checks: request.checks.map((c) => ({
          name: c.checkName,
          category: c.category,
          status: c.status,
          notes: c.notes || undefined,
        })),
        documents: request.documents.map((d) => ({
          fileName: d.fileName,
          fileType: d.fileType || undefined,
        })),
        completedAt: new Date(),
      });
    }

    const updated = await prisma.verificationRequest.update({
      where: { id },
      data: {
        status: data.status,
        finalFindings: data.finalFindings,
        externalRegistryChecked: data.externalRegistryChecked,
        externalRegistryNotes: data.externalRegistryNotes,
        assignedTo: data.assignedTo,
        reportUrl,
      },
    });

    await AuditService.log({
      adminId: adminUser.id,
      adminEmail: adminUser.email,
      action: 'VERIFICATION_STATUS_UPDATED',
      entityType: 'VERIFICATION_REQUEST',
      entityId: id,
      details: {
        code: request.verificationCode,
        previousStatus: request.status,
        newStatus: data.status,
        reportGenerated: !!reportUrl,
      },
    });

    await prisma.notification.create({
      data: {
        userId: request.userId,
        title: `Verification Update: ${request.propertyName}`,
        message: `Your verification request (${request.verificationCode}) status has been updated to ${data.status}.`,
        type: 'VERIFICATION',
        linkUrl: reportUrl || undefined,
      },
    });

    return updated;
  }
}
