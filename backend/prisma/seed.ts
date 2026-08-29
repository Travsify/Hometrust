import { PrismaClient } from '@prisma/client';
import bcrypt from 'bcryptjs';

const prisma = new PrismaClient();

async function main() {
  console.log('Seeding EstateVerify development database...');

  // 1. Create Default Platform Fees
  const fees = [
    { name: 'Standard Document Verification', feeType: 'FLAT', amount: 25000, applicableService: 'VERIFICATION' },
    { name: 'Express Document Verification', feeType: 'FLAT', amount: 45000, applicableService: 'VERIFICATION' },
    { name: 'Legal Document Drafting (Deed / Agreement)', feeType: 'FLAT', amount: 45000, applicableService: 'LEGAL' },
    { name: 'Developer Annual Listing Tier 1', feeType: 'FLAT', amount: 150000, applicableService: 'DEVELOPER_LISTING' },
    { name: 'Property Transaction Platform Service Fee', feeType: 'FLAT', amount: 5000, applicableService: 'PROPERTY_TRANSACTION' },
  ];

  for (const fee of fees) {
    await prisma.platformFeeConfig.create({ data: fee });
  }

  // 2. Create Users
  const passwordHash = await bcrypt.hash('Password123!', 10);

  // Super Admin
  const admin = await prisma.user.create({
    data: {
      email: 'admin@estateverify.ng',
      passwordHash,
      firstName: 'Admin',
      lastName: 'Director',
      phone: '+2348011223344',
      role: 'SUPER_ADMIN',
      isActive: true,
      isEmailVerified: true,
    },
  });

  // Legal Manager
  const legalMgr = await prisma.user.create({
    data: {
      email: 'legal@estateverify.ng',
      passwordHash,
      firstName: 'Barrister Folake',
      lastName: 'Adeleke',
      phone: '+2348022334455',
      role: 'LEGAL_MANAGER',
      isActive: true,
      isEmailVerified: true,
    },
  });

  // Verification Manager
  const verifMgr = await prisma.user.create({
    data: {
      email: 'verification@estateverify.ng',
      passwordHash,
      firstName: 'Emeka',
      lastName: 'Okonkwo',
      phone: '+2348033445566',
      role: 'VERIFICATION_MANAGER',
      isActive: true,
      isEmailVerified: true,
    },
  });

  // Sample Buyers
  const buyer1 = await prisma.user.create({
    data: {
      email: 'john.doe@example.com',
      passwordHash,
      firstName: 'John',
      lastName: 'Doe',
      phone: '+2348099887766',
      role: 'BUYER',
      isActive: true,
      isEmailVerified: true,
      profile: {
        create: {
          state: 'Lagos',
          city: 'Lekki',
          occupation: 'Software Engineer',
          bvnVerified: true,
        },
      },
    },
  });

  const buyer2 = await prisma.user.create({
    data: {
      email: 'chioma.nwosu@example.com',
      passwordHash,
      firstName: 'Chioma',
      lastName: 'Nwosu',
      phone: '+2348055667788',
      role: 'BUYER',
      isActive: true,
      isEmailVerified: true,
      profile: {
        create: {
          state: 'Abuja',
          city: 'Maitama',
          occupation: 'Financial Analyst',
          bvnVerified: true,
        },
      },
    },
  });

  // 3. Create Developers & Developer Users
  const devUsersData = [
    {
      email: 'landmark@africa.com',
      firstName: 'Paul',
      lastName: 'Onwuanibe',
      company: 'Landmark Africa Holdings',
      cac: 'RC-1092834',
      status: 'VERIFIED',
      isVerified: true,
      years: 15,
      completed: 18,
      ongoing: 4,
      logo: 'https://images.unsplash.com/photo-1560518883-ce09059eeffa?w=200',
      about: 'Pioneer mixed-use property developer and destination creator across West Africa.',
      address: 'Water Corporation Drive, Oniru, Victoria Island, Lagos',
    },
    {
      email: 'eko.atlantic@developers.ng',
      firstName: 'Ronald',
      lastName: 'Chagoury',
      company: 'Eko Atlantic Urban Development PLC',
      cac: 'RC-892711',
      status: 'VERIFIED',
      isVerified: true,
      years: 18,
      completed: 25,
      ongoing: 8,
      logo: 'https://images.unsplash.com/photo-1486406146926-c627a92ad1ab?w=200',
      about: 'Master developer of the next financial capital of Africa, Eko Atlantic City.',
      address: 'Ahmadu Bello Way, Victoria Island, Lagos',
    },
    {
      email: 'haven.homes@nigeria.ng',
      firstName: 'Tayo',
      lastName: 'Sonuga',
      company: 'Haven Homes Nigeria Ltd',
      cac: 'RC-651920',
      status: 'VERIFIED',
      isVerified: true,
      years: 12,
      completed: 14,
      ongoing: 3,
      logo: 'https://images.unsplash.com/photo-1545324418-cc1a3fa10c00?w=200',
      about: 'Renowned for contemporary architectural luxury and bespoke residential developments.',
      address: 'Richmond Gate Estate, Ikate Elegushi, Lekki, Lagos',
    },
    {
      email: 'primestone@estates.ng',
      firstName: 'Abubakar',
      lastName: 'Sadiq',
      company: 'PrimeStone Urban Estates',
      cac: 'RC-778210',
      status: 'UNDER_REVIEW',
      isVerified: false,
      years: 5,
      completed: 3,
      ongoing: 2,
      logo: 'https://images.unsplash.com/photo-1497366216548-37526070297c?w=200',
      about: 'Focusing on middle-income smart housing in the Federal Capital Territory and environs.',
      address: 'Plot 1022 Constitution Avenue, Central Business District, Abuja',
    },
    {
      email: 'coastal@lekkihomes.ng',
      firstName: 'Biodun',
      lastName: 'Ogunleye',
      company: 'Lekki Coastal Developments Ltd',
      cac: 'RC-991204',
      status: 'VERIFIED_WITH_LIMITATIONS',
      isVerified: true,
      years: 7,
      completed: 6,
      ongoing: 2,
      logo: 'https://images.unsplash.com/photo-1577495508048-b635879837f1?w=200',
      about: 'Specialized in affordable serviced land subdivisions and beachside estates.',
      address: 'Kilometre 38 Lekki-Epe Expressway, Ibeju-Lekki, Lagos',
    },
  ];

  const createdDevelopers: any[] = [];

  for (const d of devUsersData) {
    const user = await prisma.user.create({
      data: {
        email: d.email,
        passwordHash,
        firstName: d.firstName,
        lastName: d.lastName,
        phone: '+2348088990011',
        role: 'DEVELOPER',
        isActive: true,
        isEmailVerified: true,
      },
    });

    const dev = await prisma.developer.create({
      data: {
        userId: user.id,
        companyName: d.company,
        cacNumber: d.cac,
        businessType: d.company.includes('PLC') ? 'PLC' : 'LTD',
        contactPerson: `${d.firstName} ${d.lastName}`,
        phone: '+2348088990011',
        email: d.email,
        officeAddress: d.address,
        yearsOperating: d.years,
        isVerified: d.isVerified,
        verificationStatus: d.status,
        verificationDate: d.isVerified ? new Date() : null,
        verifiedCategories: JSON.stringify(['CORPORATE_CAC', 'IDENTITY_DIRECTORS', 'PROJECT_TRACK_RECORD', 'TAX_COMPLIANCE']),
        logoUrl: d.logo,
        about: d.about,
        completedProjectsCount: d.completed,
        ongoingProjectsCount: d.ongoing,
      },
    });

    // Add sample directors
    await prisma.director.create({
      data: {
        developerId: dev.id,
        name: `${d.firstName} ${d.lastName}`,
        role: 'Managing Director / CEO',
        idType: 'NIN',
        idNumber: `NIN-9283719${Math.floor(100 + Math.random() * 900)}`,
      },
    });

    createdDevelopers.push(dev);
  }

  // 4. Create Properties
  const propertiesData = [
    {
      developerIndex: 0,
      title: '3 Bedroom Luxury Waterfront Terrace — Lekki Phase 1',
      slug: '3-bedroom-luxury-waterfront-terrace-lekki-phase-1',
      description: 'Stunning 3-bedroom terrace with direct waterfront views, private jetty access, 24/7 power, and smart home automation.',
      propertyType: 'RESIDENTIAL',
      listingType: 'PAY_SMALL_SMALL',
      state: 'Lagos',
      city: 'Lagos',
      area: 'Lekki Phase 1',
      address: 'Admiralty Way, Lekki Phase 1, Lagos',
      price: 110000000,
      bedrooms: 3,
      bathrooms: 4,
      landSize: '320 SQM',
      landTitle: 'GOVERNORS_CONSENT',
      images: [
        'https://images.unsplash.com/photo-1600596542815-ffad4c1539a9?w=800',
        'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?w=800',
        'https://images.unsplash.com/photo-1600607687939-ce8a6c25118c?w=800',
      ],
      isFeatured: true,
      plans: [
        { name: '24 Months Pay-Small-Small', initialDeposit: 20000000, durationMonths: 24, monthlyPayment: 3750000 },
        { name: '12 Months Structured Plan', initialDeposit: 30000000, durationMonths: 12, monthlyPayment: 6666667 },
      ],
    },
    {
      developerIndex: 1,
      title: '2 Bedroom Serviced Sky Apartment — Eko Atlantic City',
      slug: '2-bedroom-serviced-sky-apartment-eko-atlantic-city',
      description: 'Ultra-modern high-rise apartment in Azuri Towers, Eko Atlantic. Uninterrupted power, ocean views, and concierge services.',
      propertyType: 'APARTMENT',
      listingType: 'OFF_PLAN',
      state: 'Lagos',
      city: 'Lagos',
      area: 'Eko Atlantic City',
      address: 'Azuri Peninsula, Eko Atlantic, Victoria Island, Lagos',
      price: 185000000,
      bedrooms: 2,
      bathrooms: 3,
      landSize: '165 SQM',
      landTitle: 'C_OF_O',
      images: [
        'https://images.unsplash.com/photo-1545324418-cc1a3fa10c00?w=800',
        'https://images.unsplash.com/photo-1512917774080-9991f1c4c750?w=800',
      ],
      isFeatured: true,
      plans: [
        { name: '36 Months Off-Plan Milestone Plan', initialDeposit: 25000000, durationMonths: 36, monthlyPayment: 4444444 },
      ],
    },
    {
      developerIndex: 4,
      title: '600 SQM Dry Residential Land (C of O) — Alaro City, Epe',
      slug: '600-sqm-dry-residential-land-c-of-o-alaro-city-epe',
      description: '100% dry, perimeter-fenced serviced residential plot within master-planned Alaro City, Lekki-Epe expressway.',
      propertyType: 'LAND',
      listingType: 'PAY_SMALL_SMALL',
      state: 'Lagos',
      city: 'Epe',
      area: 'Alaro City Corridor',
      address: 'Lekki-Epe Expressway, Opposite Alaro City Main Gate, Epe',
      price: 28000000,
      bedrooms: 0,
      bathrooms: 0,
      landSize: '600 SQM',
      landTitle: 'C_OF_O',
      images: [
        'https://images.unsplash.com/photo-1500382017468-9049fed747ef?w=800',
        'https://images.unsplash.com/photo-1628624747186-a941c476b7ef?w=800',
      ],
      isFeatured: true,
      plans: [
        { name: '20 Months Pay-Small-Small', initialDeposit: 4000000, durationMonths: 20, monthlyPayment: 1200000 },
        { name: '12 Months Zero-Interest Plan', initialDeposit: 6000000, durationMonths: 12, monthlyPayment: 1833333 },
      ],
    },
    {
      developerIndex: 2,
      title: '4 Bedroom Semi-Detached Duplex with BQ — Richmond Gate, Lekki',
      slug: '4-bedroom-semi-detached-duplex-richmond-gate-lekki',
      description: 'Contemporary design, fully fitted Italian kitchen, swimming pool, gym, and 24-hour estate surveillance.',
      propertyType: 'HOUSE',
      listingType: 'OUTRIGHT',
      state: 'Lagos',
      city: 'Lagos',
      area: 'Ikate Elegushi',
      address: 'Richmond Gate Estate 2, Ikate, Lekki, Lagos',
      price: 155000000,
      bedrooms: 4,
      bathrooms: 5,
      landSize: '400 SQM',
      landTitle: 'GOVERNORS_CONSENT',
      images: [
        'https://images.unsplash.com/photo-1613490493576-7fde63acd811?w=800',
        'https://images.unsplash.com/photo-1600585154526-990dced4db0d?w=800',
      ],
      isFeatured: false,
      plans: [],
    },
    {
      developerIndex: 3,
      title: '4 Bedroom Contemporary Duplex — Guzape Hilltop, Abuja',
      slug: '4-bedroom-contemporary-duplex-guzape-abuja',
      description: 'Spectacular city vistas over Abuja metropolis. Private elevator, infinity swimming pool, and solar hybrid backup.',
      propertyType: 'HOUSE',
      listingType: 'PAY_SMALL_SMALL',
      state: 'Abuja (FCT)',
      city: 'Abuja',
      area: 'Guzape',
      address: 'Plot 418, Guzape District, Abuja',
      price: 165000000,
      bedrooms: 4,
      bathrooms: 5,
      landSize: '550 SQM',
      landTitle: 'C_OF_O',
      images: [
        'https://images.unsplash.com/photo-1600565193348-f74bd3c7ccdf?w=800',
      ],
      isFeatured: true,
      plans: [
        { name: '18 Months Flexible Plan', initialDeposit: 30000000, durationMonths: 18, monthlyPayment: 7500000 },
      ],
    },
    {
      developerIndex: 0,
      title: '1 Acre Commercial Waterfront Land — Victoria Island',
      slug: '1-acre-commercial-waterfront-land-victoria-island',
      description: 'Prime commercial land suitable for hotel, office tower, or mixed-use development with direct Atlantic frontage.',
      propertyType: 'COMMERCIAL',
      listingType: 'OUTRIGHT',
      state: 'Lagos',
      city: 'Lagos',
      area: 'Victoria Island',
      address: 'Water Corporation Drive, Victoria Island, Lagos',
      price: 950000000,
      bedrooms: 0,
      bathrooms: 0,
      landSize: '4046 SQM (1 Acre)',
      landTitle: 'GOVERNORS_CONSENT',
      images: [
        'https://images.unsplash.com/photo-1486406146926-c627a92ad1ab?w=800',
      ],
      isFeatured: false,
      plans: [],
    },
    {
      developerIndex: 4,
      title: '500 SQM Residential Plot — Shimawa, Ogun State',
      slug: '500-sqm-residential-plot-shimawa-ogun-state',
      description: 'Fully surveyed, instant allocation plot in a peaceful gated community behind RCCG Redemption Camp.',
      propertyType: 'LAND',
      listingType: 'PAY_SMALL_SMALL',
      state: 'Ogun',
      city: 'Shimawa',
      area: 'Redemption Camp Corridor',
      address: 'Haven Court, Shimawa, Ogun State',
      price: 7500000,
      bedrooms: 0,
      bathrooms: 0,
      landSize: '500 SQM',
      landTitle: 'DEED_OF_ASSIGNMENT',
      images: [
        'https://images.unsplash.com/photo-1500382017468-9049fed747ef?w=800',
      ],
      isFeatured: false,
      plans: [
        { name: '20 Months Pay-Small-Small', initialDeposit: 1500000, durationMonths: 20, monthlyPayment: 300000 },
      ],
    },
    {
      developerIndex: 2,
      title: '3 Bedroom Penthouse — Old Ikoyi, Lagos',
      slug: '3-bedroom-penthouse-old-ikoyi-lagos',
      description: 'Exquisite penthouse occupying the top two floors with wrap-around terrace and private infinity splash pool.',
      propertyType: 'APARTMENT',
      listingType: 'OUTRIGHT',
      state: 'Lagos',
      city: 'Lagos',
      area: 'Ikoyi',
      address: 'Bour Bourdillon Road, Old Ikoyi, Lagos',
      price: 320000000,
      bedrooms: 3,
      bathrooms: 4,
      landSize: '420 SQM',
      landTitle: 'GOVERNORS_CONSENT',
      images: [
        'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?w=800',
      ],
      isFeatured: true,
      plans: [],
    },
    {
      developerIndex: 0,
      title: '2 Bedroom Smart Apartment — Ikeja GRA, Lagos',
      slug: '2-bedroom-smart-apartment-ikeja-gra-lagos',
      description: 'Centrally located luxury apartment with elevator, swimming pool, club house, and 24/7 security patrol.',
      propertyType: 'APARTMENT',
      listingType: 'PAY_SMALL_SMALL',
      state: 'Lagos',
      city: 'Ikeja',
      area: 'Ikeja GRA',
      address: 'Isaac John Street, Ikeja GRA, Lagos',
      price: 75000000,
      bedrooms: 2,
      bathrooms: 2,
      landSize: '140 SQM',
      landTitle: 'C_OF_O',
      images: [
        'https://images.unsplash.com/photo-1560448204-e02f11c3d0e2?w=800',
      ],
      isFeatured: false,
      plans: [
        { name: '15 Months Structured Plan', initialDeposit: 15000000, durationMonths: 15, monthlyPayment: 4000000 },
      ],
    },
    {
      developerIndex: 3,
      title: '4 Bedroom Terrace with BQ — Katampe Extension, Abuja',
      slug: '4-bedroom-terrace-with-bq-katampe-extension-abuja',
      description: 'Contemporary hillside terrace units with panoramic views, paved access roads, and solar street lighting.',
      propertyType: 'HOUSE',
      listingType: 'PAY_SMALL_SMALL',
      state: 'Abuja (FCT)',
      city: 'Abuja',
      area: 'Katampe Extension',
      address: 'Diplomatic Zone Road, Katampe Extension, Abuja',
      price: 135000000,
      bedrooms: 4,
      bathrooms: 5,
      landSize: '350 SQM',
      landTitle: 'C_OF_O',
      images: [
        'https://images.unsplash.com/photo-1600565193348-f74bd3c7ccdf?w=800',
      ],
      isFeatured: false,
      plans: [
        { name: '24 Months Pay-Small-Small', initialDeposit: 25000000, durationMonths: 24, monthlyPayment: 4583333 },
      ],
    },
  ];

  for (const p of propertiesData) {
    const dev = createdDevelopers[p.developerIndex];
    const property = await prisma.property.create({
      data: {
        developerId: dev.id,
        title: p.title,
        slug: p.slug,
        description: p.description,
        propertyType: p.propertyType,
        listingType: p.listingType,
        state: p.state,
        city: p.city,
        area: p.area,
        address: p.address,
        price: p.price,
        bedrooms: p.bedrooms,
        bathrooms: p.bathrooms,
        landSize: p.landSize,
        landTitle: p.landTitle,
        verificationStatus: 'VERIFIED',
        isPublished: true,
        isFeatured: p.isFeatured,
        images: JSON.stringify(p.images),
        completionStatus: 'COMPLETED',
      },
    });

    for (const plan of p.plans) {
      await prisma.paymentPlan.create({
        data: {
          propertyId: property.id,
          name: plan.name,
          totalPrice: p.price,
          initialDeposit: plan.initialDeposit,
          durationMonths: plan.durationMonths,
          monthlyPayment: plan.monthlyPayment,
          paymentFrequency: 'MONTHLY',
          platformFee: 5000,
        },
      });
    }
  }

  // 5. Create 5 Off-Plan Projects with Construction Milestones
  const projectsData = [
    {
      developerIndex: 1,
      name: 'The Atlantic Horizon Residences',
      slug: 'the-atlantic-horizon-residences',
      description: 'Iconic 25-floor twin oceanfront residential towers overlooking the Atlantic Ocean in Eko Atlantic City.',
      state: 'Lagos',
      city: 'Lagos',
      area: 'Eko Atlantic City',
      address: 'Ocean Front Drive, Eko Atlantic, Lagos',
      totalUnits: 60,
      availableUnits: 24,
      expectedCompletion: 'December 2027',
      images: ['https://images.unsplash.com/photo-1545324418-cc1a3fa10c00?w=800'],
      milestones: [
        { title: 'Substructure & Piling', percentage: 100, status: 'COMPLETED', order: 1 },
        { title: 'Ground Floor to 10th Floor Framing', percentage: 100, status: 'COMPLETED', order: 2 },
        { title: '11th to 25th Floor Structural Framing', percentage: 65, status: 'IN_PROGRESS', order: 3 },
        { title: 'External Cladding & Glazing', percentage: 20, status: 'IN_PROGRESS', order: 4 },
        { title: 'Plumbing & Electrical Rough-Ins', percentage: 10, status: 'PENDING', order: 5 },
        { title: 'Internal Luxury Finishing', percentage: 0, status: 'PENDING', order: 6 },
        { title: 'External Landscaping & Handover', percentage: 0, status: 'PENDING', order: 7 },
      ],
      units: [
        { type: '2 Bedroom Flat', name: 'Deluxe Ocean View Flat', price: 160000000, deposit: 25000000, duration: 36, monthly: 3750000, total: 30, available: 12 },
        { type: '3 Bedroom Terrace', name: 'Executive Sky Villa', price: 240000000, deposit: 40000000, duration: 36, monthly: 5555555, total: 20, available: 8 },
        { type: '4 Bedroom Duplex', name: 'Presidential Penthouse', price: 420000000, deposit: 70000000, duration: 36, monthly: 9722222, total: 10, available: 4 },
      ],
    },
    {
      developerIndex: 0,
      name: 'Coral Sands Smart Terraces',
      slug: 'coral-sands-smart-terraces',
      description: 'Exclusive cluster of 36 smart solar-powered townhouses with integrated fiber internet and biometric security.',
      state: 'Lagos',
      city: 'Lagos',
      area: 'Lekki Scheme 2',
      address: 'Ogombo Road, Lekki Scheme 2, Lagos',
      totalUnits: 36,
      availableUnits: 14,
      expectedCompletion: 'June 2027',
      images: ['https://images.unsplash.com/photo-1600596542815-ffad4c1539a9?w=800'],
      milestones: [
        { title: 'Foundation & Raft Slab', percentage: 100, status: 'COMPLETED', order: 1 },
        { title: 'Superstructure Framing', percentage: 80, status: 'IN_PROGRESS', order: 2 },
        { title: 'Roofing & Parapet Walls', percentage: 30, status: 'IN_PROGRESS', order: 3 },
        { title: 'Mechanical & Electrical', percentage: 0, status: 'PENDING', order: 4 },
        { title: 'Finishing & Smart Fitouts', percentage: 0, status: 'PENDING', order: 5 },
      ],
      units: [
        { type: '3 Bedroom Terrace', name: 'Emerald Smart Terrace', price: 85000000, deposit: 15000000, duration: 24, monthly: 2916667, total: 24, available: 10 },
        { type: '4 Bedroom Duplex', name: 'Diamond Corner Villa', price: 115000000, deposit: 20000000, duration: 24, monthly: 3958333, total: 12, available: 4 },
      ],
    },
    {
      developerIndex: 3,
      name: 'Abuja Diplomatic Residences',
      slug: 'abuja-diplomatic-residences',
      description: 'A low-density sanctuary of 24 ultra-luxury modern villas in Guzape with panoramic views of the FCT.',
      state: 'Abuja (FCT)',
      city: 'Abuja',
      area: 'Guzape',
      address: 'Diplomatic Heights, Guzape, Abuja',
      totalUnits: 24,
      availableUnits: 9,
      expectedCompletion: 'November 2027',
      images: ['https://images.unsplash.com/photo-1600585154340-be6161a56a0c?w=800'],
      milestones: [
        { title: 'Earthworks & Retaining Walls', percentage: 100, status: 'COMPLETED', order: 1 },
        { title: 'Foundation Casting', percentage: 100, status: 'COMPLETED', order: 2 },
        { title: 'First Floor Slabs', percentage: 50, status: 'IN_PROGRESS', order: 3 },
        { title: 'Roofing Structure', percentage: 0, status: 'PENDING', order: 4 },
      ],
      units: [
        { type: '4 Bedroom Duplex', name: 'The Diplomat Villa', price: 195000000, deposit: 35000000, duration: 24, monthly: 6666667, total: 16, available: 6 },
        { type: '5 Bedroom Mansion', name: 'The Ambassador Mansion', price: 310000000, deposit: 50000000, duration: 24, monthly: 10833333, total: 8, available: 3 },
      ],
    },
    {
      developerIndex: 4,
      name: 'Epe Haven Eco-Community',
      slug: 'epe-haven-eco-community',
      description: 'A 20-hectare green gated ecosystem featuring solar power, central water purification, paved walkways, and recreation hub.',
      state: 'Lagos',
      city: 'Epe',
      area: 'Ketuv-Epe',
      address: 'Epe-Itokin Road, Epe, Lagos',
      totalUnits: 120,
      availableUnits: 65,
      expectedCompletion: 'August 2026',
      images: ['https://images.unsplash.com/photo-1500382017468-9049fed747ef?w=800'],
      milestones: [
        { title: 'Site Clearing & Perimeter Fencing', percentage: 100, status: 'COMPLETED', order: 1 },
        { title: 'Drainage Network & Interlocked Spine Roads', percentage: 90, status: 'IN_PROGRESS', order: 2 },
        { title: 'Gatehouse & Security Infrastructure', percentage: 100, status: 'COMPLETED', order: 3 },
        { title: 'Electrification & Solar Street Lighting', percentage: 40, status: 'IN_PROGRESS', order: 4 },
      ],
      units: [
        { type: 'Land Plot (300 SQM)', name: 'Half Plot Eco-Plot', price: 6500000, deposit: 1000000, duration: 18, monthly: 305555, total: 50, available: 25 },
        { type: 'Land Plot (600 SQM)', name: 'Standard Residential Plot', price: 12000000, deposit: 2000000, duration: 18, monthly: 555555, total: 70, available: 40 },
      ],
    },
    {
      developerIndex: 2,
      name: 'The Crown Heights Luxury Flats',
      slug: 'the-crown-heights-luxury-flats',
      description: '16 bespoke residential suites in Old Ikoyi with private cinema, squash court, heated pool, and concierge.',
      state: 'Lagos',
      city: 'Lagos',
      area: 'Ikoyi',
      address: 'Glover Road, Old Ikoyi, Lagos',
      totalUnits: 16,
      availableUnits: 5,
      expectedCompletion: 'March 2028',
      images: ['https://images.unsplash.com/photo-1512917774080-9991f1c4c750?w=800'],
      milestones: [
        { title: 'Demolition & Deep Piling', percentage: 100, status: 'COMPLETED', order: 1 },
        { title: 'Basement & Ground Floor Slab', percentage: 40, status: 'IN_PROGRESS', order: 2 },
      ],
      units: [
        { type: '3 Bedroom Flat', name: 'Royal Executive Suite', price: 290000000, deposit: 50000000, duration: 30, monthly: 8000000, total: 12, available: 3 },
        { type: '4 Bedroom Penthouse', name: 'Imperial Sky Villa', price: 550000000, deposit: 100000000, duration: 30, monthly: 15000000, total: 4, available: 2 },
      ],
    },
  ];

  for (const p of projectsData) {
    const dev = createdDevelopers[p.developerIndex];
    const project = await prisma.project.create({
      data: {
        developerId: dev.id,
        name: p.name,
        slug: p.slug,
        description: p.description,
        state: p.state,
        city: p.city,
        area: p.area,
        address: p.address,
        totalUnits: p.totalUnits,
        availableUnits: p.availableUnits,
        images: JSON.stringify(p.images),
        expectedCompletion: p.expectedCompletion,
        status: 'UNDER_CONSTRUCTION',
        isVerified: true,
      },
    });

    for (const m of p.milestones) {
      await prisma.constructionMilestone.create({
        data: {
          projectId: project.id,
          title: m.title,
          percentage: m.percentage,
          status: m.status,
          orderIndex: m.order,
          verifiedBy: 'EstateVerify Technical Inspection Team',
        },
      });
    }

    for (const u of p.units) {
      const unit = await prisma.projectUnit.create({
        data: {
          projectId: project.id,
          unitType: u.type,
          name: u.name,
          price: u.price,
          initialDeposit: u.deposit,
          durationMonths: u.duration,
          monthlyInstalment: u.monthly,
          totalUnits: u.total,
          availableUnits: u.available,
          status: 'AVAILABLE',
        },
      });

      await prisma.paymentPlan.create({
        data: {
          projectUnitId: unit.id,
          name: `${u.duration} Months Project Payment Plan`,
          totalPrice: u.price,
          initialDeposit: u.deposit,
          durationMonths: u.duration,
          monthlyPayment: u.monthly,
          paymentFrequency: 'MONTHLY',
          platformFee: 5000,
        },
      });
    }
  }

  // 6. Create Sample Verification Requests
  const verif1 = await prisma.verificationRequest.create({
    data: {
      verificationCode: 'EV-VER-000123',
      userId: buyer1.id,
      propertyName: 'Plot 42, Block B, Lekki Phase 1',
      propertyAddress: 'Admiralty Way, Lekki Phase 1, Lagos',
      state: 'Lagos',
      city: 'Lagos',
      documentType: 'C_OF_O',
      status: 'VERIFIED',
      urgency: 'STANDARD',
      feeAmount: 25000,
      isPaid: true,
      assignedTo: 'Barrister Folake Adeleke',
      externalRegistryChecked: true,
      externalRegistryNotes: 'Title verified at Lagos State Land Registry Alausa under Vol 204, Page 12.',
      finalFindings: 'Valid Certificate of Occupancy. No unrecorded lis pendens, encumbrances, or statutory acquisitions found.',
      reportUrl: 'http://localhost:5000/api/v1/storage/files/sample_report.pdf',
    },
  });

  await prisma.verificationDocument.create({
    data: {
      verificationRequestId: verif1.id,
      fileName: 'Lekki_Plot_42_CofO.pdf',
      fileUrl: 'http://localhost:5000/api/v1/storage/files/sample_cofo.pdf',
      fileType: 'PDF',
      fileSize: 2450000,
      aiScanSummary: 'Preliminary AI scan confirmed valid C of O header, SURCON surveyor stamp, and matching plot boundaries.',
    },
  });

  await prisma.verificationCheckItem.createMany({
    data: [
      { verificationRequestId: verif1.id, checkName: 'Lagos State Lands Bureau Registry Match', category: 'REGISTRY', status: 'PASS', notes: 'Registry records match assignor name' },
      { verificationRequestId: verif1.id, checkName: 'SURCON Surveyor Beacon Verification', category: 'SURVEY', status: 'PASS', notes: 'Coordinates verified with surveyor board' },
      { verificationRequestId: verif1.id, checkName: 'Statutory Acquisition & Committed Road Setback Check', category: 'TITLE', status: 'PASS', notes: 'Plot is outside road acquisition zones' },
    ],
  });

  // 7. Create Sample Legal Request
  await prisma.legalRequest.create({
    data: {
      requestCode: 'EV-LEG-00045',
      userId: buyer2.id,
      documentCategory: 'SALE_AGREEMENT',
      title: 'Contract of Sale & Deed of Assignment for Maitama Property',
      requirements: 'Drafting structured contract of sale with 3 milestone tranches and dispute resolution arbitration clause.',
      feeAmount: 45000,
      status: 'FINALIZED',
      isPaid: true,
      finalDocumentUrl: 'http://localhost:5000/api/v1/storage/files/contract_of_sale_final.docx',
    },
  });

  // 8. Create Sample Purchase and Payments
  const sampleProp = await prisma.property.findFirst({
    where: { slug: '600-sqm-dry-residential-land-c-of-o-alaro-city-epe' },
    include: { paymentPlans: true },
  });

  if (sampleProp && sampleProp.paymentPlans[0]) {
    const purchase = await prisma.purchase.create({
      data: {
        purchaseCode: 'EV-PUR-2026-001',
        userId: buyer1.id,
        propertyId: sampleProp.id,
        paymentPlanId: sampleProp.paymentPlans[0].id,
        status: 'ACTIVE',
        totalPrice: 28000000,
        initialDeposit: 4000000,
        amountPaid: 6400000,
        outstandingBalance: 2160000,
        nextPaymentAmount: 1200000,
        nextPaymentDueDate: new Date(Date.now() + 25 * 24 * 60 * 60 * 1000),
        agreementDocumentUrl: 'http://localhost:5000/api/v1/storage/files/purchase_agreement_signed.pdf',
        signatureDate: new Date(),
      },
    });

    // Initial Deposit Payment
    await prisma.payment.create({
      data: {
        paymentReference: 'EV-PAY-INIT-001',
        purchaseId: purchase.id,
        userId: buyer1.id,
        developerId: sampleProp.developerId,
        amount: 4000000,
        platformFee: 5000,
        processingFee: 2000,
        totalAmount: 4007000,
        currency: 'NGN',
        purpose: 'INITIAL_DEPOSIT',
        status: 'SUCCESS',
        paystackReference: 'pstk_ref_init_001',
        paystackChannel: 'card',
        paidAt: new Date(Date.now() - 60 * 24 * 60 * 60 * 1000),
        verifiedAt: new Date(Date.now() - 60 * 24 * 60 * 60 * 1000),
        receiptNumber: 'RCP-2026-00192',
      },
    });

    // Month 1 Instalment
    await prisma.payment.create({
      data: {
        paymentReference: 'EV-PAY-INST-002',
        purchaseId: purchase.id,
        userId: buyer1.id,
        developerId: sampleProp.developerId,
        amount: 1200000,
        platformFee: 5000,
        processingFee: 2000,
        totalAmount: 1207000,
        currency: 'NGN',
        purpose: 'INSTALMENT',
        status: 'SUCCESS',
        paystackReference: 'pstk_ref_inst_002',
        paystackChannel: 'bank_transfer',
        paidAt: new Date(Date.now() - 30 * 24 * 60 * 60 * 1000),
        verifiedAt: new Date(Date.now() - 30 * 24 * 60 * 60 * 1000),
        receiptNumber: 'RCP-2026-00381',
      },
    });

    // Month 2 Instalment
    await prisma.payment.create({
      data: {
        paymentReference: 'EV-PAY-INST-003',
        purchaseId: purchase.id,
        userId: buyer1.id,
        developerId: sampleProp.developerId,
        amount: 1200000,
        platformFee: 5000,
        processingFee: 2000,
        totalAmount: 1207000,
        currency: 'NGN',
        purpose: 'INSTALMENT',
        status: 'SUCCESS',
        paystackReference: 'pstk_ref_inst_003',
        paystackChannel: 'card',
        paidAt: new Date(),
        verifiedAt: new Date(),
        receiptNumber: 'RCP-2026-00512',
      },
    });
  }

  // 9. Create Sample Audit Logs
  await prisma.auditLog.createMany({
    data: [
      {
        adminEmail: 'admin@estateverify.ng',
        action: 'DEVELOPER_VERIFIED',
        entityType: 'DEVELOPER',
        entityId: createdDevelopers[0].id,
        details: JSON.stringify({ company: 'Landmark Africa Holdings', cacVerified: true }),
      },
      {
        adminEmail: 'verification@estateverify.ng',
        action: 'VERIFICATION_REPORT_APPROVED',
        entityType: 'VERIFICATION_REQUEST',
        entityId: verif1.id,
        details: JSON.stringify({ code: 'EV-VER-000123', outcome: 'VERIFIED' }),
      },
    ],
  });

  console.log('EstateVerify database seeded successfully with comprehensive Nigerian proptech data!');
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
