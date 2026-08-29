import { Request, Response } from 'express';
import { PropertiesService } from './properties.service';
import { sendSuccess, sendError } from '../../utils/response';
import { AuthRequest } from '../../middlewares/auth.middleware';

export class PropertiesController {
  static async getAll(req: Request, res: Response): Promise<void> {
    try {
      const filters = {
        state: req.query.state as string,
        city: req.query.city as string,
        area: req.query.area as string,
        propertyType: req.query.propertyType as string,
        listingType: req.query.listingType as string,
        minPrice: req.query.minPrice ? parseFloat(req.query.minPrice as string) : undefined,
        maxPrice: req.query.maxPrice ? parseFloat(req.query.maxPrice as string) : undefined,
        bedrooms: req.query.bedrooms ? parseInt(req.query.bedrooms as string, 10) : undefined,
        verificationStatus: req.query.verificationStatus as string,
        isFeatured: req.query.isFeatured === 'true' ? true : undefined,
        isVerifiedDeveloperOnly: req.query.isVerifiedDeveloperOnly === 'true',
        search: req.query.search as string,
        page: req.query.page ? parseInt(req.query.page as string, 10) : 1,
        limit: req.query.limit ? parseInt(req.query.limit as string, 10) : 20,
      };

      const result = await PropertiesService.getAll(filters);
      sendSuccess(res, result.properties, 'Properties retrieved successfully', 200, {
        total: result.total,
        page: result.page,
        totalPages: result.totalPages,
      });
    } catch (error: any) {
      sendError(res, error.message, 400);
    }
  }

  static async getById(req: Request, res: Response): Promise<void> {
    try {
      const property = await PropertiesService.getById(req.params.id as string);
      sendSuccess(res, property, 'Property details retrieved');
    } catch (error: any) {
      sendError(res, error.message, 404);
    }
  }

  static async create(req: AuthRequest, res: Response): Promise<void> {
    try {
      if (!req.user) {
        sendError(res, 'Unauthorized', 401);
        return;
      }
      const property = await PropertiesService.create(req.body, req.user.id, req.user.role);
      sendSuccess(res, property, 'Property created successfully', 201);
    } catch (error: any) {
      sendError(res, error.message, 400);
    }
  }
}
