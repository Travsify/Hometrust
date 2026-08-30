import { config } from '../../config';

export interface OneSignalPushParams {
  userId: string;
  title: string;
  message: string;
  data?: Record<string, any>;
  url?: string;
}

export class OneSignalService {
  private static readonly API_URL = 'https://onesignal.com/api/v1/notifications';

  static async sendPushToUser(params: OneSignalPushParams): Promise<boolean> {
    const { appId, restApiKey } = config.onesignal;
    if (!appId || !restApiKey) {
      console.warn('[ONESIGNAL] App ID or REST API Key is missing. Skipping push notification.');
      return false;
    }

    try {
      const payload: any = {
        app_id: appId,
        target_channel: 'push',
        include_aliases: {
          external_id: [params.userId],
        },
        include_external_user_ids: [params.userId],
        channel_for_external_user_ids: 'push',
        headings: { en: params.title },
        contents: { en: params.message },
        data: params.data || {},
        priority: 10,
        ios_sound: 'default',
        android_sound: 'default',
      };

      if (params.url) {
        payload.url = params.url;
      }

      console.log(`[ONESIGNAL] Sending push notification to User ${params.userId}: "${params.title}"`);
      const response = await fetch(this.API_URL, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
          Authorization: `Key ${restApiKey}`,
        },
        body: JSON.stringify(payload),
      });

      const result: any = await response.json();
      if (response.ok && !result.errors) {
        console.log(`[ONESIGNAL] Push notification processed. ID: ${result.id}, Recipients: ${result.recipients || 0}`);
        return true;
      } else {
        console.warn(`[ONESIGNAL] Response notice:`, JSON.stringify(result));
        return false;
      }
    } catch (error: any) {
      console.warn(`[ONESIGNAL] Error sending push notification:`, error.message);
      return false;
    }
  }

  static async sendBroadcast(title: string, message: string, data?: Record<string, any>): Promise<boolean> {
    const { appId, restApiKey } = config.onesignal;
    if (!appId || !restApiKey) return false;

    try {
      const payload = {
        app_id: appId,
        included_segments: ['Subscribed Users', 'Total Subscriptions'],
        headings: { en: title },
        contents: { en: message },
        data: data || {},
      };

      const response = await fetch(this.API_URL, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
          Authorization: `Key ${restApiKey}`,
        },
        body: JSON.stringify(payload),
      });

      const result: any = await response.json();
      return response.ok && !result.errors;
    } catch (e: any) {
      console.warn('[ONESIGNAL] Broadcast failed:', e.message);
      return false;
    }
  }
}
