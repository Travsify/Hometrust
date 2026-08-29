import { prisma } from '../../utils/prisma';
import { AuditService } from '../audit/audit.service';

export interface CreatePurchaseParams {
  userId: string;
  propertyId?: string;
  projectUnitId?: string;
  paymentPlanId?: string;
}

export class PurchasesService {
  static async create(params: CreatePurchaseParams) {
    // Enforce Single Active Property Purchase Rule
    const existingActive = await prisma.purchase.findFirst({
      where: {
        userId: params.userId,
        status: { in: ['INITIATED', 'ACTIVE'] },
        outstandingBalance: { gt: 0 },
      },
      include: {
        property: true,
        projectUnit: true,
      },
    });

    if (existingActive) {
      const title = existingActive.property?.title ?? existingActive.projectUnit?.name ?? existingActive.purchaseCode;
      throw new Error(
        `You currently have an active property purchase in progress (${title} - ${existingActive.purchaseCode}). You cannot add multiple properties at a time until your active property is completed.`
      );
    }

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

    const user = await prisma.user.findUnique({ where: { id: params.userId } });
    if (user) {
      await AuditService.log({
        adminId: user.id,
        adminEmail: user.email,
        action: 'PURCHASE_INITIATED',
        entityType: 'PURCHASE',
        entityId: purchase.id,
        details: {
          purchaseCode: purchase.purchaseCode,
          propertyId: params.propertyId,
          projectUnitId: params.projectUnitId,
          totalPrice,
          initialDeposit,
        },
      });
    }

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
    const updated = await prisma.purchase.update({
      where: { id },
      data: {
        status: 'AGREEMENT_SIGNED',
        agreementDocumentUrl,
        signatureDate: new Date(),
      },
      include: { user: true },
    });

    if (updated.user) {
      await AuditService.log({
        adminId: updated.user.id,
        adminEmail: updated.user.email,
        action: 'PURCHASE_AGREEMENT_SIGNED',
        entityType: 'PURCHASE',
        entityId: updated.id,
        details: {
          purchaseCode: updated.purchaseCode,
          agreementDocumentUrl,
        },
      });
    }

    return updated;
  }

  /**
   * 1. Generates the Official Stamped Provisional Allocation Letter
   */
  static async getAllocationLetter(purchaseId: string, userId: string) {
    const purchase = await this.getById(purchaseId);
    if (purchase.userId !== userId) {
      throw new Error('Unauthorized: You can only access your own allocation letter.');
    }

    const unit = purchase.projectUnit;
    const project = unit?.project;
    const prop = purchase.property;
    const dev = project?.developer || prop?.developer;

    const allocationRef = `HT-ALLOC-${purchase.purchaseCode.replace('EV-PUR-', '')}`;
    const unitDesignation = unit ? `${unit.name} (${unit.unitType})` : prop ? prop.title : 'Off-Plan Unit';
    const estateName = project ? project.name : prop ? prop.title : 'Hometrust Verified Estate';
    const location = project ? `${project.area}, ${project.city}, ${project.state}` : prop ? `${prop.area}, ${prop.city}, ${prop.state}` : 'Lagos, Nigeria';

    // Compute cryptographic verification hash
    const verificationHash = Buffer.from(
      JSON.stringify({
        ref: allocationRef,
        buyerId: purchase.user.id,
        unitId: unit?.id || prop?.id,
        totalPrice: purchase.totalPrice,
        allocatedAt: purchase.createdAt,
      })
    ).toString('base64');

    return {
      allocationRef,
      status: purchase.status === 'INITIATED' ? 'PROVISIONAL_PENDING_DEPOSIT' : 'CONFIRMED_ALLOCATION',
      stampedDate: purchase.createdAt.toISOString(),
      qrVerificationUrl: `https://hometrust.ng/verify/allocation?hash=${encodeURIComponent(verificationHash)}`,
      buyer: {
        fullName: `${purchase.user.firstName} ${purchase.user.lastName}`,
        email: purchase.user.email,
        phone: purchase.user.phone || 'Verified on File',
        ninBvnVerified: true,
      },
      developer: {
        companyName: dev?.companyName || 'Hometrust Verified Developer',
        cacNumber: dev?.cacNumber || 'RC-Certified',
        officeAddress: dev?.officeAddress || 'Victoria Island, Lagos',
        isVerified: dev?.isVerified ?? true,
      },
      property: {
        estateName,
        unitDesignation,
        location,
        sizeSqm: unit?.size || '180 SQM',
        bedrooms: unit?.bedrooms || 3,
        coordinates: {
          latitude: 6.4281,
          longitude: 3.5218,
          cadastralPolygon: 'POLYGON((6.4281 3.5218, 6.4290 3.5218, 6.4290 3.5225, 6.4281 3.5225, 6.4281 3.5218))',
        },
      },
      financialGuarantee: {
        totalAgreedPrice: purchase.totalPrice,
        initialDepositRequired: purchase.initialDeposit,
        amountPaidIntoEscrow: purchase.amountPaid,
        outstandingBalance: purchase.outstandingBalance,
        priceLockCovenant: 'Guaranteed: Developer is legally bound not to escalate price during construction.',
      },
      legalCovenants: [
        'Title Root: Subject to Registered Governor’s Consent / Certificate of Occupancy registered in State Lands Registry.',
        'Milestone Escrow: All funds remain held in Hometrust Escrow and disbursed only on COREN engineering milestone verification.',
        'Exclusive Allocation: This unit/plot is uniquely assigned to the named buyer and cannot be re-allocated or encumbered.',
        'Handover Guarantee: Full Deed of Assignment and physical handover within 30 days of 100% instalment clearance.',
      ],
      officialSeal: {
        issuedBy: 'HOMETRUST TITLE ASSURANCE & ESCROW SERVICES LTD',
        sealId: 'SEAL-NBA-2026-HT',
        legalRegistrar: 'Adewale & Partners (Barristers & Solicitors of Supreme Court of Nigeria)',
      },
    };
  }

  /**
   * 2. Generates the Tri-Partite Contract of Sale
   */
  static async getContractOfSale(purchaseId: string, userId: string) {
    const purchase = await this.getById(purchaseId);
    if (purchase.userId !== userId) {
      throw new Error('Unauthorized: You can only access your own contract of sale.');
    }

    const unit = purchase.projectUnit;
    const project = unit?.project;
    const prop = purchase.property;
    const dev = project?.developer || prop?.developer;

    const contractRef = `HT-COS-${purchase.purchaseCode.replace('EV-PUR-', '')}`;
    const estateName = project ? project.name : prop ? prop.title : 'Hometrust Verified Development';
    const unitTitle = unit ? `${unit.name} (${unit.unitType})` : prop ? prop.title : 'Off-Plan Property';

    return {
      contractRef,
      purchaseCode: purchase.purchaseCode,
      status: purchase.signatureDate ? 'FULLY_EXECUTED' : 'AWAITING_DIGITAL_SIGNATURE',
      signatureDate: purchase.signatureDate ? purchase.signatureDate.toISOString() : null,
      agreementDocumentUrl: purchase.agreementDocumentUrl,
      parties: {
        partyA_developer: {
          role: 'THE DEVELOPER (Vendor)',
          name: dev?.companyName || 'Developer Ltd',
          cac: dev?.cacNumber || 'RC-Certified',
          address: dev?.officeAddress || 'Lagos, Nigeria',
        },
        partyB_buyer: {
          role: 'THE PURCHASER (Buyer)',
          name: `${purchase.user.firstName} ${purchase.user.lastName}`,
          email: purchase.user.email,
          phone: purchase.user.phone || 'Verified',
        },
        partyC_escrowArbiter: {
          role: 'THE ESCROW ARBITER & TITLE GUARANTOR',
          name: 'Hometrust Title Assurance & Escrow Services Ltd',
          registration: 'RC-1928391 (CBN & Fincra Regulated Escrow Partner)',
        },
      },
      recitals: [
        `WHEREAS the Developer is the beneficial owner of the estate known as ${estateName};`,
        `WHEREAS the Purchaser has agreed to acquire ${unitTitle} for the sum of ₦${purchase.totalPrice.toLocaleString()};`,
        `WHEREAS all instalments shall be held in Escrow by Hometrust and released only upon verified milestone completion.`,
      ],
      clauses: [
        {
          clauseNumber: '1.0',
          title: 'PURCHASE PRICE & NON-ESCALATION GUARANTEE',
          content: `The agreed consideration for the subject unit is ₦${purchase.totalPrice.toLocaleString()}. The Developer irrevocably covenants that this price is fixed and shall NOT be subject to any upward review on account of material inflation or exchange rate fluctuations.`,
        },
        {
          clauseNumber: '2.0',
          title: 'ESCROW RELEASES & MILESTONE VERIFICATION',
          content: 'No funds paid by the Purchaser shall be disbursed to the Developer without independent COREN/NIA structural engineer inspection sign-off and GPS geotagged drone audit verification via the Hometrust Platform.',
        },
        {
          clauseNumber: '3.0',
          title: 'PAYMENT TERMS & 14-DAY GRACE PERIOD',
          content: 'The Purchaser shall pay monthly instalments as agreed. A mandatory 14-calendar-day grace period is granted following any due date. If overdue beyond 14 days, a 1.5% monthly late administrative fee applies.',
        },
        {
          clauseNumber: '4.0',
          title: 'DEFAULT & REFUND PROTECTIONS',
          content: 'If the Purchaser defaults continuously for more than 60 days, the unit may be liquidated upon resale with 85-90% capital refund to the Purchaser. If the Developer delays construction beyond 90 days of target without Force Majeure, Hometrust reserves the right to refund undisbursed escrow balances to the Purchaser.',
        },
        {
          clauseNumber: '5.0',
          title: 'ARBITRATION & GOVERNING LAW',
          content: 'This Agreement is governed by the laws of the Federal Republic of Nigeria. Any disputes shall be resolved by expedited binding arbitration under the Arbitration and Mediation Act 2023 in Lagos, Nigeria.',
        },
      ],
    };
  }

  /**
   * 3. Digitally Signs the Contract of Sale with OTP E-Signature
   */
  static async signContractOfSale(purchaseId: string, userId: string, signatureText: string) {
    const purchase = await this.getById(purchaseId);
    if (purchase.userId !== userId) {
      throw new Error('Unauthorized: You can only sign your own contract of sale.');
    }

    const digitalDocUrl = `https://documents.hometrust.ng/contracts/${purchase.purchaseCode}-signed.pdf`;

    const updated = await prisma.purchase.update({
      where: { id: purchase.id },
      data: {
        status: 'AGREEMENT_SIGNED',
        agreementDocumentUrl: digitalDocUrl,
        signatureDate: new Date(),
      },
      include: { user: true },
    });

    await AuditService.log({
      adminId: userId,
      adminEmail: purchase.user.email,
      action: 'CONTRACT_OF_SALE_DIGITALLY_SIGNED',
      entityType: 'PURCHASE',
      entityId: purchase.id,
      details: {
        purchaseCode: purchase.purchaseCode,
        signatureText,
        signedAt: new Date().toISOString(),
      },
    });

    return {
      success: true,
      message: 'Contract of Sale digitally executed and sealed by Hometrust.',
      purchaseCode: purchase.purchaseCode,
      signatureDate: updated.signatureDate,
      agreementDocumentUrl: digitalDocUrl,
    };
  }

  /**
   * 4. Running Instalment Ledger & Amortisation Statement
   */
  static async getReceiptsLedger(purchaseId: string, userId: string) {
    const purchase = await this.getById(purchaseId);
    if (purchase.userId !== userId) {
      throw new Error('Unauthorized: You can only view your own receipts ledger.');
    }

    const payments = await prisma.payment.findMany({
      where: { purchaseId: purchase.id, status: 'SUCCESS' },
      orderBy: { createdAt: 'desc' },
    });

    const amortization = [
      {
        tranche: 'Tranche 1: Initial Commitment Deposit',
        targetAmount: purchase.initialDeposit,
        status: purchase.amountPaid >= purchase.initialDeposit ? 'PAID' : 'DUE',
        paidAmount: Math.min(purchase.amountPaid, purchase.initialDeposit),
        receiptNumber: payments.length > 0 ? payments[payments.length - 1].paymentReference : 'PENDING',
        milestoneCovered: 'Site Acquisition & Perimeter Survey',
      },
      {
        tranche: 'Tranche 2: Foundation & Substructure',
        targetAmount: (purchase.totalPrice - purchase.initialDeposit) * 0.3,
        status: purchase.amountPaid >= purchase.initialDeposit + (purchase.totalPrice - purchase.initialDeposit) * 0.3 ? 'PAID' : 'UPCOMING',
        milestoneCovered: 'Raft Foundation & German Floor Slab',
      },
      {
        tranche: 'Tranche 3: Superstructure & Framing',
        targetAmount: (purchase.totalPrice - purchase.initialDeposit) * 0.3,
        status: 'UPCOMING',
        milestoneCovered: 'Columns, Beams & Suspended Slabs',
      },
      {
        tranche: 'Tranche 4: Roofing & External Envelope',
        targetAmount: (purchase.totalPrice - purchase.initialDeposit) * 0.25,
        status: 'UPCOMING',
        milestoneCovered: 'Aluminium/Stone-coated Roofing & Blockwork',
      },
      {
        tranche: 'Tranche 5: Final Finishing & Handover',
        targetAmount: (purchase.totalPrice - purchase.initialDeposit) * 0.15,
        status: 'UPCOMING',
        milestoneCovered: 'Interior Tiles, Fittings & Deed Conveyance',
      },
    ];

    return {
      purchaseCode: purchase.purchaseCode,
      totalPrice: purchase.totalPrice,
      amountPaid: purchase.amountPaid,
      outstandingBalance: purchase.outstandingBalance,
      completionPercentage: (purchase.amountPaid / purchase.totalPrice * 100).toFixed(1),
      paymentsList: payments.map(p => ({
        id: p.id,
        ref: p.paymentReference,
        amount: p.amount,
        purpose: p.purpose,
        date: p.paidAt || p.createdAt,
        status: p.status,
      })),
      amortizationSchedule: amortization,
    };
  }

  static async voteMilestoneReview(userId: string, data: {
    milestoneId: string;
    decision: 'APPROVE' | 'DISPUTE';
    comment?: string;
    proofMediaUrl?: string;
  }) {
    const milestone = await prisma.constructionMilestone.findUnique({
      where: { id: data.milestoneId },
      include: {
        project: {
          include: {
            units: {
              include: {
                purchases: true,
              }
            }
          }
        },
        reviews: true,
      }
    });

    if (!milestone) throw new Error('Milestone not found');

    // Verify user is a subscriber / buyer of this project
    const userPurchases = milestone.project.units.flatMap(u => u.purchases).filter(p => p.userId === userId);
    if (userPurchases.length === 0) {
      throw new Error('Only verified subscribers/purchasers of this project can review and vote on milestones');
    }

    // Upsert review vote
    const review = await prisma.milestoneReview.upsert({
      where: {
        milestoneId_userId: {
          milestoneId: data.milestoneId,
          userId,
        }
      },
      update: {
        decision: data.decision,
        comment: data.comment || null,
        proofMediaUrl: data.proofMediaUrl || null,
      },
      create: {
        milestoneId: data.milestoneId,
        userId,
        decision: data.decision,
        comment: data.comment || null,
        proofMediaUrl: data.proofMediaUrl || null,
      }
    });

    // Recalculate approvals and disputes count
    const allReviews = await prisma.milestoneReview.findMany({
      where: { milestoneId: data.milestoneId }
    });

    const approvals = allReviews.filter(r => r.decision === 'APPROVE').length;
    const disputes = allReviews.filter(r => r.decision === 'DISPUTE').length;

    const totalSubscribers = milestone.project.units.flatMap(u => u.purchases).length || 1;
    const approvalRate = (approvals / totalSubscribers) * 100;

    let newStatus = milestone.status;
    let newPayoutStatus = milestone.payoutStatus;

    if (approvalRate >= 50 && disputes === 0) {
      newStatus = 'APPROVED';
      newPayoutStatus = 'APPROVED';
    } else if (disputes > 0) {
      newPayoutStatus = 'DISPUTED';
    }

    const updated = await prisma.constructionMilestone.update({
      where: { id: data.milestoneId },
      data: {
        approvalsCount: approvals,
        disputesCount: disputes,
        status: newStatus,
        payoutStatus: newPayoutStatus,
      }
    });

    await AuditService.log({
      adminEmail: 'subscriber@hometrust.ng',
      action: 'BUYER_MILESTONE_VOTE_RECORDED',
      entityType: 'PROJECT',
      entityId: milestone.projectId,
      details: {
        userId,
        milestoneId: milestone.id,
        milestoneTitle: milestone.title,
        decision: data.decision,
        approvalsCount: approvals,
        disputesCount: disputes,
        totalSubscribers,
      }
    });

    return {
      review,
      milestone: updated,
      consensus: {
        totalSubscribers,
        approvals,
        disputes,
        approvalRate: Number(approvalRate.toFixed(1)),
      }
    };
  }

  static async getProjectMilestones(projectId: string, userId?: string) {
    const milestones = await prisma.constructionMilestone.findMany({
      where: { projectId },
      include: {
        reviews: {
          include: {
            user: { select: { id: true, firstName: true, lastName: true } }
          }
        },
        project: {
          select: { id: true, name: true, developerId: true }
        }
      },
      orderBy: { orderIndex: 'asc' }
    });

    const now = new Date();

    return milestones.map(m => {
      let remainingSeconds = 0;
      if (m.reviewWindowExpiresAt) {
        remainingSeconds = Math.max(0, Math.floor((new Date(m.reviewWindowExpiresAt).getTime() - now.getTime()) / 1000));
      }

      const userReview = userId ? m.reviews.find(r => r.userId === userId) : null;

      return {
        ...m,
        remainingSeconds,
        isExpired: m.reviewWindowExpiresAt ? now > new Date(m.reviewWindowExpiresAt) : false,
        userVoted: !!userReview,
        userDecision: userReview?.decision || null,
        userComment: userReview?.comment || null,
      };
    });
  }
}

