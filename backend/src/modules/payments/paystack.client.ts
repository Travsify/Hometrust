import crypto from 'crypto';
import { config } from '../../config';
import { ApiKeysService } from '../admin/api_keys.service';

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

export interface PaystackDedicatedAccountResponse {
  status: boolean;
  message: string;
  data: {
    id?: number | string;
    bank: {
      name: string;
      id: number;
      slug: string;
    };
    account_name: string;
    account_number: string;
    assigned: boolean;
    currency: string;
    active?: boolean;
    customer_code?: string;
  };
}

export class PaystackClient {
  private static async getSecretKey(): Promise<string> {
    const dbKey = await ApiKeysService.getActiveKey('PAYSTACK').catch(() => null);
    const key = (dbKey || config.paystack.secretKey || process.env.PAYSTACK_SECRET_KEY || '')
      .trim()
      .replace(/^["']|["']$/g, '');
    return key;
  }

  static verifyWebhookSignature(signature: string, rawBody: string): boolean {
    const secretKey = config.paystack.secretKey || process.env.PAYSTACK_SECRET_KEY || '';
    if (!secretKey) return true;
    const hash = crypto
      .createHmac('sha512', secretKey)
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
    subaccount?: string;
  }): Promise<PaystackInitResponse> {
    const secretKey = await this.getSecretKey();

    const response = await fetch(`${config.paystack.baseUrl}/transaction/initialize`, {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${secretKey}`,
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
    const secretKey = await this.getSecretKey();

    const response = await fetch(`${config.paystack.baseUrl}/transaction/verify/${reference}`, {
      method: 'GET',
      headers: {
        Authorization: `Bearer ${secretKey}`,
        'Content-Type': 'application/json',
      },
    });

    return (await response.json()) as PaystackVerifyResponse;
  }

  /**
   * Generates a Dedicated Virtual Bank Account (Dedicated NUBAN) for buyers/developers
   */
  static async createDedicatedAccount(params: {
    customerEmail: string;
    firstName: string;
    lastName: string;
    phone?: string;
    bvn?: string;
    nin?: string;
    isCorporate?: boolean;
    companyName?: string;
  }): Promise<PaystackDedicatedAccountResponse> {
    const secretKey = await this.getSecretKey();
    const cleanEmail = params.customerEmail.toLowerCase().trim();
    let phoneNum = (params.phone || '09061518843').replace(/\s+/g, '');
    if (phoneNum.startsWith('+234')) {
      phoneNum = '0' + phoneNum.substring(4);
    }

    const firstName = (params.isCorporate && params.companyName ? params.companyName : params.firstName || 'Hometrust').trim();
    const lastName = (params.isCorporate ? 'Ltd' : params.lastName || 'User').trim();

    console.log(`[PAYSTACK DVA] Creating/Updating Customer on Paystack (${cleanEmail}, ${phoneNum})...`);

    let customerCode: string = '';

    // Step 1: Create or fetch customer on Paystack
    try {
      const custRes = await fetch(`${config.paystack.baseUrl}/customer`, {
        method: 'POST',
        headers: {
          Authorization: `Bearer ${secretKey}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          email: cleanEmail,
          first_name: firstName,
          last_name: lastName,
          phone: phoneNum,
        }),
      });

      const custData: any = await custRes.json();
      console.log(`[PAYSTACK DVA] Customer response (HTTP ${custRes.status}):`, JSON.stringify(custData));

      if (custData?.status && custData?.data?.customer_code) {
        customerCode = custData.data.customer_code;
      }
    } catch (err: any) {
      console.warn(`[PAYSTACK DVA] Customer creation warning:`, err.message);
    }

    // If customer already exists, fetch customer details
    if (!customerCode) {
      try {
        const fetchCustRes = await fetch(`${config.paystack.baseUrl}/customer/${encodeURIComponent(cleanEmail)}`, {
          headers: { Authorization: `Bearer ${secretKey}` },
        });
        const fetchCustData: any = await fetchCustRes.json();
        if (fetchCustData?.status && fetchCustData?.data?.customer_code) {
          customerCode = fetchCustData.data.customer_code;
          // Update phone number if missing
          await fetch(`${config.paystack.baseUrl}/customer/${customerCode}`, {
            method: 'PUT',
            headers: {
              Authorization: `Bearer ${secretKey}`,
              'Content-Type': 'application/json',
            },
            body: JSON.stringify({
              first_name: firstName,
              last_name: lastName,
              phone: phoneNum,
            }),
          });
        }
      } catch (err: any) {
        console.warn(`[PAYSTACK DVA] Customer fetch warning:`, err.message);
      }
    }

    if (!customerCode) {
      throw new Error(`Failed to create or find Paystack customer profile for ${cleanEmail}`);
    }

    // Step 2: Check if customer already has an active dedicated virtual account
    try {
      console.log(`[PAYSTACK DVA] Checking for existing dedicated accounts for customer ${customerCode}...`);
      const existingRes = await fetch(`${config.paystack.baseUrl}/dedicated_account?customer=${customerCode}`, {
        headers: { Authorization: `Bearer ${secretKey}` },
      });
      const existingData: any = await existingRes.json();
      if (existingData?.status && Array.isArray(existingData.data) && existingData.data.length > 0) {
        const acc = existingData.data[0];
        console.log(`[PAYSTACK DVA] Existing Dedicated Account found: ${acc.account_number} (${acc.bank?.name})`);
        return {
          status: true,
          message: 'Existing Dedicated Account retrieved successfully',
          data: {
            id: acc.id,
            bank: {
              name: acc.bank?.name || 'Wema Bank',
              id: acc.bank?.id || 20,
              slug: acc.bank?.slug || 'wema-bank',
            },
            account_name: acc.account_name || `HOMETRUST / ${firstName} ${lastName}`,
            account_number: acc.account_number,
            assigned: true,
            currency: 'NGN',
            active: acc.active,
            customer_code: customerCode,
          },
        };
      }
    } catch (err: any) {
      console.warn(`[PAYSTACK DVA] Existing check warning:`, err.message);
    }

    // Step 3: Assign Dedicated NUBAN Account (Try Wema Bank first, then Titan Trust)
    const bankProviders = ['wema-bank', 'titan-paystack'];
    let lastError = '';

    for (const provider of bankProviders) {
      try {
        console.log(`[PAYSTACK DVA] Requesting Dedicated NUBAN with provider ${provider}...`);
        const assignRes = await fetch(`${config.paystack.baseUrl}/dedicated_account`, {
          method: 'POST',
          headers: {
            Authorization: `Bearer ${secretKey}`,
            'Content-Type': 'application/json',
          },
          body: JSON.stringify({
            customer: customerCode,
            preferred_bank: provider,
            first_name: firstName,
            last_name: lastName,
            phone: phoneNum,
          }),
        });

        const assignData: any = await assignRes.json();
        console.log(`[PAYSTACK DVA] Assignment response (HTTP ${assignRes.status}):`, JSON.stringify(assignData));

        if (assignRes.ok && assignData?.status && assignData?.data?.account_number) {
          console.log(`[PAYSTACK DVA] Dedicated Virtual Account issued: ${assignData.data.account_number} (${assignData.data.bank?.name})`);
          return {
            status: true,
            message: 'Dedicated Virtual Account created successfully',
            data: {
              id: assignData.data.id,
              bank: {
                name: assignData.data.bank?.name || (provider === 'wema-bank' ? 'Wema Bank' : 'Paystack-Titan'),
                id: assignData.data.bank?.id || (provider === 'wema-bank' ? 20 : 629),
                slug: assignData.data.bank?.slug || provider,
              },
              account_name: assignData.data.account_name || `HOMETRUST / ${firstName} ${lastName}`,
              account_number: assignData.data.account_number,
              assigned: true,
              currency: 'NGN',
              active: true,
              customer_code: customerCode,
            },
          };
        }

        if (assignData?.message) {
          lastError = assignData.message;
        }
      } catch (err: any) {
        lastError = err.message;
        console.warn(`[PAYSTACK DVA] Assignment error with ${provider}:`, err.message);
      }
    }

    throw new Error(lastError || 'Failed to generate a dedicated virtual bank account via Paystack DVA.');
  }
}
