# 🧾 ShadeInvoice – Development Checklist

> **Goal:** Build an offline-first, secure, scalable invoice platform that can grow into a SaaS without rewrites.

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

---

### Invoice Domain Logic
- [ ] Subtotal calculation
- [ ] Tax model (name, rate, amount)
- [ ] Discount model
- [ ] Final total calculation
- [ ] Invoice numbering system
- [ ] Prevent editing PAID invoices

---

## 💾 Phase 2 – Backup & Safety

- [ ] Export all app data → JSON file
- [ ] Import JSON → restore data
- [ ] App-level "Reset Data" option
- [ ] Add `version` field to models

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

## 🧠 Phase 4 – Java Backend (Core Logic)

### Backend Setup
- [ ] Spring Boot project setup
- [ ] Supabase JWT verification
- [ ] Extract user role & subscription tier
- [ ] Health-check endpoint

### Backend Responsibilities
- [ ] Invoice validation
- [ ] Invoice status transition rules
- [ ] Feature gating (Free vs Pro)
- [ ] Secure sync endpoints
- [ ] Ensure no secrets in Flutter

---

## 📧 Phase 5 – Email & PDF Hosting

- [ ] Create Supabase Storage bucket
- [ ] Upload invoice PDFs from backend
- [ ] Integrate email provider (SES / SendGrid / Resend)
- [ ] Send invoice emails
- [ ] Track email send status

---

## 💳 Phase 6 – Payments

- [ ] Choose payment gateway (Stripe / Razorpay)
- [ ] Generate payment links
- [ ] Create webhook endpoint
- [ ] Verify payment signature
- [ ] Match payment amount with invoice
- [ ] Auto-mark invoice as PAID

---

## 💎 Phase 7 – Subscriptions

- [ ] Define Free vs Pro feature limits
- [ ] Monthly subscription billing
- [ ] Grace period handling
- [ ] Feature lock on subscription expiry

---

## 🎨 Phase 8 – Community Templates (Later)

- [ ] Template schema definition
- [ ] Template upload validation
- [ ] Moderation logic
- [ ] Ranking / popularity system
- [ ] Template preview rendering

---

## 🤖 Phase 9 – AI Assistance (Last)

- [ ] Collect invoice analytics
- [ ] Extract usage patterns
- [ ] AI-generated suggestions (read-only)
- [ ] Require user approval before applying

---

## 📏 Daily Engineering Rules

- [ ] No feature without updating models
- [ ] No business logic in UI
- [ ] No secrets on the client
- [ ] No "quick hacks"
- [ ] One feature at a time

---

## 🧠 North Star

> **Offline-first · Rule-driven · Secure · Scalable · No rewrites**

---

✅ Follow this checklist sequentially.  
❌ Do not skip phases.  
🚀 Build slow, build right.
