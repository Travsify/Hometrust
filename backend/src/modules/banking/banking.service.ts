import bcrypt from 'bcryptjs';
import { config } from '../../config';
import { prisma } from '../../utils/prisma';
import { FlutterwaveClient } from './flutterwave.client';
import { PremblyClient } from './prembly.client';
import { PaystackClient } from '../payments/paystack.client';
import { AuditService } from '../audit/audit.service';
import { ResendService } from '../notifications/resend.service';
import { NotificationsService } from '../notifications/notifications.service';
import { OneSignalService } from '../notifications/onesignal.service';

export class BankingService {
  /**
   * Internal Helper: Issues Dedicated Virtual Account exclusively via Flutterwave
   */
  private static async issueDedicatedVirtualAccount(params: {
    firstName: string;
    lastName: string;
    email: string;
    phone: string;
    bvn?: string;
    nin?: string;
    dob?: string;
    street?: string;
    city?: string;
    state?: string;
    address?: string;
    isCorporate?: boolean;
    companyName?: string;
    rcNumber?: string;
  }): Promise<{
    accountNumber: string;
    accountName: string;
    bankName: string;
    accountId: string;
    provider: string;
  }> {
    console.log(`[BANKING] Provisioning Dedicated Virtual Account via Flutterwave for ${params.email}...`);
    const flwRes = await FlutterwaveClient.createVirtualAccount(params);
    if (flwRes?.data?.account_number) {
      const displayName = params.isCorporate && params.companyName
        ? `HOMETRUST / ${params.companyName}`
        : `HOMETRUST / ${params.firstName} ${params.lastName}`;
      return {
        accountNumber: flwRes.data.account_number,
        accountName: flwRes.data.account_name || displayName,
        bankName: flwRes.data.bank_name || 'Flutterwave MFB',
        accountId: flwRes.data.id,
        provider: 'FLUTTERWAVE',
      };
    }

    throw new Error('Failed to generate dedicated virtual bank account via Flutterwave.');
  }
  /**
   * Complete Buyer KYC & Auto-Generate Dedicated Virtual Bank Account via Maplerad
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

    // Verify NIN / BVN with Prembly
    if (data.nin) {
      await PremblyClient.verifyNIN(data.nin, user.firstName, user.lastName);
    } else if (data.bvn) {
      await PremblyClient.verifyBVN(data.bvn);
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

    // 2. Auto-Generate Dedicated Virtual Account via Paystack Live (or Maplerad fallback) if not existing
    let account = user.virtualAccounts?.[0];
    if (!account) {
      const vbaRes = await this.issueDedicatedVirtualAccount({
        firstName: user.firstName,
        lastName: user.lastName,
        email: user.email,
        phone: user.phone || '09061518843',
        bvn: data.bvn,
        nin: data.nin,
        address: data.residentialAddress,
      });

      account = await prisma.virtualAccount.create({
        data: {
          userId: user.id,
          accountName: vbaRes.accountName,
          accountNumber: vbaRes.accountNumber,
          bankName: vbaRes.bankName,
          accountType: 'INDIVIDUAL',
          currency: 'NGN',
          fincraAccountId: vbaRes.accountId,
          status: 'ACTIVE',
          balance: 0,
        },
      });
    }

    await AuditService.log({
      adminId: user.id,
      adminEmail: user.email,
      action: 'BUYER_KYC_VERIFIED_VBA_GENERATED',
      entityType: 'VIRTUAL_ACCOUNT',
      entityId: account.id,
      details: {
        accountNumber: account.accountNumber,
        bankName: account.bankName,
        accountName: account.accountName,
        kycStatus: kyc.status,
      },
    });

    // Send KYC Approved Email & Virtual Account Email
    ResendService.sendKycApprovedEmail(user.email, `${user.firstName} ${user.lastName}`, 'INDIVIDUAL_KYC', {
      idNumber: data.nin || data.bvn,
      accountNumber: account.accountNumber,
      bankName: account.bankName,
    }).catch(console.warn);

    ResendService.sendVirtualAccountIssuedEmail(user.email, `${user.firstName} ${user.lastName}`, {
      accountNumber: account.accountNumber,
      bankName: account.bankName,
      accountName: account.accountName,
    }).catch(console.warn);

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
      const vbaRes = await this.issueDedicatedVirtualAccount({
        firstName: developer.companyName,
        lastName: 'Corporate',
        email: developer.email,
        phone: developer.phone || '09061518843',
        isCorporate: true,
        companyName: data.companyName,
        rcNumber: data.cacNumber,
      });

      account = await prisma.virtualAccount.create({
        data: {
          developerId: developer.id,
          accountName: vbaRes.accountName,
          accountNumber: vbaRes.accountNumber,
          bankName: vbaRes.bankName,
          accountType: 'CORPORATE',
          currency: 'NGN',
          fincraAccountId: vbaRes.accountId,
          status: 'ACTIVE',
          balance: 0,
        },
      });
    }

    await AuditService.log({
      adminEmail: developer.email,
      action: 'DEVELOPER_KYB_VERIFIED_VBA_GENERATED',
      entityType: 'VIRTUAL_ACCOUNT',
      entityId: account.id,
      details: {
        companyName: data.companyName,
        cacNumber: data.cacNumber,
        accountNumber: account.accountNumber,
        bankName: account.bankName,
      },
    });

    // Send Developer KYB Approved Email & Virtual Account Email
    ResendService.sendKycApprovedEmail(developer.email, developer.companyName, 'CORPORATE_KYB', {
      companyName: data.companyName,
      cacNumber: data.cacNumber,
      accountNumber: account.accountNumber,
      bankName: account.bankName,
    }).catch(console.warn);

    ResendService.sendVirtualAccountIssuedEmail(developer.email, developer.companyName, {
      accountNumber: account.accountNumber,
      bankName: account.bankName,
      accountName: account.accountName,
    }).catch(console.warn);

    return {
      kybStatus: kyb.status,
      virtualAccount: account,
    };
  }

  /**
   * Automated Prembly / Identitypass KYC / KYB Pipeline
   */
  static async triggerAutomatedPremblyKyc(
    userId: string,
    params?: {
      nin?: string;
      bvn?: string;
      idType?: string;
      idNumber?: string;
      dob?: string;
      gender?: string;
      residentialAddress?: string;
      streetAddress?: string;
      city?: string;
      state?: string;
      cacNumber?: string;
      companyName?: string;
      tinNumber?: string;
      officeAddress?: string;
      directorBvn?: string;
    }
  ) {
    const user = await prisma.user.findUnique({
      where: { id: userId },
      include: { profile: true, developer: true, virtualAccounts: true },
    });

    if (!user) throw new Error('User not found');

    const isDeveloper = user.role === 'DEVELOPER';

    if (isDeveloper && user.developer) {
      // 1. Corporate KYB Pipeline via Prembly IdentityPass (CAC Validation)
      const cac = params?.cacNumber || user.developer.cacNumber || `RC-${Math.floor(1000000 + Math.random() * 9000000)}`;
      const company = params?.companyName || user.developer.companyName || `${user.firstName} ${user.lastName} Developments Ltd`;
      const tin = params?.tinNumber;
      const officeAddr = params?.officeAddress || user.developer.officeAddress;

      // Verify CAC with Prembly
      await PremblyClient.verifyCAC(cac, company);

      const kyb = await prisma.kycVerification.create({
        data: {
          developerId: user.developer.id,
          kycType: 'CORPORATE_KYB',
          cacNumber: cac,
          companyName: company,
          tinNumber: tin,
          residentialAddress: officeAddr,
          status: 'VERIFIED',
          verifiedAt: new Date(),
        },
      });

      await prisma.developer.update({
        where: { id: user.developer.id },
        data: {
          companyName: company,
          cacNumber: cac,
          officeAddress: officeAddr,
          isVerified: true,
          verificationStatus: 'VERIFIED',
          verificationDate: new Date(),
        },
      });

      let account = user.virtualAccounts?.[0];
      if (!account) {
        const vbaRes = await this.issueDedicatedVirtualAccount({
          firstName: company,
          lastName: 'Corporate',
          email: user.email,
          phone: user.phone || '09061518843',
          isCorporate: true,
          companyName: company,
          rcNumber: cac,
        });

        account = await prisma.virtualAccount.create({
          data: {
            developerId: user.developer.id,
            userId: user.id,
            accountNumber: vbaRes.accountNumber,
            accountName: vbaRes.accountName,
            bankName: vbaRes.bankName,
            currency: 'NGN',
            accountType: 'CORPORATE',
            status: 'ACTIVE',
            fincraAccountId: vbaRes.accountId,
          },
        });
      }

      return {
        success: true,
        kycStatus: 'VERIFIED',
        verificationType: 'CORPORATE_KYB',
        verifiedAt: new Date(),
        virtualAccount: account,
      };
    } else {
      // 2. Individual KYC Pipeline via Prembly IdentityPass (NIN & BVN)
      const nin = params?.nin || params?.idNumber;
      const bvn = params?.bvn;
      const street = params?.streetAddress || '';
      const city = params?.city || '';
      const state = params?.state || '';
      const formattedAddress = street ? `${street}, ${city ? city + ', ' : ''}${state}`.trim() : (params?.residentialAddress || '');

      if (!nin && !bvn) {
        throw new Error('NIN or BVN is required for identity verification.');
      }

      // Verify NIN / BVN with Prembly (LIVE)
      if (nin) {
        await PremblyClient.verifyNIN(nin, user.firstName, user.lastName);
      }
      if (bvn) {
        await PremblyClient.verifyBVN(bvn);
      }

      const kyc = await prisma.kycVerification.create({
        data: {
          userId: user.id,
          kycType: 'INDIVIDUAL_KYC',
          nin,
          bvn,
          residentialAddress: formattedAddress,
          status: 'VERIFIED',
          verifiedAt: new Date(),
        },
      });

      await prisma.userProfile.upsert({
        where: { userId: user.id },
        update: { 
          nin, 
          bvnVerified: true, 
          address: formattedAddress,
          city: city || undefined,
          state: state || undefined,
        },
        create: { 
          userId: user.id, 
          nin, 
          bvnVerified: true, 
          address: formattedAddress,
          city: city || undefined,
          state: state || undefined,
        },
      });

      let account = user.virtualAccounts?.[0];
      if (!account) {
        const vbaRes = await this.issueDedicatedVirtualAccount({
          firstName: user.firstName,
          lastName: user.lastName,
          email: user.email,
          phone: user.phone || '09061518843',
          bvn: bvn || undefined,
          nin: nin || undefined,
          dob: params?.dob,
          street: street || formattedAddress,
          city: city || undefined,
          state: state || undefined,
          address: formattedAddress,
        });

        account = await prisma.virtualAccount.create({
          data: {
            userId: user.id,
            accountNumber: vbaRes.accountNumber,
            accountName: vbaRes.accountName,
            bankName: vbaRes.bankName,
            currency: 'NGN',
            accountType: 'INDIVIDUAL',
            status: 'ACTIVE',
            fincraAccountId: vbaRes.accountId,
          },
        });
      }

      return {
        success: true,
        kycStatus: 'VERIFIED',
        verificationType: 'INDIVIDUAL_KYC',
        verifiedAt: new Date(),
        virtualAccount: account,
      };
    }
  }

  /**
   * Retrieve active dedicated virtual bank account for user or developer
   */
  static async getVirtualAccount(userId?: string, developerId?: string) {
    let account: any = null;

    if (developerId) {
      account = await prisma.virtualAccount.findFirst({
        where: { developerId, status: 'ACTIVE' },
        include: { developer: true, user: true },
      });
    } else {
      account = await prisma.virtualAccount.findFirst({
        where: { userId, status: 'ACTIVE' },
        include: { user: true, developer: true },
      });
    }

    if (!account) return null;

    // Check if user is a developer or developerId provided
    const dev = developerId
      ? await prisma.developer.findUnique({ where: { id: developerId } })
      : (userId ? await prisma.developer.findUnique({ where: { userId } }) : null);

    let lockedEscrowBalance = 0;
    if (dev) {
      const purchases = await prisma.purchase.findMany({
        where: {
          OR: [
            { property: { developerId: dev.id } },
            { projectUnit: { project: { developerId: dev.id } } },
          ],
          status: { notIn: ['COMPLETED', 'CANCELLED'] },
        },
        select: { amountPaid: true },
      });
      lockedEscrowBalance = purchases.reduce((sum, p) => sum + (p.amountPaid || 0), 0);
    }

    return {
      ...account,
      availableBalance: account.balance,
      lockedEscrowBalance,
      totalEscrowBalance: account.balance + lockedEscrowBalance,
      isDeveloper: dev !== null,
    };
  }

  /**
   * Retrieve combined transaction history (Credits/Deposits + Debits/Withdrawals)
   */
  static async getMyTransactions(userId: string, developerId?: string) {
    const [payments, withdrawals] = await Promise.all([
      prisma.payment.findMany({
        where: { userId },
        orderBy: { createdAt: 'desc' },
        include: {
          purchase: {
            include: {
              property: true,
              projectUnit: true,
            },
          },
        },
      }),
      prisma.withdrawal.findMany({
        where: developerId ? { developerId } : { userId },
        orderBy: { createdAt: 'desc' },
      }),
    ]);

    const txs: any[] = [];

    for (const p of payments) {
      txs.push({
        id: p.id,
        type: 'CREDIT',
        amount: p.totalAmount,
        currency: 'NGN',
        status: p.status === 'SUCCESS' || p.status === 'CONFIRMED' || p.status === 'COMPLETED' ? 'SUCCESS' : p.status,
        purpose: p.purpose || 'ESCROW_FUNDING',
        description: p.purchase?.property?.title ? `Property Payment: ${p.purchase.property.title}` : (p.purpose || 'Escrow Deposit'),
        reference: p.paymentReference,
        channel: p.paystackChannel || 'DIRECT_BANK_TRANSFER',
        createdAt: p.createdAt,
      });
    }

    for (const w of withdrawals) {
      let finalStatus = w.status;

      // Real-time settlement verification with Paystack for pending/processing payouts
      if ((w.status === 'PROCESSING' || w.status === 'PENDING') && w.reference) {
        try {
          const secretKey = process.env.PAYSTACK_SECRET_KEY || config.paystack?.secretKey;
          if (secretKey) {
            const psRes = await fetch(`https://api.paystack.co/transfer/verify/${encodeURIComponent(w.reference)}`, {
              headers: { Authorization: `Bearer ${secretKey}` },
            });
            const psData: any = await psRes.json();
            if (psData?.status && psData.data?.status) {
              const liveStatus = psData.data.status.toLowerCase();
              if (liveStatus === 'success' || liveStatus === 'successful') {
                finalStatus = 'SUCCESS';
                await prisma.withdrawal.update({
                  where: { id: w.id },
                  data: {
                    status: 'SUCCESS',
                    fincraPayoutId: `PAYSTACK:${psData.data.transfer_code || w.reference}`,
                  },
                }).catch(() => {});
              } else if (liveStatus === 'failed' || liveStatus === 'reversed') {
                finalStatus = 'FAILED';
                await prisma.withdrawal.update({
                  where: { id: w.id },
                  data: {
                    status: 'FAILED',
                    failureReason: psData.data?.gateway_response || `Settlement status: ${liveStatus}`,
                  },
                }).catch(() => {});
                // Auto-reverse funds if not already reversed
                await prisma.virtualAccount.updateMany({
                  where: { userId: w.userId || undefined, developerId: w.developerId || undefined },
                  data: { balance: { increment: w.amount } },
                }).catch(() => {});
              }
            }
          }
        } catch (e: any) {
          console.warn(`[RECONCILIATION] Failed to verify transfer ${w.reference}:`, e.message);
        }
      }

      txs.push({
        id: w.id,
        type: 'DEBIT',
        amount: w.amount,
        currency: 'NGN',
        status: finalStatus,
        purpose: 'WITHDRAWAL',
        description: `Payout to ${w.accountName} (${w.bankName})`,
        reference: w.reference,
        channel: w.bankName || 'BANK_TRANSFER',
        createdAt: w.createdAt,
      });
    }

    txs.sort((a, b) => new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime());
    return txs;
  }

  /**
   * Name Enquiry for destination bank account via Flutterwave
   */
  static async resolveBankAccount(bankCode: string, accountNumber: string) {
    return FlutterwaveClient.nameEnquiry(accountNumber, bankCode);
  }

  /**
   * Request Developer Withdrawal / Payout to any Nigerian Commercial Bank via Flutterwave
   */
  static async requestWithdrawal(params: {
    developerId?: string;
    userId?: string;
    amount: number;
    bankCode: string;
    bankName: string;
    accountNumber: string;
    accountName: string;
    pin?: string;
    biometricAuth?: boolean;
  }) {
    if (params.amount < 1000) {
      throw new Error('Minimum withdrawal amount is ₦1,000');
    }

    let account = await this.getVirtualAccount(params.userId, params.developerId);
    if (!account && params.userId) {
      const user = await prisma.user.findUnique({
        where: { id: params.userId },
        include: { developer: true, virtualAccounts: true },
      });
      if (user?.virtualAccounts?.[0]) {
        account = user.virtualAccounts[0] as any;
      } else if (user?.developer?.id) {
        account = await prisma.virtualAccount.findFirst({
          where: { developerId: user.developer.id },
          include: { developer: true, user: true },
        }) as any;
      }
    }

    if (!account || Number(account.balance) < params.amount) {
      throw new Error('Insufficient escrow wallet balance for withdrawal');
    }

    const fee = 50;
    const netAmount = Math.max(0, params.amount - fee);
    const ref = `HT-WD-${Date.now()}-${Math.random().toString(36).substring(2, 6).toUpperCase()}`;

    // ── Resolve recipient user before any mutation ─────────────────────────────
    const targetUserId = params.userId || account.userId;
    let targetUser: any = null;
    if (targetUserId) {
      targetUser = await prisma.user.findUnique({
        where: { id: targetUserId },
        include: { developer: true },
      });
    } else if (account.developerId) {
      const dev = await prisma.developer.findUnique({
        where: { id: account.developerId },
        include: { user: true },
      });
      targetUser = dev?.user;
    }

    // ── Security Check: Verify 6-Digit Payment PIN or Biometric Authorization ──
    if (targetUser?.transactionPinHash) {
      if (params.biometricAuth === true) {
        // Biometric hardware authentication approved on mobile device
        console.log(`[WITHDRAWAL SECURITY] Biometric authentication confirmed for user ${targetUser.email}`);
      } else if (params.pin) {
        const isPinValid = await bcrypt.compare(String(params.pin).trim(), targetUser.transactionPinHash);
        if (!isPinValid) {
          throw new Error('Incorrect 6-digit Payment PIN. Please re-enter your PIN or use biometrics to confirm.');
        }
        console.log(`[WITHDRAWAL SECURITY] 6-digit PIN verified for user ${targetUser.email}`);
      } else {
        throw new Error('6-digit Payment PIN or Biometric confirmation is required to authorize this withdrawal.');
      }
    }

    const recipientEmail = targetUser?.email || (account as any).developer?.email || (account as any).user?.email || '';
    const recipientName = targetUser
      ? `${targetUser.firstName || ''} ${targetUser.lastName || ''}`.trim()
      : ((account as any).developer?.companyName || params.accountName || 'Account Holder');
    const userRole = targetUser?.role || ((account as any).developer ? 'DEVELOPER' : 'BUYER');
    const notifyUserId = targetUser?.id || targetUserId || account.userId;

    // ── STEP 1: Call gateway FIRST — do NOT touch wallet until accepted ────────
    console.log(`[WITHDRAWAL] Calling gateway for ₦${netAmount} → ${params.accountNumber} (${params.bankCode}) ref=${ref}`);

    let gatewayStatus: 'INSTANT' | 'PROCESSING' | 'FAILED' = 'FAILED';
    let externalRef = ref;
    let providerLabel = 'FLUTTERWAVE';
    let failureMsg = '';

    try {
      const payoutRes = await FlutterwaveClient.transfer({
        accountNumber: params.accountNumber,
        bankCode: params.bankCode,
        amount: netAmount,
        recipientName: params.accountName,
        reference: ref,
        narration: `Hometrust Escrow Payout ${ref}`,
      });

      const gwRawStatus = ((payoutRes.data as any)?.status || '').toLowerCase();
      console.log(`[WITHDRAWAL] Gateway response: status=${payoutRes.status} gwStatus=${gwRawStatus} msg=${payoutRes.message}`);

      if (payoutRes.status === true) {
        externalRef = String(payoutRes.data?.reference || payoutRes.data?.id || ref);
        if (payoutRes.message?.toLowerCase().includes('paystack') || (payoutRes.data as any)?.id?.toString().startsWith('TRF_') || (payoutRes.data as any)?.id?.toString().startsWith('ps_')) {
          providerLabel = 'PAYSTACK';
        }
        // "new" means queued by Flutterwave — webhook will confirm later
        // "successful"/"success" means instant settlement
        if (['successful', 'success'].includes(gwRawStatus)) {
          gatewayStatus = 'INSTANT';
        } else {
          // new / pending / otp / queued — Paystack or FLW will webhook back
          gatewayStatus = 'PROCESSING';
        }
      } else {
        gatewayStatus = 'FAILED';
        failureMsg = payoutRes.message || 'Transfer rejected by settlement gateway';
      }
    } catch (e: any) {
      console.error(`[WITHDRAWAL] Gateway error: ${e.message}`);
      gatewayStatus = 'FAILED';
      failureMsg = e.message || 'Network error calling settlement gateway';
    }

    // Hard failure — wallet untouched, throw clean error
    if (gatewayStatus === 'FAILED') {
      throw new Error(
        `Transfer could not be initiated: ${failureMsg}. No funds have been deducted from your wallet — please try again.`
      );
    }

    // ── STEP 2: Gateway accepted — NOW deduct wallet and record ───────────────
    await prisma.virtualAccount.update({
      where: { id: account.id },
      data: { balance: { decrement: params.amount } },
    });

    const dbStatus = gatewayStatus === 'INSTANT' ? 'SUCCESS' : 'PROCESSING';

    const withdrawal = await prisma.withdrawal.create({
      data: {
        developerId: params.developerId || (account as any).developerId,
        userId: params.userId || account.userId,
        amount: params.amount,
        fee,
        netAmount,
        bankCode: params.bankCode,
        bankName: params.bankName,
        accountNumber: params.accountNumber,
        accountName: params.accountName,
        reference: ref,
        status: dbStatus,
        fincraPayoutId: `${providerLabel}:${externalRef}`,
      },
    });

    // ── STEP 3: Notify with accurate status message ────────────────────────────
    const isInstant = gatewayStatus === 'INSTANT';
    const notifTitle = isInstant ? '✅ Withdrawal Successful' : '⏳ Withdrawal Processing';
    const notifMsg = isInstant
      ? `₦${netAmount.toLocaleString()} has been sent to ${params.accountName} at ${params.bankName} (${params.accountNumber}). Ref: ${ref}`
      : `Your withdrawal of ₦${netAmount.toLocaleString()} to ${params.bankName} (${params.accountNumber}) is being processed by the bank. You will get a push notification the moment funds arrive. Ref: ${ref}`;

    if (notifyUserId) {
      NotificationsService.createAndDispatch({
        userId: notifyUserId,
        title: notifTitle,
        message: notifMsg,
        type: 'PAYMENT',
        actionDetails: [
          { label: 'Amount Requested', value: `₦${params.amount.toLocaleString()}` },
          { label: 'Transfer Fee', value: `₦${fee.toLocaleString()}` },
          { label: 'Net Amount', value: `₦${netAmount.toLocaleString()}` },
          { label: 'Destination Bank', value: params.bankName },
          { label: 'Account Number', value: params.accountNumber },
          { label: 'Beneficiary', value: params.accountName },
          { label: 'Reference', value: ref },
          { label: 'Status', value: isInstant ? 'Sent ✅' : 'Processing ⏳' },
        ],
      }).catch(console.warn);

      OneSignalService.sendPushToUser({
        userId: notifyUserId,
        title: notifTitle,
        message: notifMsg,
        data: { type: 'WITHDRAWAL', reference: ref, amount: netAmount, status: dbStatus },
      }).catch(console.warn);
    }

    if (recipientEmail) {
      ResendService.sendWithdrawalDispatchedEmail(recipientEmail, recipientName, netAmount, {
        bankName: params.bankName,
        accountNumber: params.accountNumber,
        reference: ref,
        userRole,
      }).catch(console.warn);
    }

    return withdrawal;
  }

  /**
   * Handle Paystack transfer.success / transfer.failed / transfer.reversed webhooks.
   * Called from BankingController.webhook() when event starts with "transfer."
   */
  static async handleTransferWebhook(event: string, data: any): Promise<void> {
    const reference: string = data?.reference || data?.transfer_code || '';
    const paystackStatus = (data?.status || '').toLowerCase();

    console.log(`[TRANSFER WEBHOOK] event=${event} ref=${reference} status=${paystackStatus}`);

    if (!reference) return;

    const withdrawal = await prisma.withdrawal.findFirst({
      where: { reference },
      include: {
        user: true,
        developer: { include: { user: true } },
      },
    });

    if (!withdrawal) {
      console.warn(`[TRANSFER WEBHOOK] No withdrawal record found for ref=${reference}`);
      return;
    }

    // Resolve notify target
    const devUser = (withdrawal.developer as any)?.user;
    const targetUser: any = withdrawal.user || devUser;
    const notifyUserId: string | null = targetUser?.id || null;
    const recipientEmail: string = targetUser?.email || '';
    const recipientName: string = targetUser
      ? `${targetUser.firstName || ''} ${targetUser.lastName || ''}`.trim()
      : withdrawal.accountName;

    const isSuccess = event === 'transfer.success' || paystackStatus === 'success' || paystackStatus === 'successful';
    const isFailed = event === 'transfer.failed' || event === 'transfer.reversed'
      || paystackStatus === 'failed' || paystackStatus === 'reversed';

    if (isSuccess && withdrawal.status !== 'SUCCESS') {
      // ── Confirmed: money landed ─────────────────────────────────────────────
      await prisma.withdrawal.update({
        where: { id: withdrawal.id },
        data: {
          status: 'SUCCESS',
          fincraPayoutId: `PAYSTACK_WH:${data?.transfer_code || reference}`,
        },
      });

      console.log(`[TRANSFER WEBHOOK] ✅ CONFIRMED ₦${withdrawal.netAmount} → ${withdrawal.accountNumber}`);

      if (notifyUserId) {
        NotificationsService.createAndDispatch({
          userId: notifyUserId,
          title: '✅ Funds Delivered to Bank',
          message: `₦${withdrawal.netAmount.toLocaleString()} has been successfully delivered to ${withdrawal.accountName} at ${withdrawal.bankName} (${withdrawal.accountNumber}). Ref: ${reference}`,
          type: 'PAYMENT',
          actionDetails: [
            { label: 'Amount Delivered', value: `₦${withdrawal.netAmount.toLocaleString()}` },
            { label: 'Recipient', value: withdrawal.accountName },
            { label: 'Bank', value: withdrawal.bankName },
            { label: 'Account', value: withdrawal.accountNumber },
            { label: 'Reference', value: reference },
            { label: 'Status', value: '✅ Delivered' },
          ],
        }).catch(console.warn);

        OneSignalService.sendPushToUser({
          userId: notifyUserId,
          title: '✅ Funds Delivered',
          message: `₦${withdrawal.netAmount.toLocaleString()} sent to ${withdrawal.accountName} at ${withdrawal.bankName} — confirmed!`,
          data: { type: 'WITHDRAWAL_CONFIRMED', reference, amount: withdrawal.netAmount },
        }).catch(console.warn);
      }

      if (recipientEmail) {
        ResendService.sendWithdrawalDispatchedEmail(recipientEmail, recipientName, withdrawal.netAmount, {
          bankName: withdrawal.bankName,
          accountNumber: withdrawal.accountNumber,
          reference,
          userRole: 'USER',
        }).catch(console.warn);
      }

    } else if (isFailed && withdrawal.status !== 'FAILED') {
      // ── Failed: reverse the deduction ──────────────────────────────────────
      const failReason = data?.reason || data?.gateway_response || `Transfer ${event} at payment gateway`;

      await prisma.withdrawal.update({
        where: { id: withdrawal.id },
        data: { status: 'FAILED', failureReason: failReason },
      });

      console.log(`[TRANSFER WEBHOOK] ❌ FAILED ₦${withdrawal.amount} ref=${reference} reason=${failReason}`);

      if (withdrawal.userId) {
        await this.processReversalAndRefund({
          userId: withdrawal.userId,
          amount: withdrawal.amount,
          reason: failReason,
          reference,
          originalTxType: 'WITHDRAWAL',
          bankName: withdrawal.bankName,
          accountNumber: withdrawal.accountNumber,
        });
      }
    }
  }


  /**
   * Universal Reversal & Refund Engine
   * Restores wallet balance, records ledger transaction, adds persistent bell notification,
   * dispatches OneSignal mobile push notification, sends transactional email, and logs audit record.
   */
  static async processReversalAndRefund(params: {
    userId: string;
    amount: number;
    reason: string;
    reference: string;
    originalTxType?: 'WITHDRAWAL' | 'DEPOSIT' | 'ESCROW_PAYMENT';
    bankName?: string;
    accountNumber?: string;
  }) {
    const { userId, amount, reason, reference, originalTxType = 'WITHDRAWAL' } = params;

    const user = await prisma.user.findUnique({
      where: { id: userId },
      include: { virtualAccounts: true },
    });
    if (!user) return null;

    const account = user.virtualAccounts[0];
    let newBalance = amount;
    if (account) {
      const updatedAccount = await prisma.virtualAccount.update({
        where: { id: account.id },
        data: { balance: { increment: amount } },
      });
      newBalance = updatedAccount.balance;
    }

    // 1. Transaction Ledger Record
    const revRef = `HT-REV-${Date.now()}`;
    await prisma.payment.create({
      data: {
        userId,
        amount,
        totalAmount: amount,
        currency: 'NGN',
        purpose: 'WALLET_REVERSAL',
        status: 'SUCCESS',
        paymentReference: revRef,
        paystackChannel: 'REVERSAL',
        paidAt: new Date(),
        receiptNumber: `HT-RCP-REV-${Date.now()}`,
      },
    }).catch((e) => console.warn('[REVERSAL PAYMENT LOG ERROR]', e.message));

    // 2. Persistent In-App Notification Bell & Real-time Socket
    const notifTitle = '🔄 Funds Reversed & Restored';
    const notifMessage = `Your ${originalTxType.toLowerCase()} of ₦${amount.toLocaleString()} has been reversed and refunded to your escrow wallet. Reason: ${reason}. Current Balance: ₦${newBalance.toLocaleString()}.`;

    await NotificationsService.createAndDispatch({
      userId,
      title: notifTitle,
      message: notifMessage,
      type: 'PAYMENT',
      linkUrl: '/wallet',
      actionDetails: [
        { label: 'Amount Refunded', value: `₦${amount.toLocaleString()}` },
        { label: 'Restored Balance', value: `₦${newBalance.toLocaleString()}` },
        { label: 'Reversal Reason', value: reason },
        { label: 'Reference', value: reference },
      ],
    }).catch(() => {});

    // 3. Mobile Push Notification via OneSignal
    OneSignalService.sendPushToUser({
      userId,
      title: notifTitle,
      message: `₦${amount.toLocaleString()} was reversed and refunded to your Hometrust Escrow Wallet. Reason: ${reason}`,
      data: {
        type: 'PAYMENT_REVERSED',
        amount,
        newBalance,
        reference,
      },
    }).catch(() => {});

    // 4. Transactional Reversal Email via Resend
    const recipientEmail = user.email;
    const recipientName = `${user.firstName || ''} ${user.lastName || ''}`.trim() || 'Hometrust Customer';
    if (recipientEmail) {
      ResendService.sendReversalReceiptEmail(recipientEmail, recipientName, amount, {
        reason,
        reference,
        newBalance,
        txType: originalTxType,
      }).catch(console.warn);
    }

    // 5. Security Audit Log
    await AuditService.log({
      adminEmail: 'system@hometrust.ng',
      action: 'PAYMENT_REVERSED_AND_REFUNDED',
      entityType: 'VIRTUAL_ACCOUNT',
      entityId: account?.id || userId,
      details: {
        userId,
        amount,
        reason,
        reference,
        newBalance,
        originalTxType,
      },
    }).catch(() => {});

    return {
      success: true,
      newBalance,
      reference: revRef,
    };
  }

  /**
   * Pay for In-App Services (Property Instalments, Legal Title Searches, Inspections, Materials)
   * directly from Virtual Escrow Wallet Balance
   */
  static async payFromWallet(params: {
    userId: string;
    amount: number;
    purpose?: string;
    purchaseId?: string;
    verificationId?: string;
    inspectionId?: string;
    description?: string;
    pin?: string;
    biometricAuth?: boolean;
  }) {
    if (params.amount <= 0) {
      throw new Error('Invalid payment amount');
    }

    const user = await prisma.user.findUnique({
      where: { id: params.userId },
      include: { virtualAccounts: true },
    });

    if (!user) throw new Error('User not found');

    // ── Security Check: Verify 6-Digit Payment PIN or Biometric Authorization ──
    if (user.transactionPinHash) {
      if (params.biometricAuth === true) {
        console.log(`[WALLET PAYMENT SECURITY] Biometric authentication confirmed for user ${user.email}`);
      } else if (params.pin) {
        const isPinValid = await bcrypt.compare(String(params.pin).trim(), user.transactionPinHash);
        if (!isPinValid) {
          throw new Error('Incorrect 6-digit Payment PIN. Please re-enter your PIN or use biometrics to confirm.');
        }
        console.log(`[WALLET PAYMENT SECURITY] 6-digit PIN verified for user ${user.email}`);
      } else {
        throw new Error('6-digit Payment PIN or Biometric confirmation is required to authorize this payment.');
      }
    }

    const account = user.virtualAccounts?.[0];
    if (!account || account.balance < params.amount) {
      throw new Error(`Insufficient escrow wallet balance. Required: ₦${params.amount.toLocaleString()}, Available: ₦${(account?.balance || 0).toLocaleString()}`);
    }

    // Deduct from wallet balance
    const updatedAccount = await prisma.virtualAccount.update({
      where: { id: account.id },
      data: { balance: { decrement: params.amount } },
    });

    const paymentRef = `WALLET-PAY-${Date.now()}-${Math.random().toString(36).substring(2, 6).toUpperCase()}`;

    // Record Payment Entry
    const payment = await prisma.payment.create({
      data: {
        paymentReference: paymentRef,
        userId: user.id,
        purchaseId: params.purchaseId,
        amount: params.amount,
        platformFee: 0,
        processingFee: 0,
        totalAmount: params.amount,
        purpose: params.purpose || 'IN_APP_PAYMENT',
        status: 'SUCCESS',
        paidAt: new Date(),
      },
    });

    // If purchase installment, update purchase
    if (params.purchaseId) {
      const purchase = await prisma.purchase.findUnique({ where: { id: params.purchaseId } });
      if (purchase) {
        const newPaid = purchase.amountPaid + params.amount;
        const newBal = Math.max(0, purchase.totalPrice - newPaid);
        await prisma.purchase.update({
          where: { id: purchase.id },
          data: {
            amountPaid: newPaid,
            outstandingBalance: newBal,
            status: newBal <= 0 ? 'COMPLETED' : 'ACTIVE',
          },
        });
      }
    }

    // If Legal Verification Request, update status
    if (params.verificationId) {
      await prisma.verificationRequest.update({
        where: { id: params.verificationId },
        data: { status: 'PAYMENT_CONFIRMED' },
      }).catch(console.warn);
    }

    // If Inspection booking, update status
    if (params.inspectionId) {
      await prisma.inspection.update({
        where: { id: params.inspectionId },
        data: { status: 'CONFIRMED' },
      }).catch(console.warn);
    }

    // Dispatch In-App + Push + Email Notification
    NotificationsService.createAndDispatch({
      userId: user.id,
      title: '💳 Payment Confirmed',
      message: `Your payment of ₦${params.amount.toLocaleString()} for ${params.description || params.purpose || 'In-App Service'} was successful.`,
      type: 'PAYMENT',
      actionDetails: [
        { label: 'Amount Paid', value: `₦${params.amount.toLocaleString()}` },
        { label: 'Purpose', value: params.purpose || 'Escrow Payment' },
        { label: 'Reference', value: paymentRef },
        { label: 'Remaining Escrow Balance', value: `₦${updatedAccount.balance.toLocaleString()}` },
      ],
    }).catch(() => {});

    // Dispatch Payment Receipt Email
    ResendService.sendPaymentReceivedEmail(
      user.email,
      `${user.firstName} ${user.lastName}`,
      params.amount,
      updatedAccount.balance,
      paymentRef
    ).catch(console.warn);

    // Audit Log
    await AuditService.log({
      adminEmail: user.email,
      action: 'WALLET_IN_APP_PAYMENT',
      entityType: 'PAYMENT',
      entityId: payment.id,
      details: {
        amount: params.amount,
        purpose: params.purpose,
        newBalance: updatedAccount.balance,
        paymentRef,
      },
    });

    return {
      success: true,
      payment,
      newWalletBalance: updatedAccount.balance,
    };
  }

  /**
   * Re-generate / Upgrade Dedicated Virtual Account
   */
  static async syncLiveVirtualAccount(userId: string, developerId?: string) {
    const user = await prisma.user.findUnique({
      where: { id: userId },
      include: { profile: true, developer: true, virtualAccounts: true },
    });

    if (!user) throw new Error('User not found');

    const isDeveloper = !!user.developer || !!developerId;
    let vbaRes;

    if (isDeveloper && user.developer) {
      vbaRes = await this.issueDedicatedVirtualAccount({
        firstName: user.developer.companyName,
        lastName: 'Corporate',
        email: user.email,
        phone: user.phone || '09061518843',
        isCorporate: true,
        companyName: user.developer.companyName,
        rcNumber: user.developer.cacNumber,
      });
    } else {
      const nin = user.profile?.nin || undefined;
      vbaRes = await this.issueDedicatedVirtualAccount({
        firstName: user.firstName,
        lastName: user.lastName,
        email: user.email,
        phone: user.phone || '09061518843',
        nin,
      });
    }

    // Upsert VirtualAccount record
    let account = user.virtualAccounts?.[0];
    if (account) {
      account = await prisma.virtualAccount.update({
        where: { id: account.id },
        data: {
          accountNumber: vbaRes.accountNumber,
          accountName: vbaRes.accountName,
          bankName: vbaRes.bankName,
          fincraAccountId: vbaRes.accountId,
          status: 'ACTIVE',
        },
      });
    } else {
      account = await prisma.virtualAccount.create({
        data: {
          userId: user.id,
          developerId: user.developer?.id,
          accountNumber: vbaRes.accountNumber,
          accountName: vbaRes.accountName,
          bankName: vbaRes.bankName,
          currency: 'NGN',
          accountType: isDeveloper ? 'CORPORATE' : 'INDIVIDUAL',
          status: 'ACTIVE',
          balance: 0,
          fincraAccountId: vbaRes.accountId,
        },
      });
    }

    // Dispatch email
    ResendService.sendVirtualAccountIssuedEmail(
      user.email,
      isDeveloper && user.developer ? user.developer.companyName : `${user.firstName} ${user.lastName}`,
      {
        accountNumber: account.accountNumber,
        bankName: account.bankName,
        accountName: account.accountName,
      }
    ).catch(console.warn);

    // Query Flutterwave API for any recent uncredited collections for this user
    try {
      const txs = await FlutterwaveClient.fetchCustomerTransactions(user.email);
      for (const tx of txs) {
        if (tx.status === 'successful' && tx.amount > 0) {
          const txRef = String(tx.tx_ref || tx.id || tx.flw_ref);
          const existingPayment = await prisma.payment.findFirst({
            where: {
              OR: [
                { paymentReference: txRef },
                { receiptNumber: txRef },
              ],
            },
          });

          if (!existingPayment && account) {
            const amount = Number(tx.amount);
            console.log(`[SYNC RECOVERY] Crediting uncredited deposit of ₦${amount} (Ref: ${txRef}) for ${user.email}`);

            await prisma.$transaction([
              prisma.virtualAccount.update({
                where: { id: account.id },
                data: { balance: { increment: amount } },
              }),
              prisma.payment.create({
                data: {
                  userId: user.id,
                  amount,
                  currency: 'NGN',
                  purpose: 'ESCROW_WALLET_CREDIT',
                  paystackChannel: 'bank_transfer',
                  paymentReference: txRef,
                  receiptNumber: `HT-RCP-${tx.id || Date.now()}`,
                  status: 'SUCCESS',
                  totalAmount: amount,
                  paidAt: new Date(tx.created_at || Date.now()),
                },
              }),
            ]);

            account.balance += amount;

            NotificationsService.createAndDispatch({
              userId: user.id,
              title: '💰 Escrow Wallet Credited',
              message: `Your deposit of ₦${amount.toLocaleString()} via bank transfer has been synced & credited to your escrow wallet.`,
              type: 'PAYMENT',
              actionDetails: [
                { label: 'Amount Credited', value: `₦${amount.toLocaleString()}` },
                { label: 'Payment Reference', value: txRef },
                { label: 'Status', value: 'Confirmed & Cleared' },
              ],
            }).catch(() => {});
          }
        }
      }
    } catch (e: any) {
      console.warn('[SYNC FLW TXS WARNING]', e.message);
    }

    return {
      success: true,
      message: 'Dedicated Virtual Bank Account synchronized successfully!',
      virtualAccount: account,
    };
  }

  /**
   * Recover uncredited Flutterwave deposits for a user.
   * Called in background on wallet fetch to capture any missed webhook credits.
   */
  static async recoverUncreditedDeposits(userId: string) {
    const user = await prisma.user.findUnique({
      where: { id: userId },
      include: { virtualAccounts: true },
    });
    if (!user || !user.virtualAccounts?.length) return;

    const account = user.virtualAccounts[0];
    const txs = await FlutterwaveClient.fetchCustomerTransactions(user.email);

    for (const tx of txs) {
      if (tx.status === 'successful' && tx.amount > 0) {
        const txCustomerEmail = tx.customer?.email?.toLowerCase() || '';
        const txVa = tx.meta?.virtualaccountnumber || '';
        const matchesUser =
          txCustomerEmail === user.email.toLowerCase() ||
          (txVa && txVa === account.accountNumber) ||
          (user.phone && tx.customer?.phone_number === user.phone);

        if (!matchesUser) continue;

        // If virtual account number on Flutterwave differs from DB, update DB to match
        if (txVa && txVa !== account.accountNumber) {
          await prisma.virtualAccount.update({
            where: { id: account.id },
            data: { accountNumber: txVa },
          });
          account.accountNumber = txVa;
        }

        // CRITICAL: tx.flw_ref and tx.id are unique per transaction. tx.tx_ref is the STATIC account order reference!
        const uniqueTxId = String(tx.id || '');
        const uniqueFlwRef = String(tx.flw_ref || '');
        const txRef = uniqueFlwRef || uniqueTxId || String(tx.tx_ref || `FLW-${Date.now()}`);

        const existingPayment = await prisma.payment.findFirst({
          where: {
            OR: [
              { paymentReference: txRef },
              { paystackReference: uniqueFlwRef },
              { receiptNumber: `HT-RCP-${uniqueTxId}` },
              { receiptNumber: txRef },
              ...(uniqueTxId ? [{ paymentReference: uniqueTxId }] : []),
            ],
          },
        });

        if (!existingPayment) {
          const amount = Number(tx.amount);
          console.log(`[SYNC RECOVERY] Crediting uncredited deposit of ₦${amount} (Ref: ${txRef}, FLW ID: ${uniqueTxId}) for ${user.email}`);

          const [updatedAccount, newPayment] = await prisma.$transaction([
            prisma.virtualAccount.update({
              where: { id: account.id },
              data: { balance: { increment: amount } },
            }),
            prisma.payment.create({
              data: {
                userId: user.id,
                amount,
                currency: 'NGN',
                purpose: 'ESCROW_WALLET_CREDIT',
                paystackChannel: 'bank_transfer',
                paymentReference: txRef,
                paystackReference: uniqueFlwRef,
                receiptNumber: `HT-RCP-${uniqueTxId || Date.now()}`,
                status: 'SUCCESS',
                totalAmount: amount,
                paidAt: new Date(tx.created_at || Date.now()),
              },
            }),
          ]);

          // 1. Dispatch In-App & Push Notification
          await NotificationsService.createAndDispatch({
            userId: user.id,
            title: '💰 Escrow Wallet Credited',
            message: `Your deposit of ₦${amount.toLocaleString()} via bank transfer has been synced & credited to your escrow wallet.`,
            type: 'PAYMENT',
            sendEmail: false, // We send full branded email below
            actionDetails: [
              { label: 'Amount Credited', value: `₦${amount.toLocaleString()}` },
              { label: 'Payment Reference', value: txRef },
              { label: 'Sender', value: tx.meta?.originatorname || 'Direct Bank Transfer' },
              { label: 'Status', value: 'Confirmed & Cleared' },
            ],
          }).catch((err) => console.warn('[SYNC NOTIFICATION ERR]', err.message));

          // 2. Dispatch Branded Receipt Email to user
          if (user.email) {
            const recipientName = `${user.firstName || ''} ${user.lastName || ''}`.trim() || 'Hometrust Customer';
            await ResendService.sendPaymentReceivedEmail(
              user.email,
              recipientName,
              amount,
              updatedAccount.balance,
              txRef
            ).catch((err) => console.warn('[SYNC EMAIL ERR]', err.message));
          }
        }
      }
    }
  }

  /**
   * Process incoming Paystack/Flutterwave webhook when money hits a virtual account.
   */
  static async handleWebhook(event: any) {
    const eventType = event.event || event.type || event['event.type'] || '';
    const data = event.data || event;

    // ── Route ALL Paystack/Flutterwave transfer events through dedicated handler ─
    // Handles: transfer.success, transfer.failed, transfer.reversed
    if (eventType.startsWith('transfer.') || eventType === 'transfer') {
      await this.handleTransferWebhook(eventType, data);
      return { success: true };
    }

    // ── Handle Reversals / Failed Transfers from older Flutterwave webhook format ─
    const isReversal =
      eventType.includes('reversed') ||
      eventType.includes('refund');

    if (isReversal) {
      console.log(`[WEBHOOK] Processing legacy reversal event: ${eventType}`);
      const transferRef = data.reference || data.tx_ref || data.id;
      const withdrawal = await prisma.withdrawal.findFirst({
        where: {
          OR: [
            { reference: String(transferRef) },
            { fincraPayoutId: { contains: String(transferRef) } },
          ],
        },
      });

      if (withdrawal && withdrawal.userId && withdrawal.status !== 'FAILED') {
        await this.processReversalAndRefund({
          userId: withdrawal.userId,
          amount: withdrawal.amount,
          reason: data.complete_message || data.narration || data.reason || 'Transfer reversed by banking network',
          reference: withdrawal.reference,
          originalTxType: 'WITHDRAWAL',
        });
      }
      return { success: true };
    }


    const isCollection =
      eventType.includes('charge.success') ||
      eventType.includes('charge.completed') ||
      eventType.includes('dedicated_account') ||
      eventType.includes('collection') ||
      eventType.includes('virtual_account') ||
      eventType.includes('credit') ||
      eventType.includes('deposit') ||
      eventType.includes('successful');

    if (!isCollection) return { success: true };

    // ── Extract account identifier ──────────────────────────────────────────
    const accountNumber =
      data.account_number ||
      data.accountNumber ||
      data.virtual_account_number ||
      data.customer?.dedicated_account?.account_number ||
      data.meta?.receiver_account_number ||
      data.meta?.virtualaccountnumber;

    const customerCode = data.customer?.customer_code || data.customer_id || data.customerId;

    // ── Extract sender info from Flutterwave webhook (meta field) ───────────
    const senderName: string =
      data.meta?.originatorname ||
      data.meta?.sender ||
      data.authorization?.sender_name ||
      data.payer?.name ||
      '';

    const senderAccountNumber: string =
      data.meta?.originatoraccountnumber ||
      data.meta?.sourceaccountnumber ||
      data.meta?.sender_bank_account ||
      '';

    const senderBankName: string =
      data.meta?.bankname ||
      data.meta?.sender_bank ||
      data.authorization?.bank ||
      '';

    // ── Extract amount (Paystack sends kobo, Flutterwave sends naira) ───────
    const rawAmount = data.amount || data.settlement_amount || 0;
    let amount = typeof rawAmount === 'string' ? parseFloat(rawAmount) : rawAmount;
    // Paystack sends amounts in kobo (subunit). Values >10,000 on a Paystack event = kobo.
    if (eventType.includes('charge.success') && amount > 10000) {
      amount = amount / 100;
    }

    const reference = data.reference || data.tx_ref || data.flw_ref || `HT-DEP-${Date.now()}`;

    // ── Locate virtual account in database ──────────────────────────────────
    let account: any = null;
    if (accountNumber) {
      account = await prisma.virtualAccount.findUnique({
        where: { accountNumber },
        include: { user: true, developer: true },
      });
    }
    if (!account && customerCode) {
      account = await prisma.virtualAccount.findFirst({
        where: { fincraAccountId: String(customerCode) },
        include: { user: true, developer: true },
      });
    }
    // Fallback: search by customer email if account number / customer code didn't match directly
    if (!account) {
      const email = data.customer?.email || data.email || data.meta?.email || data.payer?.email;
      if (email) {
        account = await prisma.virtualAccount.findFirst({
          where: {
            OR: [
              { user: { email: { equals: email, mode: 'insensitive' } } },
              { developer: { email: { equals: email, mode: 'insensitive' } } },
            ],
          },
          include: { user: true, developer: true },
        });
      }
    }

    if (!account) {
      console.warn(`[WEBHOOK] No virtual account found for accountNumber=${accountNumber}, customerCode=${customerCode}`);
      return { success: true };
    }

    // ── Determine the expected holder name ──────────────────────────────────
    const holderFirstName = account.user?.firstName || account.developer?.companyName || '';
    const holderLastName  = account.user?.lastName  || 'Ltd';
    const holderFullName  = `${holderFirstName} ${holderLastName}`.trim();
    const recipientEmail  = account.user?.email || account.developer?.email || '';
    const recipientName   = account.user
      ? `${account.user.firstName} ${account.user.lastName}`
      : (account.developer?.companyName || 'Valued Partner');

    // Log sender info for audit
    const hasSenderInfo = senderName.trim().length > 0;
    if (hasSenderInfo) {
      console.log(`[ESCROW DEPOSIT] Sender "${senderName}" (${senderBankName}) -> Dedicated Account "${holderFullName}" (${account.accountNumber}). Crediting ₦${amount.toLocaleString()}.`);
    }

    // ── PASS: Credit the virtual account balance ────────────────────────────
    const updatedVa = await prisma.virtualAccount.update({
      where: { id: account.id },
      data: { balance: { increment: amount } },
    });

    console.log(`[ESCROW] ✅ Credited ₦${amount.toLocaleString()} to ${account.accountName} (${account.accountNumber})`);

    // ── Auto-apply to active purchase instalment OR record as Wallet Deposit ─
    let activePurchase: any = null;
    if (account.userId) {
      activePurchase = await prisma.purchase.findFirst({
        where: { userId: account.userId, status: 'ACTIVE' },
        include: { property: true, projectUnit: true },
      });

      if (activePurchase) {
        const newAmountPaid = activePurchase.amountPaid + amount;
        const newBalance    = Math.max(0, activePurchase.totalPrice - newAmountPaid);
        const isCompleted   = newBalance <= 0;

        await prisma.purchase.update({
          where: { id: activePurchase.id },
          data: {
            amountPaid: newAmountPaid,
            outstandingBalance: newBalance,
            status: isCompleted ? 'COMPLETED' : 'ACTIVE',
          },
        });

        console.log(`[ESCROW] Applied ₦${amount.toLocaleString()} to Purchase ${activePurchase.id}. Remaining: ₦${newBalance.toLocaleString()}`);
      }
    }

    // ── ALWAYS create a Payment record so Admin & User see the transaction ──
    const paymentUserId = account.userId || account.developer?.userId;
    if (paymentUserId) {
      await prisma.payment.create({
        data: {
          paymentReference: reference,
          userId: paymentUserId,
          purchaseId: activePurchase?.id || null,
          developerId: activePurchase?.property?.developerId || account.developerId || null,
          amount,
          platformFee: 0,
          processingFee: 0,
          totalAmount: amount,
          purpose: activePurchase ? 'INSTALMENT' : 'INITIAL_DEPOSIT',
          status: 'SUCCESS',
          paystackReference: reference,
          paystackChannel: 'bank_transfer',
          paidAt: new Date(),
          receiptNumber: `HT-DEP-${Date.now().toString().slice(-8)}`,
        },
      }).catch(err => console.warn('[PAYMENT LOG WARNING]', err.message));
    }

    // ── Send payment received email ─────────────────────────────────────────
    if (recipientEmail) {
      ResendService.sendPaymentReceivedEmail(
        recipientEmail,
        recipientName,
        amount,
        updatedVa.balance,
        reference
      ).catch(console.warn);
    }

    // ── Audit log successful deposit ────────────────────────────────────────
    await AuditService.log({
      adminEmail: recipientEmail || 'system@hometrustng.com',
      action: 'PAYMENT_AUTO_CAPTURED',
      entityType: 'VIRTUAL_ACCOUNT',
      entityId: account.id,
      details: {
        accountNumber: account.accountNumber,
        holderName: holderFullName,
        senderName: senderName || 'UNKNOWN',
        amount,
        reference,
        provider: account.provider || 'FLUTTERWAVE',
      },
    });

    return { success: true, action: 'CREDITED' };
  }

  /**
   * Simulate a bank transfer deposit (Useful for Sandbox Testing & Demos)
   */
  static async simulateDeposit(params: { accountNumber: string; amount: number; reference?: string }) {
    const event = {
      event: 'collection.successful',
      data: {
        account_number: params.accountNumber,
        amount: params.amount,
        currency: 'NGN',
        reference: params.reference || `SIM-DEP-${Date.now()}`,
        status: 'SUCCESSFUL',
      },
    };

    await this.handleWebhook(event);

    const updatedAccount = await prisma.virtualAccount.findUnique({
      where: { accountNumber: params.accountNumber },
      include: { user: true, developer: true },
    });

    return {
      success: true,
      message: `Successfully credited ₦${params.amount.toLocaleString()} to ${updatedAccount?.accountName || params.accountNumber}`,
      account: updatedAccount,
    };
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

  /**
   * List all Prembly KYC/KYB records for Admin audit
   */
  static async listAllKyc() {
    return prisma.kycVerification.findMany({
      include: {
        user: { select: { id: true, firstName: true, lastName: true, email: true, phone: true, role: true } },
        developer: { select: { id: true, companyName: true, cacNumber: true, email: true, phone: true } },
      },
      orderBy: { createdAt: 'desc' },
    });
  }
}
