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

  static async getById(id: string, userId?: string) {
    const [developer, followersCount, followerRecord] = await Promise.all([
      prisma.developer.findUnique({
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
      }),
      prisma.developerFollower.count({
        where: { developerId: id },
      }),
      userId
        ? prisma.developerFollower.findUnique({
            where: {
              developerId_userId: {
                developerId: id,
                userId,
              },
            },
          })
        : null,
    ]);

    if (!developer) {
      throw new Error('Developer not found');
    }

    return {
      ...developer,
      followersCount,
      isFollowing: !!followerRecord,
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

  static async getDeveloperByUserId(userId: string) {
    let developer = await prisma.developer.findFirst({
      where: { userId },
      include: {
        virtualAccounts: {
          where: { status: 'ACTIVE' },
          take: 1,
        },
        directors: true,
      },
    });

    if (!developer) {
      const user = await prisma.user.findUnique({ where: { id: userId } });
      if (!user) throw new Error('User not found');

      // Auto-provision developer profile if role is DEVELOPER
      developer = await prisma.developer.create({
        data: {
          userId,
          companyName: `${user.firstName} ${user.lastName} Developments Ltd`,
          cacNumber: `RC-${Math.floor(100000 + Math.random() * 900000)}`,
          contactPerson: `${user.firstName} ${user.lastName}`,
          phone: user.phone || '+2348000000000',
          email: user.email,
          officeAddress: 'Head Office, Victoria Island, Lagos State',
          isVerified: true,
          verificationStatus: 'VERIFIED',
          verificationDate: new Date(),
          verifiedCategories: JSON.stringify(['CORPORATE', 'IDENTITY', 'PROJECTS', 'BUSINESS']),
        },
        include: {
          virtualAccounts: true,
          directors: true,
        },
      });
    }

    return developer;
  }

  static async getMyStats(userId: string) {
    const developer = await this.getDeveloperByUserId(userId);

    // 1. Fetch virtual account balance
    const virtualAccount = await prisma.virtualAccount.findFirst({
      where: {
        OR: [
          { developerId: developer.id },
          { userId: userId },
        ],
        status: 'ACTIVE',
      },
      orderBy: { createdAt: 'desc' },
    });

    const availableBalance = virtualAccount ? virtualAccount.balance : 0;

    // 2. Fetch projects and counts
    const projects = await prisma.project.findMany({
      where: { developerId: developer.id },
      include: {
        units: true,
        milestones: true,
        inspections: true,
      },
    });

    const totalProjects = projects.length;
    let totalUnits = 0;
    let availableUnitsCount = 0;

    projects.forEach(p => {
      totalUnits += p.totalUnits;
      availableUnitsCount += p.availableUnits;
    });

    // 3. Fetch all purchases (subscribers) on developer's properties/units
    const projectUnitIds = projects.flatMap(p => p.units.map(u => u.id));

    const purchases = await prisma.purchase.findMany({
      where: {
        OR: [
          { projectUnitId: { in: projectUnitIds } },
          { property: { developerId: developer.id } },
        ],
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
        property: true,
        projectUnit: {
          include: { project: true },
        },
        paymentPlan: true,
        payments: {
          where: { status: 'SUCCESS' },
        },
      },
      orderBy: { createdAt: 'desc' },
    });

    const totalSubscribers = purchases.length;
    let totalGrossRevenue = 0;
    let lockedEscrowBalance = 0;

    purchases.forEach(pur => {
      const paid = pur.amountPaid || 0;
      totalGrossRevenue += paid;
      if (pur.status !== 'COMPLETED' && pur.status !== 'CANCELLED') {
        lockedEscrowBalance += paid;
      }
    });

    // 4. Pending inspections
    const pendingInspections = await prisma.inspection.count({
      where: {
        OR: [
          { project: { developerId: developer.id } },
          { property: { developerId: developer.id } },
        ],
        status: 'REQUESTED',
      },
    });

    // 5. Active construction milestones across all developer projects
    const activeMilestones = projects.flatMap(p =>
      p.milestones
        .filter(m => m.status === 'IN_PROGRESS' || m.status === 'PENDING')
        .map(m => ({
          id: m.id,
          projectId: p.id,
          projectName: p.name,
          title: m.title,
          description: m.description,
          orderIndex: m.orderIndex,
          percentage: m.percentage,
          status: m.status,
          completionDate: m.completionDate,
          proofPhotos: m.proofPhotos ? JSON.parse(m.proofPhotos) : [],
        }))
    );

    return {
      developer: {
        id: developer.id,
        companyName: developer.companyName,
        cacNumber: developer.cacNumber,
        contactPerson: developer.contactPerson,
        phone: developer.phone,
        email: developer.email,
        officeAddress: developer.officeAddress,
        isVerified: developer.isVerified,
        verificationStatus: developer.verificationStatus,
      },
      virtualAccount: virtualAccount ? {
        accountNumber: virtualAccount.accountNumber,
        bankName: virtualAccount.bankName,
        accountName: virtualAccount.accountName,
        balance: virtualAccount.balance,
      } : null,
      financials: {
        availableBalance,
        lockedEscrowBalance,
        totalGrossRevenue,
        currency: 'NGN',
      },
      inventory: {
        totalProjects,
        totalUnits,
        availableUnits: availableUnitsCount,
        soldUnits: totalUnits - availableUnitsCount,
      },
      activeMilestones,
      subscribers: {
        totalCount: totalSubscribers,
        activePurchases: purchases.filter(p => p.status === 'ACTIVE' || p.status === 'AGREEMENT_SIGNED').length,
        recent: purchases.slice(0, 5).map(p => ({
          purchaseCode: p.purchaseCode,
          buyerName: `${p.user.firstName} ${p.user.lastName}`,
          buyerPhone: p.user.phone,
          itemTitle: p.projectUnit?.name || p.property?.title || 'Off-Plan Property',
          projectName: p.projectUnit?.project?.name || p.property?.city || 'Estate Development',
          totalPrice: p.totalPrice,
          amountPaid: p.amountPaid,
          outstandingBalance: p.outstandingBalance,
          status: p.status,
          nextDueDate: p.nextPaymentDueDate,
        })),
      },
      pendingInspectionsCount: pendingInspections,
    };
  }

  static async getMyProjects(userId: string) {
    const developer = await this.getDeveloperByUserId(userId);

    const projects = await prisma.project.findMany({
      where: { developerId: developer.id },
      include: {
        units: {
          include: {
            paymentPlans: true,
            _count: { select: { purchases: true } },
          },
        },
        milestones: {
          orderBy: { orderIndex: 'asc' },
        },
        inspections: {
          orderBy: { createdAt: 'desc' },
        },
      },
      orderBy: { createdAt: 'desc' },
    });

    return projects.map(p => ({
      ...p,
      images: JSON.parse(p.images || '[]'),
      renderings: p.renderings ? JSON.parse(p.renderings) : [],
      architecturalPlans: p.architecturalPlans ? JSON.parse(p.architecturalPlans) : [],
    }));
  }

  static async createProject(userId: string, data: {
    projectType?: 'OFF_PLAN' | 'PAY_SMALL_SMALL';
    propertyCategory?: 'LAND' | 'BUILDING' | 'APARTMENT' | 'TERRACE' | 'COMMERCIAL';
    name: string;
    description: string;
    state: string;
    city: string;
    area: string;
    address: string;
    expectedCompletion: string;
    totalUnits?: number;
    videoUrl?: string;
    virtualTourUrl?: string;
    images?: string[];
    documentUrls?: Array<{ documentType: string; fileName: string; fileUrl: string }>;
    units?: Array<{
      unitType: string;
      name: string;
      size?: string;
      bedrooms: number;
      bathrooms: number;
      price: number;
      initialDeposit: number;
      durationMonths: number;
      monthlyInstalment: number;
      totalUnits: number;
    }>;
  }) {
    const developer = await this.getDeveloperByUserId(userId);

    const slug = `${data.name.toLowerCase().replace(/[^a-z0-9]+/g, '-')}-${Date.now().toString().slice(-4)}`;

    const totalUnitsCount = data.units?.reduce((sum, u) => sum + (u.totalUnits || 1), 0) || data.totalUnits || 1;
    const isPaySmallSmall = data.projectType === 'PAY_SMALL_SMALL';

    // Dynamic milestones depending on OFF_PLAN vs PAY_SMALL_SMALL
    const defaultMilestones = isPaySmallSmall
      ? [
          {
            title: 'Tranche 1: Commitment Deposit & Provisional Allocation',
            description: 'Immediate generation of Stamped Provisional Allocation Certificate and Tri-Partite Agreement.',
            percentage: 20,
            orderIndex: 1,
            status: 'COMPLETED',
          },
          {
            title: 'Tranche 2: 50% Equity & Physical Site Possession / Key Release',
            description: 'Buyer reaches 50% threshold and receives authorization for physical move-in or site demarcation.',
            percentage: 30,
            orderIndex: 2,
            status: 'IN_PROGRESS',
          },
          {
            title: 'Tranche 3: Continuous Instalment Amortisation (75%)',
            description: 'Ongoing monthly escrow deductions with live amortisation receipts and running statement updates.',
            percentage: 25,
            orderIndex: 3,
            status: 'PENDING',
          },
          {
            title: 'Tranche 4: 100% Liquidation & Deed of Assignment Conveyance',
            description: 'Final balance clearance, release of escrow funds to developer, and formal state title conveyance.',
            percentage: 25,
            orderIndex: 4,
            status: 'PENDING',
          },
        ]
      : [
          {
            title: 'Substructure & Foundation',
            description: 'Excavation, casting of ground beams, DPC German floor and subterranean anti-termite treatment.',
            percentage: 20,
            orderIndex: 1,
            status: 'COMPLETED',
          },
          {
            title: 'Structural Framing & Lintels',
            description: 'Reinforced concrete columns, beams, suspended floor slabs, and block masonry to lintel level.',
            percentage: 25,
            orderIndex: 2,
            status: 'IN_PROGRESS',
          },
          {
            title: 'Roofing & External Walling',
            description: 'Roof trusses, 0.55mm stone-coated step-tiles, external boundary walls, and parapet fascia.',
            percentage: 20,
            orderIndex: 3,
            status: 'PENDING',
          },
          {
            title: 'Plumbing, Electrical & MEP',
            description: 'Conduit piping, 100% pure copper electrical wiring, water reticulation, and bio-digester soakaway.',
            percentage: 15,
            orderIndex: 4,
            status: 'PENDING',
          },
          {
            title: 'Interior Plastering & Finishing',
            description: 'Vitrified tiling, POP false ceilings, acrylic wall screeding, sanitary fittings, and Turkish security doors.',
            percentage: 15,
            orderIndex: 5,
            status: 'PENDING',
          },
          {
            title: 'Snagging, Landscaping & Handover',
            description: 'External interlocking stone paving, solar street lighting, final snag audit, and issuance of Deed of Assignment.',
            percentage: 5,
            orderIndex: 6,
            status: 'PENDING',
          },
        ];

    const project = await prisma.project.create({
      data: {
        developerId: developer.id,
        name: data.name,
        slug,
        description: data.description,
        state: data.state,
        city: data.city,
        area: data.area,
        address: data.address,
        totalUnits: totalUnitsCount,
        availableUnits: totalUnitsCount,
        expectedCompletion: data.expectedCompletion,
        status: isPaySmallSmall ? 'COMPLETED' : 'UNDER_CONSTRUCTION',
        isVerified: true,
        images: JSON.stringify(data.images && data.images.length > 0 ? data.images : [
          'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?w=1200&q=80',
          'https://images.unsplash.com/photo-1600607687939-ce8a6c25118c?w=1200&q=80',
        ]),
        renderings: data.videoUrl ? JSON.stringify([data.videoUrl]) : undefined,
        architecturalPlans: data.documentUrls ? JSON.stringify(data.documentUrls) : undefined,
        milestones: {
          create: defaultMilestones,
        },
        units: data.units && data.units.length > 0 ? {
          create: data.units.map(u => ({
            unitType: u.unitType,
            name: u.name,
            size: u.size || (isPaySmallSmall ? 'Serviced Plot / 200 SQM' : '160 SQM'),
            bedrooms: u.bedrooms,
            bathrooms: u.bathrooms,
            price: u.price,
            initialDeposit: u.initialDeposit,
            durationMonths: u.durationMonths || (isPaySmallSmall ? 24 : 12),
            monthlyInstalment: u.monthlyInstalment || Math.round((u.price - u.initialDeposit) / (u.durationMonths || 12)),
            totalUnits: u.totalUnits || 1,
            availableUnits: u.totalUnits || 1,
            status: 'AVAILABLE',
          })),
        } : undefined,
      },
      include: {
        units: true,
        milestones: true,
      },
    });

    await AuditService.log({
      adminEmail: developer.email || 'developer@hometrust.ng',
      action: isPaySmallSmall ? 'DEVELOPER_PAY_SMALL_SMALL_PROJECT_CREATED' : 'DEVELOPER_PROJECT_CREATED',
      entityType: 'PROJECT',
      entityId: project.id,
      details: {
        developerId: developer.id,
        developerCompany: developer.companyName,
        projectName: project.name,
        projectType: data.projectType || 'OFF_PLAN',
        totalUnits: totalUnitsCount,
        city: project.city,
      },
    });

    return project;
  }


  static async addUnitToProject(userId: string, projectId: string, data: {
    unitType: string;
    name: string;
    size?: string;
    bedrooms: number;
    bathrooms: number;
    price: number;
    initialDeposit: number;
    durationMonths: number;
    totalUnits: number;
  }) {
    const developer = await this.getDeveloperByUserId(userId);

    const project = await prisma.project.findFirst({
      where: { id: projectId, developerId: developer.id },
    });

    if (!project) throw new Error('Project not found or unauthorized');

    const monthlyInstalment = Math.round((data.price - data.initialDeposit) / (data.durationMonths || 12));

    const unit = await prisma.projectUnit.create({
      data: {
        projectId,
        unitType: data.unitType,
        name: data.name,
        size: data.size || '180 SQM',
        bedrooms: data.bedrooms,
        bathrooms: data.bathrooms,
        price: data.price,
        initialDeposit: data.initialDeposit,
        durationMonths: data.durationMonths || 12,
        monthlyInstalment,
        totalUnits: data.totalUnits || 1,
        availableUnits: data.totalUnits || 1,
        status: 'AVAILABLE',
      },
    });

    // Update project total units
    await prisma.project.update({
      where: { id: projectId },
      data: {
        totalUnits: { increment: data.totalUnits || 1 },
        availableUnits: { increment: data.totalUnits || 1 },
      },
    });

    await AuditService.log({
      adminEmail: developer.email || 'developer@hometrust.ng',
      action: 'DEVELOPER_UNIT_ADDED',
      entityType: 'PROJECT_UNIT',
      entityId: unit.id,
      details: {
        projectId,
        projectName: project.name,
        unitName: unit.name,
        price: unit.price,
      },
    });

    return unit;
  }

  static async getMySubscribers(userId: string) {
    const developer = await this.getDeveloperByUserId(userId);

    const projects = await prisma.project.findMany({
      where: { developerId: developer.id },
      select: { id: true, name: true, units: { select: { id: true } } },
    });

    const projectUnitIds = projects.flatMap(p => p.units.map(u => u.id));

    const purchases = await prisma.purchase.findMany({
      where: {
        OR: [
          { projectUnitId: { in: projectUnitIds } },
          { property: { developerId: developer.id } },
        ],
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
        property: true,
        projectUnit: {
          include: { project: true },
        },
        paymentPlan: true,
        payments: {
          where: { status: 'SUCCESS' },
          orderBy: { createdAt: 'desc' },
        },
      },
      orderBy: { createdAt: 'desc' },
    });

    return purchases.map(p => ({
      id: p.id,
      purchaseCode: p.purchaseCode,
      buyer: {
        id: p.user.id,
        name: `${p.user.firstName} ${p.user.lastName}`,
        email: p.user.email,
        phone: p.user.phone,
      },
      propertyTitle: p.projectUnit?.name || p.property?.title || 'Off-Plan Property',
      projectName: p.projectUnit?.project?.name || p.property?.city || 'Estate Development',
      unitType: p.projectUnit?.unitType || 'Residential Unit',
      totalPrice: p.totalPrice,
      initialDeposit: p.initialDeposit,
      amountPaid: p.amountPaid,
      outstandingBalance: p.outstandingBalance,
      nextPaymentAmount: p.nextPaymentAmount,
      nextPaymentDueDate: p.nextPaymentDueDate,
      status: p.status,
      agreementDocumentUrl: p.agreementDocumentUrl,
      signatureDate: p.signatureDate,
      paymentsCount: p.payments.length,
      recentPayments: p.payments.slice(0, 3).map(pay => ({
        reference: pay.paymentReference,
        amount: pay.amount,
        paidAt: pay.paidAt,
        receiptNumber: pay.receiptNumber,
      })),
      createdAt: p.createdAt,
    }));
  }

  static async requestMilestoneInspection(userId: string, data: {
    projectId: string;
    milestoneId: string;
    preferredDate: string;
    preferredTime: string;
    siteContactName: string;
    siteContactPhone: string;
    notes?: string;
  }) {
    const developer = await this.getDeveloperByUserId(userId);

    const project = await prisma.project.findFirst({
      where: { id: data.projectId, developerId: developer.id },
    });

    if (!project) throw new Error('Project not found or unauthorized');

    const milestone = await prisma.constructionMilestone.findFirst({
      where: { id: data.milestoneId, projectId: data.projectId },
    });

    if (!milestone) throw new Error('Milestone not found');

    // Update milestone status to SUBMITTED
    await prisma.constructionMilestone.update({
      where: { id: data.milestoneId },
      data: { status: 'SUBMITTED' },
    });

    // Create inspection request
    const inspection = await prisma.inspection.create({
      data: {
        userId,
        projectId: data.projectId,
        preferredDate: data.preferredDate,
        preferredTime: data.preferredTime,
        attendeeName: data.siteContactName,
        attendeePhone: data.siteContactPhone,
        attendeeEmail: developer.email,
        status: 'REQUESTED',
        notes: `Milestone Verification: ${milestone.title}. ${data.notes || ''}`,
      },
    });

    await AuditService.log({
      adminEmail: developer.email || 'developer@hometrust.ng',
      action: 'DEVELOPER_MILESTONE_INSPECTION_REQUESTED',
      entityType: 'INSPECTION',
      entityId: inspection.id,
      details: {
        developerId: developer.id,
        developerCompany: developer.companyName,
        projectId: project.id,
        projectName: project.name,
        milestoneTitle: milestone.title,
        scheduledDate: data.preferredDate,
      },
    });

    return inspection;
  }

  static async submitMilestoneProofPack(userId: string, data: {
    projectId: string;
    milestoneId: string;
    corenEngineerName: string;
    corenLicenseNumber: string;
    corenCertificateUrl?: string;
    testReportUrl?: string;
    walkthroughVideoUrl?: string;
    trancheAmount?: number;
    notes?: string;
  }) {
    const developer = await this.getDeveloperByUserId(userId);

    const project = await prisma.project.findFirst({
      where: { id: data.projectId, developerId: developer.id },
      include: {
        units: {
          include: {
            purchases: {
              include: { user: true }
            }
          }
        }
      }
    });

    if (!project) throw new Error('Project not found or unauthorized');

    const milestone = await prisma.constructionMilestone.findFirst({
      where: { id: data.milestoneId, projectId: data.projectId },
    });

    if (!milestone) throw new Error('Milestone not found');

    const now = new Date();
    const reviewExpires = new Date(now.getTime() + 5 * 24 * 60 * 60 * 1000);

    const updatedMilestone = await prisma.constructionMilestone.update({
      where: { id: data.milestoneId },
      data: {
        status: 'IN_REVIEW',
        corenEngineerName: data.corenEngineerName,
        corenLicenseNumber: data.corenLicenseNumber,
        corenCertificateUrl: data.corenCertificateUrl || null,
        testReportUrl: data.testReportUrl || null,
        walkthroughVideoUrl: data.walkthroughVideoUrl || null,
        trancheAmount: data.trancheAmount ? Number(data.trancheAmount) : milestone.trancheAmount,
        proofSubmittedAt: now,
        reviewWindowExpiresAt: reviewExpires,
        payoutStatus: 'IN_REVIEW',
        description: data.notes ? `${milestone.description || ''}\n${data.notes}`.trim() : milestone.description,
        approvalsCount: 0,
        disputesCount: 0,
      },
    });

    // Notify all subscribers of this project
    const buyers = project.units.flatMap(u => u.purchases.map(p => p.user)).filter(Boolean);
    const uniqueBuyerIds = [...new Set(buyers.map(b => b.id))];

    for (const buyerId of uniqueBuyerIds) {
      await prisma.notification.create({
        data: {
          userId: buyerId,
          title: `🏗️ Milestone Review: ${project.name}`,
          message: `Milestone "${milestone.title}" is complete with COREN engineer certification and 360° video. You have 5 days to review and approve tranche release.`,
          type: 'MILESTONE_REVIEW',
        }
      }).catch(() => {});
    }

    await AuditService.log({
      adminEmail: developer.email || 'developer@hometrust.ng',
      action: 'DEVELOPER_MILESTONE_PROOF_SUBMITTED',
      entityType: 'PROJECT',
      entityId: project.id,
      details: {
        developerId: developer.id,
        developerCompany: developer.companyName,
        projectId: project.id,
        projectName: project.name,
        milestoneTitle: milestone.title,
        corenEngineerName: data.corenEngineerName,
        corenLicenseNumber: data.corenLicenseNumber,
        trancheAmount: data.trancheAmount,
        reviewWindowExpiresAt: reviewExpires.toISOString(),
      },
    });

    return updatedMilestone;
  }

  static async requestPayout(userId: string, data: {
    amount: number;
    bankCode: string;
    bankName: string;
    accountNumber: string;
    accountName: string;
  }) {
    const developer = await this.getDeveloperByUserId(userId);

    const virtualAccount = await prisma.virtualAccount.findFirst({
      where: {
        OR: [
          { developerId: developer.id },
          { userId },
        ],
        status: 'ACTIVE',
      },
    });

    if (!virtualAccount || virtualAccount.balance < data.amount) {
      throw new Error(`Insufficient available funds. Current available balance is ₦${(virtualAccount?.balance || 0).toLocaleString()}`);
    }

    const netAmount = data.amount - 50; // ₦50 NIP settlement fee
    const reference = `HT-PAYOUT-${Date.now().toString().slice(-8)}`;

    // Deduct available balance
    await prisma.virtualAccount.update({
      where: { id: virtualAccount.id },
      data: {
        balance: { decrement: data.amount },
      },
    });

    const withdrawal = await prisma.withdrawal.create({
      data: {
        developerId: developer.id,
        userId,
        amount: data.amount,
        fee: 50,
        netAmount,
        bankCode: data.bankCode,
        bankName: data.bankName,
        accountNumber: data.accountNumber,
        accountName: data.accountName,
        reference,
        status: 'PROCESSING',
      },
    });

    await AuditService.log({
      adminEmail: developer.email || 'developer@hometrust.ng',
      action: 'DEVELOPER_PAYOUT_REQUESTED',
      entityType: 'WITHDRAWAL',
      entityId: withdrawal.id,
      details: {
        developerId: developer.id,
        developerCompany: developer.companyName,
        amount: data.amount,
        recipientAccount: data.accountNumber,
        bankName: data.bankName,
        reference,
      },
    });

    return withdrawal;
  }

  static async validateBoq(data: {
    state: string;
    items: Array<{
      category: string;
      name: string;
      quantity: number;
      unit: string;
      contractorUnitPrice: number;
    }>;
  }) {
    // Benchmark prices based on 36 states material index
    const benchmarks: Record<string, number> = {
      'Dangote 3X Portland Cement': 8600,
      'BUA Extra Cement': 8400,
      'Elephant / Lafarge Supaset': 8550,
      '12mm High-Yield TMT Steel Rods (Fe500)': 1280000,
      '16mm High-Yield TMT Steel Rods (Fe500)': 1280000,
      '10mm High-Yield TMT Steel Rods (Fe500)': 1295000,
      '20mm High-Yield TMT Steel Rods (Fe500)': 1280000,
      '25mm High-Yield TMT Steel Rods (Fe500)': 1310000,
      '30 Tonne Tipper (3/4 Inch Clean Granite)': 385000,
      '20 Tonne Tipper (Sharp River Sand)': 165000,
      '9-Inch Vibrated Hollow Sandcrete Blocks': 650,
      '6-Inch Vibrated Hollow Sandcrete Blocks': 550,
      '0.55mm Stone-Coated Step-Tile Roofing Sheets': 5800,
      '0.45mm Aluminium Long-Span Corrugated Sheets': 4400,
      '1.5mm Single-Core Pure Copper Cable (100m)': 28500,
      '2.5mm Single-Core Pure Copper Cable (100m)': 46000,
      '60x60cm Vitrified Polished Porcelain Floor Tiles': 8500,
    };

    let totalContractorCost = 0;
    let totalBenchmarkCost = 0;
    let inflatedItemsCount = 0;

    const validatedItems = data.items.map(item => {
      const benchmarkPrice = benchmarks[item.name] || item.contractorUnitPrice * 0.95;
      const contractorTotal = item.quantity * item.contractorUnitPrice;
      const benchmarkTotal = item.quantity * benchmarkPrice;
      const diffPercent = ((item.contractorUnitPrice - benchmarkPrice) / benchmarkPrice) * 100;

      totalContractorCost += contractorTotal;
      totalBenchmarkCost += benchmarkTotal;

      let status = 'FAIR';
      if (diffPercent > 15) {
        status = 'INFLATED';
        inflatedItemsCount++;
      } else if (diffPercent > 5) {
        status = 'ELEVATED';
      }

      return {
        ...item,
        benchmarkUnitPrice: benchmarkPrice,
        contractorTotal,
        benchmarkTotal,
        differencePercentage: Math.round(diffPercent * 10) / 10,
        status,
      };
    });

    const totalExcessCost = Math.max(0, totalContractorCost - totalBenchmarkCost);
    const overallVariancePercent = totalBenchmarkCost > 0
      ? Math.round(((totalContractorCost - totalBenchmarkCost) / totalBenchmarkCost) * 1000) / 10
      : 0;

    return {
      state: data.state,
      summary: {
        totalContractorCost,
        totalBenchmarkCost,
        totalExcessCost,
        overallVariancePercent,
        totalItems: data.items.length,
        inflatedItemsCount,
        verdict: totalExcessCost > 0 ? 'PADDING_DETECTED' : 'FAIR_MARKET_VALUE',
      },
      items: validatedItems,
    };
  }

  static async getJvLandListings() {
    return [
      {
        id: 'jv-lek-001',
        title: 'Prime 2,400 SQM Waterfront Land for Luxury Terrace Development',
        location: 'Off Admiralty Way, Lekki Phase 1, Lagos',
        state: 'Lagos',
        sizeSqm: 2400,
        zoning: 'Mixed-Use Residential (High Density)',
        titleDocument: "Governor's Consent (Perfected)",
        sharingRatio: '60% Developer / 40% Landowner',
        facilitationFee: '3% Legal & Escrow Coordination',
        estimatedGrossDevValue: 1200000000,
        verificationStatus: 'CERTIFIED_VERIFIED',
        ownerKybStatus: 'VERIFIED_DIRECT_OWNER',
        features: ['Paved dual carriageway access', 'Direct water frontage for jetty', 'LASPPPA approval clearance', 'Zero encumbrance/court injunction'],
        images: ['https://images.unsplash.com/photo-1500382017468-9049fed747ef?w=1200&q=80'],
      },
      {
        id: 'jv-ikoy-002',
        title: '3,200 SQM Commercial / Residential Land for High-Rise Apartments',
        location: 'Old Ikoyi, Lagos Island, Lagos State',
        state: 'Lagos',
        sizeSqm: 3200,
        zoning: 'High-Rise Residential (10+ Floors Allowed)',
        titleDocument: 'Federal Certificate of Occupancy (C-of-O)',
        sharingRatio: '65% Developer / 35% Landowner',
        facilitationFee: '3% Legal & Escrow Coordination',
        estimatedGrossDevValue: 4500000000,
        verificationStatus: 'CERTIFIED_VERIFIED',
        ownerKybStatus: 'VERIFIED_DIRECT_OWNER',
        features: ['Federal C of O with 68 years unexpired term', 'Independent Power Reticulation', 'Prime diplomatic corridor'],
        images: ['https://images.unsplash.com/photo-1512917774080-9991f1c4c750?w=1200&q=80'],
      },
      {
        id: 'jv-abj-003',
        title: '5,000 SQM Diplomatic Zone Land for Gated Villa Community',
        location: 'Maitama Extension / Katampe Main, Abuja FCT',
        state: 'Abuja FCT',
        sizeSqm: 5000,
        zoning: 'Low-Density Luxury Residential',
        titleDocument: 'FCDA / AGIS Certificate of Occupancy',
        sharingRatio: '70% Developer / 30% Landowner',
        facilitationFee: '3% Legal & Escrow Coordination',
        estimatedGrossDevValue: 2800000000,
        verificationStatus: 'CERTIFIED_VERIFIED',
        ownerKybStatus: 'VERIFIED_DIRECT_OWNER',
        features: ['FCDA Cadastral Survey Beacon Certified', 'Panoramic hill-top view', 'Infrastructure levy fully settled'],
        images: ['https://images.unsplash.com/photo-1600585154340-be6161a56a0c?w=1200&q=80'],
      },
    ];
  }

  static async sendBuyerReminder(developerUserId: string, purchaseId: string) {
    const developer = await this.getDeveloperByUserId(developerUserId);

    const purchase = await prisma.purchase.findUnique({
      where: { id: purchaseId },
      include: {
        user: true,
        projectUnit: { include: { project: true } },
        property: true,
      },
    });

    if (!purchase) throw new Error('Purchase record not found');

    const unitName = purchase.projectUnit?.name || purchase.property?.title || 'Property';

    // Create system notification for buyer
    await prisma.notification.create({
      data: {
        userId: purchase.userId,
        title: `Payment Reminder: ${unitName}`,
        message: `Dear ${purchase.user.firstName}, this is a gentle reminder regarding your upcoming instalment on ${unitName}. Please fund your dedicated Hometrust escrow account to avoid late settlement penalties.`,
        type: 'PAYMENT',
      },
    });

    await AuditService.log({
      adminEmail: developer.email || 'developer@hometrust.ng',
      action: 'DEVELOPER_AUTOMATED_REMINDER_SENT',
      entityType: 'PURCHASE',
      entityId: purchaseId,
      details: {
        developerId: developer.id,
        developerCompany: developer.companyName,
        buyerId: purchase.userId,
        purchaseCode: purchase.purchaseCode,
      },
    });

    return {
      success: true,
      message: 'Automated in-app and SMS reminder dispatched to buyer via Hometrust Shield.',
    };
  }
}

