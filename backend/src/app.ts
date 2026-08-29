import express, { Request, Response } from 'express';
import cors from 'cors';
import helmet from 'helmet';
import rateLimit from 'express-rate-limit';
import path from 'path';

import { authRoutes } from './modules/auth/auth.routes';
import { propertyRoutes } from './modules/properties/properties.routes';
import { projectRoutes } from './modules/projects/projects.routes';
import { developerRoutes } from './modules/developers/developers.routes';
import { paymentRoutes } from './modules/payments/payments.routes';
import { verificationRoutes } from './modules/verifications/verifications.routes';
import { legalRoutes } from './modules/legal/legal.routes';
import { purchaseRoutes } from './modules/purchases/purchases.routes';
import { inspectionRoutes } from './modules/inspections/inspections.routes';
import { chatRoutes } from './modules/chat/chat.routes';
import { notificationRoutes } from './modules/notifications/notifications.routes';
import { adminRoutes } from './modules/admin/admin.routes';
import { storageRoutes } from './modules/storage/storage.routes';
import { errorHandler } from './middlewares/error.middleware';

const app = express();

// Security Middlewares
app.use(helmet({
  crossOriginResourcePolicy: { policy: 'cross-origin' },
}));

app.use(cors({
  origin: '*',
  methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE'],
  allowedHeaders: ['Content-Type', 'Authorization', 'x-paystack-signature'],
}));

// Rate Limiter
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 1000,
  message: { success: false, message: 'Too many requests from this IP, please try again later.' },
});
app.use('/api/', limiter);

// Body Parsers
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// Health Check
app.get('/health', (req: Request, res: Response) => {
  res.status(200).json({
    status: 'online',
    platform: 'EstateVerify API',
    tagline: 'Verify. Buy. Pay. Track.',
    version: '1.0.0',
    timestamp: new Date().toISOString(),
  });
});

// API Routes
const apiPrefix = '/api/v1';
app.use(`${apiPrefix}/auth`, authRoutes);
app.use(`${apiPrefix}/properties`, propertyRoutes);
app.use(`${apiPrefix}/projects`, projectRoutes);
app.use(`${apiPrefix}/developers`, developerRoutes);
app.use(`${apiPrefix}/payments`, paymentRoutes);
app.use(`${apiPrefix}/verifications`, verificationRoutes);
app.use(`${apiPrefix}/legal`, legalRoutes);
app.use(`${apiPrefix}/purchases`, purchaseRoutes);
app.use(`${apiPrefix}/inspections`, inspectionRoutes);
app.use(`${apiPrefix}/chat`, chatRoutes);
app.use(`${apiPrefix}/notifications`, notificationRoutes);
app.use(`${apiPrefix}/admin`, adminRoutes);
app.use(`${apiPrefix}/storage`, storageRoutes);

// Error Middleware
app.use(errorHandler);

export default app;
