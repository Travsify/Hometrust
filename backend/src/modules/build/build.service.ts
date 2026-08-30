import { prisma } from '../../utils/prisma';
import { AuditService } from '../audit/audit.service';
import { NotificationsService } from '../notifications/notifications.service';
import { ChatService } from '../chat/chat.service';

export interface CreateBuildRequestParams {
  userId: string;
  projectTitle: string;
  buildingType: string;
  state: string;
  city: string;
  lga?: string;
  siteAddress: string;
  landOwnershipStatus?: string;
  landTitleType?: string;
  estimatedBudget: number;
  targetStartDate: string;
  architecturalStatus?: string;
  architecturalDrawingsUrl?: string;
  specialRequirements?: string;
}

export class BuildService {
  /**
   * Get Active Building & Construction Fee Settings (Admin configurable)
   */
  static async getBuildFees() {
    const [subFeeSetting, consultFeeSetting, mgmtFeeSetting] = await Promise.all([
      prisma.systemSetting.findUnique({ where: { key: 'BUILD_SUBMISSION_FEE' } }),
      prisma.systemSetting.findUnique({ where: { key: 'BUILD_CONSULTATION_FEE' } }),
      prisma.systemSetting.findUnique({ where: { key: 'BUILD_MANAGEMENT_FEE_PCT' } }),
    ]);

    const submissionFee = subFeeSetting ? parseFloat(subFeeSetting.value) || 25000 : 25000;
    const consultationFee = consultFeeSetting ? parseFloat(consultFeeSetting.value) || 50000 : 50000;
    const managementFeePct = mgmtFeeSetting ? parseFloat(mgmtFeeSetting.value) || 6.0 : 6.0;

    return {
      submissionFee,
      consultationFee,
      managementFeePercentage: managementFeePct,
    };
  }

  /**
   * 1. Submit a new custom property building request with ₦25,000 commitment fee
   */
  static async createRequest(params: CreateBuildRequestParams) {
    const requestCode = `HT-BLD-${Math.floor(10000 + Math.random() * 90000)}`;
    const budget = Math.max(0, Number(params.estimatedBudget) || 0);

    const fees = await this.getBuildFees();
    const submissionFee = fees.submissionFee;

    // Check user's dedicated escrow virtual account balance
    const virtualAccount = await prisma.virtualAccount.findFirst({
      where: { userId: params.userId },
    });

    const balance = virtualAccount?.balance || 0;
    if (!virtualAccount || balance < submissionFee) {
      return {
        success: false,
        code: 'INSUFFICIENT_FUNDS',
        requiredAmount: submissionFee,
        currentBalance: balance,
        deficit: Math.max(0, submissionFee - balance),
      };
    }

    // Deduct ₦25,000 submission commitment fee and create project atomically
    const [updatedAccount, request] = await prisma.$transaction([
      prisma.virtualAccount.update({
        where: { id: virtualAccount.id },
        data: { balance: { decrement: submissionFee } },
      }),
      prisma.buildRequest.create({
        data: {
          requestCode,
          userId: params.userId,
          projectTitle: params.projectTitle,
          buildingType: params.buildingType,
          state: params.state,
          city: params.city,
          lga: params.lga || null,
          siteAddress: params.siteAddress,
          landOwnershipStatus: params.landOwnershipStatus || 'OWNED_WITH_TITLE',
          landTitleType: params.landTitleType || 'C_OF_O',
          estimatedBudget: budget,
          targetStartDate: params.targetStartDate,
          architecturalStatus: params.architecturalStatus || 'NEED_ARCHITECT',
          architecturalDrawingsUrl: params.architecturalDrawingsUrl || null,
          specialRequirements: params.specialRequirements || null,
          submissionFee,
          isSubmissionFeePaid: true,
          consultationFee: fees.consultationFee,
          isConsultationPaid: false,
          totalContractValue: budget,
          managementFeePercentage: fees.managementFeePercentage,
          managementFeeAmount: (budget * fees.managementFeePercentage) / 100,
          defectRetentionPercentage: 5.0,
          status: 'PENDING_ADMIN_APPROVAL',
        },
      }),
      prisma.payment.create({
        data: {
          userId: params.userId,
          amount: submissionFee,
          currency: 'NGN',
          purpose: 'BUILD_REQUEST_SUBMISSION_FEE',
          paystackChannel: 'wallet_transfer',
          paymentReference: `HT-PAY-SUB-${Date.now()}`,
          receiptNumber: `HT-RCP-SUB-${Date.now()}`,
          status: 'SUCCESS',
          totalAmount: submissionFee,
          paidAt: new Date(),
        },
      }),
    ]);

    // Create standard 6-phase construction milestone blueprint
    const milestoneTemplates = [
      {
        stageNumber: 1,
        stageName: 'STAGE_1_SUBSTRUCTURE_FOUNDATION',
        title: 'Phase 1: Substructure & Foundation',
        description: 'Site clearing, excavation, blinding, foundation rebar reinforcement, German floor concrete cast (DPC).',
        targetDurationWeeks: 4,
        percentage: 0.20, // 20%
      },
      {
        stageNumber: 2,
        stageName: 'STAGE_2_SUPERSTRUCTURE_LINTEL_DECKING',
        title: 'Phase 2: Superstructure & First Floor Slab',
        description: 'Setting of hollow/solid sandcrete blocks, reinforced columns, lintels, formwork, and first-floor concrete decking.',
        targetDurationWeeks: 5,
        percentage: 0.25, // 25%
      },
      {
        stageNumber: 3,
        stageName: 'STAGE_3_ROOFING_CARPENTRY',
        title: 'Phase 3: Roof Framing, Parapet & Step-Tiles',
        description: 'Hardwood roof carcass truss installation, aluminum/stone-coated step-tiles, parapet casting, and fascia boards.',
        targetDurationWeeks: 3,
        percentage: 0.15, // 15%
      },
      {
        stageNumber: 4,
        stageName: 'STAGE_4_PLASTERING_MEP_ROUGH_IN',
        title: 'Phase 4: Internal/External Plastering & MEP Rough-In',
        description: 'Conduit electrical piping, plumbing rough-in, internal wall plastering, screeding, and POP ceiling framework.',
        targetDurationWeeks: 4,
        percentage: 0.15, // 15%
      },
      {
        stageNumber: 5,
        stageName: 'STAGE_5_FINISHING_TILING_PAINTING',
        title: 'Phase 5: Architectural Finishes & Installations',
        description: 'Vitrified floor/wall tiling, security steel doors, aluminum casement windows, sanitary wares, and first coat painting.',
        targetDurationWeeks: 4,
        percentage: 0.20, // 20%
      },
      {
        stageNumber: 6,
        stageName: 'STAGE_6_HANDOVER_DEFECT_LIABILITY',
        title: 'Phase 6: Final Handover & 90-Day Defect Retention',
        description: '5% retention fund held in escrow for 90 days after key handover to guarantee zero structural or MEP defects.',
        targetDurationWeeks: 12,
        percentage: 0.05, // 5%
      },
    ];

    for (const m of milestoneTemplates) {
      await prisma.buildMilestone.create({
        data: {
          buildRequestId: request.id,
          stageNumber: m.stageNumber,
          stageName: m.stageName,
          title: m.title,
          description: m.description,
          targetDurationWeeks: m.targetDurationWeeks,
          amount: budget * m.percentage,
          status: 'PENDING_DEPOSIT',
        },
      });
    }

    // Dispatch in-app push & activity audit email
    await NotificationsService.createAndDispatch({
      userId: params.userId,
      title: '🏗️ Building Request Submitted (₦25,000 Commitment Paid)',
      message: `Your Charter-A-Builder request for "${params.projectTitle}" (${requestCode}) has been received. A team expert is reviewing your proposal and will initiate an in-app chat with you shortly.`,
      type: 'MILESTONE',
      actionDetails: [
        { label: 'Request Code', value: requestCode },
        { label: 'Project Title', value: params.projectTitle },
        { label: 'Submission Fee', value: `₦${submissionFee.toLocaleString()}` },
        { label: 'Estimated Budget', value: `₦${budget.toLocaleString()}` },
        { label: 'Status', value: 'Pending Team Expert Review ⏳' },
      ],
    });

    return {
      success: true,
      request: await this.getRequestById(request.id, params.userId),
      remainingBalance: updatedAccount.balance,
    };
  }

  /**
   * 2. Admin: Approves Build Request & Starts Direct In-App Chat with the User
   */
  static async adminApproveBuildRequest(requestId: string, adminUser: any, adminNotes?: string) {
    const request = await prisma.buildRequest.findUnique({
      where: { id: requestId },
      include: { user: true },
    });

    if (!request) throw new Error('Build request not found');

    const updated = await prisma.buildRequest.update({
      where: { id: requestId },
      data: {
        status: 'APPROVED_IN_CONSULTATION',
        approvedByAdminId: adminUser.id,
        approvedAt: new Date(),
        assignedEngineerId: adminUser.id,
        adminNotes: adminNotes || 'Approved by Hometrust Admin Director',
      },
      include: {
        user: true,
        milestones: true,
        assignedEngineer: true,
      },
    });

    // 1. Automatically open in-app direct chat thread between Admin and User
    const conversation = await ChatService.getOrCreateConversation(request.userId, adminUser.id);

    // 2. Send opening greeting message in the chat thread
    const welcomeMsg = `Hello ${request.user.firstName}! Your building proposal for "${request.projectTitle}" (${request.requestCode}) with an estimated budget of ₦${request.estimatedBudget.toLocaleString()} has been reviewed and approved by Hometrust Engineering. I am your assigned Project Lead. Let's discuss your site requirements, architectural drawings, and milestone schedule right here in this chat.`;

    await ChatService.sendMessage({
      conversationId: conversation.id,
      senderId: adminUser.id,
      content: welcomeMsg,
    });

    // 3. Dispatch in-app push notification & email to user
    await NotificationsService.createAndDispatch({
      userId: request.userId,
      title: '🎉 Building Proposal Approved & Chat Active',
      message: `Your building request "${request.projectTitle}" (${request.requestCode}) has been approved! Admin is now chatting with you in-app. Open your Messages Inbox to reply.`,
      type: 'MILESTONE',
      actionDetails: [
        { label: 'Project Title', value: request.projectTitle },
        { label: 'Request Code', value: request.requestCode },
        { label: 'Status', value: 'Approved & Chat Active 💬' },
        { label: 'Assigned Lead', value: `${adminUser.firstName || 'Hometrust'} ${adminUser.lastName || 'Director'}` },
      ],
    });

    await AuditService.log({
      adminId: adminUser.id,
      adminEmail: adminUser.email,
      action: 'BUILD_REQUEST_APPROVED',
      entityType: 'BUILD_REQUEST',
      entityId: request.id,
      details: {
        requestCode: request.requestCode,
        title: request.projectTitle,
        budget: request.estimatedBudget,
      },
    });

    return {
      success: true,
      message: 'Build proposal approved and in-app chat thread opened with user.',
      request: updated,
      conversationId: conversation.id,
    };
  }

  /**
   * 3. Pay Consultation Fee (₦50,000) from Dedicated Virtual Account Wallet
   */
  static async payConsultationFee(requestId: string, userId: string) {
    const request = await prisma.buildRequest.findUnique({
      where: { id: requestId },
      include: { user: true },
    });

    if (!request) throw new Error('Build request not found');
    if (request.userId !== userId) throw new Error('Unauthorized access');
    if (request.isConsultationPaid) {
      return { success: true, message: 'Consultation fee already paid', request };
    }

    const fee = request.consultationFee;
    const virtualAccount = await prisma.virtualAccount.findFirst({
      where: { userId },
    });

    const balance = virtualAccount?.balance || 0;
    if (!virtualAccount || balance < fee) {
      return {
        success: false,
        code: 'INSUFFICIENT_FUNDS',
        requiredAmount: fee,
        currentBalance: balance,
        deficit: Math.max(0, fee - balance),
      };
    }

    // Deduct fee and update request atomically
    const [updatedAccount, updatedRequest] = await prisma.$transaction([
      prisma.virtualAccount.update({
        where: { id: virtualAccount.id },
        data: { balance: { decrement: fee } },
      }),
      prisma.buildRequest.update({
        where: { id: requestId },
        data: {
          isConsultationPaid: true,
          status: 'ENGINEER_ASSIGNED',
        },
      }),
      prisma.payment.create({
        data: {
          userId,
          amount: fee,
          currency: 'NGN',
          purpose: 'BUILD_ENGINEER_CONSULTATION',
          paystackChannel: 'wallet_transfer',
          paymentReference: `HT-PAY-BLD-${Date.now()}`,
          receiptNumber: `HT-RCP-BLD-${Date.now()}`,
          status: 'SUCCESS',
          totalAmount: fee,
          paidAt: new Date(),
        },
      }),
    ]);

    // Dispatch in-app push & email
    await NotificationsService.createAndDispatch({
      userId,
      title: '👷 COREN Engineer Assigned & Consultation Active',
      message: `Your ₦${fee.toLocaleString()} consultation fee for ${request.projectTitle} was successful. An accredited structural engineer has been assigned to your project.`,
      type: 'MILESTONE',
      actionDetails: [
        { label: 'Project Title', value: request.projectTitle },
        { label: 'Consultation Fee', value: `₦${fee.toLocaleString()}` },
        { label: 'Status', value: 'Engineer Assigned ✅' },
      ],
    });

    return {
      success: true,
      request: await this.getRequestById(requestId, userId),
      remainingBalance: updatedAccount.balance,
    };
  }

  /**
   * 4. Fund a specific construction milestone into Escrow
   */
  static async fundMilestone(milestoneId: string, userId: string) {
    const milestone = await prisma.buildMilestone.findUnique({
      where: { id: milestoneId },
      include: { buildRequest: true },
    });

    if (!milestone) throw new Error('Milestone not found');
    if (milestone.buildRequest.userId !== userId) throw new Error('Unauthorized');
    if (milestone.status !== 'PENDING_DEPOSIT') {
      return { success: true, message: 'Milestone is already funded or in progress', milestone };
    }

    const amount = milestone.amount;
    const virtualAccount = await prisma.virtualAccount.findFirst({
      where: { userId },
    });

    const balance = virtualAccount?.balance || 0;
    if (!virtualAccount || balance < amount) {
      return {
        success: false,
        code: 'INSUFFICIENT_FUNDS',
        requiredAmount: amount,
        currentBalance: balance,
        deficit: Math.max(0, amount - balance),
      };
    }

    // Deduct from wallet and lock in escrow
    const [updatedAccount, updatedMilestone] = await prisma.$transaction([
      prisma.virtualAccount.update({
        where: { id: virtualAccount.id },
        data: { balance: { decrement: amount } },
      }),
      prisma.buildMilestone.update({
        where: { id: milestoneId },
        data: { status: 'FUNDED_IN_ESCROW' },
      }),
      prisma.buildRequest.update({
        where: { id: milestone.buildRequestId },
        data: { status: 'ACTIVE_CONSTRUCTION' },
      }),
      prisma.payment.create({
        data: {
          userId,
          amount,
          currency: 'NGN',
          purpose: `BUILD_MILESTONE_${milestone.stageNumber}`,
          paystackChannel: 'wallet_transfer',
          paymentReference: `HT-PAY-BLD-MS-${Date.now()}`,
          receiptNumber: `HT-RCP-BLD-MS-${Date.now()}`,
          status: 'SUCCESS',
          totalAmount: amount,
          paidAt: new Date(),
        },
      }),
    ]);

    await NotificationsService.createAndDispatch({
      userId,
      title: `🔒 Milestone ${milestone.stageNumber} Funded in Escrow`,
      message: `₦${amount.toLocaleString()} for "${milestone.title}" has been locked in Hometrust Escrow. The contractor has been authorized to commence works.`,
      type: 'PAYMENT',
      actionDetails: [
        { label: 'Milestone', value: milestone.title },
        { label: 'Amount Locked', value: `₦${amount.toLocaleString()}` },
        { label: 'Status', value: 'Funded in Escrow 🔒' },
      ],
    });

    return {
      success: true,
      milestone: updatedMilestone,
      remainingBalance: updatedAccount.balance,
    };
  }

  /**
   * 5. Engineer Submits Completed Milestone for Audit
   */
  static async submitMilestoneCompletion(milestoneId: string, engineerId: string, data: { completionPhotos?: string[]; engineerNotes?: string; geofencedVideoUrl?: string }) {
    const milestone = await prisma.buildMilestone.findUnique({
      where: { id: milestoneId },
      include: { buildRequest: true },
    });

    if (!milestone) throw new Error('Milestone not found');

    const updated = await prisma.buildMilestone.update({
      where: { id: milestoneId },
      data: {
        status: 'AUDIT_SUBMITTED',
        completionPhotos: data.completionPhotos ? JSON.stringify(data.completionPhotos) : undefined,
        engineerNotes: data.engineerNotes || undefined,
        geofencedVideoUrl: data.geofencedVideoUrl || undefined,
      },
    });

    // Notify buyer that stage is ready for inspection
    await NotificationsService.createAndDispatch({
      userId: milestone.buildRequest.userId,
      title: `📸 Milestone ${milestone.stageNumber} Completed: Audit Ready`,
      message: `The engineer has completed "${milestone.title}". Please review the completion photos, geofenced video, and schedule an inspection or authorize disbursement.`,
      type: 'MILESTONE',
      actionDetails: [
        { label: 'Stage', value: milestone.title },
        { label: 'Status', value: 'Audit Submitted - Awaiting Inspection' },
      ],
    });

    return updated;
  }

  /**
   * 6. Buyer Authorizes Milestone Payout Release
   */
  static async authorizeAndDisburseMilestone(milestoneId: string, userId: string) {
    const milestone = await prisma.buildMilestone.findUnique({
      where: { id: milestoneId },
      include: {
        buildRequest: {
          include: {
            assignedEngineer: {
              include: { virtualAccounts: true },
            },
          },
        },
      },
    });

    if (!milestone) throw new Error('Milestone not found');
    if (milestone.buildRequest.userId !== userId) throw new Error('Unauthorized');

    const totalAmount = milestone.amount;
    const mgmtFee = (totalAmount * milestone.buildRequest.managementFeePercentage) / 100;
    const netDisbursement = totalAmount - mgmtFee;

    const engineerAccountId = milestone.buildRequest.assignedEngineer?.virtualAccounts?.[0]?.id;

    // Release disbursement to engineer wallet
    await prisma.$transaction([
      prisma.buildMilestone.update({
        where: { id: milestoneId },
        data: {
          status: 'DISBURSED',
          buyerAuthorizedAt: new Date(),
          disbursedAt: new Date(),
        },
      }),
      ...(engineerAccountId
        ? [
            prisma.virtualAccount.update({
              where: { id: engineerAccountId },
              data: { balance: { increment: netDisbursement } },
            }),
          ]
        : []),
    ]);

    await NotificationsService.createAndDispatch({
      userId,
      title: `💸 Milestone ${milestone.stageNumber} Funds Disbursed`,
      message: `₦${netDisbursement.toLocaleString()} for "${milestone.title}" has been released to the project engineer.`,
      type: 'PAYMENT',
      actionDetails: [
        { label: 'Milestone', value: milestone.title },
        { label: 'Gross Amount', value: `₦${totalAmount.toLocaleString()}` },
        { label: 'Platform Management Fee (6%)', value: `₦${mgmtFee.toLocaleString()}` },
        { label: 'Net Disbursed', value: `₦${netDisbursement.toLocaleString()}` },
      ],
    });

    return {
      success: true,
      message: 'Milestone payout authorized and disbursed successfully',
    };
  }

  /**
   * 7. Get all custom building projects for a user
   */
  static async getUserBuildRequests(userId: string) {
    const requests = await prisma.buildRequest.findMany({
      where: { userId },
      orderBy: { createdAt: 'desc' },
      include: {
        milestones: {
          orderBy: { stageNumber: 'asc' },
        },
        assignedEngineer: {
          select: {
            id: true,
            firstName: true,
            lastName: true,
            avatarUrl: true,
            developer: {
              select: {
                companyName: true,
                isVerified: true,
              },
            },
          },
        },
      },
    });

    return requests.map((r) => {
      const completedCount = r.milestones.filter((m) => m.status === 'DISBURSED').length;
      const progressPercentage = Math.round((completedCount / (r.milestones.length || 1)) * 100);

      return {
        ...r,
        progressPercentage,
        completedMilestones: completedCount,
        totalMilestones: r.milestones.length,
      };
    });
  }

  /**
   * 8. Get specific build request details
   */
  static async getRequestById(idOrCode: string, userId?: string) {
    const request = await prisma.buildRequest.findFirst({
      where: {
        OR: [{ id: idOrCode }, { requestCode: idOrCode }],
      },
      include: {
        milestones: {
          orderBy: { stageNumber: 'asc' },
        },
        assignedEngineer: {
          select: {
            id: true,
            firstName: true,
            lastName: true,
            avatarUrl: true,
            developer: {
              select: {
                companyName: true,
                isVerified: true,
              },
            },
          },
        },
        user: {
          select: {
            id: true,
            firstName: true,
            lastName: true,
            email: true,
            phone: true,
          },
        },
      },
    });

    if (!request) throw new Error('Build request not found');

    const completedCount = request.milestones.filter((m) => m.status === 'DISBURSED').length;
    const progressPercentage = Math.round((completedCount / (request.milestones.length || 1)) * 100);

    return {
      ...request,
      progressPercentage,
      completedMilestones: completedCount,
      totalMilestones: request.milestones.length,
    };
  }

  /**
   * 9. Admin: List all build requests with pagination & filters
   */
  static async adminListRequests(filters?: { status?: string; search?: string; page?: number; limit?: number }) {
    const page = filters?.page || 1;
    const limit = filters?.limit || 50;
    const skip = (page - 1) * limit;

    const where: any = {};
    if (filters?.status) where.status = filters.status;
    if (filters?.search) {
      where.OR = [
        { requestCode: { contains: filters.search, mode: 'insensitive' } },
        { projectTitle: { contains: filters.search, mode: 'insensitive' } },
        { user: { email: { contains: filters.search, mode: 'insensitive' } } },
        { user: { firstName: { contains: filters.search, mode: 'insensitive' } } },
        { user: { lastName: { contains: filters.search, mode: 'insensitive' } } },
      ];
    }

    const [requests, total] = await Promise.all([
      prisma.buildRequest.findMany({
        where,
        skip,
        take: limit,
        orderBy: { createdAt: 'desc' },
        include: {
          user: { select: { id: true, firstName: true, lastName: true, email: true, phone: true } },
          assignedEngineer: { select: { id: true, firstName: true, lastName: true, email: true } },
          milestones: true,
        },
      }),
      prisma.buildRequest.count({ where }),
    ]);

    return { requests, total, page, totalPages: Math.ceil(total / limit) };
  }

  /**
   * 10. Admin: Update Building & Escrow Fee Settings
   */
  static async adminUpdateSettings(data: { submissionFee?: number; consultationFee?: number; managementFeePercentage?: number }) {
    const updates: any[] = [];

    if (data.submissionFee !== undefined) {
      updates.push(
        prisma.systemSetting.upsert({
          where: { key: 'BUILD_SUBMISSION_FEE' },
          update: { value: String(data.submissionFee) },
          create: { key: 'BUILD_SUBMISSION_FEE', value: String(data.submissionFee), description: 'Charter A Builder submission fee (NGN)' },
        })
      );
    }

    if (data.consultationFee !== undefined) {
      updates.push(
        prisma.systemSetting.upsert({
          where: { key: 'BUILD_CONSULTATION_FEE' },
          update: { value: String(data.consultationFee) },
          create: { key: 'BUILD_CONSULTATION_FEE', value: String(data.consultationFee), description: 'Charter A Builder COREN engineer consultation fee (NGN)' },
        })
      );
    }

    if (data.managementFeePercentage !== undefined) {
      updates.push(
        prisma.systemSetting.upsert({
          where: { key: 'BUILD_MANAGEMENT_FEE_PCT' },
          update: { value: String(data.managementFeePercentage) },
          create: { key: 'BUILD_MANAGEMENT_FEE_PCT', value: String(data.managementFeePercentage), description: 'Hometrust construction management commission (%)' },
        })
      );
    }

    await prisma.$transaction(updates);
    return this.getBuildFees();
  }
}
