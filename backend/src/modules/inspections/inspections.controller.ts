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
        preferredDate: req.body.preferredDate,
        preferredTime: req.body.preferredTime,
        attendeeName: req.body.attendeeName || `${req.user.firstName} ${req.user.lastName}`,
        attendeePhone: req.body.attendeePhone || '',
        attendeeEmail: req.body.attendeeEmail || req.user.email,
        notes: req.body.notes,
      });
      sendSuccess(res, result, 'Inspection requested', 201);
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
      });
      sendSuccess(res, result, 'All inspections retrieved');
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
