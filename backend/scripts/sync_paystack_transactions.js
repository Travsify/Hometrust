const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

const PAYSTACK_SECRET = process.env.PAYSTACK_SECRET_KEY;

async function fetchPaystack(endpoint) {
  const url = `https://api.paystack.co${endpoint}`;
  const res = await fetch(url, {
    headers: {
      Authorization: `Bearer ${PAYSTACK_SECRET}`,
      'Content-Type': 'application/json',
    },
  });
  return res.json();
}

async function main() {
  console.log('=== SYNCING ALL HISTORICAL PAYSTACK PAYMENTS & BALANCES ===');

  // 1. Fetch all successful transactions from Paystack
  console.log('Fetching transactions from Paystack API...');
  const txRes = await fetchPaystack('/transaction?perPage=100&status=success');

  if (!txRes || !txRes.status) {
    console.error('Failed to fetch Paystack transactions:', txRes);
    return;
  }

  const transactions = txRes.data || [];
  console.log(`Found ${transactions.length} successful transactions on Paystack.`);

  // 2. Fetch all users and virtual accounts in DB
  const users = await prisma.user.findMany({
    include: { virtualAccounts: true, developer: true },
  });

  console.log(`Loaded ${users.length} active users from database.`);

  let syncedCount = 0;

  for (const tx of transactions) {
    const amountInNaira = (tx.amount || 0) / 100; // Paystack sends kobo
    const reference = tx.reference;
    const paidAt = tx.paid_at ? new Date(tx.paid_at) : new Date(tx.created_at);
    const customerEmail = tx.customer?.email?.toLowerCase();
    const customerCode = tx.customer?.customer_code;
    const channel = tx.channel || 'bank_transfer';

    console.log(`\nProcessing Tx: Ref=${reference}, Amount=₦${amountInNaira.toLocaleString()}, Email=${customerEmail}, Channel=${channel}`);

    // Locate the matching user
    let user = users.find(u => u.email.toLowerCase() === customerEmail);

    if (!user && tx.metadata?.userId) {
      user = users.find(u => u.id === tx.metadata.userId);
    }

    // Try finding by virtual account customer code
    if (!user && customerCode) {
      const va = await prisma.virtualAccount.findFirst({
        where: { fincraAccountId: customerCode },
        include: { user: { include: { virtualAccounts: true, developer: true } } },
      });
      if (va && va.user) {
        user = va.user;
      }
    }

    // If still not found, check if there's any user whose virtual account or email matches
    if (!user) {
      console.warn(`⚠️ Could not find DB user for Paystack customer ${customerEmail} (${customerCode})`);
      continue;
    }

    console.log(`Matched to User: ${user.firstName} ${user.lastName} (${user.id})`);

    // Check if payment record already exists
    const existingPayment = await prisma.payment.findFirst({
      where: {
        OR: [
          { paymentReference: reference },
          { paystackReference: reference },
        ],
      },
    });

    if (!existingPayment) {
      await prisma.payment.create({
        data: {
          paymentReference: reference,
          paystackReference: reference,
          userId: user.id,
          developerId: user.developer?.id || null,
          amount: amountInNaira,
          platformFee: 0,
          processingFee: 0,
          totalAmount: amountInNaira,
          purpose: 'INITIAL_DEPOSIT',
          status: 'SUCCESS',
          paystackChannel: channel,
          paidAt: paidAt,
          receiptNumber: `HT-DEP-${reference.slice(-8).toUpperCase()}`,
        },
      });
      console.log(`✅ Created Payment record in database for ₦${amountInNaira.toLocaleString()}`);
      syncedCount++;
    } else {
      console.log(`Payment record already exists in database.`);
    }

    // Ensure user's virtual account balance reflects the deposit
    const va = user.virtualAccounts?.[0] || await prisma.virtualAccount.findFirst({ where: { userId: user.id } });
    if (va) {
      // Recalculate total successful payments deposited into this user's account
      const totalDeposited = await prisma.payment.aggregate({
        where: {
          userId: user.id,
          status: 'SUCCESS',
        },
        _sum: { amount: true },
      });

      const totalWithdrawals = await prisma.withdrawal.aggregate({
        where: {
          userId: user.id,
          status: { in: ['COMPLETED', 'SUCCESS', 'PROCESSING'] },
        },
        _sum: { amount: true },
      });

      const netBalance = Math.max(0, (totalDeposited._sum.amount || 0) - (totalWithdrawals._sum.amount || 0));

      await prisma.virtualAccount.update({
        where: { id: va.id },
        data: { balance: netBalance },
      });

      console.log(`✅ Updated Virtual Account (${va.accountNumber}) balance to: ₦${netBalance.toLocaleString()}`);
    }
  }

  console.log(`\n=== SYNC COMPLETE: ${syncedCount} new transactions synced ===`);
}

main()
  .catch(console.error)
  .finally(() => prisma.$disconnect());
