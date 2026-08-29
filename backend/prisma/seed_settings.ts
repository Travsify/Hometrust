import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

async function run() {
  console.log('Synchronizing Platform Fee Rules, Named API Keys & Fincra Virtual Accounts in Supabase...');

  await prisma.platformFeeConfig.deleteMany();
  await prisma.platformFeeConfig.createMany({
    data: [
      {
        name: 'Standard Document Verification',
        feeType: 'FIXED',
        fixedAmount: 25000,
        percentage: 0,
        amount: 25000,
        applicableService: 'VERIFICATION',
        description: 'C of O, Governor Consent, Registered Deed title search',
        isActive: true,
      },
      {
        name: 'Express Document Verification (24h Expedited)',
        feeType: 'FIXED',
        fixedAmount: 45000,
        percentage: 0,
        amount: 45000,
        applicableService: 'VERIFICATION',
        description: 'Expedited cadastral search with physical surveyor site check',
        isActive: true,
      },
      {
        name: 'Legal Document Drafting (Custom Contract / Deed)',
        feeType: 'FIXED',
        fixedAmount: 45000,
        percentage: 0,
        amount: 45000,
        applicableService: 'LEGAL',
        description: 'Lawyer-certified Contract of Sale & Deed of Assignment drafting',
        isActive: true,
      },
      {
        name: 'Property Purchase Transaction Fee',
        feeType: 'BOTH',
        fixedAmount: 5000,
        percentage: 1.0,
        capAmount: 50000,
        amount: 5000,
        applicableService: 'PROPERTY_TRANSACTION',
        description: 'Platform escrow management fee (₦5,000 + 1.0%, capped at ₦50,000)',
        isActive: true,
      },
      {
        name: 'Developer Annual Listing Tier 1',
        feeType: 'FIXED',
        fixedAmount: 150000,
        percentage: 0,
        amount: 150000,
        applicableService: 'DEVELOPER_LISTING',
        description: 'Annual verified developer badge and off-plan listing tier',
        isActive: true,
      },
    ],
  });

  await prisma.apiKeyConfig.deleteMany();
  await prisma.apiKeyConfig.createMany({
    data: [
      {
        name: 'Fincra Production Banking API Key',
        service: 'FINCRA',
        keyType: 'SECRET',
        keyValue: 'gel847St1V9DvVk40Ec6Vfm869Yw63Ue',
        environment: 'LIVE',
        description: 'Fincra API for Buyer Dedicated Virtual Accounts, KYB/KYC and Commercial Bank Disbursements',
        isActive: true,
      },
      {
        name: 'Paystack Production Secret Key',
        service: 'PAYSTACK',
        keyType: 'SECRET',
        keyValue: process.env.PAYSTACK_SECRET_KEY || 'sk_live_paystack_secret_sample',
        environment: 'LIVE',
        description: 'Primary Paystack secret key for card debits and DVA bank transfers',
        isActive: true,
      },
      {
        name: 'Flutterwave Live Secret Key',
        service: 'FLUTTERWAVE',
        keyType: 'SECRET',
        keyValue: process.env.FLUTTERWAVE_SECRET_KEY || 'FLWSECK_LIVE-sample_secret_key',
        environment: 'LIVE',
        description: 'Secondary gateway for direct debit and bank checkout',
        isActive: true,
      },
      {
        name: 'OpenRouter Free AI Scanner Key',
        service: 'OPENROUTER',
        keyType: 'SECRET',
        keyValue: process.env.OPENROUTER_API_KEY || 'sk-or-v1-openrouter-free-models',
        environment: 'LIVE',
        description: 'OpenRouter API key powering free Llama 3.1 & Gemini 2.0 document legal scans',
        isActive: true,
      },
      {
        name: 'Prembly / IdentityPass Live Verification Key',
        service: 'PREMBLY',
        keyType: 'SECRET',
        keyValue: 'live_sk_2a238fff60994964b3f8d9a5a6178d23',
        environment: 'LIVE',
        description: 'Automated CAC RC corporate registry and Director NIN verification',
        isActive: true,
      },
      {
        name: 'Fincra Dedicated Virtual Banking Key',
        service: 'FINCRA',
        keyType: 'SECRET',
        keyValue: 'gel847St1V9DvVk40Ec6Vfm869Yw63Ue',
        environment: 'LIVE',
        description: 'Instant NUBAN virtual accounts and developer commercial payouts (Business ID: 693c5533957c9000120117a6)',
        isActive: true,
      },
    ],
  });

  // Seed Initial Dedicated Virtual Accounts for existing developers and buyers
  const developers = await prisma.developer.findMany({ take: 3 });
  const buyers = await prisma.user.findMany({ where: { role: 'BUYER' }, take: 3 });

  for (const dev of developers) {
    await prisma.virtualAccount.upsert({
      where: { accountNumber: `08${dev.cacNumber.replace(/[^0-9]/g, '').slice(0, 8)}` },
      update: {},
      create: {
        developerId: dev.id,
        accountName: `Hometrust / ${dev.companyName}`,
        accountNumber: `08${dev.cacNumber.replace(/[^0-9]/g, '').slice(0, 8)}`,
        bankName: 'Providus Bank',
        accountType: 'CORPORATE',
        currency: 'NGN',
        status: 'ACTIVE',
        balance: 15400000,
      },
    });
  }

  for (const buyer of buyers) {
    const num = '02' + Math.floor(10000000 + Math.random() * 90000000).toString();
    await prisma.virtualAccount.create({
      data: {
        userId: buyer.id,
        accountName: `Hometrust / ${buyer.firstName} ${buyer.lastName}`,
        accountNumber: num,
        bankName: 'Providus Bank',
        accountType: 'INDIVIDUAL',
        currency: 'NGN',
        status: 'ACTIVE',
        balance: 2500000,
      },
    });
  }

  // Seed sample developer withdrawal
  if (developers.length > 0) {
    await prisma.withdrawal.create({
      data: {
        developerId: developers[0].id,
        amount: 5000000,
        fee: 50,
        netAmount: 4999950,
        bankCode: '058',
        bankName: 'Guaranty Trust Bank (GTBank)',
        accountNumber: '0129482910',
        accountName: `${developers[0].companyName} Operations Account`,
        reference: `EV-WD-${Date.now()}`,
        status: 'SUCCESS',
      },
    });
  }

  console.log('✅ Successfully seeded Platform Fees, Named API Keys, and Fincra Banking in Supabase!');
}

run()
  .catch(console.error)
  .finally(() => prisma.$disconnect());
