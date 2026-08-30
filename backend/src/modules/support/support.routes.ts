import { Router } from 'express';
import { SupportController } from './support.controller';
import { authenticate, requireRoles } from '../../middlewares/auth.middleware';

const router = Router();

// ── User Routes ──────────────────────────────────────────────────────────────
router.post('/tickets', authenticate, SupportController.createTicket);
router.get('/tickets', authenticate, SupportController.getMyTickets);
router.get('/tickets/:id', authenticate, SupportController.getTicket);

// ── Admin Routes ─────────────────────────────────────────────────────────────
router.get('/admin/tickets', authenticate, requireRoles('ADMIN', 'SUPER_ADMIN', 'SUPPORT_AGENT'), SupportController.adminGetTickets);
router.post('/admin/tickets/:id/reply', authenticate, requireRoles('ADMIN', 'SUPER_ADMIN', 'SUPPORT_AGENT'), SupportController.adminReply);
router.patch('/admin/tickets/:id/status', authenticate, requireRoles('ADMIN', 'SUPER_ADMIN', 'SUPPORT_AGENT'), SupportController.adminUpdateStatus);

export default router;
