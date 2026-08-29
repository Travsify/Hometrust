import { z } from 'zod';

export const registerSchema = z.object({
  email: z.string().email(),
  password: z.string().min(6, 'Password must be at least 6 characters'),
  firstName: z.string().min(2),
  lastName: z.string().min(2),
  phone: z.string().optional(),
  role: z.enum(['BUYER', 'DEVELOPER']).default('BUYER'),
  
  // Optional developer onboarding info during registration
  developerInfo: z.object({
    companyName: z.string().min(2),
    cacNumber: z.string().min(5),
    businessType: z.string().default('LTD'),
    contactPerson: z.string().min(2),
    officeAddress: z.string().min(5),
    yearsOperating: z.number().default(1),
    website: z.string().optional(),
    about: z.string().optional(),
  }).optional(),
});

export const loginSchema = z.object({
  email: z.string().email(),
  password: z.string().min(1, 'Password is required'),
});

export const updateProfileSchema = z.object({
  firstName: z.string().optional(),
  lastName: z.string().optional(),
  phone: z.string().optional(),
  state: z.string().optional(),
  city: z.string().optional(),
  address: z.string().optional(),
  occupation: z.string().optional(),
  nextOfKinName: z.string().optional(),
  nextOfKinPhone: z.string().optional(),
});
