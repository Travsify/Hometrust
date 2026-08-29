import { prisma } from '../../utils/prisma';

export interface CreateInspectionParams {
  userId: string;
  propertyId?: string;
  projectId?: string;
  preferredDate: string;
  preferredTime: string;
  attendeeName: string;
  attendeePhone: string;
  attendeeEmail: string;
  notes?: string;
}

export class InspectionsService {
  static async create(params: CreateInspectionParams) {
    const inspection = await prisma.inspection.create({
      data: {
        userId: params.userId,
        propertyId: params.propertyId,
        projectId: params.projectId,
        preferredDate: params.preferredDate,
        preferredTime: params.preferredTime,
        attendeeName: params.attendeeName,
        attendeePhone: params.attendeePhone,
        attendeeEmail: params.attendeeEmail,
        notes: params.notes,
        status: 'REQUESTED',
      },
      include: {
        property: true,
        project: true,
      },
    });

    return inspection;
  }

  static async getUserInspections(userId: string) {
    return prisma.inspection.findMany({
      where: { userId },
      orderBy: { createdAt: 'desc' },
      include: {
        property: true,
        project: true,
      },
    });
  }

  static async getAll(filters: { status?: string }) {
    const where = filters.status ? { status: filters.status } : {};
    return prisma.inspection.findMany({
      where,
      orderBy: { createdAt: 'desc' },
      include: {
        user: true,
        property: true,
        project: true,
      },
    });
  }

  static async updateStatus(id: string, status: string, developerNotes?: string) {
    return prisma.inspection.update({
      where: { id },
      data: {
        status,
        developerNotes,
      },
    });
  }
}
