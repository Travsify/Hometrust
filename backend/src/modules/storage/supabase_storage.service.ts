import { createClient, SupabaseClient } from '@supabase/supabase-js';
import { config } from '../../config';

export class SupabaseStorageService {
  private static client: SupabaseClient | null = null;

  private static getClient(): SupabaseClient | null {
    if (!this.client && config.supabase.url && config.supabase.serviceRoleKey) {
      this.client = createClient(config.supabase.url, config.supabase.serviceRoleKey);
    }
    return this.client;
  }

  /**
   * Uploads a document buffer directly to a Supabase Private Storage Bucket
   */
  static async uploadFile(
    bucket: string,
    filePath: string,
    fileBuffer: Buffer,
    contentType: string
  ): Promise<{ path: string; fullUrl: string }> {
    const supabase = this.getClient();
    if (!supabase) {
      // Fallback URL if Supabase credentials are not provided
      return {
        path: filePath,
        fullUrl: `${config.storage.baseUrl}/files/${filePath}`,
      };
    }

    const { data, error } = await supabase.storage
      .from(bucket)
      .upload(filePath, fileBuffer, {
        contentType,
        upsert: true,
      });

    if (error) {
      console.warn('Supabase bucket upload warning:', error.message);
      return {
        path: filePath,
        fullUrl: `${config.storage.baseUrl}/files/${filePath}`,
      };
    }

    // Generate signed URL (expires in 7 days for authorized viewing)
    const { data: signedData } = await supabase.storage
      .from(bucket)
      .createSignedUrl(filePath, 60 * 60 * 24 * 7);

    return {
      path: data.path,
      fullUrl: signedData?.signedUrl || `${config.supabase.url}/storage/v1/object/public/${bucket}/${filePath}`,
    };
  }

  /**
   * Creates a time-limited signed URL for secure document access
   */
  static async getSignedUrl(bucket: string, filePath: string, expiresInSeconds: number = 3600): Promise<string> {
    const supabase = this.getClient();
    if (!supabase) {
      return `${config.storage.baseUrl}/files/${filePath}`;
    }

    const { data, error } = await supabase.storage
      .from(bucket)
      .createSignedUrl(filePath, expiresInSeconds);

    if (error || !data?.signedUrl) {
      return `${config.storage.baseUrl}/files/${filePath}`;
    }

    return data.signedUrl;
  }
}
