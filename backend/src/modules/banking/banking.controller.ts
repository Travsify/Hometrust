import { Request, Response } from 'express';
import { BankingService } from './banking.service';
import { FincraClient } from './fincra.client';
import { sendSuccess, sendError } from '../../utils/response';
import { AuthRequest } from '../../middlewares/auth.middleware';

export class BankingController {
  static async submitBuyerKyc(req: AuthRequest, res: Response): Promise<void> {
    try {
      if (!req.user) {
        sendError(res, 'Unauthorized', 401);
        return;
      }
      const result = await BankingService.submitBuyerKyc(req.user.id, req.body);
      sendSuccess(res, result, 'KYC verified & Dedicated Virtual Account generated', 201);
    } catch (error: any) {
      sendError(res, error.message, 400);
    }
  }

  static async submitDeveloperKyb(req: AuthRequest, res: Response): Promise<void> {
    try {
      if (!req.user) {
        sendError(res, 'Unauthorized', 401);
        return;
      }
      const developerId = req.params.developerId || req.body.developerId;
      const result = await BankingService.submitDeveloperKyb(developerId, req.body);
      sendSuccess(res, result, 'KYB verified & Corporate Business Account generated', 201);
    } catch (error: any) {
      sendError(res, error.message, 400);
    }
  }

  static async getMyVirtualAccount(req: AuthRequest, res: Response): Promise<void> {
    try {
      if (!req.user) {
        sendError(res, 'Unauthorized', 401);
        return;
      }
      const account = await BankingService.getVirtualAccount(req.user.id, req.query.developerId as string);
      sendSuccess(res, account, 'Virtual bank account retrieved');
    } catch (error: any) {
      sendError(res, error.message, 400);
    }
  }

  static async resolveBankAccount(req: Request, res: Response): Promise<void> {
    try {
      const { bankCode, accountNumber } = req.body;
      if (!bankCode || !accountNumber) {
        sendError(res, 'Bank code and account number are required', 400);
        return;
      }
      const resolved = await BankingService.resolveBankAccount(bankCode, accountNumber);
      sendSuccess(res, resolved.data, 'Account name resolved');
    } catch (error: any) {
      sendError(res, error.message, 400);
    }
  }

  static async requestWithdrawal(req: AuthRequest, res: Response): Promise<void> {
    try {
      if (!req.user) {
        sendError(res, 'Unauthorized', 401);
        return;
      }
      const result = await BankingService.requestWithdrawal({
        userId: req.user.id,
        developerId: req.body.developerId,
        amount: parseFloat(req.body.amount),
        bankCode: req.body.bankCode,
        bankName: req.body.bankName,
        accountNumber: req.body.accountNumber,
        accountName: req.body.accountName,
      });
      sendSuccess(res, result, 'Withdrawal request queued successfully', 201);
    } catch (error: any) {
      sendError(res, error.message, 400);
    }
  }

  static async webhook(req: Request, res: Response): Promise<void> {
    try {
      const signature = req.headers['x-fincra-signature'] as string;
      const rawPayload = JSON.stringify(req.body);

      if (signature && !FincraClient.verifyWebhookSignature(signature, rawPayload)) {
        res.status(400).send('Invalid signature');
        return;
      }

      await BankingService.handleWebhook(req.body);
      res.status(200).send('Webhook processed');
    } catch (e: any) {
      console.error('Fincra webhook error:', e);
      res.status(500).send('Error processing webhook');
    }
  }

  static async listAllAccounts(req: Request, res: Response): Promise<void> {
    try {
      const accounts = await BankingService.listAllAccounts();
      sendSuccess(res, accounts, 'All virtual accounts retrieved');
    } catch (error: any) {
      sendError(res, error.message, 400);
    }
  }

  static async listAllWithdrawals(req: Request, res: Response): Promise<void> {
    try {
      const withdrawals = await BankingService.listAllWithdrawals();
      sendSuccess(res, withdrawals, 'All withdrawals retrieved');
    } catch (error: any) {
      sendError(res, error.message, 400);
    }
  }

  static async listAllKyc(req: Request, res: Response): Promise<void> {
    try {
      const kycList = await BankingService.listAllKyc();
      sendSuccess(res, kycList, 'All Prembly KYC verifications retrieved');
    } catch (error: any) {
      sendError(res, error.message, 400);
    }
  }
}
