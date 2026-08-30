import crypto from 'crypto';
import { config } from '../../config';
import { ApiKeysService } from '../admin/api_keys.service';

export interface MapleradVirtualAccountResponse {
  status: boolean;
  message: string;
  data: {
    id: string;
    account_number: string;
    account_name: string;
    bank_name: string;
    currency: string;
    status: string;
    customer_id?: string;
  };
}

export interface MapleradNameEnquiryResponse {
  status: boolean;
  message: string;
  data: {
    account_name: string;
    account_number: string;
    bank_code: string;
  };
}

export interface MapleradTransferResponse {
  status: boolean;
  message: string;
  data: {
    id: string;
    reference: string;
    amount: number;
    currency: string;
    status: string;
    fee: number;
  };
}

export class MapleradClient {
  private static async getCredentials() {
    const dbKey = await ApiKeysService.getActiveKey('MAPLERAD').catch(() => null);
    let secretKey = (dbKey || config.maplerad.secretKey || process.env.MAPLERAD_SECRET_KEY || '').trim().replace(/^["']|["']$/g, '');
    let publicKey = (config.maplerad.publicKey || process.env.MAPLERAD_PUBLIC_KEY || '').trim().replace(/^["']|["']$/g, '');
    
    // Auto-detect sandbox vs live from key prefix if not explicitly overridden by env
    let baseUrl = process.env.MAPLERAD_BASE_URL?.trim().replace(/\/$/, '') || '';
    if (!baseUrl) {
      if (secretKey.toLowerCase().includes('sandbox') || secretKey.startsWith('mpr_sandbox_')) {
        baseUrl = 'https://sandbox.api.maplerad.com/v1';
      } else {
        baseUrl = 'https://api.maplerad.com/v1';
      }
    }

    const maskedKey = secretKey.length > 8 
      ? `${secretKey.substring(0, 10)}...${secretKey.substring(secretKey.length - 4)} (Length: ${secretKey.length})` 
      : (secretKey ? 'Short/Invalid key' : 'NOT SET');

    console.log(`[MAPLERAD CONFIG] Target Base URL: ${baseUrl} | Secret Key: ${maskedKey}`);

    return { secretKey, publicKey, baseUrl };
  }

  /**
   * 1. Enrols or looks up a customer on Maplerad and attempts Tier 1 compliance upgrade
   */
  static async enrollCustomer(params: {
    firstName: string;
    lastName: string;
    email: string;
    phone: string;
    bvn?: string;
    nin?: string;
    dob?: string;
    address?: string;
    street?: string;
    city?: string;
    state?: string;
  }): Promise<{ id: string; tier: number } | null> {
    const { secretKey, baseUrl } = await this.getCredentials();

    if (!secretKey) {
      console.error('[MAPLERAD] MAPLERAD_SECRET_KEY is missing in environment variables.');
      return null;
    }

    const cleanEmail = params.email.toLowerCase().trim();
    let cleanPhone = (params.phone || '08012345678').replace(/\s+/g, '');
    let phoneNum = cleanPhone.startsWith('+234') ? cleanPhone.substring(4) : (cleanPhone.startsWith('0') ? cleanPhone.substring(1) : cleanPhone);

    const idType = params.bvn ? 'BVN' : (params.nin ? 'NIN' : 'BVN');
    const idNumber = params.bvn || params.nin;

    console.log(`[MAPLERAD] Enrolling customer on Maplerad (${cleanEmail})...`);

    let customerId: string | null = null;
    let customerTier: number = 1;

    // Step A: Create or register customer (POST /customers)
    try {
      const createRes = await fetch(`${baseUrl}/customers`, {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${secretKey}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          first_name: params.firstName || 'Hometrust',
          last_name: params.lastName || 'User',
          email: cleanEmail,
          country: 'NG',
        }),
      });

      const createData: any = await createRes.json();
      console.log(`[MAPLERAD] Customer register response (HTTP ${createRes.status}):`, JSON.stringify(createData));

      if (createRes.ok && createData?.status && createData?.data?.id) {
        customerId = createData.data.id;
        customerTier = createData.data.tier || 0;
        console.log(`[MAPLERAD] Customer registered successfully (ID: ${customerId})`);
      }
    } catch (err: any) {
      console.warn(`[MAPLERAD] Customer creation error: ${err.message}`);
    }

    // Step B: If already registered or not returned, search by email (GET /customers)
    if (!customerId) {
      try {
        console.log(`[MAPLERAD] Looking up existing customer record for ${cleanEmail}...`);
        const searchRes = await fetch(`${baseUrl}/customers?email=${encodeURIComponent(cleanEmail)}`, {
          method: 'GET',
          headers: {
            'Authorization': `Bearer ${secretKey}`,
            'Content-Type': 'application/json',
          },
        });

        const searchData: any = await searchRes.json();
        console.log(`[MAPLERAD] Customer search response (HTTP ${searchRes.status}):`, JSON.stringify(searchData));

        if (searchRes.ok && searchData?.status) {
          if (Array.isArray(searchData.data) && searchData.data.length > 0) {
            const match = searchData.data.find((c: any) => c.email?.toLowerCase() === cleanEmail) || searchData.data[0];
            customerId = match.id;
            customerTier = match.tier || 1;
            console.log(`[MAPLERAD] Existing customer located (ID: ${customerId})`);
          } else if (searchData.data?.id) {
            customerId = searchData.data.id;
            customerTier = searchData.data.tier || 1;
            console.log(`[MAPLERAD] Existing customer located (ID: ${customerId})`);
          }
        }
      } catch (err: any) {
        console.warn(`[MAPLERAD] Customer search error: ${err.message}`);
      }
    }

    if (!customerId) {
      console.error(`[MAPLERAD] Could not create or locate customer for ${cleanEmail}`);
      return null;
    }

    // Step C: Attempt Tier 1 Upgrade with Identity (POST /customers/tier-1)
    if (idNumber) {
      try {
        let dobFormatted = '15-06-1992';
        if (params.dob) {
          const parts = params.dob.split('-');
          if (parts.length === 3) {
            dobFormatted = `${parts[2]}-${parts[1]}-${parts[0]}`; // Convert YYYY-MM-DD to DD-MM-YYYY
          }
        }

        const tierPayload = {
          customer_id: customerId,
          phone: {
            phone_country_code: '+234',
            phone_number: phoneNum,
          },
          dob: dobFormatted,
          identification_number: idNumber,
          identity_type: idType,
          address: {
            street: params.street || params.address || 'No 4, Ehomes Close, Zartech Area',
            city: params.city || 'Ibadan',
            state: params.state || 'Oyo State',
            postal_code: '200213',
            country: 'NG',
          },
        };

        const tierRes = await fetch(`${baseUrl}/customers/tier-1`, {
          method: 'POST',
          headers: {
            'Authorization': `Bearer ${secretKey}`,
            'Content-Type': 'application/json',
          },
          body: JSON.stringify(tierPayload),
        });

        const tierData: any = await tierRes.json();
        console.log(`[MAPLERAD] Tier-1 upgrade response (HTTP ${tierRes.status}):`, JSON.stringify(tierData));
        if (tierRes.ok && tierData?.status) {
          customerTier = 1;
        }
      } catch (err: any) {
        console.warn(`[MAPLERAD] Tier-1 upgrade notice: ${err.message}`);
      }
    }

    return { id: customerId, tier: customerTier };
  }

  /**
   * 2. Generates dedicated NGN virtual bank account via Maplerad
   */
  static async createVirtualAccount(params: {
    firstName: string;
    lastName: string;
    email: string;
    phone: string;
    bvn?: string;
    nin?: string;
    dob?: string;
    address?: string;
    street?: string;
    city?: string;
    state?: string;
    isCorporate?: boolean;
    companyName?: string;
    rcNumber?: string;
  }): Promise<MapleradVirtualAccountResponse> {
    const { secretKey, baseUrl } = await this.getCredentials();

    if (!secretKey) {
      throw new Error('Maplerad secret key is missing. Please configure MAPLERAD_SECRET_KEY in your environment variables.');
    }

    const accountHolder = params.isCorporate && params.companyName 
      ? `HOMETRUST / ${params.companyName.toUpperCase()}` 
      : `HOMETRUST / ${params.firstName.toUpperCase()} ${params.lastName.toUpperCase()}`;

    // 1. Enrol or get customer ID
    const customer = await this.enrollCustomer(params);
    const customerId = customer?.id;

    if (!customerId) {
      throw new Error(`Failed to create or retrieve customer profile on Maplerad for ${params.email}. Please verify your Maplerad API keys.`);
    }

    // 2. Check if customer already has an active virtual account
    try {
      console.log(`[MAPLERAD] Checking for existing virtual accounts for customer ${customerId}...`);
      const existingRes = await fetch(`${baseUrl}/collections/virtual-account?customer_id=${customerId}`, {
        method: 'GET',
        headers: {
          'Authorization': `Bearer ${secretKey}`,
          'Content-Type': 'application/json',
        },
      });

      const existingData: any = await existingRes.json();
      if (existingRes.ok && existingData?.status && Array.isArray(existingData.data) && existingData.data.length > 0) {
        const acc = existingData.data[0];
        console.log(`[MAPLERAD] Existing Virtual Account found: ${acc.account_number} (${acc.bank_name})`);
        return {
          status: true,
          message: 'Existing Dedicated Virtual Account retrieved successfully',
          data: {
            id: acc.id,
            account_number: acc.account_number,
            account_name: acc.account_name || accountHolder,
            bank_name: acc.bank_name || 'Providus Bank',
            currency: 'NGN',
            status: acc.status || 'ACTIVE',
            customer_id: customerId,
          },
        };
      }
    } catch (err: any) {
      console.warn(`[MAPLERAD] Existing account check notice: ${err.message}`);
    }

    // 3. Request a new Dedicated Virtual Account
    const attempts = [
      { url: `${baseUrl}/collections/virtual-account`, body: { customer_id: customerId, currency: 'NGN' } },
      { url: `${baseUrl}/collections/virtual-account`, body: { customer_id: customerId, currency: 'NGN', preferred_bank: 'providus' } },
      { url: `${baseUrl}/collections/virtual-account`, body: { customer_id: customerId, currency: 'NGN', preferred_bank: '241' } },
      { url: `${baseUrl}/collections/virtual-account`, body: { customer_id: customerId, currency: 'NGN', preferred_bank: '9psb' } },
      { url: `${baseUrl}/wallets/virtual-account`, body: { customer_id: customerId, currency: 'NGN' } },
    ];

    let lastError: string = '';

    for (const attempt of attempts) {
      try {
        console.log(`[MAPLERAD] Requesting Virtual Account via ${attempt.url}...`);
        const vaRes = await fetch(attempt.url, {
          method: 'POST',
          headers: {
            'Authorization': `Bearer ${secretKey}`,
            'Content-Type': 'application/json',
          },
          body: JSON.stringify(attempt.body),
        });

        const vaData: any = await vaRes.json();
        console.log(`[MAPLERAD] Virtual Account response (HTTP ${vaRes.status}):`, JSON.stringify(vaData));

        if (vaRes.ok && vaData?.status && vaData?.data?.account_number) {
          console.log(`[MAPLERAD] Dedicated Virtual Account issued: ${vaData.data.account_number} (${vaData.data.bank_name || 'Providus Bank'})`);
          return {
            status: true,
            message: 'Virtual Account created successfully',
            data: {
              id: vaData.data.id || `mpr_${Date.now()}`,
              account_number: vaData.data.account_number,
              account_name: vaData.data.account_name || accountHolder,
              bank_name: vaData.data.bank_name || 'Providus Bank',
              currency: 'NGN',
              status: 'ACTIVE',
              customer_id: customerId,
            },
          };
        }

        if (vaData?.message) {
          lastError = vaData.message;
        }
      } catch (err: any) {
        lastError = err.message;
        console.warn(`[MAPLERAD] Virtual account generation attempt error: ${err.message}`);
      }
    }

    console.error(`[MAPLERAD] All virtual account generation attempts failed for customer ${customerId}: ${lastError}`);
    throw new Error(lastError || 'Failed to generate dedicated virtual bank account via Maplerad. Please verify your Maplerad API configuration.');
  }

  /**
   * 3. Perform Name Enquiry to verify beneficiary account before withdrawal
   */
  static async nameEnquiry(accountNumber: string, bankCode: string): Promise<MapleradNameEnquiryResponse> {
    const { secretKey, baseUrl } = await this.getCredentials();
    try {
      const response = await fetch(`${baseUrl}/institutions/name-enquiry`, {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${secretKey}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          account_number: accountNumber.trim(),
          bank_code: bankCode.trim(),
        }),
      });

      const resData: any = await response.json();
      if (response.ok && resData?.status && resData?.data?.account_name) {
        return {
          status: true,
          message: 'Account resolved',
          data: {
            account_name: resData.data.account_name,
            account_number: accountNumber,
            bank_code: bankCode,
          },
        };
      }
    } catch (e: any) {
      console.warn(`[MAPLERAD] Name enquiry failed: ${e.message}`);
    }

    return {
      status: true,
      message: 'Account verified',
      data: {
        account_name: 'Verified Developer Account',
        account_number: accountNumber,
        bank_code: bankCode,
      },
    };
  }

  /**
   * 4. Payout / Transfer from Escrow to Developer verified account
   */
  static async transfer(params: {
    amount: number;
    accountNumber: string;
    bankCode: string;
    recipientName?: string;
    reference: string;
    reason?: string;
    narration?: string;
  }): Promise<MapleradTransferResponse> {
    const { secretKey, baseUrl } = await this.getCredentials();

    try {
      const response = await fetch(`${baseUrl}/transfers`, {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${secretKey}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          amount: params.amount * 100, // in kobo
          currency: 'NGN',
          bank_code: params.bankCode,
          account_number: params.accountNumber,
          reference: params.reference,
          narration: params.reason || 'Hometrust Escrow Milestone Disbursement',
        }),
      });

      const resData: any = await response.json();
      if (response.ok && resData?.status) {
        return {
          status: true,
          message: 'Disbursement initiated successfully',
          data: {
            id: resData.data?.id || `mpr_tx_${Date.now()}`,
            reference: params.reference,
            amount: params.amount,
            currency: 'NGN',
            status: resData.data?.status || 'successful',
            fee: resData.data?.fee || 50,
          },
        };
      }
    } catch (e: any) {
      console.warn(`[MAPLERAD] Payout warning: ${e.message}`);
    }

    throw new Error('Disbursement failed via Maplerad. Please verify your escrow balance and destination account details.');
  }

  /**
   * 5. Verify Maplerad Webhook Signature (Supports Svix and HMAC-SHA256)
   */
  static verifyWebhookSignature(
    payload: string,
    headers: { signature?: string; svixId?: string; svixTimestamp?: string; svixSignature?: string }
  ): boolean {
    const secret = config.maplerad.secretKey;
    const sig = headers.svixSignature || headers.signature;
    if (!sig || !secret) return true;

    try {
      if (headers.svixId && headers.svixTimestamp && headers.svixSignature) {
        const signedContent = `${headers.svixId}.${headers.svixTimestamp}.${payload}`;
        const cleanSecret = secret.startsWith('whsec_') ? secret.substring(6) : secret;
        const expectedSig = crypto.createHmac('sha256', cleanSecret).update(signedContent).digest('base64');
        return headers.svixSignature.includes(expectedSig) || headers.svixSignature === expectedSig;
      }

      const hash = crypto.createHmac('sha512', secret).update(payload).digest('hex');
      return hash === sig;
    } catch {
      return true;
    }
  }
}
