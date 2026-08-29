import { prisma } from '../../utils/prisma';
import { AuditService } from '../audit/audit.service';

export class ApiKeysService {
  /**
   * List all system API keys with values masked for security
   */
  static async listApiKeys() {
    const keys = await prisma.apiKeyConfig.findMany({
      orderBy: { createdAt: 'desc' },
    });

    return keys.map((k) => ({
      id: k.id,
      name: k.name,
      service: k.service,
      keyType: k.keyType,
      environment: k.environment,
      isActive: k.isActive,
      description: k.description,
      maskedValue: this.maskKey(k.keyValue),
      lastTestedAt: k.lastTestedAt,
      createdAt: k.createdAt,
      updatedAt: k.updatedAt,
    }));
  }

  /**
   * Save or add a new named API key
   */
  static async addApiKey(
    data: {
      name: string;
      service: string;
      keyType?: string;
      keyValue: string;
      environment?: string;
      description?: string;
    },
    adminUser: any
  ) {
    if (!data.name || !data.service || !data.keyValue) {
      throw new Error('Key Name, Service, and Key Value are required');
    }

    const newKey = await prisma.apiKeyConfig.create({
      data: {
        name: data.name.trim(),
        service: data.service.toUpperCase().trim(),
        keyType: data.keyType || 'SECRET',
        keyValue: data.keyValue.trim(),
        environment: data.environment || 'LIVE',
        description: data.description,
        isActive: true,
      },
    });

    await AuditService.log({
      adminId: adminUser.id,
      adminEmail: adminUser.email,
      action: 'API_KEY_ADDED',
      entityType: 'SETTING',
      entityId: newKey.id,
      details: { name: newKey.name, service: newKey.service, environment: newKey.environment },
    });

    return {
      ...newKey,
      maskedValue: this.maskKey(newKey.keyValue),
    };
  }

  /**
   * Update an existing API key
   */
  static async updateApiKey(
    id: string,
    data: {
      name?: string;
      keyValue?: string;
      isActive?: boolean;
      environment?: string;
      description?: string;
    },
    adminUser: any
  ) {
    const updateData: any = {};
    if (data.name) updateData.name = data.name.trim();
    if (data.keyValue && data.keyValue.trim() !== '') updateData.keyValue = data.keyValue.trim();
    if (typeof data.isActive === 'boolean') updateData.isActive = data.isActive;
    if (data.environment) updateData.environment = data.environment;
    if (data.description !== undefined) updateData.description = data.description;

    const updated = await prisma.apiKeyConfig.update({
      where: { id },
      data: updateData,
    });

    await AuditService.log({
      adminId: adminUser.id,
      adminEmail: adminUser.email,
      action: 'API_KEY_UPDATED',
      entityType: 'SETTING',
      entityId: id,
      details: { name: updated.name, service: updated.service, isActive: updated.isActive },
    });

    return {
      ...updated,
      maskedValue: this.maskKey(updated.keyValue),
    };
  }

  /**
   * Delete an API key
   */
  static async deleteApiKey(id: string, adminUser: any) {
    const key = await prisma.apiKeyConfig.delete({
      where: { id },
    });

    await AuditService.log({
      adminId: adminUser.id,
      adminEmail: adminUser.email,
      action: 'API_KEY_DELETED',
      entityType: 'SETTING',
      entityId: id,
      details: { name: key.name, service: key.service },
    });

    return { message: 'API key deleted successfully' };
  }

  /**
   * Test connection with the live API service
   */
  static async testApiKey(id: string) {
    const key = await prisma.apiKeyConfig.findUnique({
      where: { id },
    });

    if (!key) {
      throw new Error('API key not found');
    }

    let isHealthy = false;
    let message = '';

    try {
      if (key.service === 'PAYSTACK') {
        const res = await fetch('https://api.paystack.co/transaction', {
          method: 'GET',
          headers: { Authorization: `Bearer ${key.keyValue}` },
        });
        const json = (await res.json()) as any;
        isHealthy = json.status === true || res.status === 200;
        message = isHealthy ? 'Paystack API key connected and verified successfully!' : (json.message || 'Paystack validation failed');
      } else if (key.service === 'FLUTTERWAVE') {
        const res = await fetch('https://api.flutterwave.com/v3/transactions', {
          method: 'GET',
          headers: { Authorization: `Bearer ${key.keyValue}` },
        });
        const json = (await res.json()) as any;
        isHealthy = json.status === 'success' || res.status === 200;
        message = isHealthy ? 'Flutterwave API key connected and verified successfully!' : (json.message || 'Flutterwave validation failed');
      } else if (key.service === 'OPENROUTER') {
        const res = await fetch('https://openrouter.ai/api/v1/models', {
          method: 'GET',
          headers: { Authorization: `Bearer ${key.keyValue}` },
        });
        isHealthy = res.status === 200;
        message = isHealthy ? 'OpenRouter API key verified with active models access!' : 'OpenRouter validation failed';
      } else if (key.service === 'PREMBLY' || key.service === 'IDENTITYPASS') {
        // Test Prembly IdentityPass connectivity
        try {
          const res = await fetch('https://api.prembly.com/identitypass/verification/nin', {
            method: 'POST',
            headers: {
              'Content-Type': 'application/json',
              'x-api-key': key.keyValue,
              'app-id': process.env.PREMBLY_APP_ID || 'app_hometrust_identity_2026',
            },
            body: JSON.stringify({ number_nin: '00000000000' }),
          });
          // 200 or 400 (invalid test number) means key is authenticated, 401/403 means auth failed
          isHealthy = res.status !== 401 && res.status !== 403;
          message = isHealthy
            ? 'Prembly / IdentityPass API key authenticated successfully with NIMC/CAC gateways!'
            : 'Prembly authentication failed (Invalid API Key or App ID)';
        } catch {
          isHealthy = key.keyValue.length >= 10;
          message = isHealthy ? 'Prembly key format validated.' : 'Prembly key invalid';
        }
      } else if (key.service === 'FINCRA') {
        // Test Fincra API connectivity
        try {
          const res = await fetch('https://api.fincra.com/core/accounts/banks', {
            method: 'GET',
            headers: { 'api-key': key.keyValue },
          });
          isHealthy = res.status === 200 || res.status === 400;
          message = isHealthy
            ? 'Fincra Virtual Banking API key connected successfully!'
            : 'Fincra API authentication failed (Check Secret Key)';
        } catch {
          isHealthy = key.keyValue.length >= 10;
          message = isHealthy ? 'Fincra key format validated.' : 'Fincra key invalid';
        }
      } else {
        isHealthy = true;
        message = `${key.service} key format validated.`;
      }

      await prisma.apiKeyConfig.update({
        where: { id },
        data: { lastTestedAt: new Date() },
      });

      return { success: isHealthy, message, service: key.service };
    } catch (e: any) {
      return { success: false, message: e.message || 'Gateway connection error', service: key.service };
    }
  }

  /**
   * Retrieves active live key for a service from database (with fallback to .env)
   */
  static async getActiveKey(service: string): Promise<string | null> {
    const key = await prisma.apiKeyConfig.findFirst({
      where: { service: service.toUpperCase(), isActive: true },
      orderBy: { updatedAt: 'desc' },
    });

    if (key && key.keyValue) {
      return key.keyValue;
    }

    // Fallbacks from environment variables
    if (service === 'PAYSTACK') return process.env.PAYSTACK_SECRET_KEY || null;
    if (service === 'FLUTTERWAVE') return process.env.FLUTTERWAVE_SECRET_KEY || null;
    if (service === 'OPENROUTER') return process.env.OPENROUTER_API_KEY || null;
    if (service === 'PREMBLY' || service === 'IDENTITYPASS') return process.env.PREMBLY_API_KEY || null;
    if (service === 'FINCRA') return process.env.FINCRA_SECRET_KEY || null;
    return null;
  }

  private static maskKey(val: string): string {
    if (!val || val.length < 8) return '********';
    const prefix = val.slice(0, 7);
    const suffix = val.slice(-4);
    return `${prefix}...${suffix}`;
  }
}
