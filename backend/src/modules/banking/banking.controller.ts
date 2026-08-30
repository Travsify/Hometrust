import { Request, Response } from 'express';
import { BankingService } from './banking.service';
import { FlutterwaveClient } from './flutterwave.client';
import { PaystackClient } from '../payments/paystack.client';
import { AdminService } from '../admin/admin.service';
import { sendSuccess, sendError } from '../../utils/response';
import { AuthRequest } from '../../middlewares/auth.middleware';
import { prisma } from '../../utils/prisma';
import { BankingPdfService } from './banking_pdf.service';

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

  static async triggerPremblyAutoKyc(req: AuthRequest, res: Response): Promise<void> {
    try {
      if (!req.user) {
        sendError(res, 'Unauthorized', 401);
        return;
      }
      const result = await BankingService.triggerAutomatedPremblyKyc(req.user.id, req.body);
      sendSuccess(res, result, 'Prembly Automated KYC Completed & Bank Account Active', 200);
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
      let account = await BankingService.getVirtualAccount(req.user.id, req.query.developerId as string);

      // Background: sync with Flutterwave to recover any uncredited deposits
      if (account) {
        BankingService.recoverUncreditedDeposits(req.user.id).catch((e: any) =>
          console.warn('[SYNC RECOVERY BG]', e.message)
        );
      }

      sendSuccess(res, account, 'Virtual bank account retrieved');
    } catch (error: any) {
      sendError(res, error.message, 400);
    }
  }

  static async getMyTransactions(req: AuthRequest, res: Response): Promise<void> {
    try {
      if (!req.user) {
        sendError(res, 'Unauthorized', 401);
        return;
      }
      const txs = await BankingService.getMyTransactions(req.user.id, req.query.developerId as string);
      sendSuccess(res, txs, 'Transactions retrieved successfully');
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
      sendSuccess(res, result, 'Withdrawal request processed successfully', 201);
    } catch (error: any) {
      sendError(res, error.message, 400);
    }
  }

  static async payFromWallet(req: AuthRequest, res: Response): Promise<void> {
    try {
      if (!req.user) {
        sendError(res, 'Unauthorized', 401);
        return;
      }
      const result = await BankingService.payFromWallet({
        userId: req.user.id,
        amount: parseFloat(req.body.amount),
        purpose: req.body.purpose,
        purchaseId: req.body.purchaseId,
        verificationId: req.body.verificationId,
        inspectionId: req.body.inspectionId,
        description: req.body.description,
      });
      sendSuccess(res, result, 'Payment deducted successfully from Escrow Wallet', 200);
    } catch (error: any) {
      sendError(res, error.message, 400);
    }
  }

  static async syncLiveAccount(req: AuthRequest, res: Response): Promise<void> {
    try {
      if (!req.user) {
        sendError(res, 'Unauthorized', 401);
        return;
      }
      const result = await BankingService.syncLiveVirtualAccount(req.user.id, req.body.developerId);
      sendSuccess(res, result, result.message, 200);
    } catch (error: any) {
      sendError(res, error.message, 400);
    }
  }

  static async webhook(req: Request, res: Response): Promise<void> {
    try {
      const paystackSignature = req.headers['x-paystack-signature'] as string;
      const flwSignature = req.headers['verif-hash'] as string;
      const rawPayload = JSON.stringify(req.body);

      // Verify Paystack or Flutterwave signatures
      if (paystackSignature && !PaystackClient.verifyWebhookSignature(rawPayload, paystackSignature)) {
        res.status(400).send('Invalid Paystack signature');
        return;
      }

      if (flwSignature && !FlutterwaveClient.verifyWebhookSignature(flwSignature)) {
        res.status(400).send('Invalid Flutterwave signature');
        return;
      }

      await BankingService.handleWebhook(req.body);
      res.status(200).send('Webhook processed');
    } catch (e: any) {
      console.error('Banking webhook error:', e);
      res.status(500).send('Error processing webhook');
    }
  }

  static async simulateDeposit(req: Request, res: Response): Promise<void> {
    try {
      const { accountNumber, amount } = req.body;
      if (!accountNumber || !amount) {
        sendError(res, 'Account number and amount are required', 400);
        return;
      }
      const result = await BankingService.simulateDeposit({
        accountNumber: accountNumber.trim(),
        amount: parseFloat(amount),
      });
      sendSuccess(res, result, result.message, 200);
    } catch (error: any) {
      sendError(res, error.message, 400);
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

  static async listAllTransactions(req: Request, res: Response): Promise<void> {
    try {
      const filters = {
        type: req.query.type ? String(req.query.type) : undefined,
        status: req.query.status ? String(req.query.status) : undefined,
        search: req.query.search ? String(req.query.search) : undefined,
        page: req.query.page ? parseInt(String(req.query.page), 10) : 1,
        limit: req.query.limit ? parseInt(String(req.query.limit), 10) : 100,
      };
      const result = await AdminService.getAllTransactions(filters);
      sendSuccess(res, result.transactions, 'All platform transactions retrieved', 200, {
        total: result.total,
        page: result.page,
        totalPages: result.totalPages,
      });
    } catch (error: any) {
      sendError(res, error.message, 400);
    }
  }

  static async listAllDispatchedNotifications(req: Request, res: Response): Promise<void> {
    try {
      const filters = {
        search: req.query.search ? String(req.query.search) : undefined,
        page: req.query.page ? parseInt(String(req.query.page), 10) : 1,
        limit: req.query.limit ? parseInt(String(req.query.limit), 10) : 100,
      };
      const result = await AdminService.getAllDispatchedNotifications(filters);
      sendSuccess(res, result.notifications, 'All dispatched notifications retrieved', 200, {
        total: result.total,
        page: result.page,
        totalPages: result.totalPages,
      });
    } catch (error: any) {
      sendError(res, error.message, 400);
    }
  }

  static async downloadStatementPdf(req: AuthRequest, res: Response): Promise<void> {
    try {
      if (!req.user) {
        sendError(res, 'Unauthorized', 401);
        return;
      }
      const user = await prisma.user.findUnique({
        where: { id: req.user.id },
        include: { virtualAccounts: true },
      });
      if (!user) {
        sendError(res, 'User not found', 404);
        return;
      }
      const account = user.virtualAccounts?.[0];
      const filterType = (String(req.query.type || 'ALL')).toUpperCase();
      let transactions = await BankingService.getMyTransactions(req.user.id);

      if (filterType === 'CREDIT' || filterType === 'INFLOW') {
        transactions = transactions.filter((t: any) => t.type === 'CREDIT');
      } else if (filterType === 'DEBIT' || filterType === 'OUTFLOW') {
        transactions = transactions.filter((t: any) => t.type === 'DEBIT');
      }

      const pdf = await BankingPdfService.generateStatementPdf({
        userName: `${user.firstName} ${user.lastName}`,
        email: user.email,
        accountNumber: account?.accountNumber || 'N/A',
        bankName: account?.bankName || 'Hometrust Dedicated Bank',
        balance: account?.balance || 0,
        transactions,
        filterType,
      });

      res.setHeader('Content-Type', 'application/pdf');
      res.setHeader('Content-Disposition', `attachment; filename="${pdf.fileName}"`);
      res.download(pdf.filePath, pdf.fileName);
    } catch (error: any) {
      sendError(res, error.message, 500);
    }
  }

  static async downloadReceiptPdf(req: AuthRequest, res: Response): Promise<void> {
    try {
      if (!req.user) {
        sendError(res, 'Unauthorized', 401);
        return;
      }
      const targetId = String(req.params.id);
      const user = await prisma.user.findUnique({
        where: { id: req.user.id },
      });
      if (!user) {
        sendError(res, 'User not found', 404);
        return;
      }

      const payment = await prisma.payment.findFirst({
        where: {
          OR: [{ id: targetId }, { paymentReference: targetId }, { receiptNumber: targetId }],
          userId: req.user.id,
        },
      });

      if (!payment) {
        // Check withdrawals
        const withdrawal = await prisma.withdrawal.findFirst({
          where: {
            OR: [{ id: targetId }, { reference: targetId }],
            userId: req.user.id,
          },
        });

        if (withdrawal) {
          const pdf = await BankingPdfService.generateReceiptPdf({
            userName: `${user.firstName} ${user.lastName}`,
            email: user.email,
            txId: withdrawal.id,
            reference: withdrawal.reference,
            type: 'WITHDRAWAL / DEBIT',
            amount: withdrawal.amount,
            purpose: `Payout to ${withdrawal.bankName} (${withdrawal.accountNumber})`,
            status: withdrawal.status,
            channel: withdrawal.bankName || 'Commercial Bank Transfer',
            createdAt: withdrawal.createdAt,
            bankName: withdrawal.bankName,
            accountNumber: withdrawal.accountNumber,
          });

          res.setHeader('Content-Type', 'application/pdf');
          res.setHeader('Content-Disposition', `attachment; filename="${pdf.fileName}"`);
          res.download(pdf.filePath, pdf.fileName);
          return;
        }

        sendError(res, 'Transaction not found', 404);
        return;
      }

      const pdf = await BankingPdfService.generateReceiptPdf({
        userName: `${user.firstName} ${user.lastName}`,
        email: user.email,
        txId: payment.id,
        reference: payment.receiptNumber || payment.paymentReference,
        type: 'ESCROW DEPOSIT / CREDIT',
        amount: payment.totalAmount || payment.amount,
        purpose: payment.purpose || 'Escrow Funding',
        status: payment.status,
        channel: payment.paystackChannel || 'Direct Bank Transfer',
        createdAt: payment.createdAt,
      });

      res.setHeader('Content-Type', 'application/pdf');
      res.setHeader('Content-Disposition', `attachment; filename="${pdf.fileName}"`);
      res.download(pdf.filePath, pdf.fileName);
    } catch (error: any) {
      sendError(res, error.message, 500);
    }
  }
}
