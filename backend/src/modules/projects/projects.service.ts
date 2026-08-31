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

  /**
   * Returns live interactive unit matrix (e.g. Unit 1 to 20 or Plot 1 to 50)
   * with real-time availability badges and subscription tracking.
   */
  static async getUnitsMatrix(projectId: string) {
    const project = await prisma.project.findUnique({
      where: { id: projectId },
      include: {
        units: {
          include: {
            purchases: {
              select: {
                id: true,
                purchaseCode: true,
                status: true,
                amountPaid: true,
                createdAt: true,
              },
            },
          },
        },
      },
    });

    if (!project) throw new Error('Project not found');

    const now = new Date();
    const matrixUnits = project.units.map((unit, idx) => {
      const activePaidPurchases = unit.purchases.filter(p => p.status !== 'CANCELLED' && p.amountPaid > 0);
      const activeLockPurchase = unit.purchases.find(p => p.status !== 'CANCELLED' && (p.amountPaid || 0) === 0 && (p as any).lockStatus === 'LOCKED' && (p as any).lockedUntil && new Date((p as any).lockedUntil) > now);

      let status = 'AVAILABLE';
      let reservedUntil: string | null = null;

      if (unit.status === 'SOLD' || activePaidPurchases.length > 0 || unit.availableUnits <= 0) {
        status = 'SOLD';
      } else if (unit.status === 'RESERVED' || activeLockPurchase) {
        status = 'RESERVED';
        reservedUntil = (activeLockPurchase as any)?.lockedUntil ? new Date((activeLockPurchase as any).lockedUntil).toISOString() : null;
      }

      return {
        id: unit.id,
        unitCode: unit.name.toUpperCase().startsWith('UNIT') ? unit.name : `UNIT-${String.fromCharCode(65 + (idx % 26))}${idx >= 26 ? Math.floor(idx / 26) : ''}`, // e.g. UNIT-A, UNIT-B, UNIT-C
        name: unit.name,
        unitType: unit.unitType,
        size: unit.size || '180 SQM',
        bedrooms: unit.bedrooms,
        bathrooms: unit.bathrooms,
        price: unit.price,
        initialDeposit: unit.initialDeposit,
        monthlyInstalment: unit.monthlyInstalment,
        durationMonths: unit.durationMonths,
        status, // 'AVAILABLE', 'RESERVED', 'SOLD'
        isAvailableForPurchase: status === 'AVAILABLE',
        reservedUntil,
        activeSubscriberHash: activePaidPurchases.length > 0 ? `SUB-${activePaidPurchases[0].purchaseCode.slice(-4)}` : null,
      };
    });

    const total = matrixUnits.length;
    const soldCount = matrixUnits.filter(u => u.status === 'SOLD').length;
    const reservedCount = matrixUnits.filter(u => u.status === 'RESERVED').length;
    const availableCount = matrixUnits.filter(u => u.status === 'AVAILABLE').length;

    return {
      projectId: project.id,
      projectName: project.name,
      totalUnits: total,
      availableUnits: availableCount,
      subscribedUnits: soldCount + reservedCount,
      soldUnits: soldCount,
      reservedUnits: reservedCount,
      soldPercentage: total > 0 ? Math.round((soldCount / total) * 100) : 0,
      units: matrixUnits,
    };
  }

  /**
   * 30-Minute Temporary Atomic Reservation Lock
   */
  static async lockUnit(projectId: string, unitId: string, userId: string) {
    const unit = await prisma.projectUnit.findUnique({
      where: { id: unitId },
      include: { purchases: true },
    });

    if (!unit) throw new Error('Unit not found');
    if (unit.projectId !== projectId) throw new Error('Unit does not belong to this project');

    const isSubscribed = unit.purchases.some(p => p.status !== 'CANCELLED');
    if (isSubscribed) {
      throw new Error('This unit is already locked and subscribed by another buyer.');
    }

    const expiresAt = new Date(Date.now() + 30 * 60 * 1000); // 30 minutes from now

    return {
      success: true,
      unitId: unit.id,
      unitName: unit.name,
      price: unit.price,
      initialDeposit: unit.initialDeposit,
      reservationExpiresAt: expiresAt.toISOString(),
      message: 'Unit reserved for 30 minutes. Complete initial deposit via your dedicated Escrow NUBAN to finalize allocation.',
    };
  }
}

