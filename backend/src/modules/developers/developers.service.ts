import { prisma } from '../../utils/prisma';
import { AuditService } from '../audit/audit.service';

export class DevelopersService {
  static async getAll(filters: { isVerified?: boolean; status?: string; search?: string; page?: number; limit?: number }) {
    const page = filters.page || 1;
    const limit = filters.limit || 20;
    const skip = (page - 1) * limit;

    const where: any = {};
    if (filters.isVerified !== undefined) where.isVerified = filters.isVerified;
    if (filters.status) where.verificationStatus = filters.status;
    if (filters.search) {
      where.OR = [
        { companyName: { contains: filters.search } },
        { cacNumber: { contains: filters.search } },
        { contactPerson: { contains: filters.search } },
      ];
    }

    const [developers, total] = await Promise.all([
      prisma.developer.findMany({
        where,
        skip,
        take: limit,
        orderBy: [{ isVerified: 'desc' }, { createdAt: 'desc' }],
        include: {
          directors: true,
          _count: {
            select: {
              properties: true,
              projects: true,
            },
          },
        },
      }),
      prisma.developer.count({ where }),
    ]);

    const formattedDevelopers = developers.map(d => ({
      ...d,
      verifiedCategories: d.verifiedCategories ? JSON.parse(d.verifiedCategories) : [],
    }));

    return {
      developers: formattedDevelopers,
      total,
      page,
      totalPages: Math.ceil(total / limit),
    };
  }

  static async getById(id: string) {
    const developer = await prisma.developer.findUnique({
      where: { id },
      include: {
        directors: true,
        documents: true,
        properties: {
          where: { isPublished: true },
          take: 10,
        },
        projects: {
          take: 10,
        },
      },
    });

    if (!developer) {
      throw new Error('Developer not found');
    }

    return {
      ...developer,
      verifiedCategories: developer.verifiedCategories ? JSON.parse(developer.verifiedCategories) : [],
      properties: developer.properties.map(p => ({
        ...p,
        images: JSON.parse(p.images || '[]'),
      })),
      projects: developer.projects.map(p => ({
        ...p,
        images: JSON.parse(p.images || '[]'),
      })),
    };
  }

  static async verifyDeveloper(id: string, status: string, categories: string[], adminUser: any) {
    const isVerified = status === 'VERIFIED' || status === 'VERIFIED_WITH_LIMITATIONS';

    const developer = await prisma.developer.update({
      where: { id },
      data: {
        verificationStatus: status,
        isVerified,
        verificationDate: isVerified ? new Date() : null,
        verifiedCategories: JSON.stringify(categories),
      },
    });

    await AuditService.log({
      adminId: adminUser.id,
      adminEmail: adminUser.email,
      action: 'DEVELOPER_VERIFICATION_STATUS_CHANGED',
      entityType: 'DEVELOPER',
      entityId: id,
      details: { status, categories, developerCompany: developer.companyName },
    });

    // Notify developer user
    await prisma.notification.create({
      data: {
        userId: developer.userId,
        title: `Developer Onboarding Status: ${status}`,
        message: isVerified
          ? `Congratulations! ${developer.companyName} has been verified on Hometrust.`
          : `Your onboarding status was updated to ${status}.`,
        type: 'SYSTEM',
      },
    });

    return developer;
  }
}
