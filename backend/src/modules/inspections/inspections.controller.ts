import { Request, Response } from 'express';
import { InspectionsService } from './inspections.service';
import { sendSuccess, sendError } from '../../utils/response';
import { AuthRequest } from '../../middlewares/auth.middleware';

export class InspectionsController {
  static async create(req: AuthRequest, res: Response): Promise<void> {
    try {
      if (!req.user) {
        sendError(res, 'Unauthorized', 401);
        return;
      }
      const result = await InspectionsService.create({
        userId: req.user.id,
        propertyId: req.body.propertyId,
        projectId: req.body.projectId,
        milestoneId: req.body.milestoneId,
        inspectionType: req.body.inspectionType,
        scope: req.body.scope,
        preferredDate: req.body.preferredDate,
        preferredTime: req.body.preferredTime,
        attendeeName: req.body.attendeeName || `${req.user.firstName} ${req.user.lastName}`,
        attendeePhone: req.body.attendeePhone || '',
        attendeeEmail: req.body.attendeeEmail || req.user.email,
        representativeName: req.body.representativeName,
        representativePhone: req.body.representativePhone,
        notes: req.body.notes,
        paymentReference: req.body.paymentReference,
      });
      sendSuccess(res, result, 'Inspection booked successfully', 201);
    } catch (error: any) {
      sendError(res, error.message, 400);
    }
  }

  static async getMyInspections(req: AuthRequest, res: Response): Promise<void> {
    try {
      if (!req.user) {
        sendError(res, 'Unauthorized', 401);
        return;
      }
      const result = await InspectionsService.getUserInspections(req.user.id);
      sendSuccess(res, result, 'User inspections retrieved');
    } catch (error: any) {
      sendError(res, error.message, 400);
    }
  }

  static async getAll(req: Request, res: Response): Promise<void> {
    try {
      const result = await InspectionsService.getAll({
        status: req.query.status as string,
        type: req.query.type as string,
        scope: req.query.scope as string,
      });
      sendSuccess(res, result, 'All inspections retrieved');
    } catch (error: any) {
      sendError(res, error.message, 400);
    }
  }

  static async assignCoren(req: AuthRequest, res: Response): Promise<void> {
    try {
      if (!req.user) {
        sendError(res, 'Unauthorized', 401);
        return;
      }
      const { engineerName, licenseNumber } = req.body;
      const result = await InspectionsService.assignCorenEngineer(req.params.id as string, engineerName, licenseNumber, req.user);
      sendSuccess(res, result, 'COREN Engineer assigned');
    } catch (error: any) {
      sendError(res, error.message, 400);
    }
  }

  static async submitCorenReport(req: AuthRequest, res: Response): Promise<void> {
    try {
      if (!req.user) {
        sendError(res, 'Unauthorized', 401);
        return;
      }
      const result = await InspectionsService.submitCorenReport(req.params.id as string, req.body, req.user);
      sendSuccess(res, result, 'COREN Inspection Report uploaded');
    } catch (error: any) {
      sendError(res, error.message, 400);
    }
  }

  static async submitGeofencedVideo(req: AuthRequest, res: Response): Promise<void> {
    try {
      if (!req.user) {
        sendError(res, 'Unauthorized', 401);
        return;
      }
      const result = await InspectionsService.submitGeofencedVideo(req.params.id as string, req.body);
      sendSuccess(res, result, 'Geofenced live video submitted');
    } catch (error: any) {
      sendError(res, error.message, 400);
    }
  }

  static async updateStatus(req: Request, res: Response): Promise<void> {
    try {
      const result = await InspectionsService.updateStatus(
        req.params.id as string,
        req.body.status,
        req.body.developerNotes
      );
      sendSuccess(res, result, 'Inspection status updated');
    } catch (error: any) {
      sendError(res, error.message, 400);
    }
  }
}
