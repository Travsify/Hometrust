import request from 'supertest';
import app from '../src/app';
import { prisma } from '../src/utils/prisma';

jest.setTimeout(30000);

describe('Hometrust API Integration Test Suite', () => {
  let authToken = '';

  beforeAll(async () => {
    // Clean up any test user if exists
    await prisma.user.deleteMany({
      where: { email: { in: ['testbuyer@hometrust.ng'] } },
    });
  });

  afterAll(async () => {
    await prisma.$disconnect();
  });

  it('GET /health should return 200 with platform info', async () => {
    const res = await request(app).get('/health');
    expect(res.status).toBe(200);
    expect(res.body.platform).toContain('Hometrust API');
    expect(res.body.tagline).toBe('Verify. Buy. Pay. Track.');
  });

  it('POST /api/v1/auth/register should create a new buyer user', async () => {
    const res = await request(app).post('/api/v1/auth/register').send({
      email: 'testbuyer@hometrust.ng',
      password: 'Password123!',
      firstName: 'Tunde',
      lastName: 'Bakare',
      phone: '+2348031112233',
      role: 'BUYER',
    });

    expect(res.status).toBe(201);
    expect(res.body.success).toBe(true);
    expect(res.body.data.token).toBeDefined();
    expect(res.body.data.user.email).toBe('testbuyer@hometrust.ng');
    authToken = res.body.data.token;
  });

  it('POST /api/v1/auth/login should authenticate user and return token', async () => {
    const res = await request(app).post('/api/v1/auth/login').send({
      email: 'testbuyer@hometrust.ng',
      password: 'Password123!',
    });

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.data.token).toBeDefined();
  });

  it('GET /api/v1/properties should list properties with filters', async () => {
    const res = await request(app).get('/api/v1/properties?state=Lagos');
    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(Array.isArray(res.body.data)).toBe(true);
  });

  it('POST /api/v1/verifications should create a document verification request and trigger AI analysis', async () => {
    const res = await request(app)
      .post('/api/v1/verifications')
      .set('Authorization', `Bearer ${authToken}`)
      .send({
        propertyName: 'Plot 10, Victoria Garden City',
        propertyAddress: 'Road 5, VGC, Lekki, Lagos',
        state: 'Lagos',
        city: 'Lagos',
        documentType: 'C_OF_O',
        urgency: 'STANDARD',
        documents: [
          {
            fileName: 'VGC_Plot10_CofO.pdf',
            fileUrl: 'http://localhost:5000/api/v1/storage/files/vgc_cofo.pdf',
            fileType: 'PDF',
            fileSize: 1200000,
          },
        ],
      });

    expect(res.status).toBe(201);
    expect(res.body.success).toBe(true);
    expect(res.body.data.verificationCode).toBeDefined();
    expect(res.body.data.status).toBe('SUBMITTED');
    expect(res.body.data.documents.length).toBeGreaterThan(0);
    expect(res.body.data.documents[0].aiScanSummary).toBeDefined();
  });

  it('POST /api/v1/payments/initialize should calculate fees and return Paystack checkout info', async () => {
    const res = await request(app)
      .post('/api/v1/payments/initialize')
      .set('Authorization', `Bearer ${authToken}`)
      .send({
        amount: 25000,
        purpose: 'VERIFICATION_FEE',
      });

    expect(res.status).toBe(201);
    expect(res.body.success).toBe(true);
    expect(res.body.data.paymentReference).toBeDefined();
    expect(res.body.data.authorizationUrl).toBeDefined();
  });
});
