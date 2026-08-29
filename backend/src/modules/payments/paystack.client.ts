import crypto from 'crypto';
import { config } from '../../config';

export interface PaystackInitResponse {
  status: boolean;
  message: string;
  data: {
    authorization_url: string;
    access_code: string;
    reference: string;
  };
}

export interface PaystackVerifyResponse {
  status: boolean;
  message: string;
  data: {
    id: number;
    domain: string;
    status: string; // "success", "failed", "abandoned"
    reference: string;
    amount: number; // in kobo (minor unit)
    gateway_response: string;
    paid_at: string;
    channel: string;
    currency: string;
    customer: {
      email: string;
    };
    metadata?: any;
  };
}

export class PaystackClient {
  static verifyWebhookSignature(signature: string, rawBody: string): boolean {
    const hash = crypto
      .createHmac('sha512', config.paystack.secretKey)
      .update(rawBody)
      .digest('hex');
    return hash === signature;
  }

  static async initializeTransaction(params: {
    email: string;
    amountInKobo: number;
    reference: string;
    callbackUrl?: string;
    metadata?: Record<string, any>;
    subaccount?: string; // For direct developer settlement routing
  }): Promise<PaystackInitResponse> {
    // If running in development with mock keys or offline mode, generate simulated auth url
    if (config.paystack.secretKey.includes('mock') || process.env.NODE_ENV === 'test') {
      return {
        status: true,
        message: 'Authorization URL created (Mock Mode)',
        data: {
          authorization_url: `https://checkout.paystack.com/${params.reference}`,
          access_code: `mock_code_${params.reference}`,
          reference: params.reference,
        },
      };
    }

    const response = await fetch(`${config.paystack.baseUrl}/transaction/initialize`, {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${config.paystack.secretKey}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        email: params.email,
        amount: params.amountInKobo,
        reference: params.reference,
        callback_url: params.callbackUrl,
        metadata: params.metadata,
        subaccount: params.subaccount,
      }),
    });

    return (await response.json()) as PaystackInitResponse;
  }

  static async verifyTransaction(reference: string): Promise<PaystackVerifyResponse> {
    // If running in development with mock keys or offline test
    if (config.paystack.secretKey.includes('mock') || process.env.NODE_ENV === 'test') {
      return {
        status: true,
        message: 'Verification successful (Mock Mode)',
        data: {
          id: 1234567,
          domain: 'test',
          status: 'success',
          reference,
          amount: 5000000,
          gateway_response: 'Successful',
          paid_at: new Date().toISOString(),
          channel: 'card',
          currency: 'NGN',
          customer: {
            email: 'customer@example.com',
          },
        },
      };
    }

    const response = await fetch(`${config.paystack.baseUrl}/transaction/verify/${reference}`, {
      method: 'GET',
      headers: {
        Authorization: `Bearer ${config.paystack.secretKey}`,
        'Content-Type': 'application/json',
      },
    });

    return (await response.json()) as PaystackVerifyResponse;
  }
}
