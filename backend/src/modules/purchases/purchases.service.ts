import { prisma } from '../../utils/prisma';

export interface CreatePurchaseParams {
  userId: string;
  propertyId?: string;
  projectUnitId?: string;
  paymentPlanId?: string;
}

export class PurchasesService {
  static async create(params: CreatePurchaseParams) {
    let totalPrice = 0;
    let initialDeposit = 0;
    let nextPaymentAmount: number | null = null;
    let nextPaymentDueDate: Date | null = null;

    if (params.propertyId) {
      const property = await prisma.property.findUnique({
        where: { id: params.propertyId },
        include: { paymentPlans: true },
      });
      if (!property) throw new Error('Property not found');

      if (params.paymentPlanId) {
        const plan = property.paymentPlans.find(p => p.id === params.paymentPlanId);
        if (!plan) throw new Error('Selected payment plan not found');
        totalPrice = plan.totalPrice;
        initialDeposit = plan.initialDeposit;
        nextPaymentAmount = plan.monthlyPayment;
      } else {
        totalPrice = property.price;
        initialDeposit = property.price;
      }
    } else if (params.projectUnitId) {
      const unit = await prisma.projectUnit.findUnique({
        where: { id: params.projectUnitId },
        include: { paymentPlans: true },
      });
      if (!unit) throw new Error('Project unit not found');

      totalPrice = unit.price;
      initialDeposit = unit.initialDeposit;
      nextPaymentAmount = unit.monthlyInstalment;
    } else {
      throw new Error('Either propertyId or projectUnitId must be provided');
    }

    const purchaseCode = `EV-PUR-${Date.now().toString().slice(-6)}-${Math.floor(100 + Math.random() * 900)}`;

    const purchase = await prisma.purchase.create({
      data: {
        purchaseCode,
        userId: params.userId,
        propertyId: params.propertyId,
        projectUnitId: params.projectUnitId,
        paymentPlanId: params.paymentPlanId,
        totalPrice,
        initialDeposit,
        amountPaid: 0,
        outstandingBalance: totalPrice,
        nextPaymentAmount,
        status: 'INITIATED',
      },
      include: {
        property: true,
        projectUnit: true,
        paymentPlan: true,
      },
    });

    return purchase;
  }

  static async getById(idOrCode: string) {
    const purchase = await prisma.purchase.findFirst({
      where: {
        OR: [{ id: idOrCode }, { purchaseCode: idOrCode }],
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
        property: {
          include: { developer: true },
        },
        projectUnit: {
          include: {
            project: {
              include: { developer: true },
            },
          },
        },
        paymentPlan: true,
        payments: {
          orderBy: { createdAt: 'desc' },
        },
      },
    });

    if (!purchase) {
      throw new Error('Purchase record not found');
    }

    return purchase;
  }

  static async getUserPurchases(userId: string) {
    return prisma.purchase.findMany({
      where: { userId },
      orderBy: { createdAt: 'desc' },
      include: {
        property: {
          include: { developer: true },
        },
        projectUnit: {
          include: {
            project: {
              include: { developer: true },
            },
          },
        },
        paymentPlan: true,
        payments: {
          where: { status: 'SUCCESS' },
          orderBy: { paidAt: 'desc' },
        },
      },
    });
  }

  static async signAgreement(id: string, agreementDocumentUrl: string) {
    return prisma.purchase.update({
      where: { id },
      data: {
        status: 'AGREEMENT_SIGNED',
        agreementDocumentUrl,
        signatureDate: new Date(),
      },
    });
  }
}
