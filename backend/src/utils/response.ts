import { Response } from 'express';

export interface ApiResponse<T = any> {
  success: boolean;
  message: string;
  data?: T;
  meta?: Record<string, any>;
  errors?: any;
}

export const sendSuccess = <T>(
  res: Response,
  data: T,
  message = 'Operation successful',
  statusCode = 200,
  meta?: Record<string, any>
) => {
  const responseBody: ApiResponse<T> = {
    success: true,
    message,
    data,
    meta,
  };
  return res.status(statusCode).json(responseBody);
};

export const sendError = (
  res: Response,
  message = 'An error occurred',
  statusCode = 400,
  errors?: any
) => {
  const responseBody: ApiResponse = {
    success: false,
    message,
    errors,
  };
  return res.status(statusCode).json(responseBody);
};
