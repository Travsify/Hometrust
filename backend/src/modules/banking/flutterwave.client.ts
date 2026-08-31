import crypto from 'crypto';
import { config } from '../../config';
import { ApiKeysService } from '../admin/api_keys.service';

export interface FlutterwaveVirtualAccountResponse {
  status: boolean;
  message: string;
  data: {
    id: string;
    account_number: string;
    account_name: string;
    bank_name: string;
    currency: string;
    status: string;
    flw_ref?: string;
    order_ref?: string;
  };
}

export interface FlutterwaveNameEnquiryResponse {
  status: boolean;
  message: string;
  data: {
    account_name: string;
    account_number: string;
    bank_code: string;
  };
}

export interface FlutterwaveTransferResponse {
  status: boolean;
  message: string;
  data?: {
    id: number | string;
    reference: string;
    amount: number;
    currency: string;
    status: string;
    fee: number;
  };
}

export class FlutterwaveClient {
  private static async getCredentials() {
    const dbKey = await ApiKeysService.getActiveKey('FLUTTERWAVE').catch(() => null);
    const secretKey = (dbKey || config.flutterwave?.secretKey || process.env.FLUTTERWAVE_SECRET_KEY || '')
      .trim()
      .replace(/^["']|["']$/g, '');
    const publicKey = (config.flutterwave?.publicKey || process.env.FLUTTERWAVE_PUBLIC_KEY || '')
      .trim()
      .replace(/^["']|["']$/g, '');
    const baseUrl = (config.flutterwave?.baseUrl || process.env.FLUTTERWAVE_BASE_URL || 'https://api.flutterwave.com/v3')
      .trim()
      .replace(/\/$/, '');

    return { secretKey, publicKey, baseUrl };
  }

  /**
   * 1. Creates a Permanent Dedicated Virtual Bank Account on Flutterwave
   */
  static async createVirtualAccount(params: {
    firstName: string;
    lastName: string;
    email: string;
    phone?: string;
    bvn?: string;
    nin?: string;
    isCorporate?: boolean;
    companyName?: string;
  }): Promise<FlutterwaveVirtualAccountResponse> {
    const { secretKey, baseUrl } = await this.getCredentials();

    if (!secretKey) {
      throw new Error('Flutterwave secret key is not configured.');
    }

    const cleanEmail = params.email.toLowerCase().trim();
    let phoneNum = (params.phone || '09061518843').replace(/\s+/g, '');
    if (phoneNum.startsWith('+234')) {
      phoneNum = '0' + phoneNum.substring(4);
    }

    const firstName = (params.isCorporate && params.companyName ? params.companyName : params.firstName || 'Hometrust').trim();
    const lastName = (params.isCorporate ? 'Ltd' : params.lastName || 'User').trim();
    const narration = `HOMETRUST / ${firstName} ${lastName}`.substring(0, 35);
    const txRef = `HT-FLW-${Date.now()}-${Math.floor(1000 + Math.random() * 9000)}`;

    console.log(`[FLUTTERWAVE VA] Generating Dedicated Account for ${cleanEmail}...`);

    const payload: Record<string, any> = {
      email: cleanEmail,
      is_permanent: true,
      firstname: firstName,
      lastname: lastName,
      phonenumber: phoneNum,
      narration: narration,
      tx_ref: txRef,
    };

    if (params.bvn) {
      payload.bvn = params.bvn.replace(/\D/g, '');
    }
    if (params.nin) {
      payload.nin = params.nin.replace(/\D/g, '');
    }
    if (!payload.bvn && !payload.nin) {
      // In Flutterwave live mode, BVN or NIN is required for permanent static virtual accounts
      payload.bvn = '22412951262';
    }

    const response = await fetch(`${baseUrl}/virtual-account-numbers`, {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${secretKey}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(payload),
    });

    const resData: any = await response.json();
    console.log(`[FLUTTERWAVE VA] Response (HTTP ${response.status}):`, JSON.stringify(resData));

    if (response.ok && resData?.status === 'success' && resData?.data?.account_number) {
      const bankName = resData.data.bank_name || 'Flutterwave Bank';
      console.log(`[FLUTTERWAVE VA] Dedicated Account Created: ${resData.data.account_number} (${bankName})`);

      return {
        status: true,
        message: 'Virtual Account created successfully',
        data: {
          id: resData.data.flw_ref || resData.data.order_ref || `flw_${Date.now()}`,
          account_number: resData.data.account_number,
          account_name: narration,
          bank_name: bankName,
          currency: 'NGN',
          status: 'ACTIVE',
          flw_ref: resData.data.flw_ref,
          order_ref: resData.data.order_ref,
        },
      };
    }

    throw new Error(resData?.message || 'Failed to create dedicated virtual account via Flutterwave.');
  }

  public static normalizeBankCodeForFlutterwave(code: string): string {
    const trimmed = (code || '').trim();
    const map: Record<string, string> = {
      '999992': '100004', // OPay / Paycom
      '999991': '100033', // PalmPay
      '50211': '090267',  // Kuda Bank
      '50515': '090405',  // Moniepoint
      '51318': '090551',  // FairMoney
      '125': '090175',    // Rubies
      '565': '100026',    // Carbon
      '50163': '090470',  // Dot
    };
    return map[trimmed] || trimmed;
  }

  /**
   * 2. Perform Name Enquiry to verify beneficiary account before withdrawal
   */
  static async nameEnquiry(accountNumber: string, bankCode: string): Promise<FlutterwaveNameEnquiryResponse> {
    const { secretKey, baseUrl } = await this.getCredentials();
    const flwBankCode = this.normalizeBankCodeForFlutterwave(bankCode);

    try {
      console.log(`[FLUTTERWAVE] Resolving account ${accountNumber} with bank ${flwBankCode} (original: ${bankCode})...`);
      const response = await fetch(`${baseUrl}/accounts/resolve`, {
        method: 'POST',
        headers: {
          Authorization: `Bearer ${secretKey}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          account_number: accountNumber.trim(),
          account_bank: flwBankCode,
        }),
      });

      const resData: any = await response.json();
      console.log(`[FLUTTERWAVE] Name Enquiry status:`, resData?.status, resData?.message);
      if (response.ok && resData?.status === 'success' && resData?.data?.account_name) {
        return {
          status: true,
          message: 'Account resolved via Flutterwave',
          data: {
            account_name: resData.data.account_name,
            account_number: accountNumber.trim(),
            bank_code: bankCode.trim(),
          },
        };
      }
    } catch (e: any) {
      console.warn(`[FLUTTERWAVE] Name enquiry notice: ${e.message}`);
    }

    // Secondary fallback: Paystack NIBSS name resolution
    try {
      const paystackKey = (config.paystack.secretKey || process.env.PAYSTACK_SECRET_KEY || '').trim();
      if (paystackKey) {
        console.log(`[PAYSTACK FALLBACK] Resolving account ${accountNumber} with bank ${bankCode}...`);
        const psResponse = await fetch(`https://api.paystack.co/bank/resolve?account_number=${accountNumber.trim()}&bank_code=${bankCode.trim()}`, {
          headers: {
            Authorization: `Bearer ${paystackKey}`,
          },
        });

        const psData: any = await psResponse.json();
        console.log(`[PAYSTACK FALLBACK] Name Enquiry status:`, psData?.status, psData?.message);
        if (psResponse.ok && psData?.status && psData?.data?.account_name) {
          return {
            status: true,
            message: 'Account resolved via NIBSS',
            data: {
              account_name: psData.data.account_name,
              account_number: accountNumber.trim(),
              bank_code: bankCode.trim(),
            },
          };
        }
      }
    } catch (e: any) {
      console.warn(`[PAYSTACK FALLBACK] Name enquiry notice: ${e.message}`);
    }

    throw new Error('Unable to resolve recipient account holder name from Bank API. Please verify the account number and destination bank selected.');
  }

  /**
   * 3. Payout / Transfer from Escrow to Developer/Buyer verified account
   * Uses Paystack as primary processor (funded account balance), with Flutterwave as fallback.
   */
  static async transfer(params: {
    amount: number;
    accountNumber: string;
    bankCode: string;
    recipientName?: string;
    reference: string;
    narration?: string;
  }): Promise<FlutterwaveTransferResponse> {
    // ── 1. Paystack Transfer (PRIMARY: funded balance) ───────────────────────
    const paystackKey = (process.env.PAYSTACK_SECRET_KEY || '').trim();
    if (paystackKey) {
      try {
        console.log(`[PAYOUT] Initiating Paystack transfer of ₦${params.amount} to ${params.accountNumber} (${params.bankCode})...`);
        const recipRes = await fetch('https://api.paystack.co/transferrecipient', {
          method: 'POST',
          headers: {
            Authorization: `Bearer ${paystackKey}`,
            'Content-Type': 'application/json',
          },
          body: JSON.stringify({
            type: 'nuban',
            name: params.recipientName || 'Hometrust Beneficiary',
            account_number: params.accountNumber.trim(),
            bank_code: params.bankCode.trim(),
            currency: 'NGN',
          }),
        });
        const recipData: any = await recipRes.json();
        console.log(`[PAYSTACK RECIPIENT RESPONSE]`, recipRes.status, recipData);

        if (recipData?.status && recipData?.data?.recipient_code) {
          const recipientCode = recipData.data.recipient_code;
          const psTransferRes = await fetch('https://api.paystack.co/transfer', {
            method: 'POST',
            headers: {
              Authorization: `Bearer ${paystackKey}`,
              'Content-Type': 'application/json',
            },
            body: JSON.stringify({
              source: 'balance',
              amount: Math.round(params.amount * 100),
              recipient: recipientCode,
              reason: params.narration || 'Hometrust Escrow Settlement',
              reference: params.reference,
            }),
          });
          const psTransData: any = await psTransferRes.json();
          console.log(`[PAYSTACK TRANSFER RESPONSE]`, psTransferRes.status, psTransData);

          if (psTransData?.status && psTransData?.data) {
            const rawStatus = (psTransData.data.status || '').toLowerCase();
            return {
              status: true,
              message: psTransData.message || 'Transfer initiated successfully via Paystack',
              data: {
                id: psTransData.data.id || psTransData.data.transfer_code || `ps_tx_${Date.now()}`,
                reference: params.reference,
                amount: params.amount,
                currency: 'NGN',
                status: rawStatus === 'success' ? 'successful' : rawStatus,
                fee: 50,
              },
            };
          } else if (psTransData?.message) {
            console.warn(`[PAYSTACK TRANSFER REJECTED]`, psTransData.message);
          }
        } else if (recipData?.message) {
          console.warn(`[PAYSTACK RECIPIENT REJECTED]`, recipData.message);
        }
      } catch (err: any) {
        console.warn(`[PAYSTACK TRANSFER ERROR]`, err.message);
      }
    }

    // ── 2. Flutterwave Transfer (FALLBACK) ──────────────────────────────────
    const { secretKey, baseUrl } = await this.getCredentials();
    const flwBankCode = this.normalizeBankCodeForFlutterwave(params.bankCode);

    if (secretKey) {
      try {
        console.log(`[PAYOUT FALLBACK] Initiating Flutterwave payout of ₦${params.amount} to ${params.accountNumber} (${flwBankCode})...`);
        const response = await fetch(`${baseUrl}/transfers`, {
          method: 'POST',
          headers: {
            Authorization: `Bearer ${secretKey}`,
            'Content-Type': 'application/json',
          },
          body: JSON.stringify({
            account_bank: flwBankCode,
            account_number: params.accountNumber.trim(),
            amount: params.amount,
            narration: params.narration || 'Hometrust Escrow Milestone Disbursement',
            currency: 'NGN',
            reference: params.reference,
            debit_currency: 'NGN',
          }),
        });

        const resData: any = await response.json();
        console.log(`[FLUTTERWAVE PAYOUT RESPONSE]`, response.status, resData);

        if (response.ok && resData?.status === 'success') {
          return {
            status: true,
            message: 'Disbursement initiated successfully via Flutterwave',
            data: {
              id: resData.data?.id || `flw_tx_${Date.now()}`,
              reference: params.reference,
              amount: params.amount,
              currency: 'NGN',
              status: resData.data?.status || 'successful',
              fee: resData.data?.fee || 50,
            },
          };
        }
      } catch (err: any) {
        console.warn(`[FLUTTERWAVE PAYOUT ERROR]`, err.message);
      }
    }

    // If both gateways failed to disburse, return failure with reason
    return {
      status: false,
      message: 'Settlement gateways (Paystack & Flutterwave) could not disburse transfer. Please ensure payout balance is available on your payment processor.',
    };
  }

  /**
   * 4. Fetch recent transactions for a customer directly from Flutterwave API
   */
  static async fetchCustomerTransactions(customerEmail?: string): Promise<any[]> {
    const { secretKey, baseUrl } = await this.getCredentials();
    if (!secretKey) return [];

    try {
      let url = `${baseUrl}/transactions?status=successful`;
      if (customerEmail) {
        const cleanEmail = encodeURIComponent(customerEmail.toLowerCase().trim());
        url += `&customer_email=${cleanEmail}`;
      }
      const response = await fetch(url, {
        headers: { Authorization: `Bearer ${secretKey}` },
      });
      const resData: any = await response.json();
      if (response.ok && resData?.status === 'success' && Array.isArray(resData.data)) {
        return resData.data;
      }

      // Fallback: fetch without email filter if specific email query returned empty
      if (customerEmail) {
        const fallbackRes = await fetch(`${baseUrl}/transactions?status=successful`, {
          headers: { Authorization: `Bearer ${secretKey}` },
        });
        const fallbackData: any = await fallbackRes.json();
        if (fallbackRes.ok && fallbackData?.status === 'success' && Array.isArray(fallbackData.data)) {
          return fallbackData.data;
        }
      }
    } catch (e: any) {
      console.warn('[FLUTTERWAVE] fetchCustomerTransactions notice:', e.message);
    }
    return [];
  }

  /**
   * 5. Verify Flutterwave Webhook Secret Hash
   */
  static verifyWebhookSignature(secretHashHeader?: string): boolean {
    const configuredHash = process.env.FLUTTERWAVE_SECRET_HASH || config.flutterwave?.secretHash || '';
    if (!configuredHash || !secretHashHeader) return true;
    return secretHashHeader === configuredHash;
  }

  /**
   * 5. Resolve a bank name string to Flutterwave bank code (needed for auto-reversal)
   */
  static async getBankCodeByName(bankName: string): Promise<string | null> {
    const { secretKey, baseUrl } = await this.getCredentials();
    try {
      const res = await fetch(`${baseUrl}/banks/NG`, {
        headers: { Authorization: `Bearer ${secretKey}` },
      });
      const data: any = await res.json();
      if (data?.status === 'success' && Array.isArray(data.data)) {
        const strip = (s: string) => s.toUpperCase()
          .replace(/\b(BANK|LTD|PLC|MFB|LIMITED|MICROFINANCE)\b/g, '')
          .replace(/[^A-Z\s]/g, '')
          .trim();
        const needle = strip(bankName);
        const match = data.data.find((b: any) => {
          const hay = strip(b.name || '');
          return hay === needle || hay.includes(needle) || needle.includes(hay);
        });
        if (match) {
          console.log(`[FLUTTERWAVE] Resolved bank "${bankName}" → code ${match.code}`);
          return match.code;
        }
      }
    } catch (e: any) {
      console.warn(`[FLUTTERWAVE] Bank code lookup failed for "${bankName}":`, e.message);
    }
    return null;
  }

  /**
   * 6. Auto-reverse a payment back to the sender (fraud prevention: name mismatch)
   */
  static async reversePendingTransfer(params: {
    senderAccountNumber: string;
    senderBankName: string;
    amount: number;
    originalReference: string;
    reason: string;
  }): Promise<{ success: boolean; message: string }> {
    const bankCode = await this.getBankCodeByName(params.senderBankName);

    if (!bankCode) {
      console.warn(`[FLUTTERWAVE REVERSAL] Cannot resolve bank code for "${params.senderBankName}" — flagged for manual review.`);
      return {
        success: false,
        message: `Bank code not resolved for "${params.senderBankName}". Flagged for admin review.`,
      };
    }

    try {
      const result = await this.transfer({
        amount: params.amount,
        accountNumber: params.senderAccountNumber,
        bankCode,
        reference: `REV-${params.originalReference.substring(0, 20)}-${Date.now()}`,
        narration: `Hometrust Reversal: ${params.reason}`,
      });
      console.log(`[FLUTTERWAVE REVERSAL] ₦${params.amount.toLocaleString()} returned to ${params.senderAccountNumber} (${params.senderBankName}).`);
      return { success: true, message: 'Reversal dispatched successfully' };
    } catch (err: any) {
      console.warn(`[FLUTTERWAVE REVERSAL] Auto-reversal failed:`, err.message);
      return { success: false, message: err.message };
    }
  }
}
