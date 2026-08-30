import { Request, Response } from 'express';
import { SupportService } from './support.service';
import { sendSuccess, sendError } from '../../utils/response';
import { AuthRequest } from '../../middlewares/auth.middleware';

export class SupportController {
  /** POST /api/v1/support/tickets — user opens a ticket */
  static async createTicket(req: AuthRequest, res: Response): Promise<void> {
    try {
      if (!req.user) { sendError(res, 'Unauthorized', 401); return; }
      const ticket = await SupportService.createTicket(req.user.id, req.body);
      sendSuccess(res, ticket, 'Support ticket created successfully', 201);
    } catch (e: any) { sendError(res, e.message, 400); }
  }

  /** GET /api/v1/support/tickets — user lists their own tickets */
  static async getMyTickets(req: AuthRequest, res: Response): Promise<void> {
    try {
      if (!req.user) { sendError(res, 'Unauthorized', 401); return; }
      const tickets = await SupportService.getUserTickets(req.user.id);
      sendSuccess(res, tickets, 'Your support tickets retrieved');
    } catch (e: any) { sendError(res, e.message, 400); }
  }

  /** GET /api/v1/support/tickets/:id — user gets single ticket */
  static async getTicket(req: AuthRequest, res: Response): Promise<void> {
    try {
      if (!req.user) { sendError(res, 'Unauthorized', 401); return; }
      const ticket = await SupportService.getTicket(req.params.id as string, req.user.id);
      sendSuccess(res, ticket, 'Ticket retrieved');
    } catch (e: any) { sendError(res, e.message, 404); }
  }

  /** GET /api/v1/support/admin/tickets — admin views all tickets */
  static async adminGetTickets(req: Request, res: Response): Promise<void> {
    try {
      const filters = {
        status: req.query.status ? String(req.query.status) : undefined,
        category: req.query.category ? String(req.query.category) : undefined,
        priority: req.query.priority ? String(req.query.priority) : undefined,
        search: req.query.search ? String(req.query.search) : undefined,
        page: req.query.page ? parseInt(String(req.query.page)) : 1,
        limit: req.query.limit ? parseInt(String(req.query.limit)) : 50,
      };
      const result = await SupportService.adminGetTickets(filters);
      sendSuccess(res, result.tickets, 'All support tickets retrieved', 200, {
        total: result.total,
        page: result.page,
        totalPages: result.totalPages,
      });
    } catch (e: any) { sendError(res, e.message, 400); }
  }

  /** POST /api/v1/support/admin/tickets/:id/reply — admin replies to ticket */
  static async adminReply(req: AuthRequest, res: Response): Promise<void> {
    try {
      if (!req.user) { sendError(res, 'Unauthorized', 401); return; }
      const ticket = await SupportService.adminReplyTicket(req.params.id as string, req.user, req.body.reply);
      sendSuccess(res, ticket, 'Reply sent to user');
    } catch (e: any) { sendError(res, e.message, 400); }
  }

  /** PATCH /api/v1/support/admin/tickets/:id/status — admin updates ticket status */
  static async adminUpdateStatus(req: AuthRequest, res: Response): Promise<void> {
    try {
      if (!req.user) { sendError(res, 'Unauthorized', 401); return; }
      const ticket = await SupportService.adminUpdateStatus(req.params.id as string, req.user, req.body.status);
      sendSuccess(res, ticket, `Ticket marked as ${req.body.status}`);
    } catch (e: any) { sendError(res, e.message, 400); }
  }
}
