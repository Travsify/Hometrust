const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function createBucketViaSql() {
  try {
    console.log('Connecting to Supabase PostgreSQL...');
    
    // 1. Insert or update the bucket
    await prisma.$executeRawUnsafe(`
      INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
      VALUES ('estateverify-documents', 'estateverify-documents', true, 104857600, NULL)
      ON CONFLICT (id) DO UPDATE SET public = true;
    `);
    console.log('✅ Bucket "estateverify-documents" created and set to PUBLIC = TRUE');

    // 2. Add public read policy
    try {
      await prisma.$executeRawUnsafe(`
        CREATE POLICY "Allow Public Read" ON storage.objects
        FOR SELECT
        USING (bucket_id = 'estateverify-documents');
      `);
      console.log('✅ "Allow Public Read" policy created');
    } catch (e) {
      console.log('ℹ️ Select policy:', e.message.includes('already exists') ? 'Already exists' : e.message);
    }

    // 3. Add public upload policy
    try {
      await prisma.$executeRawUnsafe(`
        CREATE POLICY "Allow Public Insert" ON storage.objects
        FOR INSERT
        WITH CHECK (bucket_id = 'estateverify-documents');
      `);
      console.log('✅ "Allow Public Insert" policy created');
    } catch (e) {
      console.log('ℹ️ Insert policy:', e.message.includes('already exists') ? 'Already exists' : e.message);
    }

    // 4. Add public update policy
    try {
      await prisma.$executeRawUnsafe(`
        CREATE POLICY "Allow Public Update" ON storage.objects
        FOR UPDATE
        USING (bucket_id = 'estateverify-documents');
      `);
      console.log('✅ "Allow Public Update" policy created');
    } catch (e) {
      console.log('ℹ️ Update policy:', e.message.includes('already exists') ? 'Already exists' : e.message);
    }

    // 5. Verify the bucket in the database
    const buckets = await prisma.$queryRawUnsafe(`
      SELECT id, name, public, created_at FROM storage.buckets WHERE id = 'estateverify-documents';
    `);
    console.log('Confirmed Bucket Info:', buckets);

  } catch (err) {
    console.error('❌ SQL Setup Error:', err);
  } finally {
    await prisma.$disconnect();
  }
}

createBucketViaSql();
