import { Request, Response } from 'express';
import { VerificationsService } from './verifications.service';
import { sendSuccess, sendError } from '../../utils/response';
import { AuthRequest } from '../../middlewares/auth.middleware';
import { createClient } from '@supabase/supabase-js';
import { config } from '../../config';

const supabase = createClient(
  config.storage?.supabaseUrl || config.supabase.url,
  config.storage?.supabaseKey || config.supabase.serviceRoleKey
);
const BUCKET = config.storage?.supabaseBucket || 'estateverify-documents';

export class VerificationsController {
  static async create(req: AuthRequest, res: Response): Promise<void> {
    try {
      if (!req.user) {
        sendError(res, 'Unauthorized', 401);
        return;
      }

      let documents: Array<{ fileName: string; fileUrl: string; fileType?: string; fileSize?: number }> = [];

      if (req.body.documents) {
        if (typeof req.body.documents === 'string') {
          try {
            documents = JSON.parse(req.body.documents);
          } catch (_) {}
        } else if (Array.isArray(req.body.documents)) {
          documents = req.body.documents;
        }
      }

      // Handle uploaded files via multer
      const files = (req.files as Express.Multer.File[]) || (req.file ? [req.file] : []);
      for (const file of files) {
        const ext = (file.originalname.split('.').pop() || 'pdf').toLowerCase();
        const storagePath = `verifications/${req.user.id}/${Date.now()}-${file.originalname.replace(/[^a-zA-Z0-9._-]/g, '_')}`;

        const { error: uploadError } = await supabase.storage
          .from(BUCKET)
          .upload(storagePath, file.buffer, {
            contentType: file.mimetype || 'application/octet-stream',
            upsert: true,
          });

        let fileUrl = '';
        if (!uploadError) {
          const { data: publicData } = supabase.storage.from(BUCKET).getPublicUrl(storagePath);
          fileUrl = publicData.publicUrl;
        } else {
          console.warn('[SUPABASE VERIFICATION UPLOAD ERROR]', uploadError.message);
          fileUrl = `/uploads/verifications/${file.originalname}`;
        }

        documents.push({
          fileName: file.originalname,
          fileUrl,
          fileType: file.mimetype,
          fileSize: file.size,
        });
      }

      const result = await VerificationsService.create({
        userId: req.user.id,
        propertyName: req.body.propertyName,
        propertyAddress: req.body.propertyAddress,
        state: req.body.state,
        city: req.body.city,
        documentType: req.body.documentType,
        urgency: req.body.urgency,
        deliveryOption: req.body.deliveryOption,
        deliveryAddress: req.body.deliveryAddress,
        deliveryFee: req.body.deliveryFee ? parseFloat(req.body.deliveryFee) : 0,
        documents,
      });

      sendSuccess(res, result, 'Verification request submitted successfully', 201);
    } catch (error: any) {
      sendError(res, error.message, 400);
    }
  }

  static async getById(req: Request, res: Response): Promise<void> {
    try {
      const result = await VerificationsService.getById(req.params.idOrCode as string);
      sendSuccess(res, result, 'Verification details retrieved');
    } catch (error: any) {
      sendError(res, error.message, 404);
    }
  }

  static async getMyRequests(req: AuthRequest, res: Response): Promise<void> {
    try {
      if (!req.user) {
        sendError(res, 'Unauthorized', 401);
        return;
      }
      const requests = await VerificationsService.getUserRequests(req.user.id);
      sendSuccess(res, requests, 'User verification requests retrieved');
    } catch (error: any) {
      sendError(res, error.message, 400);
    }
  }

  static async getAll(req: Request, res: Response): Promise<void> {
    try {
      const filters = {
        status: req.query.status as string,
        search: req.query.search as string,
        page: req.query.page ? parseInt(req.query.page as string, 10) : 1,
        limit: req.query.limit ? parseInt(req.query.limit as string, 10) : 20,
      };
      const result = await VerificationsService.getAll(filters);
      sendSuccess(res, result.requests, 'Verification requests retrieved', 200, {
        total: result.total,
        page: result.page,
        totalPages: result.totalPages,
      });
    } catch (error: any) {
      sendError(res, error.message, 400);
    }
  }

  static async updateStatus(req: AuthRequest, res: Response): Promise<void> {
    try {
      if (!req.user) {
        sendError(res, 'Unauthorized', 401);
        return;
      }
      const result = await VerificationsService.updateStatus(req.params.id as string, req.body, req.user);
      sendSuccess(res, result, 'Verification request updated successfully');
    } catch (error: any) {
      sendError(res, error.message, 400);
    }
  }

  static async payWithWallet(req: AuthRequest, res: Response): Promise<void> {
    try {
      if (!req.user) {
        sendError(res, 'Unauthorized', 401);
        return;
      }
      const result = await VerificationsService.payWithWallet(req.params.id as string, req.user.id);
      if (!result.success && result.code === 'INSUFFICIENT_FUNDS') {
        sendError(res, 'Insufficient funds in dedicated wallet', 402, result);
        return;
      }
      sendSuccess(res, result, 'Verification fee paid successfully');
    } catch (error: any) {
      sendError(res, error.message, 400);
    }
  }


  static async dispatchCourier(req: AuthRequest, res: Response): Promise<void> {
    try {
      if (!req.user) {
        sendError(res, 'Unauthorized', 401);
        return;
      }
      const result = await VerificationsService.dispatchCourier(req.params.id as string, req.body, req.user);
      sendSuccess(res, result, 'Hard copies marked as dispatched');
    } catch (error: any) {
      sendError(res, error.message, 400);
    }
  }

  static async confirmDelivery(req: Request, res: Response): Promise<void> {
    try {
      const result = await VerificationsService.confirmDelivery(req.params.id as string, req.body);
      sendSuccess(res, result, 'Delivery confirmed successfully');
    } catch (error: any) {
      sendError(res, error.message, 400);
    }
  }

}
