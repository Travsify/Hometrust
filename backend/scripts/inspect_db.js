const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function main() {
  const users = await prisma.user.findMany({
    select: { id: true, email: true, firstName: true, lastName: true, role: true, isEmailVerified: true, kycVerifications: true },
  });
  const vas = await prisma.virtualAccount.findMany();
  const payments = await prisma.payment.findMany();

  console.log('=== USERS ===');
  console.log(JSON.stringify(users, null, 2));

  console.log('=== VIRTUAL ACCOUNTS ===');
  console.log(JSON.stringify(vas, null, 2));

  console.log('=== PAYMENTS ===');
  console.log(JSON.stringify(payments, null, 2));
}

main()
  .catch(console.error)
  .finally(() => prisma.$disconnect());
