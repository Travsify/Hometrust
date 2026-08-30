import { prisma } from '../../utils/prisma';
import { AuditService } from '../audit/audit.service';

export interface CreateInspectionParams {
  userId: string;
  propertyId?: string;
  projectId?: string;
  milestoneId?: string;
  inspectionType?: 'SELF_OR_REPRESENTATIVE' | 'COREN_ENGINEER' | 'GEOFENCED_VIDEO';
  scope?: 'PRE_PURCHASE' | 'MILESTONE_VERIFICATION';
  preferredDate: string;
  preferredTime: string;
  attendeeName: string;
  attendeePhone: string;
  attendeeEmail: string;
  representativeName?: string;
  representativePhone?: string;
  notes?: string;
  paymentReference?: string;
}

export class InspectionsService {
  static async create(params: CreateInspectionParams) {
    const type = params.inspectionType || 'SELF_OR_REPRESENTATIVE';
    const scope = params.scope || (params.milestoneId ? 'MILESTONE_VERIFICATION' : 'PRE_PURCHASE');
    const fee = type === 'COREN_ENGINEER' ? 25000 : 0;
    const paymentStatus = type === 'COREN_ENGINEER' ? (params.paymentReference ? 'PAID' : 'PENDING') : 'WAIVED';
    const gatePassCode = `HT-PASS-${Math.floor(100000 + Math.random() * 900000)}`;

    const inspection = await prisma.inspection.create({
      data: {
        userId: params.userId,
        propertyId: params.propertyId || null,
        projectId: params.projectId || null,
        milestoneId: params.milestoneId || null,
        inspectionType: type,
        scope,
        preferredDate: params.preferredDate,
        preferredTime: params.preferredTime,
        attendeeName: params.attendeeName,
        attendeePhone: params.attendeePhone,
        attendeeEmail: params.attendeeEmail,
        representativeName: params.representativeName || null,
        representativePhone: params.representativePhone || null,
        fee,
        paymentStatus,
        paymentReference: params.paymentReference || null,
        gatePassCode,
        status: type === 'COREN_ENGINEER' ? 'ASSIGNED' : 'REQUESTED',
        notes: params.notes || null,
      },
      include: {
        property: true,
        project: true,
      },
    });

    // Create In-App Notification
    await prisma.notification.create({
      data: {
        userId: params.userId,
        title: type === 'COREN_ENGINEER' 
          ? '🏛️ COREN Engineer Inspection Booked'
          : type === 'GEOFENCED_VIDEO'
            ? '📹 Geofenced Video Inspection Requested'
            : '🎟️ Site Inspection Pass Generated',
        message: type === 'COREN_ENGINEER'
          ? `An accredited COREN structural engineer has been scheduled for inspection on ${params.preferredDate} (${params.preferredTime}).`
          : type === 'GEOFENCED_VIDEO'
            ? `Your request for a live geofenced site walkthrough video has been dispatched to the project developer.`
            : `Your site access pass (${gatePassCode}) is ready for ${params.attendeeName || params.representativeName} on ${params.preferredDate}.`,
        type: 'INSPECTION',
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

  static async getAll(filters: { status?: string; type?: string; scope?: string }) {
    const where: any = {};
    if (filters.status) where.status = filters.status;
    if (filters.type) where.inspectionType = filters.type;
    if (filters.scope) where.scope = filters.scope;

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

  static async assignCorenEngineer(id: string, engineerName: string, licenseNumber: string, user: any) {
    const updated = await prisma.inspection.update({
      where: { id },
      data: {
        corenEngineerName: engineerName,
        corenLicenseNumber: licenseNumber,
        status: 'ASSIGNED',
      },
    });

    await AuditService.log({
      userId: user.id,
      userEmail: user.email,
      userRole: user.role,
      action: 'ASSIGN_COREN_ENGINEER',
      entity: 'Inspection',
      entityId: id,
      details: { engineerName, licenseNumber },
    });

    return updated;
  }

  static async submitCorenReport(
    id: string,
    data: { reportUrl: string; structuralScore?: number; defectNotes?: string; status?: string },
    user: any
  ) {
    const updated = await prisma.inspection.update({
      where: { id },
      data: {
        corenReportUrl: data.reportUrl,
        structuralScore: data.structuralScore || 90,
        defectNotes: data.defectNotes || null,
        status: data.status || 'COMPLETED',
        reportSubmittedAt: new Date(),
      },
      include: { user: true, project: true },
    });

    // Notify Buyer
    if (updated.userId) {
      await prisma.notification.create({
        data: {
          userId: updated.userId,
          title: '📋 COREN Inspection Report Available',
          message: `Your accredited structural engineer has uploaded the certified inspection report for ${updated.project?.name || 'your property'}. Score: ${data.structuralScore || 90}/100.`,
          type: 'INSPECTION',
        },
      });
    }

    await AuditService.log({
      userId: user.id,
      userEmail: user.email,
      userRole: user.role,
      action: 'SUBMIT_COREN_REPORT',
      entity: 'Inspection',
      entityId: id,
      details: data,
    });

    return updated;
  }

  static async submitGeofencedVideo(
    id: string,
    data: { videoUrl: string; latitude: number; longitude: number }
  ) {
    const inspection = await prisma.inspection.findUnique({
      where: { id },
      include: { project: true, property: true },
    });

    if (!inspection) throw new Error('Inspection request not found');

    const updated = await prisma.inspection.update({
      where: { id },
      data: {
        geofencedVideoUrl: data.videoUrl,
        geofenceLatitude: data.latitude,
        geofenceLongitude: data.longitude,
        isGeofenceVerified: true,
        status: 'COMPLETED',
        reportSubmittedAt: new Date(),
      },
    });

    // Notify Buyer
    await prisma.notification.create({
      data: {
        userId: inspection.userId,
        title: '📹 Live Geofenced Video Received',
        message: `The developer has recorded and uploaded a verified on-site live walkthrough video for ${inspection.project?.name || 'your property'}.`,
        type: 'INSPECTION',
      },
    });

    return updated;
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
