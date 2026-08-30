import dotenv from 'dotenv';
import path from 'path';

dotenv.config();

export const config = {
  port: parseInt(process.env.PORT || '5000', 10),
  nodeEnv: process.env.NODE_ENV || 'development',
  jwtSecret: process.env.JWT_SECRET || 'Hometrust_super_secure_jwt_secret_dev_2026',
  jwtExpiresIn: process.env.JWT_EXPIRES_IN || '7d',
  
  paystack: {
    secretKey: process.env.PAYSTACK_SECRET_KEY || '',
    publicKey: process.env.PAYSTACK_PUBLIC_KEY || '',
    baseUrl: process.env.PAYSTACK_BASE_URL || 'https://api.paystack.co',
  },
  
  storage: {
    uploadDir: path.resolve(process.env.UPLOAD_DIR || './uploads'),
    baseUrl: process.env.STORAGE_BASE_URL || 'http://localhost:5000/api/v1/storage',
    supabaseUrl: process.env.SUPABASE_URL || '',
    supabaseKey: process.env.SUPABASE_SERVICE_ROLE_KEY || process.env.SUPABASE_ANON_KEY || '',
    supabaseBucket: process.env.SUPABASE_STORAGE_BUCKET || 'Hometrust-documents',
  },

  openai: {
    apiKey: process.env.OPENAI_API_KEY || '',
    model: process.env.OPENAI_MODEL || 'gpt-4o-mini',
  },

  supabase: {
    url: process.env.SUPABASE_URL || '',
    anonKey: process.env.SUPABASE_ANON_KEY || '',
    serviceRoleKey: process.env.SUPABASE_SERVICE_ROLE_KEY || '',
  },
  
  platform: {
    name: process.env.PLATFORM_NAME || 'Hometrust',
    tagline: 'Verify. Buy. Pay. Track.',
    supportEmail: process.env.SUPPORT_EMAIL || 'support@hometrust.ng',
  },

  resend: {
    apiKey: process.env.RESEND_API_KEY || '',
    fromEmail: process.env.RESEND_FROM_EMAIL || 'Hometrust Security <info@hometrustng.com>',
    fallbackFrom: process.env.RESEND_FALLBACK_FROM || 'onboarding@resend.dev',
  },

  twilio: {
    accountSid: process.env.TWILIO_ACCOUNT_SID || '',
    authToken: process.env.TWILIO_AUTH_TOKEN || '',
    phoneNumber: process.env.TWILIO_PHONE_NUMBER || '',
    verifyServiceSid: process.env.TWILIO_VERIFY_SERVICE_SID || '',
  },

  prembly: {
    secretKey: process.env.PREMBLY_API_KEY || 'live_sk_2a238fff60994964b3f8d9a5a6178d23',
    publicKey: process.env.PREMBLY_PUBLIC_KEY || 'live_pk_ffabb0478dd04d89b2b22729872f5b1d',
    appId: process.env.PREMBLY_APP_ID || 'app_hometrust_identity_2026',
    baseUrl: process.env.PREMBLY_BASE_URL || 'https://api.prembly.com/identitypass/verification',
  },

  flutterwave: {
    secretKey: process.env.FLUTTERWAVE_SECRET_KEY || '',
    publicKey: process.env.FLUTTERWAVE_PUBLIC_KEY || '',
    baseUrl: process.env.FLUTTERWAVE_BASE_URL || 'https://api.flutterwave.com/v3',
    secretHash: process.env.FLUTTERWAVE_SECRET_HASH || 'hometrust_flw_webhook_secret_2026',
  },

  onesignal: {
    appId: process.env.ONESIGNAL_APP_ID || '41b932e7-a242-4e35-89c4-f743b0ff005a',
    restApiKey: process.env.ONESIGNAL_REST_API_KEY || '',
  },
};
