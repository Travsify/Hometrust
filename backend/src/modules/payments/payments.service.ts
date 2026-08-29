import { prisma } from '../../utils/prisma';
import { PaystackClient } from './paystack.client';

export interface InitializePaymentParams {
  userId: string;
  userEmail: string;
  amount: number; // in NGN
  purpose: 'INITIAL_DEPOSIT' | 'INSTALMENT' | 'VERIFICATION_FEE' | 'LEGAL_DOCUMENT_FEE' | 'SERVICE_FEE';
  purchaseId?: string;
  verificationRequestId?: string;
  legalRequestId?: string;
  developerId?: string;
  callbackUrl?: string;
}

export class PaymentsService {
  static async calculateFees(amount: number, purpose: string) {
    // Check if there is an active fee config
    let platformFee = 5000;
    if (purpose === 'VERIFICATION_FEE' || purpose === 'LEGAL_DOCUMENT_FEE') {
      platformFee = 0; // Fee is already the core service amount
    }

    // Paystack standard fee: 1.5% + N100 (capped at N2000 for NGN transactions)
    const rawProcessingFee = (amount * 0.015) + (amount > 2500 ? 100 : 0);
    const processingFee = Math.min(rawProcessingFee, 2000);

    const totalAmount = amount + platformFee + processingFee;

    return {
      amount,
      platformFee,
      processingFee: Math.round(processingFee * 100) / 100,
      totalAmount: Math.round(totalAmount * 100) / 100,
    };
  }

  static async initializePayment(params: InitializePaymentParams) {
    const feeBreakdown = await this.calculateFees(params.amount, params.purpose);
    const paymentRef = `EV-PAY-${Date.now()}-${Math.random().toString(36).substring(2, 7).toUpperCase()}`;

    const payment = await prisma.payment.create({
      data: {
        paymentReference: paymentRef,
        userId: params.userId,
        purchaseId: params.purchaseId,
        verificationRequestId: params.verificationRequestId,
        legalRequestId: params.legalRequestId,
        developerId: params.developerId,
        amount: feeBreakdown.amount,
        platformFee: feeBreakdown.platformFee,
        processingFee: feeBreakdown.processingFee,
        totalAmount: feeBreakdown.totalAmount,
        currency: 'NGN',
        purpose: params.purpose,
        status: 'PENDING',
      },
    });

    const amountInKobo = Math.round(feeBreakdown.totalAmount * 100);

    const paystackRes = await PaystackClient.initializeTransaction({
      email: params.userEmail,
      amountInKobo,
      reference: paymentRef,
      callbackUrl: params.callbackUrl,
      metadata: {
        paymentId: payment.id,
        purpose: params.purpose,
        purchaseId: params.purchaseId,
        userId: params.userId,
      },
    });

    if (!paystackRes.status) {
      throw new Error(paystackRes.message || 'Failed to initialize Paystack payment');
    }

    return {
      paymentId: payment.id,
      paymentReference: paymentRef,
      totalAmount: feeBreakdown.totalAmount,
      feeBreakdown,
      authorizationUrl: paystackRes.data.authorization_url,
      accessCode: paystackRes.data.access_code,
    };
  }

  static async verifyPayment(reference: string) {
    const payment = await prisma.payment.findUnique({
      where: { paymentReference: reference },
      include: {
        user: true,
        purchase: {
          include: {
            paymentPlan: true,
          },
        },
      },
    });

    if (!payment) {
      throw new Error(`Payment with reference ${reference} not found`);
    }

    if (payment.status === 'SUCCESS') {
      return payment; // Already verified (idempotent)
    }

    const paystackRes = await PaystackClient.verifyTransaction(reference);

    if (!paystackRes.status || paystackRes.data.status !== 'success') {
      await prisma.payment.update({
        where: { id: payment.id },
        data: { status: 'FAILED' },
      });
      throw new Error('Payment verification failed on Paystack');
    }

    const receiptNumber = `RCP-${Date.now().toString(36).toUpperCase()}-${Math.floor(1000 + Math.random() * 9000)}`;

    const updatedPayment = await prisma.payment.update({
      where: { id: payment.id },
      data: {
        status: 'SUCCESS',
        paystackReference: reference,
        paystackChannel: paystackRes.data.channel,
        paidAt: new Date(paystackRes.data.paid_at || Date.now()),
        verifiedAt: new Date(),
        receiptNumber,
        rawWebhookData: JSON.stringify(paystackRes.data),
      },
    });

    // 1. If this was a Purchase instalment or initial deposit, update purchase ledger
    if (payment.purchaseId && payment.purchase) {
      const newAmountPaid = payment.purchase.amountPaid + payment.amount;
      const newOutstandingBalance = Math.max(0, payment.purchase.totalPrice - newAmountPaid);
      const isFullyPaid = newOutstandingBalance <= 0;

      // Calculate next due date (30 days ahead if not fully paid)
      const nextDueDate = new Date();
      nextDueDate.setDate(nextDueDate.getDate() + 30);

      await prisma.purchase.update({
        where: { id: payment.purchaseId },
        data: {
          amountPaid: newAmountPaid,
          outstandingBalance: newOutstandingBalance,
          status: isFullyPaid ? 'COMPLETED' : 'ACTIVE',
          nextPaymentDueDate: isFullyPaid ? null : nextDueDate,
        },
      });
    }

    // 2. If this was a Verification request fee, update verification request
    if (payment.verificationRequestId) {
      await prisma.verificationRequest.update({
        where: { id: payment.verificationRequestId },
        data: {
          isPaid: true,
          status: 'PAYMENT_CONFIRMED',
        },
      });
    }

    // 3. If this was a Legal request fee, update legal request
    if (payment.legalRequestId) {
      await prisma.legalRequest.update({
        where: { id: payment.legalRequestId },
        data: {
          isPaid: true,
          status: 'PAYMENT_CONFIRMED',
        },
      });
    }

    // Send in-app notification
    await prisma.notification.create({
      data: {
        userId: payment.userId,
        title: 'Payment Successful',
        message: `Your payment of ₦${payment.totalAmount.toLocaleString()} (${payment.purpose}) was successfully confirmed. Receipt: ${receiptNumber}`,
        type: 'PAYMENT',
      },
    });

    return updatedPayment;
  }

  static async getUserPayments(userId: string) {
    return prisma.payment.findMany({
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
    });
  }

  static async getPaymentDetails(idOrRef: string) {
    const payment = await prisma.payment.findFirst({
      where: {
        OR: [{ id: idOrRef }, { paymentReference: idOrRef }],
      },
      include: {
        user: {
          select: {
            id: true,
            firstName: true,
            lastName: true,
            email: true,
            phone: true,
          },
        },
        purchase: {
          include: {
            property: true,
            projectUnit: true,
          },
        },
        developer: true,
      },
    });

    if (!payment) {
      throw new Error('Payment record not found');
    }

    return payment;
  }
}
