import { Request, Response } from 'express';
import { ChatService } from './chat.service';
import { sendSuccess, sendError } from '../../utils/response';
import { AuthRequest } from '../../middlewares/auth.middleware';

export class ChatController {
  static async getOrCreate(req: AuthRequest, res: Response): Promise<void> {
    try {
      if (!req.user) {
        sendError(res, 'Unauthorized', 401);
        return;
      }
      const conversation = await ChatService.getOrCreateConversation(
        req.user.id,
        req.body.recipientId,
        req.body.propertyId,
        req.body.projectId
      );
      sendSuccess(res, conversation, 'Conversation retrieved');
    } catch (error: any) {
      sendError(res, error.message, 400);
    }
  }

  static async startWithDeveloper(req: AuthRequest, res: Response): Promise<void> {
    try {
      if (!req.user) {
        sendError(res, 'Unauthorized', 401);
        return;
      }
      const { developerId, propertyId, projectId, message } = req.body;
      if (!developerId) {
        sendError(res, 'developerId is required', 400);
        return;
      }

      const conversation = await ChatService.startWithDeveloper(
        req.user.id,
        developerId,
        propertyId,
        projectId,
        message
      );
      sendSuccess(res, conversation, 'Conversation with developer opened', 201);
    } catch (error: any) {
      sendError(res, error.message, 400);
    }
  }

  static async startWithSupport(req: AuthRequest, res: Response): Promise<void> {
    try {
      if (!req.user) {
        sendError(res, 'Unauthorized', 401);
        return;
      }
      const { message } = req.body;
      const conversation = await ChatService.startWithSupport(req.user.id, message);
      sendSuccess(res, conversation, 'Conversation with Hometrust support opened', 201);
    } catch (error: any) {
      sendError(res, error.message, 400);
    }
  }

  static async getMyConversations(req: AuthRequest, res: Response): Promise<void> {
    try {
      if (!req.user) {
        sendError(res, 'Unauthorized', 401);
        return;
      }
      const conversations = await ChatService.getUserConversations(req.user.id);
      sendSuccess(res, conversations, 'Conversations retrieved');
    } catch (error: any) {
      sendError(res, error.message, 400);
    }
  }

  static async getConversationMessages(req: AuthRequest, res: Response): Promise<void> {
    try {
      if (!req.user) {
        sendError(res, 'Unauthorized', 401);
        return;
      }
      const conversationId = req.params.conversationId as string;
      const messages = await ChatService.getConversationMessages(conversationId, req.user.id);
      sendSuccess(res, messages, 'Messages retrieved');
    } catch (error: any) {
      sendError(res, error.message, 400);
    }
  }

  static async sendMessage(req: AuthRequest, res: Response): Promise<void> {
    try {
      if (!req.user) {
        sendError(res, 'Unauthorized', 401);
        return;
      }
      const message = await ChatService.sendMessage({
        conversationId: req.params.conversationId as string,
        senderId: req.user.id,
        content: req.body.content,
        attachmentUrl: req.body.attachmentUrl,
        attachmentType: req.body.attachmentType,
      });
      sendSuccess(res, message, 'Message sent', 201);
    } catch (error: any) {
      sendError(res, error.message, 400);
    }
  }

  static async getUnreadCount(req: AuthRequest, res: Response): Promise<void> {
    try {
      if (!req.user) {
        sendError(res, 'Unauthorized', 401);
        return;
      }
      const count = await ChatService.getUnreadCount(req.user.id);
      sendSuccess(res, count, 'Unread count retrieved');
    } catch (error: any) {
      sendError(res, error.message, 400);
    }
  }
}
