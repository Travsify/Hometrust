import { Router } from 'express';
import { ChatController } from './chat.controller';
import { authenticate } from '../../middlewares/auth.middleware';

const router = Router();

router.post('/conversation', authenticate as any, ChatController.getOrCreate as any);
router.post('/start/developer', authenticate as any, ChatController.startWithDeveloper as any);
router.post('/start/support', authenticate as any, ChatController.startWithSupport as any);
router.get('/my-conversations', authenticate as any, ChatController.getMyConversations as any);
router.get('/conversations/:conversationId/messages', authenticate as any, ChatController.getConversationMessages as any);
router.post('/conversations/:conversationId/messages', authenticate as any, ChatController.sendMessage as any);
router.get('/unread-count', authenticate as any, ChatController.getUnreadCount as any);

export const chatRoutes = router;
