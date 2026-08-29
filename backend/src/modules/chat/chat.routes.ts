import { Router } from 'express';
import { ChatController } from './chat.controller';
import { authenticate } from '../../middlewares/auth.middleware';

const router = Router();

router.post('/conversation', authenticate as any, ChatController.getOrCreate as any);
router.get('/my-conversations', authenticate as any, ChatController.getMyConversations as any);
router.post('/conversation/:conversationId/message', authenticate as any, ChatController.sendMessage as any);

export const chatRoutes = router;
