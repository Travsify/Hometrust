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

  static async getUsers(filters: { role?: string; search?: string; page?: number; limit?: number }) {
    const page = filters.page || 1;
    const limit = filters.limit || 20;
    const skip = (page - 1) * limit;

    const where: any = {};
    if (filters.role) where.role = filters.role;
    if (filters.search) {
      where.OR = [
        { email: { contains: filters.search } },
        { firstName: { contains: filters.search } },
        { lastName: { contains: filters.search } },
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
            select: { id: true, companyName: true, isVerified: true },
          },
        },
      }),
      prisma.user.count({ where }),
    ]);

    return {
      users,
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

  static async getPlatformFees() {
    return prisma.platformFeeConfig.findMany({
      orderBy: { createdAt: 'desc' },
    });
  }

  static async updatePlatformFee(id: string, amount: number, isActive: boolean, adminUser: any) {
    const fee = await prisma.platformFeeConfig.update({
      where: { id },
      data: { amount, isActive },
    });

    await AuditService.log({
      adminId: adminUser.id,
      adminEmail: adminUser.email,
      action: 'PLATFORM_FEE_UPDATED',
      entityType: 'SETTING',
      entityId: id,
      details: { name: fee.name, amount, isActive },
    });

    return fee;
  }
}
