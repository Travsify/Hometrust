import { prisma } from '../../utils/prisma';
import { MapleradClient } from './maplerad.client';
import { PremblyClient } from './prembly.client';
import { AuditService } from '../audit/audit.service';
import { ResendService } from '../notifications/resend.service';

export class BankingService {
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

    // 2. Auto-Generate Dedicated Virtual Account via Maplerad if not existing
    let account = user.virtualAccounts?.[0];
    if (!account) {
      const mapleradRes = await MapleradClient.createVirtualAccount({
        firstName: user.firstName,
        lastName: user.lastName,
        email: user.email,
        phone: user.phone || '08012345678',
        bvn: data.bvn,
        nin: data.nin,
      });

      account = await prisma.virtualAccount.create({
        data: {
          userId: user.id,
          accountName: mapleradRes.data.account_name,
          accountNumber: mapleradRes.data.account_number,
          bankName: mapleradRes.data.bank_name,
          accountType: 'INDIVIDUAL',
          currency: 'NGN',
          fincraAccountId: mapleradRes.data.id,
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
        provider: 'MAPLERAD',
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

    // 2. Provision Corporate Dedicated Virtual Account via Maplerad
    let account = developer.virtualAccounts?.[0];
    if (!account) {
      const mapleradRes = await MapleradClient.createVirtualAccount({
        firstName: developer.companyName,
        lastName: 'Corporate',
        email: developer.email,
        phone: developer.phone || '08012345678',
        isCorporate: true,
        companyName: data.companyName,
        rcNumber: data.cacNumber,
      });

      account = await prisma.virtualAccount.create({
        data: {
          developerId: developer.id,
          accountName: mapleradRes.data.account_name,
          accountNumber: mapleradRes.data.account_number,
          bankName: mapleradRes.data.bank_name,
          accountType: 'CORPORATE',
          currency: 'NGN',
          fincraAccountId: mapleradRes.data.id,
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
        provider: 'MAPLERAD',
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
        const mapleradRes = await MapleradClient.createVirtualAccount({
          firstName: company,
          lastName: 'Corporate',
          email: user.email,
          phone: user.phone || '08012345678',
          isCorporate: true,
          companyName: company,
          rcNumber: cac,
        });

        account = await prisma.virtualAccount.create({
          data: {
            developerId: user.developer.id,
            userId: user.id,
            accountNumber: mapleradRes.data.account_number,
            accountName: mapleradRes.data.account_name,
            bankName: mapleradRes.data.bank_name,
            currency: 'NGN',
            accountType: 'CORPORATE',
            status: 'ACTIVE',
            fincraAccountId: mapleradRes.data.id,
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
        const mapleradRes = await MapleradClient.createVirtualAccount({
          firstName: user.firstName,
          lastName: user.lastName,
          email: user.email,
          phone: user.phone || '08012345678',
          bvn: bvn || undefined,
          nin: nin || undefined,
        });

        account = await prisma.virtualAccount.create({
          data: {
            userId: user.id,
            accountNumber: mapleradRes.data.account_number,
            accountName: mapleradRes.data.account_name,
            bankName: mapleradRes.data.bank_name,
            currency: 'NGN',
            accountType: 'INDIVIDUAL',
            status: 'ACTIVE',
            fincraAccountId: mapleradRes.data.id,
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
    if (developerId) {
      return prisma.virtualAccount.findFirst({
        where: { developerId, status: 'ACTIVE' },
        include: { developer: true, user: true },
      });
    }

    return prisma.virtualAccount.findFirst({
      where: { userId, status: 'ACTIVE' },
      include: { user: true, developer: true },
    });
  }

  /**
   * Name Enquiry for destination bank account via Maplerad
   */
  static async resolveBankAccount(bankCode: string, accountNumber: string) {
    return MapleradClient.nameEnquiry(accountNumber, bankCode);
  }

  /**
   * Request Developer Withdrawal / Payout to any Nigerian Commercial Bank via Maplerad
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
    const ref = `HT-WD-${Date.now()}-${Math.random().toString(36).substring(2, 6).toUpperCase()}`;

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
        status: 'PENDING',
      },
    });

    // Dispatch via Maplerad Transfer
    const payoutRes = await MapleradClient.transfer({
      accountNumber: params.accountNumber,
      bankCode: params.bankCode,
      amount: netAmount,
      reference: ref,
      narration: `Hometrust Escrow Settlement ${ref}`,
    });

    await prisma.withdrawal.update({
      where: { id: withdrawal.id },
      data: {
        status: payoutRes.status ? 'SUCCESS' : 'FAILED',
        fincraPayoutId: payoutRes.data?.reference,
      },
    });

    // Send Withdrawal Dispatched Email
    const devEmail = account.developer?.email || account.user?.email || '';
    const devName = account.developer?.companyName || `${account.user?.firstName || ''} ${account.user?.lastName || ''}`;
    if (devEmail) {
      ResendService.sendWithdrawalDispatchedEmail(devEmail, devName, netAmount, {
        bankName: params.bankName,
        accountNumber: params.accountNumber,
        reference: ref,
      }).catch(console.warn);
    }

    return withdrawal;
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
  }) {
    if (params.amount <= 0) {
      throw new Error('Invalid payment amount');
    }

    const user = await prisma.user.findUnique({
      where: { id: params.userId },
      include: { virtualAccounts: true },
    });

    if (!user) throw new Error('User not found');

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
   * Re-generate / Upgrade to Live CBN Providus Virtual Account for Sandbox Users
   */
  static async syncLiveVirtualAccount(userId: string, developerId?: string) {
    const user = await prisma.user.findUnique({
      where: { id: userId },
      include: { profile: true, developer: true, virtualAccounts: true },
    });

    if (!user) throw new Error('User not found');

    const isDeveloper = !!user.developer || !!developerId;
    let newAccountRes;

    if (isDeveloper && user.developer) {
      newAccountRes = await MapleradClient.createVirtualAccount({
        firstName: user.developer.companyName,
        lastName: 'Corporate',
        email: user.email,
        phone: user.phone || '08012345678',
        isCorporate: true,
        companyName: user.developer.companyName,
        rcNumber: user.developer.cacNumber,
      });
    } else {
      const nin = user.profile?.nin || '12345678901';
      newAccountRes = await MapleradClient.createVirtualAccount({
        firstName: user.firstName,
        lastName: user.lastName,
        email: user.email,
        phone: user.phone || '08012345678',
        nin,
      });
    }

    // Upsert VirtualAccount record
    let account = user.virtualAccounts?.[0];
    if (account) {
      account = await prisma.virtualAccount.update({
        where: { id: account.id },
        data: {
          accountNumber: newAccountRes.data.account_number,
          accountName: newAccountRes.data.account_name,
          bankName: newAccountRes.data.bank_name,
          fincraAccountId: newAccountRes.data.id,
          status: 'ACTIVE',
        },
      });
    } else {
      account = await prisma.virtualAccount.create({
        data: {
          userId: user.id,
          developerId: user.developer?.id,
          accountNumber: newAccountRes.data.account_number,
          accountName: newAccountRes.data.account_name,
          bankName: newAccountRes.data.bank_name,
          currency: 'NGN',
          accountType: isDeveloper ? 'CORPORATE' : 'INDIVIDUAL',
          status: 'ACTIVE',
          balance: 0,
          fincraAccountId: newAccountRes.data.id,
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

    return {
      success: true,
      message: 'Live Central Bank Providus account synchronized successfully!',
      virtualAccount: account,
    };
  }

  /**
   * Process incoming Maplerad/Fincra webhook when a buyer transfers money into their virtual account
   * Automatically captures deposit, credits escrow wallet, and updates milestone plans
   */
  static async handleWebhook(event: any) {
    const eventType = event.event || event.type || '';
    const isCollection = 
      eventType.includes('collection') || 
      eventType.includes('virtual_account') || 
      eventType.includes('credit') ||
      eventType.includes('deposit') ||
      eventType.includes('successful');

    if (isCollection) {
      const data = event.data || event;
      const accountNumber = data.account_number || data.accountNumber || data.virtual_account_number;
      const customerId = data.customer_id || data.customerId;
      const rawAmount = data.amount || data.settlement_amount || 0;
      const reference = data.reference || data.id || `MPR-DEP-${Date.now()}`;

      let amount = typeof rawAmount === 'string' ? parseFloat(rawAmount) : rawAmount;
      // If event explicitly came from real Maplerad webhook with currency NGN in kobo:
      if (data.amount_in_kobo) {
        amount = amount / 100;
      }

      let account = null;
      if (accountNumber) {
        account = await prisma.virtualAccount.findUnique({
          where: { accountNumber },
          include: { user: true, developer: true },
        });
      }

      if (!account && customerId) {
        account = await prisma.virtualAccount.findFirst({
          where: { fincraAccountId: customerId },
          include: { user: true, developer: true },
        });
      }

      if (account) {
        // 1. Credit virtual account balance
        const updatedVa = await prisma.virtualAccount.update({
          where: { id: account.id },
          data: { balance: { increment: amount } },
        });

        console.log(`[MAPLERAD AUTO-CAPTURE] Credited ₦${amount.toLocaleString()} to Account ${account.accountNumber} (${account.accountName})`);

        // 2. If user has an active purchase, auto-credit the next instalment!
        if (account.userId) {
          const activePurchase = await prisma.purchase.findFirst({
            where: { userId: account.userId, status: 'ACTIVE' },
            include: { property: true, projectUnit: true },
          });

          if (activePurchase) {
            const paidAmount = amount;
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
                paymentReference: reference,
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

            console.log(`[ESCROW AUTO-CAPTURE] Applied ₦${paidAmount.toLocaleString()} to Purchase ${activePurchase.id}. New Balance: ₦${newBalance.toLocaleString()}`);
          }
        }

        // 3. Send Payment Received Email to User
        const recipientEmail = account.user?.email || account.developer?.email;
        const recipientName = account.user ? `${account.user.firstName} ${account.user.lastName}` : (account.developer?.companyName || 'Valued Partner');
        if (recipientEmail) {
          ResendService.sendPaymentReceivedEmail(
            recipientEmail,
            recipientName,
            amount,
            updatedVa.balance,
            reference
          ).catch(console.warn);
        }

        // 4. Audit Log
        await AuditService.log({
          adminEmail: recipientEmail || 'system@hometrustng.com',
          action: 'PAYMENT_AUTO_CAPTURED',
          entityType: 'VIRTUAL_ACCOUNT',
          entityId: account.id,
          details: {
            accountNumber: account.accountNumber,
            amount,
            reference,
            provider: 'MAPLERAD',
          },
        });
      }
    }
    return { success: true };
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
