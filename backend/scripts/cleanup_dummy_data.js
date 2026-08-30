const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function main() {
  console.log('Starting DB cleanup of dummy seed users and dummy payments...');

  // 1. Find dummy users by email or dummy pattern
  const dummyEmails = [
    'john.doe@example.com',
    'chioma.nwosu@example.com',
    'info@globalline.io',
    'testbuyer@hometrust.ng',
  ];

  const dummyUsers = await prisma.user.findMany({
    where: {
      email: { in: dummyEmails },
    },
    select: { id: true, email: true },
  });

  const dummyUserIds = dummyUsers.map(u => u.id);
  console.log(`Found ${dummyUsers.length} dummy users to clean:`, dummyUsers.map(u => u.email));

  if (dummyUserIds.length > 0) {
    // Clean related records first
    await prisma.payment.deleteMany({ where: { userId: { in: dummyUserIds } } });
    await prisma.purchase.deleteMany({ where: { userId: { in: dummyUserIds } } });
    await prisma.virtualAccount.deleteMany({ where: { userId: { in: dummyUserIds } } });
    await prisma.kycVerification.deleteMany({ where: { userId: { in: dummyUserIds } } });
    await prisma.userProfile.deleteMany({ where: { userId: { in: dummyUserIds } } });
    await prisma.notification.deleteMany({ where: { userId: { in: dummyUserIds } } });
    await prisma.user.deleteMany({ where: { id: { in: dummyUserIds } } });
    console.log('✅ Deleted dummy users and their associated records.');
  }

  // 2. Delete any orphaned or test payments with status PENDING and no real reference
  const dummyPayments = await prisma.payment.deleteMany({
    where: {
      OR: [
        { paymentReference: { contains: 'EV-PAY-1788031006959' } },
        { status: 'PENDING', paidAt: null, paystackReference: null },
      ],
    },
  });
  console.log(`✅ Deleted ${dummyPayments.count} dummy/abandoned payment records.`);

  // 3. Delete any orphaned virtual accounts
  const dummyVAs = await prisma.virtualAccount.deleteMany({
    where: {
      accountNumber: { in: ['0225663763', '0237308694', '0234214701'] },
    },
  });
  console.log(`✅ Deleted ${dummyVAs.count} dummy seed virtual accounts.`);

  console.log('Cleanup finished successfully!');
}

main()
  .catch(console.error)
  .finally(() => prisma.$disconnect());
