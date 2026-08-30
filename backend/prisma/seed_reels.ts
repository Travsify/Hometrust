import { prisma } from '../src/utils/prisma';

async function seed() {
  const dev = await prisma.developer.findFirst();
  if (!dev) {
    console.log('No developer found to attach reels.');
    return;
  }

  // Create an active off-plan project for this developer if none exists
  let project = await prisma.project.findFirst({ where: { developerId: dev.id } });
  if (!project) {
    project = await prisma.project.create({
      data: {
        developerId: dev.id,
        name: 'The Sapphire Crest Residences',
        slug: 'the-sapphire-crest-residences',
        description: 'Luxury 4-Bedroom Smart Terraces & Penthouses with milestone escrow protection, smart automation, and 24/7 solar micro-grid.',
        state: 'Lagos',
        city: 'Lekki Phase 1',
        area: 'Freedom Way, Lekki',
        address: '14 Freedom Way, Lekki Phase 1, Lagos',
        totalUnits: 18,
        availableUnits: 7,
        expectedCompletion: 'Q3 2027',
        status: 'UNDER_CONSTRUCTION',
        isVerified: true,
        images: JSON.stringify([
          'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?auto=format&fit=crop&w=1200&q=80',
          'https://images.unsplash.com/photo-1600596542815-ffad4c1539a9?auto=format&fit=crop&w=1200&q=80',
        ]),
        units: {
          create: [
            {
              unitType: '4 Bedroom Smart Terrace',
              name: 'Unit 4B - Coral Wing',
              bedrooms: 4,
              bathrooms: 5,
              price: 85000000,
              initialDeposit: 8500000,
              monthlyInstalment: 2500000,
              size: '260 SQM',
            },
          ],
        },
      },
    });
    console.log('Created sample project:', project.name);
  }

  // Delete existing demo posts if any
  await prisma.developerPost.deleteMany({ where: { developerId: dev.id } });

  // Sample reels with high quality architectural / site walkthrough video URLs
  const sampleReels = [
    {
      mediaUrl: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4',
      mediaType: 'VIDEO',
      thumbnailUrl: 'https://images.unsplash.com/photo-1541888946425-d0fbb186156a?auto=format&fit=crop&w=1080&q=80',
      caption: '3rd Floor Lintel & Deck Casting Complete! 🏗️ COREN engineering inspection verified. 5 units left on 24-month pay-small-small plan.',
      tagTitle: 'The Sapphire Crest • Lekki Phase 1',
      tagPrice: 'From ₦8.5M Initial Deposit',
      likesCount: 38,
      sharesCount: 14,
      viewsCount: 240,
    },
    {
      mediaUrl: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerEscapes.mp4',
      mediaType: 'VIDEO',
      thumbnailUrl: 'https://images.unsplash.com/photo-1600607687939-ce8a6c25118c?auto=format&fit=crop&w=1080&q=80',
      caption: 'Groundbreaking drone overview of our ongoing foundation & soil stabilization works at Epe Tech Corridor! 🚁 100% C-of-O verified.',
      tagTitle: 'Epe Tech Corridor • C-of-O Land',
      tagPrice: 'From ₦1.8M Initial Deposit',
      likesCount: 52,
      sharesCount: 22,
      viewsCount: 410,
    },
    {
      mediaUrl: 'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?auto=format&fit=crop&w=1080&q=80',
      mediaType: 'IMAGE',
      thumbnailUrl: 'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?auto=format&fit=crop&w=1080&q=80',
      caption: 'Interior tiling and MEP installation on Villa Block C underway. Milestone 4 escrow funds released after certified audit approval! ✨',
      tagTitle: 'Villa Block C • Luxury Terraces',
      tagPrice: 'Pay ₦450k Monthly',
      likesCount: 27,
      sharesCount: 9,
      viewsCount: 185,
    },
  ];

  for (const r of sampleReels) {
    await prisma.developerPost.create({
      data: {
        developerId: dev.id,
        projectId: project.id,
        mediaUrl: r.mediaUrl,
        mediaType: r.mediaType,
        thumbnailUrl: r.thumbnailUrl,
        caption: r.caption,
        tagTitle: r.tagTitle,
        tagPrice: r.tagPrice,
        likesCount: r.likesCount,
        sharesCount: r.sharesCount,
        viewsCount: r.viewsCount,
      },
    });
  }

  console.log(`Seeded ${sampleReels.length} reels for developer ${dev.companyName}`);
}

seed()
  .catch(e => console.error(e))
  .finally(() => prisma.$disconnect());
