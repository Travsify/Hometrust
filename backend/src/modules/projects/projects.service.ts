import { prisma } from '../../utils/prisma';

export class ProjectsService {
  static async getAll(filters: { state?: string; city?: string; isVerified?: boolean; status?: string; page?: number; limit?: number }) {
    const page = filters.page || 1;
    const limit = filters.limit || 20;
    const skip = (page - 1) * limit;

    const where: any = {};
    if (filters.state) where.state = { contains: filters.state };
    if (filters.city) where.city = { contains: filters.city };
    if (filters.status) where.status = filters.status;
    if (filters.isVerified !== undefined) where.isVerified = filters.isVerified;

    const [projects, total] = await Promise.all([
      prisma.project.findMany({
        where,
        skip,
        take: limit,
        orderBy: { createdAt: 'desc' },
        include: {
          developer: {
            select: {
              id: true,
              companyName: true,
              cacNumber: true,
              isVerified: true,
              verificationStatus: true,
              logoUrl: true,
            },
          },
          units: true,
          milestones: {
            orderBy: { orderIndex: 'asc' },
          },
        },
      }),
      prisma.project.count({ where }),
    ]);

    const formattedProjects = projects.map(p => ({
      ...p,
      images: JSON.parse(p.images || '[]'),
      renderings: p.renderings ? JSON.parse(p.renderings) : [],
    }));

    return {
      projects: formattedProjects,
      total,
      page,
      totalPages: Math.ceil(total / limit),
    };
  }

  static async getById(idOrSlug: string) {
    const project = await prisma.project.findFirst({
      where: {
        OR: [{ id: idOrSlug }, { slug: idOrSlug }],
      },
      include: {
        developer: {
          include: {
            directors: true,
          },
        },
        units: {
          include: {
            paymentPlans: true,
          },
        },
        milestones: {
          orderBy: { orderIndex: 'asc' },
        },
      },
    });

    if (!project) {
      throw new Error('Project not found');
    }

    return {
      ...project,
      images: JSON.parse(project.images || '[]'),
      renderings: project.renderings ? JSON.parse(project.renderings) : [],
      architecturalPlans: project.architecturalPlans ? JSON.parse(project.architecturalPlans) : [],
      floorPlans: project.floorPlans ? JSON.parse(project.floorPlans) : [],
      developer: {
        ...project.developer,
        verifiedCategories: project.developer.verifiedCategories ? JSON.parse(project.developer.verifiedCategories) : [],
      },
    };
  }

  static async updateMilestone(milestoneId: string, data: { percentage?: number; status?: string; proofPhotos?: string[]; verifiedBy?: string }) {
    return prisma.constructionMilestone.update({
      where: { id: milestoneId },
      data: {
        percentage: data.percentage,
        status: data.status,
        proofPhotos: data.proofPhotos ? JSON.stringify(data.proofPhotos) : undefined,
        verifiedBy: data.verifiedBy,
      },
    });
  }
}
