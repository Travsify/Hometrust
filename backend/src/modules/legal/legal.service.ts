import { prisma } from '../../utils/prisma';
import { AuditService } from '../audit/audit.service';
import { NotificationsService } from '../notifications/notifications.service';

export interface CreateLegalRequestParams {
  userId: string;
  documentCategory: string;
  title: string;
  requirements: string;
  agreedAmount?: number;
  deliveryOption?: 'DIGITAL_ONLY' | 'LOCAL_COURIER' | 'INTERSTATE_COURIER' | 'INTERNATIONAL';
  deliveryAddress?: string; // JSON string
  deliveryFee?: number;
  supportingDocuments?: string[];
}

export class LegalService {
  /**
   * Get Active Legal Drafting Fee Percentage (Admin configured, default 3%)
   */
  static async getLegalFeePercentage(): Promise<number> {
    try {
      const config = await prisma.platformFeeConfig.findFirst({
        where: {
          applicableService: 'LEGAL',
          isActive: true,
        },
      });

      if (config && config.percentage > 0) {
        return config.percentage;
      }
      return 3.0; // Default 3.0%
    } catch {
      return 3.0;
    }
  }

  /**
   * Calculate Legal Drafting Fee Quote based on property transaction value
   */
  static async getFeeQuote(agreedAmount: number) {
    const feePercentage = await this.getLegalFeePercentage();
    const cleanAmount = Math.max(0, Number(agreedAmount) || 0);
    const feeAmount = (cleanAmount * feePercentage) / 100;

    return {
      agreedAmount: cleanAmount,
      feePercentage,
      feeAmount,
    };
  }

  /**
   * Create Legal Drafting Request with calculated 3% fee
   */
  static async create(params: CreateLegalRequestParams) {
    const requestCode = `HT-LEG-${Math.floor(10000 + Math.random() * 90000)}`;
    const feePercentage = await this.getLegalFeePercentage();
    const agreedAmount = Math.max(0, Number(params.agreedAmount) || 0);
    const legalDraftFee = agreedAmount > 0 ? (agreedAmount * feePercentage) / 100 : 45000;
    const deliveryFee = params.deliveryFee || 0;
    const totalFeeAmount = legalDraftFee + deliveryFee;
    const isPhysical = params.deliveryOption && params.deliveryOption !== 'DIGITAL_ONLY';
    const deliveryOtp = isPhysical ? Math.floor(1000 + Math.random() * 9000).toString() : null;

    const request = await prisma.legalRequest.create({
      data: {
        requestCode,
        userId: params.userId,
        documentCategory: params.documentCategory,
        title: params.title,
        requirements: params.requirements,
        agreedAmount,
        feePercentage,
        feeAmount: totalFeeAmount,
        deliveryOption: params.deliveryOption || 'DIGITAL_ONLY',
        deliveryAddress: params.deliveryAddress || null,
        deliveryFee,
        deliveryStatus: isPhysical ? 'PENDING' : 'DELIVERED',
        deliveryOtp,
        supportingDocuments: params.supportingDocuments ? JSON.stringify(params.supportingDocuments) : undefined,
        status: 'REQUESTED',
        isPaid: false,
      },
    });

    const user = await prisma.user.findUnique({ where: { id: params.userId } });
    if (user) {
      await AuditService.log({
        adminId: user.id,
        adminEmail: user.email,
        action: 'LEGAL_DOCUMENT_REQUESTED',
        entityType: 'LEGAL_REQUEST',
        entityId: request.id,
        details: {
          requestCode,
          title: params.title,
          category: params.documentCategory,
          agreedAmount,
          feePercentage: `${feePercentage}%`,
          feeAmount: totalFeeAmount,
          deliveryOption: params.deliveryOption,
          deliveryFee,
        },
      });
    }

    return request;
  }

  /**
   * Pay Legal Fee from Dedicated Virtual Account Wallet
   */
  static async payWithWallet(requestId: string, userId: string) {
    const request = await prisma.legalRequest.findUnique({
      where: { id: requestId },
      include: { user: true },
    });

    if (!request) {
      throw new Error('Legal request not found');
    }

    if (request.userId !== userId) {
      throw new Error('Unauthorized access to this legal request');
    }

    if (request.isPaid) {
      return { success: true, message: 'Legal fee has already been paid.', request };
    }

    // Find User's Dedicated Virtual Account
    const virtualAccount = await prisma.virtualAccount.findFirst({
      where: { userId },
    });

    const currentBalance = virtualAccount?.balance || 0;
    const requiredAmount = request.feeAmount;

    if (!virtualAccount || currentBalance < requiredAmount) {
      return {
        success: false,
        code: 'INSUFFICIENT_FUNDS',
        requiredAmount,
        currentBalance,
        deficit: Math.max(0, requiredAmount - currentBalance),
        virtualAccount: virtualAccount
          ? {
              accountNumber: virtualAccount.accountNumber,
              bankName: virtualAccount.bankName,
              accountName: virtualAccount.accountName,
            }
          : null,
      };
    }

    // Deduct fee and confirm payment atomically
    const [updatedAccount, updatedRequest, payment] = await prisma.$transaction([
      prisma.virtualAccount.update({
        where: { id: virtualAccount.id },
        data: {
          balance: { decrement: requiredAmount },
        },
      }),
      prisma.legalRequest.update({
        where: { id: requestId },
        data: {
          isPaid: true,
          status: 'PAYMENT_CONFIRMED',
        },
      }),
      prisma.payment.create({
        data: {
          userId,
          legalRequestId: request.id,
          amount: requiredAmount,
          currency: 'NGN',
          purpose: 'LEGAL_DOCUMENT_FEE',
          paystackChannel: 'wallet_transfer',
          paymentReference: `HT-PAY-LEG-${Date.now()}`,
          receiptNumber: `HT-RCP-LEG-${Date.now()}`,
          status: 'SUCCESS',
          totalAmount: requiredAmount,
          paidAt: new Date(),
        },
      }),
    ]);

    await AuditService.log({
      adminId: request.user.id,
      adminEmail: request.user.email,
      action: 'LEGAL_FEE_PAID_VIA_WALLET',
      entityType: 'LEGAL_REQUEST',
      entityId: request.id,
      details: {
        requestCode: request.requestCode,
        amount: requiredAmount,
        paymentReference: payment.paymentReference,
        remainingBalance: updatedAccount.balance,
      },
    });

    await NotificationsService.createAndDispatch({
      userId,
      title: `Legal Fee Paid: ${request.title}`,
      message: `Your payment of ₦${requiredAmount.toLocaleString()} (3% drafting fee) for ${request.requestCode} was successful. Our legal team is now drafting your document.`,
      type: 'LEGAL',
      actionDetails: [
        { label: 'Request Code', value: request.requestCode },
        { label: 'Document Title', value: request.title },
        { label: 'Fee Amount Paid', value: `₦${requiredAmount.toLocaleString()}` },
        { label: 'Payment Reference', value: payment.paymentReference || 'Wallet' },
      ],
    });

    return {
      success: true,
      request: updatedRequest,
      payment,
      remainingBalance: updatedAccount.balance,
    };
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

  /**
   * Admin: Dispatch physical hard copy legal deed with courier tracking
   */
  static async dispatchCourier(id: string, data: { courierPartner: string; waybillNumber: string }, adminUser: any) {
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
        deliveryStatus: 'DISPATCHED',
        courierPartner: data.courierPartner,
        waybillNumber: data.waybillNumber,
        dispatchedAt: new Date(),
      },
    });

    await AuditService.log({
      adminId: adminUser.id,
      adminEmail: adminUser.email,
      action: 'HARD_COPY_LEGAL_DEED_DISPATCHED',
      entityType: 'LEGAL_REQUEST',
      entityId: id,
      details: {
        code: request.requestCode,
        courier: data.courierPartner,
        waybill: data.waybillNumber,
      },
    });

    await NotificationsService.createAndDispatch({
      userId: request.userId,
      title: `Legal Hard Copies Dispatched: ${request.title}`,
      message: `Your sealed Deed / Contract has been dispatched via ${data.courierPartner} (Waybill: ${data.waybillNumber}). Delivery PIN: ${request.deliveryOtp}`,
      type: 'LEGAL',
      actionDetails: [
        { label: 'Courier Partner', value: data.courierPartner },
        { label: 'Waybill Number', value: data.waybillNumber },
        { label: 'Delivery PIN', value: request.deliveryOtp || 'N/A' },
        { label: 'Status', value: 'In Transit 🚚' },
      ],
    });

    return updated;
  }

  /**
   * Confirm physical legal delivery with 4-Digit OTP Handover PIN
   */
  static async confirmDelivery(id: string, data: { otp: string }) {
    const request = await prisma.legalRequest.findUnique({ where: { id } });
    if (!request) throw new Error('Legal request not found');

    if (request.deliveryOtp && request.deliveryOtp !== data.otp) {
      throw new Error('Invalid Delivery PIN. Handover cannot be confirmed.');
    }

    const updated = await prisma.legalRequest.update({
      where: { id },
      data: {
        deliveryStatus: 'DELIVERED',
        deliveredAt: new Date(),
      },
    });

    await NotificationsService.createAndDispatch({
      userId: request.userId,
      title: `Legal Deed Delivered: ${request.title}`,
      message: `Your hard copy legal documents have been safely delivered and confirmed.`,
      type: 'LEGAL',
    });

    return updated;
  }

}
