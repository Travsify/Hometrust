import dotenv from 'dotenv';
import path from 'path';

dotenv.config();

export const config = {
  port: parseInt(process.env.PORT || '5000', 10),
  nodeEnv: process.env.NODE_ENV || 'development',
  jwtSecret: process.env.JWT_SECRET || 'estateverify_super_secure_jwt_secret_dev_2026',
  jwtExpiresIn: process.env.JWT_EXPIRES_IN || '7d',
  
  paystack: {
    secretKey: process.env.PAYSTACK_SECRET_KEY || 'sk_test_mock_paystack_secret_key_12345',
    publicKey: process.env.PAYSTACK_PUBLIC_KEY || 'pk_test_mock_paystack_public_key_12345',
    baseUrl: process.env.PAYSTACK_BASE_URL || 'https://api.paystack.co',
  },
  
  storage: {
    uploadDir: path.resolve(process.env.UPLOAD_DIR || './uploads'),
    baseUrl: process.env.STORAGE_BASE_URL || 'http://localhost:5000/api/v1/storage',
    supabaseUrl: process.env.SUPABASE_URL || '',
    supabaseKey: process.env.SUPABASE_SERVICE_ROLE_KEY || process.env.SUPABASE_ANON_KEY || '',
    supabaseBucket: process.env.SUPABASE_STORAGE_BUCKET || 'estateverify-documents',
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
    name: process.env.PLATFORM_NAME || 'EstateVerify',
    tagline: 'Verify. Buy. Pay. Track.',
    supportEmail: process.env.SUPPORT_EMAIL || 'support@estateverify.ng',
  },
};
