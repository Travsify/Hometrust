# EstateVerify — Nigerian Real Estate Verification, Off-Plan & Pay-Small-Small Platform

> **"Verify. Buy. Pay. Track."**
> A production-ready, cross-platform real-estate technology platform built for the Nigerian market with document verification workflows, verified developer onboarding, off-plan project milestone tracking, and transparent pay-small-small instalment purchases.

---

## 🏗️ Architecture & Modules Overview

```
Hometrust/
├── backend/                   # Node.js + TypeScript + Express + Prisma REST API
│   ├── prisma/                # Prisma schema, migrations, and comprehensive seed data
│   ├── src/
│   │   ├── config/            # Environment & Service configuration (Paystack, Storage)
│   │   ├── middlewares/       # JWT Auth, RBAC, Zod validation, Error handlers
│   │   ├── modules/
│   │   │   ├── auth/          # Registration, login, profile management
│   │   │   ├── properties/    # Property listings, search filters, land titles
│   │   │   ├── projects/      # Off-plan developments, construction milestones
│   │   │   ├── developers/    # CAC verification, director checks, track records
│   │   │   ├── payments/      # Paystack integration, platform fee splits, receipts
│   │   │   ├── verifications/ # AI preliminary analysis, legal review queue, PDF reports
│   │   │   ├── legal/         # Real estate legal document drafting workflow
│   │   │   ├── purchases/     # Buyer purchase ledger & instalment calculator
│   │   │   ├── inspections/   # Physical site inspection scheduling
│   │   │   ├── chat/          # In-app messaging
│   │   │   ├── notifications/ # Push and in-app notifications
│   │   │   ├── audit/         # Tamper-evident security and regulatory audit logs
│   │   │   ├── admin/         # Metrics, user management, platform fee configs
│   │   │   └── storage/       # Secure file upload and access control
│   │   └── server.ts          # Express server entry point
│   └── tests/                 # Jest + Supertest integration and financial calculation unit tests
│
├── admin_dashboard/           # Responsive Web Admin Console (React 19 + Vite + Tailwind CSS)
│   ├── src/
│   │   ├── components/        # Sidebar, Header, KPI Cards
│   │   ├── pages/             # Dashboard, Verifications, Developers, Properties, Projects,
│   │   │                      # Payments & Reconciliation, Legal Requests, Audit Logs, Settings
│   │   └── services/          # Axios API client
│   └── dist/                  # Production build output
│
└── mobile_app/                # Cross-platform Mobile App (Flutter 3.38+ / Dart 3.10+)
    └── lib/
        ├── core/              # Theme palette, constants, API client, CurrencyFormatter (₦)
        ├── models/            # User, Property, Project, Verification, Purchase models
        ├── providers/         # Auth, Property, Verification, Purchase state management
        └── screens/           # Home, Explore, PropertyDetail, ProjectDetail, Verify, Purchases, Profile
```

---

## 🔒 Compliance & Non-Custodial Safeguards

1. **Non-Custodial Architecture**: EstateVerify strictly routes transaction payments directly to merchant/developer accounts using configured Paystack subaccounts/settlement infrastructure. The platform does not hold pooled client deposits or operate un-regulated wallets.
2. **Document & Verification Disclaimers**: AI preliminary scans are clearly flagged as preliminary assistive checks. Official PDF verification reports and legal preparation workflows are executed by the internal **EstateVerify Legal & Verification Team** and state that reports do not guarantee title against unrecorded future disputes.
3. **No Crowdfunding / Public Securities in V1**: The database and architecture are designed to be extensible for regulated SPVs and co-ownership in future releases without exposing them in V1.

---

## 🚀 Local Development Setup

### Prerequisites
- **Node.js**: v18+ (v24 recommended)
- **Flutter SDK**: v3.38+
- **Database**: SQLite (default zero-config local) or PostgreSQL

### 1. Backend Setup
```bash
cd backend
npm install
npx prisma generate
npx prisma db push
npx tsx prisma/seed.ts
npm test                 # Run automated test suite
npm run dev              # Start API on http://localhost:5000
```

### 2. Admin Dashboard Setup
```bash
cd ../admin_dashboard
npm install
npm run dev              # Starts on http://localhost:3000
npm run build            # Production build
```

### 3. Flutter Mobile App Setup
```bash
cd ../mobile_app
flutter pub get
flutter analyze          # Verify zero lint errors
flutter run              # Launch on connected device / emulator / Chrome
```

---

## ☁️ Supabase & OpenAI Integration

### 1. Connecting Supabase for Backend Data & Document Storage
- **PostgreSQL Database**:
  1. In your [Supabase Dashboard](https://supabase.com), copy your PostgreSQL Connection String under **Project Settings -> Database**.
  2. Set `DATABASE_URL="postgresql://postgres.[REF]:[PASSWORD]@aws-0-[REGION].pooler.supabase.com:6543/postgres?pgbouncer=true"` in `backend/.env`.
  3. In `backend/prisma/schema.prisma`, set `provider = "postgresql"` and run:
     ```bash
     npx prisma db push
     npx tsx prisma/seed.ts
     ```
- **Supabase Storage (Secure Document Vault)**:
  1. Add `SUPABASE_URL` and `SUPABASE_SERVICE_ROLE_KEY` to `backend/.env`.
  2. Documents uploaded for verification (C of O, Deeds, Surveys) can be stored in a private Supabase bucket (`estateverify-documents`) with time-limited signed URLs.

### 2. Testing AI Document Scanning with OpenAI Keys
- You can provide your **OpenAI API Key** (`sk-...`) in `backend/.env`:
  ```env
  OPENAI_API_KEY="sk-proj-your-openai-api-key-here"
  OPENAI_MODEL="gpt-4o-mini"
  ```
- **How it works**:
  - When an API key is provided, the backend automatically uses `gpt-4o-mini` with structured JSON schema output to parse and inspect surveyor registration (SURCON), plot coordinates, assignor/assignee covenants, stamping endorsements, and title consistency.
  - If no OpenAI key is set (or if credits run out), the system **automatically falls back to the built-in deterministic heuristic rule engine** so your tests and development workflows never break.

---

## 🧪 Testing & Verification

### Automated Test Coverage:
- **Financial Calculations**: Verified platform fee splits (₦5,000 + 1.5% processing fee capped at ₦2,000) without floating point inaccuracies.
- **Paystack Webhook & Idempotency**: Verified server-side HMAC SHA512 signature validation.
- **Authentication & RBAC**: Tested user registration, login, role restrictions (`SUPER_ADMIN`, `LEGAL_MANAGER`, `BUYER`, `DEVELOPER`).
- **Document Verification Workflow**: Tested verification creation -> AI scan -> Legal approval -> PDF report generation.
