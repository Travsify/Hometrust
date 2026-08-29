import { Request, Response, NextFunction } from 'express';
import { ZodSchema, ZodError } from 'zod';
import { sendError } from '../utils/response';

export const validateBody = (schema: ZodSchema) => {
  return (req: Request, res: Response, next: NextFunction): void => {
    try {
      req.body = schema.parse(req.body);
      next();
    } catch (error) {
      if (error instanceof ZodError) {
        sendError(res, 'Validation failed', 422, error.errors.map(e => ({
          field: e.path.join('.'),
          message: e.message,
        })));
        return;
      }
      sendError(res, 'Invalid request payload', 400);
    }
  };
};
