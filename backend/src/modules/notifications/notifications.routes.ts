import { Router } from 'express';
import { NotificationsController } from './notifications.controller';
import { authenticate } from '../../middlewares/auth.middleware';

const router = Router();

router.get('/', authenticate as any, NotificationsController.getMyNotifications as any);
router.patch('/:id/read', authenticate as any, NotificationsController.markAsRead);
router.patch('/read-all', authenticate as any, NotificationsController.markAllAsRead as any);

export const notificationRoutes = router;
