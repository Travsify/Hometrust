import { prisma } from '../../utils/prisma';

export class UsersService {
  static async updateProfile(userId: string, data: any) {
    const { firstName, lastName, phone, ...profileData } = data;

    const user = await prisma.user.update({
      where: { id: userId },
      data: {
        firstName,
        lastName,
        phone,
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

    const { passwordHash, ...userWithoutPassword } = user;
    return userWithoutPassword;
  }
}
