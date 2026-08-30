import { Router } from 'express';
import { NotificationsController } from './notifications.controller';
import { authenticate } from '../../middlewares/auth.middleware';

const router = Router();

router.get('/', authenticate as any, NotificationsController.getMyNotifications as any);
router.patch('/read-all', authenticate as any, NotificationsController.markAllAsRead as any);
router.delete('/clear-all', authenticate as any, NotificationsController.clearAll as any);
router.patch('/:id/read', authenticate as any, NotificationsController.markAsRead as any);
router.delete('/:id', authenticate as any, NotificationsController.deleteNotification as any);

export const notificationRoutes = router;
