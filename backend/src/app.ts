import express, { Request, Response } from 'express';
import cors from 'cors';
import helmet from 'helmet';
import rateLimit from 'express-rate-limit';
import path from 'path';
import fs from 'fs';

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
import { bankingRoutes } from './modules/banking/banking.routes';
import { aiRoutes } from './modules/ai/ai.routes';
import { materialsRoutes } from './modules/materials/materials.routes';
import supportRoutes from './modules/support/support.routes';
import { buildRoutes } from './modules/build/build.routes';
import { reelsRoutes } from './modules/reels/reels.routes';
import { userRoutes } from './modules/users/users.routes';
import { errorHandler } from './middlewares/error.middleware';

const app = express();

// Enable trust proxy for Render / load balancers
app.set('trust proxy', 1);

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

// Static Admin Dashboard Assets
const publicDir = path.resolve(__dirname, '../public');
if (fs.existsSync(publicDir)) {
  app.use(express.static(publicDir));
}

// Health Check
app.get('/health', (req: Request, res: Response) => {
  res.status(200).json({
    status: 'online',
    platform: 'Hometrust API & Admin Console',
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
app.use(`${apiPrefix}/banking`, bankingRoutes);
app.use(`${apiPrefix}/ai`, aiRoutes);
app.use(`${apiPrefix}/materials`, materialsRoutes);
app.use(`${apiPrefix}/support`, supportRoutes);
app.use(`${apiPrefix}/build`, buildRoutes);
app.use(`${apiPrefix}/reels`, reelsRoutes);
app.use(`${apiPrefix}/users`, userRoutes);

// Fallback to Admin Dashboard SPA if public/index.html exists
app.get('*', (req: Request, res: Response, next) => {
  if (req.path.startsWith('/api/')) return next();
  const indexHtml = path.join(publicDir, 'index.html');
  if (fs.existsSync(indexHtml)) {
    return res.sendFile(indexHtml);
  }
  res.status(200).json({
    status: 'online',
    platform: 'Hometrust Platform',
    tagline: 'Verify. Buy. Pay. Track.',
    version: '1.0.0',
    endpoints: '/api/v1',
  });
});

// Error Middleware
app.use(errorHandler);

export default app;
