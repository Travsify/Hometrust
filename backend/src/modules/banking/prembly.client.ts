import { ApiKeysService } from '../admin/api_keys.service';
import { config } from '../../config';

export interface PremblyVerificationResponse {
  status: boolean;
  response_code?: string;
  detail?: string;
  message?: string;
  data?: {
    nin?: string;
    bvn?: string;
    firstName?: string;
    lastName?: string;
    middleName?: string;
    dateOfBirth?: string;
    gender?: string;
    phone?: string;
    address?: string;
    company_name?: string;
    rc_number?: string;
    status?: string;
    branchAddress?: string;
    registrationDate?: string;
  };
}

export class PremblyClient {
  private static async getCredentials() {
    const dbKey = await ApiKeysService.getActiveKey('PREMBLY').catch(() => null);
    const apiKey = dbKey || config.prembly.secretKey;
    const appId = config.prembly.appId;
    const baseUrl = config.prembly.baseUrl;

    if (!apiKey || apiKey.length < 10) {
      throw new Error('Prembly API key is not configured. Set PREMBLY_API_KEY in environment variables.');
    }

    return { apiKey, appId, baseUrl };
  }

  /**
   * Verify National Identity Number (NIN) against NIMC via Prembly IdentityPass (LIVE)
   */
  static async verifyNIN(nin: string, firstName?: string, lastName?: string): Promise<PremblyVerificationResponse> {
    if (!nin || nin.length !== 11 || !/^\d+$/.test(nin)) {
      throw new Error('Invalid NIN format. NIN must be exactly 11 digits.');
    }

    const { apiKey, appId, baseUrl } = await this.getCredentials();

    console.log(`[PREMBLY] Verifying NIN ${nin.substring(0, 3)}****${nin.substring(8)} via live API...`);

    const response = await fetch(`${baseUrl}/nin_wo_face`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'x-api-key': apiKey,
        'app-id': appId,
      },
      body: JSON.stringify({
        number: nin,
      }),
    });

    const data = (await response.json()) as any;

    if (!response.ok) {
      console.error(`[PREMBLY] NIN verification failed (HTTP ${response.status}):`, JSON.stringify(data));
      throw new Error(data?.detail || data?.message || `Prembly NIN verification failed (HTTP ${response.status}). Please check your NIN and try again.`);
    }

    if (data?.verification?.status === 'NOT_VERIFIED' || data?.status === false) {
      console.error('[PREMBLY] NIN verification returned NOT_VERIFIED:', JSON.stringify(data));
      throw new Error('NIN verification failed. The provided NIN could not be verified against NIMC records.');
    }

    console.log(`[PREMBLY] NIN verified successfully for ${data?.data?.firstName || firstName || 'user'} ${data?.data?.lastName || lastName || ''}`);

    return {
      status: true,
      message: 'NIN verified successfully against NIMC records via Prembly IdentityPass',
      data: {
        nin,
        firstName: data?.data?.firstName || firstName,
        lastName: data?.data?.lastName || lastName,
        middleName: data?.data?.middleName,
        dateOfBirth: data?.data?.dateOfBirth || data?.data?.birthdate,
        gender: data?.data?.gender,
        phone: data?.data?.phone || data?.data?.telephoneno,
        status: 'VERIFIED',
      },
    };
  }

  /**
   * Verify Bank Verification Number (BVN) against NIBSS via Prembly IdentityPass (LIVE)
   */
  static async verifyBVN(bvn: string): Promise<PremblyVerificationResponse> {
    if (!bvn || bvn.length !== 11 || !/^\d+$/.test(bvn)) {
      throw new Error('Invalid BVN format. BVN must be exactly 11 digits.');
    }

    const { apiKey, appId, baseUrl } = await this.getCredentials();

    console.log(`[PREMBLY] Verifying BVN ${bvn.substring(0, 3)}****${bvn.substring(8)} via live API...`);

    const response = await fetch(`${baseUrl}/bvn`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'x-api-key': apiKey,
        'app-id': appId,
      },
      body: JSON.stringify({ number: bvn }),
    });

    const data = (await response.json()) as any;

    if (!response.ok) {
      console.error(`[PREMBLY] BVN verification failed (HTTP ${response.status}):`, JSON.stringify(data));
      throw new Error(data?.detail || data?.message || `Prembly BVN verification failed (HTTP ${response.status}). Please check your BVN and try again.`);
    }

    if (data?.verification?.status === 'NOT_VERIFIED' || data?.status === false) {
      console.error('[PREMBLY] BVN verification returned NOT_VERIFIED:', JSON.stringify(data));
      throw new Error('BVN verification failed. The provided BVN could not be verified against NIBSS records.');
    }

    console.log(`[PREMBLY] BVN verified successfully for ${data?.data?.firstName || 'user'}`);

    return {
      status: true,
      message: 'BVN verified successfully against NIBSS records via Prembly IdentityPass',
      data: {
        bvn,
        firstName: data?.data?.firstName,
        lastName: data?.data?.lastName,
        dateOfBirth: data?.data?.dateOfBirth,
        phone: data?.data?.phoneNumber || data?.data?.phone,
        status: 'VERIFIED',
      },
    };
  }

  /**
   * Verify Corporate CAC Registration against CAC Registry via Prembly IdentityPass (LIVE)
   */
  static async verifyCAC(cacNumber: string, companyName: string): Promise<PremblyVerificationResponse> {
    if (!cacNumber || cacNumber.trim().length < 4) {
      throw new Error('Invalid CAC/RC number. Please provide a valid company registration number.');
    }

    const { apiKey, appId, baseUrl } = await this.getCredentials();

    console.log(`[PREMBLY] Verifying CAC ${cacNumber} for "${companyName}" via live API...`);

    const response = await fetch(`${baseUrl}/cac`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'x-api-key': apiKey,
        'app-id': appId,
      },
      body: JSON.stringify({
        rc_number: cacNumber,
        company_name: companyName,
      }),
    });

    const data = (await response.json()) as any;

    if (!response.ok) {
      console.error(`[PREMBLY] CAC verification failed (HTTP ${response.status}):`, JSON.stringify(data));
      throw new Error(data?.detail || data?.message || `Prembly CAC verification failed (HTTP ${response.status}). Please check your RC number and try again.`);
    }

    if (data?.verification?.status === 'NOT_VERIFIED' || data?.status === false) {
      console.error('[PREMBLY] CAC verification returned NOT_VERIFIED:', JSON.stringify(data));
      throw new Error('CAC verification failed. The provided RC number could not be verified against Corporate Affairs Commission records.');
    }

    console.log(`[PREMBLY] CAC verified successfully: ${data?.data?.company_name || companyName} (RC: ${cacNumber})`);

    return {
      status: true,
      message: 'Corporate CAC registration verified with Corporate Affairs Commission via Prembly IdentityPass',
      data: {
        rc_number: cacNumber,
        company_name: data?.data?.company_name || companyName,
        status: data?.data?.status || 'ACTIVE',
        branchAddress: data?.data?.branchAddress,
        registrationDate: data?.data?.registrationDate,
      },
    };
  }
}
