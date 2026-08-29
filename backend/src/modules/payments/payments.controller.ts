import { Request, Response } from 'express';
import { PaymentsService } from './payments.service';
import { PaystackClient } from './paystack.client';
import { sendSuccess, sendError } from '../../utils/response';
import { AuthRequest } from '../../middlewares/auth.middleware';

export class PaymentsController {
  static async initialize(req: AuthRequest, res: Response): Promise<void> {
    try {
      if (!req.user) {
        sendError(res, 'Unauthorized', 401);
        return;
      }

      const result = await PaymentsService.initializePayment({
        userId: req.user.id,
        userEmail: req.user.email,
        amount: parseFloat(req.body.amount),
        purpose: req.body.purpose,
        purchaseId: req.body.purchaseId,
        verificationRequestId: req.body.verificationRequestId,
        legalRequestId: req.body.legalRequestId,
        developerId: req.body.developerId,
        callbackUrl: req.body.callbackUrl,
      });

      sendSuccess(res, result, 'Payment initialized', 201);
    } catch (error: any) {
      sendError(res, error.message, 400);
    }
  }

  static async generateVirtualAccount(req: AuthRequest, res: Response): Promise<void> {
    try {
      if (!req.user) {
        sendError(res, 'Unauthorized', 401);
        return;
      }

      const dva = await PaystackClient.createDedicatedAccount({
        customerEmail: req.user.email,
        firstName: req.body.firstName || 'Buyer',
        lastName: req.body.lastName || 'Customer',
        phone: req.body.phone,
      });

      sendSuccess(res, dva.data, 'Dedicated virtual bank account generated for bank transfer');
    } catch (error: any) {
      sendError(res, error.message, 400);
    }
  }

  static async verify(req: Request, res: Response): Promise<void> {
    try {
      const reference = req.params.reference as string;
      const payment = await PaymentsService.verifyPayment(reference);
      sendSuccess(res, payment, 'Payment verified successfully');
    } catch (error: any) {
      sendError(res, error.message, 400);
    }
  }

  static async webhook(req: Request, res: Response): Promise<void> {
    try {
      const signature = req.headers['x-paystack-signature'] as string;
      const rawBody = JSON.stringify(req.body);

      // In production, verify signature
      if (signature && !PaystackClient.verifyWebhookSignature(signature, rawBody)) {
        res.status(400).send('Invalid signature');
        return;
      }

      const event = req.body;
      if (event.event === 'charge.success') {
        const reference = event.data.reference;
        await PaymentsService.verifyPayment(reference);
      }

      res.status(200).send('Webhook processed');
    } catch (error: any) {
      console.error('Paystack webhook error:', error);
      res.status(500).send('Webhook handling error');
    }
  }

  static async getMyPayments(req: AuthRequest, res: Response): Promise<void> {
    try {
      if (!req.user) {
        sendError(res, 'Unauthorized', 401);
        return;
      }
      const payments = await PaymentsService.getUserPayments(req.user.id);
      sendSuccess(res, payments, 'Payment history retrieved');
    } catch (error: any) {
      sendError(res, error.message, 400);
    }
  }

  static async getDetails(req: Request, res: Response): Promise<void> {
    try {
      const payment = await PaymentsService.getPaymentDetails(req.params.idOrRef as string);
      sendSuccess(res, payment, 'Payment details retrieved');
    } catch (error: any) {
      sendError(res, error.message, 404);
    }
  }
}
