import { prisma } from '../../utils/prisma';
import { FincraClient } from './fincra.client';
import { AuditService } from '../audit/audit.service';

export class BankingService {
  /**
   * Complete Buyer KYC & Auto-Generate Dedicated Virtual Bank Account
   */
  static async submitBuyerKyc(
    userId: string,
    data: {
      nin: string;
      bvn: string;
      residentialAddress?: string;
      documentUrl?: string;
    }
  ) {
    const user = await prisma.user.findUnique({
      where: { id: userId },
      include: { profile: true, virtualAccounts: true },
    });

    if (!user) {
      throw new Error('User not found');
    }

    // 1. Record KYC Verification
    const kyc = await prisma.kycVerification.create({
      data: {
        userId: user.id,
        kycType: 'INDIVIDUAL_KYC',
        nin: data.nin,
        bvn: data.bvn,
        residentialAddress: data.residentialAddress,
        documentUrl: data.documentUrl,
        status: 'VERIFIED',
        verifiedAt: new Date(),
      },
    });

    // Update user profile
    await prisma.userProfile.upsert({
      where: { userId: user.id },
      update: {
        nin: data.nin,
        bvnVerified: true,
        address: data.residentialAddress,
      },
      create: {
        userId: user.id,
        nin: data.nin,
        bvnVerified: true,
        address: data.residentialAddress,
      },
    });

    // 2. Auto-Generate Dedicated Virtual Account via Fincra if not existing
    let account = user.virtualAccounts?.[0];
    if (!account) {
      const ref = `EV-VBA-USR-${Date.now()}`;
      const fincraRes = await FincraClient.createIndividualVirtualAccount({
        firstName: user.firstName,
        lastName: user.lastName,
        email: user.email,
        phone: user.phone || '08012345678',
        bvn: data.bvn,
        nin: data.nin,
        reference: ref,
      });

      account = await prisma.virtualAccount.create({
        data: {
          userId: user.id,
          accountName: fincraRes.data.accountInformation.accountName,
          accountNumber: fincraRes.data.accountInformation.accountNumber,
          bankName: fincraRes.data.accountInformation.bankName,
          accountType: 'INDIVIDUAL',
          currency: 'NGN',
          fincraAccountId: fincraRes.data.reference,
          status: 'ACTIVE',
          balance: 0,
        },
      });
    }

    return {
      kycStatus: kyc.status,
      virtualAccount: account,
    };
  }

  /**
   * Complete Developer KYB & Auto-Generate Corporate Dedicated Virtual Bank Account
   */
  static async submitDeveloperKyb(
    developerId: string,
    data: {
      cacNumber: string;
      companyName: string;
      tinNumber?: string;
      directorNin?: string;
      documentUrl?: string;
    }
  ) {
    const developer = await prisma.developer.findUnique({
      where: { id: developerId },
      include: { virtualAccounts: true },
    });

    if (!developer) {
      throw new Error('Developer not found');
    }

    // 1. Record KYB Verification
    const kyb = await prisma.kycVerification.create({
      data: {
        developerId: developer.id,
        kycType: 'CORPORATE_KYB',
        cacNumber: data.cacNumber,
        companyName: data.companyName,
        tinNumber: data.tinNumber,
        nin: data.directorNin,
        documentUrl: data.documentUrl,
        status: 'VERIFIED',
        verifiedAt: new Date(),
      },
    });

    // Update developer verification status
    await prisma.developer.update({
      where: { id: developer.id },
      data: {
        isVerified: true,
        verificationStatus: 'VERIFIED',
        verificationDate: new Date(),
      },
    });

    // 2. Provision Corporate Dedicated Virtual Account
    let account = developer.virtualAccounts?.[0];
    if (!account) {
      const ref = `EV-VBA-DEV-${Date.now()}`;
      const fincraRes = await FincraClient.createCorporateVirtualAccount({
        companyName: data.companyName,
        cacNumber: data.cacNumber,
        email: developer.email,
        phone: developer.phone,
        reference: ref,
      });

      account = await prisma.virtualAccount.create({
        data: {
          developerId: developer.id,
          accountName: fincraRes.data.accountInformation.accountName,
          accountNumber: fincraRes.data.accountInformation.accountNumber,
          bankName: fincraRes.data.accountInformation.bankName,
          accountType: 'CORPORATE',
          currency: 'NGN',
          fincraAccountId: fincraRes.data.reference,
          status: 'ACTIVE',
          balance: 0,
        },
      });
    }

    return {
      kybStatus: kyb.status,
      virtualAccount: account,
    };
  }

  /**
   * Retrieve active dedicated virtual bank account for user or developer
   */
  static async getVirtualAccount(userId?: string, developerId?: string) {
    if (developerId) {
      return prisma.virtualAccount.findFirst({
        where: { developerId, status: 'ACTIVE' },
        include: { developer: true },
      });
    }

    return prisma.virtualAccount.findFirst({
      where: { userId, status: 'ACTIVE' },
      include: { user: true },
    });
  }

  /**
   * Name Enquiry for destination bank account
   */
  static async resolveBankAccount(bankCode: string, accountNumber: string) {
    return FincraClient.resolveAccount(bankCode, accountNumber);
  }

  /**
   * Request Developer Withdrawal / Payout to any Nigerian Commercial Bank
   */
  static async requestWithdrawal(params: {
    developerId?: string;
    userId?: string;
    amount: number;
    bankCode: string;
    bankName: string;
    accountNumber: string;
    accountName: string;
  }) {
    if (params.amount < 1000) {
      throw new Error('Minimum withdrawal amount is ₦1,000');
    }

    // Check account balance
    const account = await this.getVirtualAccount(params.userId, params.developerId);
    if (!account || account.balance < params.amount) {
      throw new Error('Insufficient wallet balance for withdrawal');
    }

    const fee = 50; // Standard ₦50 NIP transfer fee
    const netAmount = params.amount - fee;
    const ref = `EV-WD-${Date.now()}-${Math.random().toString(36).substring(2, 6).toUpperCase()}`;

    // Deduct balance
    await prisma.virtualAccount.update({
      where: { id: account.id },
      data: { balance: { decrement: params.amount } },
    });

    const withdrawal = await prisma.withdrawal.create({
      data: {
        developerId: params.developerId,
        userId: params.userId,
        amount: params.amount,
        fee,
        netAmount,
        bankCode: params.bankCode,
        bankName: params.bankName,
        accountNumber: params.accountNumber,
        accountName: params.accountName,
        reference: ref,
        status: 'PROCESSING',
      },
    });

    // Dispatch via Fincra Payouts
    const payoutRes = await FincraClient.createPayout({
      amount: netAmount,
      bankCode: params.bankCode,
      accountNumber: params.accountNumber,
      accountName: params.accountName,
      reference: ref,
    });

    await prisma.withdrawal.update({
      where: { id: withdrawal.id },
      data: {
        status: payoutRes.status ? 'SUCCESS' : 'FAILED',
        fincraPayoutId: payoutRes.data?.reference,
      },
    });

    return withdrawal;
  }

  /**
   * Process incoming Fincra webhook when a buyer transfers money into their virtual account
   */
  static async handleWebhook(event: any) {
    if (event.event === 'collection.successful' || event.event === 'virtual_account.credited') {
      const { accountNumber, amount, customerReference } = event.data || {};

      const account = await prisma.virtualAccount.findUnique({
        where: { accountNumber },
        include: { user: true, developer: true },
      });

      if (account) {
        // Credit virtual account balance
        await prisma.virtualAccount.update({
          where: { id: account.id },
          data: { balance: { increment: parseFloat(amount) } },
        });

        // If user has an active purchase, auto-credit the next instalment!
        if (account.userId) {
          const activePurchase = await prisma.purchase.findFirst({
            where: { userId: account.userId, status: 'ACTIVE' },
            include: { property: true, projectUnit: true },
          });

          if (activePurchase) {
            const paidAmount = parseFloat(amount);
            const newAmountPaid = activePurchase.amountPaid + paidAmount;
            const newBalance = Math.max(0, activePurchase.totalPrice - newAmountPaid);
            const isCompleted = newBalance <= 0;

            await prisma.purchase.update({
              where: { id: activePurchase.id },
              data: {
                amountPaid: newAmountPaid,
                outstandingBalance: newBalance,
                status: isCompleted ? 'COMPLETED' : 'ACTIVE',
              },
            });

            // Record payment entry
            await prisma.payment.create({
              data: {
                paymentReference: `EV-VBA-TRF-${Date.now()}`,
                userId: account.userId,
                purchaseId: activePurchase.id,
                developerId: activePurchase.property?.developerId || account.developerId,
                amount: paidAmount,
                platformFee: 0,
                processingFee: 0,
                totalAmount: paidAmount,
                purpose: 'INSTALMENT',
                status: 'SUCCESS',
                paidAt: new Date(),
              },
            });
          }
        }
      }
    }
    return { success: true };
  }

  /**
   * List all virtual accounts for Admin audit
   */
  static async listAllAccounts() {
    return prisma.virtualAccount.findMany({
      include: {
        user: { select: { id: true, firstName: true, lastName: true, email: true, phone: true } },
        developer: { select: { id: true, companyName: true, cacNumber: true, email: true, phone: true } },
      },
      orderBy: { createdAt: 'desc' },
    });
  }

  /**
   * List all withdrawals for Admin audit
   */
  static async listAllWithdrawals() {
    return prisma.withdrawal.findMany({
      include: {
        developer: { select: { companyName: true, email: true } },
        user: { select: { firstName: true, lastName: true, email: true } },
      },
      orderBy: { createdAt: 'desc' },
    });
  }
}
