import { prisma } from '../../utils/prisma';

export class UsersService {
  static async updateProfile(userId: string, data: any) {
    const {
      firstName,
      lastName,
      phone,
      avatarUrl,
      logoUrl,
      companyName,
      officeAddress,
      businessAddress,
      about,
      website,
      cacNumber,
      contactPerson,
      ...profileData
    } = data;

    // Check if user is a developer
    const existingUser = await prisma.user.findUnique({
      where: { id: userId },
      include: { developer: true },
    });

    const user = await prisma.user.update({
      where: { id: userId },
      data: {
        ...(firstName ? { firstName } : {}),
        ...(lastName ? { lastName } : {}),
        ...(phone ? { phone } : {}),
        ...(avatarUrl ? { avatarUrl } : {}),
        profile: {
          upsert: {
            create: profileData,
            update: profileData,
          },
        },
      },
      include: {
        profile: true,
        developer: true,
      },
    });

    if (existingUser?.developer) {
      await prisma.developer.update({
        where: { id: existingUser.developer.id },
        data: {
          companyName: companyName || existingUser.developer.companyName,
          officeAddress: officeAddress || businessAddress || existingUser.developer.officeAddress,
          about: about !== undefined ? about : existingUser.developer.about,
          website: website !== undefined ? website : existingUser.developer.website,
          cacNumber: cacNumber || existingUser.developer.cacNumber,
          contactPerson: contactPerson || existingUser.developer.contactPerson,
          phone: phone || existingUser.developer.phone,
          logoUrl: logoUrl || avatarUrl || existingUser.developer.logoUrl,
        },
      });
    }

    const updated = await prisma.user.findUnique({
      where: { id: userId },
      include: {
        profile: true,
        developer: true,
      },
    });

    const { passwordHash, ...userWithoutPassword } = updated || user;
    return userWithoutPassword;
  }
}
