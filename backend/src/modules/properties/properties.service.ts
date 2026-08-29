import { prisma } from '../../utils/prisma';

export interface PropertyFilterParams {
  state?: string;
  city?: string;
  area?: string;
  propertyType?: string;
  listingType?: string;
  minPrice?: number;
  maxPrice?: number;
  bedrooms?: number;
  verificationStatus?: string;
  isFeatured?: boolean;
  isVerifiedDeveloperOnly?: boolean;
  search?: string;
  page?: number;
  limit?: number;
}

export class PropertiesService {
  static async getAll(filters: PropertyFilterParams) {
    const page = filters.page || 1;
    const limit = filters.limit || 20;
    const skip = (page - 1) * limit;

    const where: any = {
      isPublished: true,
    };

    if (filters.state) where.state = { contains: filters.state };
    if (filters.city) where.city = { contains: filters.city };
    if (filters.area) where.area = { contains: filters.area };
    if (filters.propertyType) where.propertyType = filters.propertyType;
    if (filters.listingType) where.listingType = filters.listingType;
    if (filters.bedrooms) where.bedrooms = { gte: filters.bedrooms };
    if (filters.verificationStatus) where.verificationStatus = filters.verificationStatus;
    if (filters.isFeatured !== undefined) where.isFeatured = filters.isFeatured;

    if (filters.minPrice || filters.maxPrice) {
      where.price = {};
      if (filters.minPrice) where.price.gte = filters.minPrice;
      if (filters.maxPrice) where.price.lte = filters.maxPrice;
    }

    if (filters.search) {
      where.OR = [
        { title: { contains: filters.search } },
        { description: { contains: filters.search } },
        { area: { contains: filters.search } },
        { city: { contains: filters.search } },
      ];
    }

    if (filters.isVerifiedDeveloperOnly) {
      where.developer = { isVerified: true };
    }

    const [properties, total] = await Promise.all([
      prisma.property.findMany({
        where,
        skip,
        take: limit,
        orderBy: [{ isFeatured: 'desc' }, { createdAt: 'desc' }],
        include: {
          developer: {
            select: {
              id: true,
              companyName: true,
              cacNumber: true,
              isVerified: true,
              verificationStatus: true,
              logoUrl: true,
              completedProjectsCount: true,
              yearsOperating: true,
            },
          },
          paymentPlans: {
            where: { isActive: true },
          },
        },
      }),
      prisma.property.count({ where }),
    ]);

    const formattedProperties = properties.map(p => ({
      ...p,
      images: JSON.parse(p.images || '[]'),
    }));

    return {
      properties: formattedProperties,
      total,
      page,
      totalPages: Math.ceil(total / limit),
    };
  }

  static async getById(idOrSlug: string) {
    const property = await prisma.property.findFirst({
      where: {
        OR: [{ id: idOrSlug }, { slug: idOrSlug }],
      },
      include: {
        developer: {
          select: {
            id: true,
            companyName: true,
            cacNumber: true,
            businessType: true,
            contactPerson: true,
            phone: true,
            email: true,
            officeAddress: true,
            yearsOperating: true,
            website: true,
            isVerified: true,
            verificationStatus: true,
            verificationDate: true,
            verifiedCategories: true,
            logoUrl: true,
            about: true,
            completedProjectsCount: true,
            ongoingProjectsCount: true,
          },
        },
        documents: {
          where: { isPublic: true },
        },
        paymentPlans: {
          where: { isActive: true },
        },
      },
    });

    if (!property) {
      throw new Error('Property not found');
    }

    return {
      ...property,
      images: JSON.parse(property.images || '[]'),
      developer: {
        ...property.developer,
        verifiedCategories: property.developer.verifiedCategories
          ? JSON.parse(property.developer.verifiedCategories)
          : [],
      },
    };
  }

  static async create(data: any, userId: string, userRole: string) {
    let developerId = data.developerId;

    if (userRole === 'DEVELOPER') {
      const developer = await prisma.developer.findUnique({
        where: { userId },
      });
      if (!developer) {
        throw new Error('Developer profile not found');
      }
      developerId = developer.id;
    }

    const slug = `${data.title.toLowerCase().replace(/[^a-z0-9]+/g, '-')}-${Date.now().toString(36)}`;

    const property = await prisma.property.create({
      data: {
        developerId,
        title: data.title,
        slug,
        description: data.description,
        propertyType: data.propertyType,
        listingType: data.listingType || 'OUTRIGHT',
        state: data.state,
        city: data.city,
        area: data.area,
        address: data.address,
        price: data.price,
        bedrooms: data.bedrooms || 0,
        bathrooms: data.bathrooms || 0,
        landSize: data.landSize,
        landTitle: data.landTitle,
        verificationStatus: data.verificationStatus || 'PENDING_REVIEW',
        isPublished: data.isPublished !== undefined ? data.isPublished : true,
        isFeatured: data.isFeatured || false,
        images: JSON.stringify(data.images || []),
        videoUrl: data.videoUrl,
        virtualTourUrl: data.virtualTourUrl,
        completionDate: data.completionDate,
        completionStatus: data.completionStatus || 'COMPLETED',
      },
    });

    // Create payment plans if provided
    if (data.paymentPlans && Array.isArray(data.paymentPlans)) {
      for (const plan of data.paymentPlans) {
        await prisma.paymentPlan.create({
          data: {
            propertyId: property.id,
            name: plan.name,
            totalPrice: plan.totalPrice || property.price,
            initialDeposit: plan.initialDeposit,
            durationMonths: plan.durationMonths || 12,
            monthlyPayment: plan.monthlyPayment || ((plan.totalPrice || property.price) - plan.initialDeposit) / (plan.durationMonths || 12),
            paymentFrequency: plan.paymentFrequency || 'MONTHLY',
            platformFee: plan.platformFee || 5000,
          },
        });
      }
    }

    return property;
  }
}
