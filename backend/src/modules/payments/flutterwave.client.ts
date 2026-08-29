import crypto from 'crypto';
import { config } from '../../config';

export interface FlutterwaveInitResponse {
  status: string;
  message: string;
  data: {
    link: string;
  };
}

export interface FlutterwaveVerifyResponse {
  status: string;
  message: string;
  data: {
    id: number;
    tx_ref: string;
    flw_ref: string;
    amount: number;
    currency: string;
    charged_amount: number;
    status: string; // "successful", "failed"
    payment_type: string;
    customer: {
      id: number;
      name: string;
      phone_number: string;
      email: string;
    };
  };
}

export class FlutterwaveClient {
  static verifyWebhookSignature(signature: string, secretHash: string): boolean {
    return signature === secretHash;
  }

  static async initializePayment(params: {
    tx_ref: string;
    amount: number;
    currency?: string;
    redirect_url: string;
    customer: {
      email: string;
      phonenumber?: string;
      name: string;
    };
    customizations?: {
      title: string;
      description?: string;
      logo?: string;
    };
    secretKey?: string;
  }): Promise<FlutterwaveInitResponse> {
    const key = params.secretKey || process.env.FLUTTERWAVE_SECRET_KEY || 'FLWSECK_TEST-mock-key';

    if (key.includes('mock') || process.env.NODE_ENV === 'test') {
      return {
        status: 'success',
        message: 'Hosted link created (Mock Mode)',
        data: {
          link: `https://checkout.flutterwave.com/v3/hosted/pay/${params.tx_ref}`,
        },
      };
    }

    const response = await fetch('https://api.flutterwave.com/v3/payments', {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${key}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        tx_ref: params.tx_ref,
        amount: params.amount,
        currency: params.currency || 'NGN',
        redirect_url: params.redirect_url,
        customer: params.customer,
        customizations: params.customizations || {
          title: 'Hometrust Real Estate Payment',
          description: 'Verified property and verification fees payment',
        },
      }),
    });

    return (await response.json()) as FlutterwaveInitResponse;
  }

  static async verifyTransaction(transactionId: string, secretKey?: string): Promise<FlutterwaveVerifyResponse> {
    const key = secretKey || process.env.FLUTTERWAVE_SECRET_KEY || 'FLWSECK_TEST-mock-key';

    if (key.includes('mock') || process.env.NODE_ENV === 'test') {
      return {
        status: 'success',
        message: 'Transaction verified (Mock Mode)',
        data: {
          id: 123456,
          tx_ref: 'EV-FLW-TX-001',
          flw_ref: 'FLW-MOCK-REF-99',
          amount: 5000000,
          currency: 'NGN',
          charged_amount: 5000000,
          status: 'successful',
          payment_type: 'card',
          customer: {
            id: 8821,
            name: 'Buyer Name',
            phone_number: '+2348012345678',
            email: 'buyer@example.com',
          },
        },
      };
    }

    const response = await fetch(`https://api.flutterwave.com/v3/transactions/${transactionId}/verify`, {
      method: 'GET',
      headers: {
        Authorization: `Bearer ${key}`,
        'Content-Type': 'application/json',
      },
    });

    return (await response.json()) as FlutterwaveVerifyResponse;
  }
}
