import { prisma } from '../../utils/prisma';
import { AuditService } from '../audit/audit.service';

export class AdminService {
  static async getDashboardMetrics() {
    const [
      totalUsers,
      totalDevelopers,
      verifiedDevelopers,
      totalProperties,
      totalProjects,
      totalVerifications,
      completedVerifications,
      pendingVerifications,
      totalPurchases,
      activePurchases,
      payments,
      recentAuditLogs,
    ] = await Promise.all([
      prisma.user.count(),
      prisma.developer.count(),
      prisma.developer.count({ where: { isVerified: true } }),
      prisma.property.count(),
      prisma.project.count(),
      prisma.verificationRequest.count(),
      prisma.verificationRequest.count({ where: { status: 'COMPLETED' } }),
      prisma.verificationRequest.count({ where: { status: { in: ['SUBMITTED', 'PAYMENT_CONFIRMED', 'LEGAL_REVIEW'] } } }),
      prisma.purchase.count(),
      prisma.purchase.count({ where: { status: 'ACTIVE' } }),
      prisma.payment.findMany({
        where: { status: 'SUCCESS' },
        select: { amount: true, platformFee: true, processingFee: true, totalAmount: true },
      }),
      prisma.auditLog.findMany({
        take: 10,
        orderBy: { createdAt: 'desc' },
      }),
    ]);

    const totalVolume = payments.reduce((sum, p) => sum + p.totalAmount, 0);
    const totalPlatformFees = payments.reduce((sum, p) => sum + p.platformFee, 0);
    const totalCoreRevenue = payments.reduce((sum, p) => sum + p.amount, 0);

    return {
      metrics: {
        totalUsers,
        totalDevelopers,
        verifiedDevelopers,
        totalProperties,
        totalProjects,
        totalVerifications,
        completedVerifications,
        pendingVerifications,
        totalPurchases,
        activePurchases,
        totalVolume,
        totalPlatformFees,
        totalCoreRevenue,
      },
      charts: {
        monthlyGrowth: [
          { month: 'Jan', users: 120, verifications: 45, volume: 15000000 },
          { month: 'Feb', users: 210, verifications: 68, volume: 28000000 },
          { month: 'Mar', users: 340, verifications: 95, volume: 42000000 },
          { month: 'Apr', users: 480, verifications: 130, volume: 65000000 },
          { month: 'May', users: 620, verifications: 180, volume: 88000000 },
          { month: 'Jun', users: 790, verifications: 240, volume: 110000000 },
        ],
        propertyTypeBreakdown: [
          { name: 'Residential', count: 35 },
          { name: 'Off-Plan', count: 28 },
          { name: 'Land', count: 22 },
          { name: 'Commercial', count: 15 },
        ],
      },
      recentAuditLogs,
    };
  }

  static async getUsers(filters: { role?: string; isVerified?: string; search?: string; page?: number; limit?: number }) {
    const page = filters.page || 1;
    const limit = filters.limit || 20;
    const skip = (page - 1) * limit;

    const where: any = {};
    if (filters.role) where.role = filters.role;
    if (filters.search) {
      where.OR = [
        { email: { contains: filters.search, mode: 'insensitive' } },
        { firstName: { contains: filters.search, mode: 'insensitive' } },
        { lastName: { contains: filters.search, mode: 'insensitive' } },
        { phone: { contains: filters.search } },
      ];
    }

    if (filters.isVerified === 'true') {
      where.OR = [
        { kycVerifications: { some: { status: 'VERIFIED' } } },
        { developer: { isVerified: true } },
      ];
    } else if (filters.isVerified === 'false') {
      where.AND = [
        { kycVerifications: { none: { status: 'VERIFIED' } } },
        { OR: [{ developer: null }, { developer: { isVerified: false } }] },
      ];
    }

    const [users, total] = await Promise.all([
      prisma.user.findMany({
        where,
        skip,
        take: limit,
        orderBy: { createdAt: 'desc' },
        select: {
          id: true,
          email: true,
          firstName: true,
          lastName: true,
          phone: true,
          role: true,
          isActive: true,
          isEmailVerified: true,
          createdAt: true,
          developer: {
            select: { id: true, companyName: true, isVerified: true, verificationStatus: true },
          },
          virtualAccounts: {
            select: {
              id: true,
              accountNumber: true,
              accountName: true,
              bankName: true,
              balance: true,
              status: true,
            },
          },
          kycVerifications: {
            where: { status: 'VERIFIED' },
            select: { id: true, kycType: true, nin: true, bvn: true, verifiedAt: true },
            take: 1,
          },
        },
      }),
      prisma.user.count({ where }),
    ]);

    const formattedUsers = users.map((u) => {
      const isKycVerified = (u.kycVerifications && u.kycVerifications.length > 0) || u.developer?.isVerified || false;
      const primaryVa = u.virtualAccounts?.[0];
      return {
        id: u.id,
        email: u.email,
        name: `${u.firstName} ${u.lastName}`.trim(),
        firstName: u.firstName,
        lastName: u.lastName,
        phone: u.phone || 'N/A',
        role: u.role,
        isActive: u.isActive,
        isEmailVerified: u.isEmailVerified,
        isKycVerified,
        developer: u.developer,
        virtualAccount: primaryVa
          ? {
              accountNumber: primaryVa.accountNumber,
              accountName: primaryVa.accountName,
              bankName: primaryVa.bankName,
              balance: primaryVa.balance,
              status: primaryVa.status,
            }
          : null,
        createdAt: u.createdAt,
      };
    });

    return {
      users: formattedUsers,
      total,
      page,
      totalPages: Math.ceil(total / limit),
    };
  }

  static async updateUserStatus(userId: string, isActive: boolean, adminUser: any) {
    const user = await prisma.user.update({
      where: { id: userId },
      data: { isActive },
    });

    await AuditService.log({
      adminId: adminUser.id,
      adminEmail: adminUser.email,
      action: isActive ? 'USER_ACTIVATED' : 'USER_SUSPENDED',
      entityType: 'USER',
      entityId: userId,
    });

    return user;
  }

  static async updateUserRole(userId: string, role: string, adminUser: any) {
    const user = await prisma.user.update({
      where: { id: userId },
      data: { role },
    });

    await AuditService.log({
      adminId: adminUser.id,
      adminEmail: adminUser.email,
      action: 'USER_ROLE_UPDATED',
      entityType: 'USER',
      entityId: userId,
      details: { newRole: role },
    });

    return user;
  }

  static async revokeUserKyc(userId: string, adminUser: any, reason?: string) {
    // 1. Mark existing KYC verifications as REJECTED
    await prisma.kycVerification.updateMany({
      where: { userId },
      data: {
        status: 'REJECTED',
        rejectionReason: reason || 'Revoked by administration for re-verification',
      },
    });

    // 2. Reset user profile verification flags
    await prisma.userProfile.updateMany({
      where: { userId },
      data: {
        bvnVerified: false,
      },
    });

    // 3. Notify user in-app
    await prisma.notification.create({
      data: {
        userId,
        title: '⚠️ KYC Identity Verification Reset',
        message: `Your identity verification badge has been reset by administration (${reason || 'Profile update required'}). Please visit your profile to submit your updated verification details.`,
        type: 'KYC_STATUS',
      },
    }).catch(() => {});

    // 4. Audit Log
    await AuditService.log({
      adminId: adminUser.id,
      adminEmail: adminUser.email,
      action: 'USER_KYC_REVOKED',
      entityType: 'USER',
      entityId: userId,
      details: { reason: reason || 'Administrative Reset' },
    });

    return { success: true, message: 'User KYC verification revoked' };
  }

  static async verifyUserKyc(userId: string, adminUser: any) {
    const existingKyc = await prisma.kycVerification.findFirst({
      where: { userId },
      orderBy: { createdAt: 'desc' },
    });

    if (existingKyc) {
      await prisma.kycVerification.update({
        where: { id: existingKyc.id },
        data: {
          status: 'VERIFIED',
          verifiedAt: new Date(),
          rejectionReason: null,
        },
      });
    } else {
      await prisma.kycVerification.create({
        data: {
          userId,
          kycType: 'INDIVIDUAL_KYC',
          status: 'VERIFIED',
          verifiedAt: new Date(),
        },
      });
    }

    await prisma.userProfile.upsert({
      where: { userId },
      update: { bvnVerified: true },
      create: { userId, bvnVerified: true },
    });

    await prisma.notification.create({
      data: {
        userId,
        title: '🛡️ KYC Identity Verified',
        message: 'Your identity has been successfully verified by administration. All escrow privileges and dedicated account services are active.',
        type: 'KYC_STATUS',
      },
    }).catch(() => {});

    await AuditService.log({
      adminId: adminUser.id,
      adminEmail: adminUser.email,
      action: 'USER_KYC_MANUALLY_APPROVED',
      entityType: 'USER',
      entityId: userId,
    });

    return { success: true, message: 'User KYC verified successfully' };
  }

  static async getPlatformFees() {
    return prisma.platformFeeConfig.findMany({
      orderBy: { createdAt: 'asc' },
    });
  }

  static async createPlatformFee(data: any, adminUser: any) {
    const fee = await prisma.platformFeeConfig.create({
      data: {
        name: data.name,
        feeType: data.feeType || 'FIXED',
        fixedAmount: parseFloat(data.fixedAmount || 0),
        percentage: parseFloat(data.percentage || 0),
        capAmount: data.capAmount ? parseFloat(data.capAmount) : null,
        amount: parseFloat(data.fixedAmount || data.amount || 0),
        applicableService: data.applicableService || 'PROPERTY_TRANSACTION',
        description: data.description,
        isActive: data.isActive !== undefined ? data.isActive : true,
      },
    });

    await AuditService.log({
      adminId: adminUser.id,
      adminEmail: adminUser.email,
      action: 'PLATFORM_FEE_CREATED',
      entityType: 'SETTING',
      entityId: fee.id,
      details: { name: fee.name, feeType: fee.feeType, fixedAmount: fee.fixedAmount, percentage: fee.percentage },
    });

    return fee;
  }

  static async updatePlatformFee(id: string, data: any, adminUser: any) {
    const updateData: any = {};
    if (data.name) updateData.name = data.name;
    if (data.feeType) updateData.feeType = data.feeType;
    if (data.fixedAmount !== undefined) updateData.fixedAmount = parseFloat(data.fixedAmount);
    if (data.percentage !== undefined) updateData.percentage = parseFloat(data.percentage);
    if (data.capAmount !== undefined) updateData.capAmount = data.capAmount ? parseFloat(data.capAmount) : null;
    if (data.amount !== undefined) updateData.amount = parseFloat(data.amount);
    if (data.applicableService) updateData.applicableService = data.applicableService;
    if (data.description !== undefined) updateData.description = data.description;
    if (typeof data.isActive === 'boolean') updateData.isActive = data.isActive;

    const fee = await prisma.platformFeeConfig.update({
      where: { id },
      data: updateData,
    });

    await AuditService.log({
      adminId: adminUser.id,
      adminEmail: adminUser.email,
      action: 'PLATFORM_FEE_UPDATED',
      entityType: 'SETTING',
      entityId: id,
      details: { name: fee.name, feeType: fee.feeType, fixedAmount: fee.fixedAmount, percentage: fee.percentage, isActive: fee.isActive },
    });

    return fee;
  }

  static async getPaymentsLedger(filters?: { search?: string; purpose?: string; status?: string }) {
    const where: any = {};
    if (filters?.purpose) where.purpose = filters.purpose;
    if (filters?.status) where.status = filters.status;
    if (filters?.search) {
      where.OR = [
        { paymentReference: { contains: filters.search } },
        { paystackReference: { contains: filters.search } },
        { receiptNumber: { contains: filters.search } },
        { user: { firstName: { contains: filters.search } } },
        { user: { lastName: { contains: filters.search } } },
        { user: { email: { contains: filters.search } } },
      ];
    }

    const payments = await prisma.payment.findMany({
      where,
      include: {
        user: { select: { id: true, firstName: true, lastName: true, email: true, phone: true } },
        developer: { select: { id: true, companyName: true, email: true } },
      },
      orderBy: { createdAt: 'desc' },
      take: 100,
    });

    return payments.map((p) => ({
      id: p.id,
      paymentReference: p.paymentReference,
      customerName: `${p.user?.firstName || 'Buyer'} ${p.user?.lastName || ''}`.trim(),
      customerEmail: p.user?.email || 'N/A',
      developerName: p.developer?.companyName || null,
      purpose: p.purpose,
      amount: p.amount,
      platformFee: p.platformFee,
      processingFee: p.processingFee,
      totalAmount: p.totalAmount,
      status: p.status,
      currency: p.currency,
      paystackReference: p.paystackReference || 'N/A',
      paystackChannel: p.paystackChannel || 'bank_transfer',
      paidAt: p.paidAt ? p.paidAt.toISOString() : p.createdAt.toISOString(),
      receiptNumber: p.receiptNumber || `RCP-${p.id.slice(0, 8).toUpperCase()}`,
      receiptUrl: p.receiptUrl,
      createdAt: p.createdAt,
    }));
  }

  static async getMilestonesOverview(filters?: { status?: string; projectId?: string; search?: string }) {
    const where: any = {};
    if (filters?.status) where.status = filters.status;
    if (filters?.projectId) where.projectId = filters.projectId;
    if (filters?.search) {
      where.OR = [
        { title: { contains: filters.search } },
        { corenEngineerName: { contains: filters.search } },
        { corenLicenseNumber: { contains: filters.search } },
        { project: { name: { contains: filters.search } } },
      ];
    }

    const milestones = await prisma.constructionMilestone.findMany({
      where,
      include: {
        project: {
          include: {
            developer: { select: { id: true, companyName: true, email: true, phone: true, isVerified: true } },
            units: {
              include: {
                purchases: {
                  include: { user: { select: { id: true, firstName: true, lastName: true, email: true } } }
                }
              }
            }
          }
        },
        reviews: {
          include: {
            user: { select: { id: true, firstName: true, lastName: true, email: true } }
          }
        }
      },
      orderBy: { updatedAt: 'desc' },
      take: 100,
    });

    const now = new Date();

    return milestones.map(m => {
      let remainingSeconds = 0;
      if (m.reviewWindowExpiresAt) {
        remainingSeconds = Math.max(0, Math.floor((new Date(m.reviewWindowExpiresAt).getTime() - now.getTime()) / 1000));
      }

      const totalSubscribers = m.project.units.flatMap(u => u.purchases).length || 1;
      const approvalRate = Number(((m.approvalsCount / totalSubscribers) * 100).toFixed(1));

      return {
        id: m.id,
        projectId: m.projectId,
        projectName: m.project.name,
        developerCompany: m.project.developer?.companyName || 'Developer',
        developerEmail: m.project.developer?.email,
        developerVerified: m.project.developer?.isVerified,
        title: m.title,
        description: m.description,
        percentage: m.percentage,
        status: m.status,
        trancheAmount: m.trancheAmount,
        payoutStatus: m.payoutStatus,
        corenEngineerName: m.corenEngineerName,
        corenLicenseNumber: m.corenLicenseNumber,
        corenCertificateUrl: m.corenCertificateUrl,
        testReportUrl: m.testReportUrl,
        walkthroughVideoUrl: m.walkthroughVideoUrl,
        proofSubmittedAt: m.proofSubmittedAt,
        reviewWindowExpiresAt: m.reviewWindowExpiresAt,
        remainingSeconds,
        isExpired: m.reviewWindowExpiresAt ? now > new Date(m.reviewWindowExpiresAt) : false,
        totalSubscribers,
        approvalsCount: m.approvalsCount,
        disputesCount: m.disputesCount,
        approvalRate,
        remediationNotes: m.remediationNotes,
        reviews: m.reviews.map(r => ({
          id: r.id,
          userName: `${r.user.firstName} ${r.user.lastName}`,
          userEmail: r.user.email,
          decision: r.decision,
          comment: r.comment,
          proofMediaUrl: r.proofMediaUrl,
          createdAt: r.createdAt,
        })),
        createdAt: m.createdAt,
        updatedAt: m.updatedAt,
      };
    });
  }

  static async adminDisburseMilestone(adminUser: any, milestoneId: string, data: {
    action: 'APPROVE_AND_DISBURSE' | 'FLAG_DISPUTE' | 'REQUEST_REMEDIATION';
    notes?: string;
  }) {
    const milestone = await prisma.constructionMilestone.findUnique({
      where: { id: milestoneId },
      include: {
        project: {
          include: {
            developer: true,
            units: {
              include: { purchases: { include: { user: true } } }
            }
          }
        }
      }
    });

    if (!milestone) throw new Error('Milestone not found');

    let newStatus = milestone.status;
    let newPayoutStatus = milestone.payoutStatus;
    let payoutRef = milestone.payoutTransactionRef;

    if (data.action === 'APPROVE_AND_DISBURSE') {
      newStatus = 'COMPLETED';
      newPayoutStatus = 'DISBURSED';
      payoutRef = `ESC-DISB-${Date.now().toString().slice(-6)}-${Math.floor(100 + Math.random() * 900)}`;
    } else if (data.action === 'FLAG_DISPUTE') {
      newPayoutStatus = 'DISPUTED';
    } else if (data.action === 'REQUEST_REMEDIATION') {
      newStatus = 'REMEDIATION_REQUIRED';
      newPayoutStatus = 'REMEDIATION_REQUIRED';
    }

    const updated = await prisma.constructionMilestone.update({
      where: { id: milestoneId },
      data: {
        status: newStatus,
        payoutStatus: newPayoutStatus,
        payoutTransactionRef: payoutRef,
        remediationNotes: data.notes || milestone.remediationNotes,
      }
    });

    // Notify developer
    if (milestone.project.developer) {
      await prisma.notification.create({
        data: {
          userId: milestone.project.developer.userId,
          title: data.action === 'APPROVE_AND_DISBURSE'
            ? `💰 Milestone Escrow Disbursed: ${milestone.title}`
            : `⚠️ Milestone Status Update: ${milestone.title}`,
          message: data.action === 'APPROVE_AND_DISBURSE'
            ? `Tranche payout of ₦${milestone.trancheAmount.toLocaleString()} has been unlocked and transferred to your corporate account (Ref: ${payoutRef}).`
            : `Admin notes: ${data.notes || 'Under review'}.`,
          type: 'ESCROW_PAYOUT',
        }
      }).catch(() => {});
    }

    await AuditService.log({
      adminId: adminUser.id,
      adminEmail: adminUser.email,
      action: `ADMIN_MILESTONE_${data.action}`,
      entityType: 'PROJECT',
      entityId: milestone.projectId,
      details: {
        milestoneId: milestone.id,
        milestoneTitle: milestone.title,
        action: data.action,
        payoutRef,
        notes: data.notes,
      }
    });

    return updated;
  }

  static async getAllTransactions(filters?: { status?: string; type?: string; search?: string; page?: number; limit?: number }) {
    const page = filters?.page || 1;
    const limit = filters?.limit || 100;
    const skip = (page - 1) * limit;

    const [payments, withdrawals] = await Promise.all([
      prisma.payment.findMany({
        orderBy: { createdAt: 'desc' },
        include: {
          user: { select: { id: true, firstName: true, lastName: true, email: true, phone: true } },
          developer: { select: { id: true, companyName: true, email: true } },
          purchase: {
            include: {
              property: { select: { id: true, title: true, address: true, city: true, state: true } },
            },
          },
        },
      }),
      prisma.withdrawal.findMany({
        orderBy: { createdAt: 'desc' },
        include: {
          user: { select: { id: true, firstName: true, lastName: true, email: true, phone: true } },
          developer: { select: { id: true, companyName: true, email: true } },
        },
      }),
    ]);

    const txs: any[] = [];

    for (const p of payments) {
      txs.push({
        id: p.id,
        type: 'CREDIT',
        amount: p.totalAmount,
        currency: 'NGN',
        status: p.status === 'SUCCESS' || p.status === 'CONFIRMED' || p.status === 'COMPLETED' ? 'SUCCESS' : p.status,
        purpose: p.purpose || 'ESCROW_FUNDING',
        description: p.purchase?.property?.title ? `Property Payment: ${p.purchase.property.title}` : (p.purpose || 'Escrow Deposit'),
        reference: p.paymentReference,
        channel: p.paystackChannel || 'DIRECT_BANK_TRANSFER',
        userName: p.user ? `${p.user.firstName} ${p.user.lastName}`.trim() : (p.developer?.companyName || 'User'),
        userEmail: p.user?.email || p.developer?.email || '',
        createdAt: p.createdAt,
      });
    }

    for (const w of withdrawals) {
      txs.push({
        id: w.id,
        type: 'DEBIT',
        amount: w.amount,
        currency: 'NGN',
        status: w.status,
        purpose: 'WITHDRAWAL',
        description: `Payout to ${w.accountName} (${w.bankName} - ${w.accountNumber})`,
        reference: w.reference,
        channel: w.bankName || 'COMMERCIAL_BANK_TRANSFER',
        userName: w.accountName || (w.user ? `${w.user.firstName} ${w.user.lastName}`.trim() : (w.developer?.companyName || 'Developer')),
        userEmail: w.user?.email || w.developer?.email || '',
        bankName: w.bankName,
        accountNumber: w.accountNumber,
        accountName: w.accountName,
        createdAt: w.createdAt,
      });
    }

    let filtered = txs;
    if (filters?.type && filters.type !== 'ALL') {
      filtered = filtered.filter(t => t.type === filters.type);
    }
    if (filters?.status && filters.status !== 'ALL') {
      filtered = filtered.filter(t => t.status === filters.status);
    }
    if (filters?.search) {
      const q = filters.search.toLowerCase();
      filtered = filtered.filter(t =>
        t.reference.toLowerCase().includes(q) ||
        t.userName.toLowerCase().includes(q) ||
        t.userEmail.toLowerCase().includes(q) ||
        t.description.toLowerCase().includes(q)
      );
    }

    filtered.sort((a, b) => new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime());

    const total = filtered.length;
    const paginated = filtered.slice(skip, skip + limit);

    return {
      transactions: paginated,
      total,
      page,
      totalPages: Math.ceil(total / limit),
    };
  }

  static async getAllDispatchedNotifications(filters?: { search?: string; page?: number; limit?: number }) {
    const page = filters?.page || 1;
    const limit = filters?.limit || 100;
    const skip = (page - 1) * limit;

    const where: any = {};
    if (filters?.search) {
      where.OR = [
        { title: { contains: filters.search, mode: 'insensitive' } },
        { message: { contains: filters.search, mode: 'insensitive' } },
        { user: { email: { contains: filters.search, mode: 'insensitive' } } },
      ];
    }

    const [notifications, total] = await Promise.all([
      prisma.notification.findMany({
        where,
        skip,
        take: limit,
        orderBy: { createdAt: 'desc' },
        include: {
          user: { select: { id: true, firstName: true, lastName: true, email: true, phone: true } },
        },
      }),
      prisma.notification.count({ where }),
    ]);

    return {
      notifications,
      total,
      page,
      totalPages: Math.ceil(total / limit),
    };
  }
}
