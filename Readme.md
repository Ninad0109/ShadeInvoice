# 🧾 ShadeInvoice – Development Checklist

> **Goal:** Build an offline-first, secure, scalable invoice platform that can grow into a SaaS without rewrites.

> **Team Context:** 3-4 friends learning Java together, preparing for internships. Strategic choice: Java Spring Boot for learning + resume building (favored by Indian tech companies).

---

## 🧭 Phase 0 – Team Alignment (DO FIRST)

- [ ] Decide team roles (Flutter / Backend / Infra)
- [ ] Decide repo strategy (mono-repo or multi-repo)
- [ ] Define Git rules
    - No direct commits to `main`
    - Feature branches only
    - PR review required
- [ ] Write a 1-page vision doc (scope + non-goals)

---

## 🎯 Phase 0.5 – Product Definition (CRITICAL)

### Pricing & Tiers
- [ ] **Free Tier:** 10 invoices/month, basic templates, local storage only
- [ ] **Pro Tier:** Unlimited invoices, email sending, custom templates, cloud sync
- [ ] **Pricing:** ₹299-499/month (Indian market)
- [ ] **Target Market:** Freelancers and small businesses in India

### Feature Gating Strategy
- [ ] Document which features are Free vs Pro
- [ ] Define upgrade prompts and messaging
- [ ] Plan trial period (7-14 days free Pro access)

---

## 🧱 Phase 1 – Core Foundation (HIGH PRIORITY)

### Data & Architecture
- [ ] Replace `SharedPreferences` → **Hive**
- [ ] Add UUIDs for all entities
- [ ] Introduce `InvoiceStatus` enum  
  (`DRAFT`, `SENT`, `PAID`, `OVERDUE`, `CANCELLED`)
- [ ] Add timestamps (`createdAt`, `updatedAt`)
- [ ] Freeze totals at invoice creation
- [ ] Move all calculations to domain layer
- [ ] Separate **local** and **remote** repositories
- [ ] Ensure **no business logic in UI**

### Invoice Domain Logic
- [ ] Subtotal calculation
- [ ] Tax model (name, rate, amount)
- [ ] Discount model
- [ ] Final total calculation
- [ ] Invoice numbering system
- [ ] Prevent editing PAID invoices

---

## 🧪 Phase 1.5 – Testing Foundation (ADD THIS)

### Testing Strategy
- [ ] Unit tests for invoice calculations
- [ ] Unit tests for domain logic (tax, discount, totals)
- [ ] Widget tests for critical user flows
- [ ] Test invoice status transitions
- [ ] Test data validation logic

### CI/CD Pipeline
- [ ] Set up GitHub Actions workflow
- [ ] Run tests on every PR
- [ ] Code coverage reporting (target 80%)
- [ ] Enforce linting rules
- [ ] Automated build checks

### Quality Gates
- [ ] Require tests for new features
- [ ] Block PRs with failing tests
- [ ] Review test coverage in PRs

---

## 💾 Phase 2 – Backup & Safety

- [ ] Export all app data → JSON file
- [ ] Import JSON → restore data
- [ ] App-level "Reset Data" option
- [ ] Add `version` field to models
- [ ] Validate imported data structure
- [ ] Handle migration between versions

---

## 📊 Phase 2.5 – Observability (ADD THIS)

### Error Tracking
- [ ] Integrate Sentry for crash reporting
- [ ] Set up error alerts
- [ ] Track critical user flows
- [ ] Monitor app performance metrics

### Logging Strategy
- [ ] Implement structured logging in backend
- [ ] Log all API requests/responses
- [ ] Track sync operations
- [ ] Monitor payment transactions

### Health Monitoring
- [ ] Backend health check endpoint
- [ ] Database connection monitoring
- [ ] API response time tracking
- [ ] Set up uptime monitoring

---

## 🔐 Phase 3 – Supabase Integration (No Features Yet)

- [ ] Create Supabase project
- [ ] Enable email authentication
- [ ] Build login / signup UI
- [ ] Store Supabase `userId` locally
- [ ] Handle JWT tokens in Flutter
- [ ] ❌ No direct DB access from Flutter
- [ ] Add SyncPolicy (localOnly / cloudSync)
- [ ] Implement LocalInvoiceRepository (Hive)
- [ ] Implement CloudInvoiceRepository (API-based)
- [ ] Queue-based sync for premium users
- [ ] Backend subscription enforcement
- [ ] Device sync on login
- [ ] Last-write-wins conflict resolution

---

## 🔒 Phase 3.5 – Security Audit (ADD THIS)

### Authentication Security
- [ ] Review JWT implementation
- [ ] Test token expiration handling
- [ ] Validate refresh token flow
- [ ] Test auth edge cases (expired, invalid tokens)
- [ ] Implement rate limiting on auth endpoints

### API Security
- [ ] Validate all API inputs
- [ ] Check for SQL injection risks
- [ ] Test authorization on all endpoints
- [ ] Implement request rate limiting
- [ ] Review CORS configuration

### Data Security
- [ ] Review data encryption at rest
- [ ] Validate secure data transmission (HTTPS)
- [ ] Check for sensitive data in logs
- [ ] Review file upload security
- [ ] Test for common vulnerabilities (OWASP Top 10)

---

## 🧠 Phase 4 – Java Backend (Core Logic)

### Backend Setup
- [ ] Spring Boot project setup
- [ ] Supabase JWT verification
- [ ] Extract user role & subscription tier
- [ ] Health-check endpoint
- [ ] API documentation (Swagger/OpenAPI)

### Backend Responsibilities
- [ ] Invoice validation
- [ ] Invoice status transition rules
- [ ] Feature gating (Free vs Pro)
- [ ] Secure sync endpoints
- [ ] Ensure no secrets in Flutter
- [ ] Implement proper error responses
- [ ] Add request/response logging

---

## 💳 Phase 4.5 – Payment POC (MOVED FROM PHASE 6)

### Early Payment Integration
- [ ] Choose Razorpay (Indian market)
- [ ] Set up test account
- [ ] Create basic payment link generation
- [ ] Implement webhook endpoint
- [ ] Test webhook signature verification
- [ ] Validate payment amount matching
- [ ] Test with small amounts (₹1-10)
- [ ] Document payment flow

**Why Early:** Payment integration is complex. Test early to identify issues before building features on top.

---

## 📧 Phase 5 – Email & PDF Hosting

- [ ] Create Supabase Storage bucket
- [ ] Upload invoice PDFs from backend
- [ ] Integrate email provider (SES / SendGrid / Resend)
- [ ] Send invoice emails
- [ ] Track email send status
- [ ] Handle email delivery failures
- [ ] Add email templates

---

## 💳 Phase 6 – Full Payment Integration

- [ ] Complete Razorpay integration
- [ ] Generate payment links for invoices
- [ ] Auto-mark invoice as PAID on success
- [ ] Handle payment failures
- [ ] Add payment history tracking
- [ ] Implement refund handling
- [ ] Add payment receipts

---

## 💎 Phase 7 – Subscriptions

- [ ] Implement Free tier limits (10 invoices/month)
- [ ] Implement Pro tier features (unlimited)
- [ ] Monthly subscription billing via Razorpay
- [ ] Grace period handling (3-7 days)
- [ ] Feature lock on subscription expiry
- [ ] Subscription renewal reminders
- [ ] Handle subscription cancellations

---

## 🎨 Phase 8 – Community Templates (Later)

- [ ] Template schema definition
- [ ] Template upload validation
- [ ] Moderation logic
- [ ] Ranking / popularity system
- [ ] Template preview rendering
- [ ] User-submitted templates
- [ ] Template categories

---

## 🤖 Phase 9 – AI Assistance (Last)

- [ ] Collect invoice analytics
- [ ] Extract usage patterns
- [ ] AI-generated suggestions (read-only)
- [ ] Require user approval before applying
- [ ] Smart invoice item suggestions
- [ ] Automated client categorization

---

## 📏 Daily Engineering Rules

- [ ] No feature without updating models
- [ ] No business logic in UI
- [ ] No secrets on the client
- [ ] No "quick hacks"
- [ ] One feature at a time
- [ ] Write tests for new features
- [ ] Document complex logic
- [ ] Review code before merging

---

## 🎯 Execution Order Summary

```
Phase 0: Team Alignment
Phase 0.5: Product Definition ← DEFINE PRICING FIRST
Phase 1: Core Foundation (Hive, UUIDs, domain logic)
Phase 1.5: Testing Foundation ← QUALITY GATES
Phase 2: Backup & Safety
Phase 2.5: Observability ← MONITORING
Phase 3: Supabase Auth + Sync
Phase 3.5: Security Audit ← SECURITY REVIEW
Phase 4: Java Backend (Spring Boot)
Phase 4.5: Payment POC ← TEST EARLY
Phase 5: Email & PDF
Phase 6: Full Payment Integration
Phase 7: Subscriptions
Phase 8: Community Templates
Phase 9: AI Features
```

---

## 💼 Interview Talking Points

This project demonstrates:
- ✅ **Microservices Architecture** (Flutter + Java Backend + Supabase)
- ✅ **Offline-First Design** (Repository pattern, sync queues)
- ✅ **Payment Gateway Integration** (Razorpay webhooks)
- ✅ **Spring Boot REST APIs** (JWT auth, feature gating)
- ✅ **Database Design** (Supabase PostgreSQL)
- ✅ **Mobile Development** (Flutter cross-platform)
- ✅ **Testing & CI/CD** (Unit tests, GitHub Actions)
- ✅ **Security Best Practices** (No client secrets, JWT validation)

---

## 🧠 North Star

> **Offline-first · Rule-driven · Secure · Scalable · No rewrites**

---

## 🚀 Why This Approach?

### Java Spring Boot Choice
- Learning Java this semester (team skill development)
- Preparing for internships (Java favored by TCS, Infosys, Wipro, Accenture)
- Real project experience > toy projects
- Industry-standard tech stack

### Supabase Choice
- All-in-one: Auth + Database + Storage
- Developer-friendly, modern
- Cost-effective for startups
- Easy to scale

### Offline-First Philosophy
- Works without internet (critical for invoicing)
- Better user experience
- Respects user privacy
- Matches apps like Notion, Todoist

---

✅ Follow this checklist sequentially.  
❌ Do not skip phases.  
🚀 Build slow, build right.  
💎 This is your portfolio piece for internships.