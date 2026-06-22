# ShadeInvoice — Founder Playbook (Supabase-Only Backend)

> **Stack:** Flutter · Supabase (Auth + Postgres + Storage + Edge Functions) · Paddle (MoR) · Cloudflare R2 (optional, Supabase Storage preferred) · Antigravity CLI + skills.sh  
> **No Spring Boot. No separate server. No DevOps overhead.**  
> **Goal:** 100 paid users by Day 30 · Breakeven by Month 2 · $10K MRR by Month 18

---

## Table of Contents

1. [30-Day Launch Plan](#1-30-day-launch-plan)
2. [Paddle + Supabase Integration (Flutter)](#2-paddle--supabase-integration-flutter)
3. [Developer Setup & Antigravity skills.sh Skills](#3-developer-setup--antigravity-skillssh-skills)

---

## 1. 30-Day Launch Plan

### North Star for Day 30
**100 paid subscribers × $2.99/mo = ~$260 net MRR after Paddle fees.**  
Not downloads. Not signups. **Paid.**

---

### Pre-Week — Fix Code Bugs Before Writing a Line of Cloud Code

These are existing bugs in the codebase that will break a real product:

| File | Bug | Fix |
|---|---|---|
| `invoice_model.dart:13` | `tax => subtotal * 0.0` — hardcoded zero, GST broken | Add `taxRate` field, compute dynamically |
| `local_storage_service.dart` | `SharedPreferences.getStringList` — serialises entire invoice list on every save | Migrate to **Hive** before adding any sync |
| `invoice_model.dart` | `Client` embedded inside `Invoice` as nested object | Separate entities — use `clientId` FK in sync layer |
| `main.dart` | App title `'BillSnap'` | Rename to `'ShadeInvoice'` |
| `main.dart` | No auth check — goes straight to `HomeScreen()` | Add session check on startup |
| `settings_screen.dart` | `print()` statements with error details in production | Replace with proper error handling, remove all `print()` |
| `invoice_preview_screen.dart` | `print('Error exporting PDF: $e')` | Same — remove before production build |

---

### Week 1 — Days 1–7: Offline Core (Ship-Ready Local App)

**Goal:** A production-quality offline app. No auth. No cloud. No Paddle.

**What to build:**

- [ ] Fix all bugs in the table above
- [ ] Migrate `SharedPreferences` → **Hive** (`hive_flutter` package)
  - `InvoiceBox`, `ClientBox`, `CompanyInfoBox` — typed boxes
  - UUIDs on all entities (use `uuid` package — already in your pubspec)
- [ ] Add `taxRate` field to `Invoice` model
  - Preset rates: 0%, 5%, 12%, 18%, 28% + custom input
  - `taxAmount = subtotal * taxRate`, `total = subtotal + taxAmount`
  - Freeze all monetary values at creation — never recalculate on open
- [ ] Add `InvoiceStatus.cancelled` (your README lists it, code is missing it)
- [ ] Add `updatedAt` timestamp to all models
- [ ] `generateInvoiceNumber()` already exists — make it gapless and thread-safe in Hive
- [ ] Prevent editing `PAID` invoices (read-only mode in `CreateInvoiceScreen`)
- [ ] Remove all `print()` debug statements — use `debugPrint()` only in debug builds
- [ ] Test local PDF export on Android + iOS physical device

**What NOT to build this week:** Auth, Supabase, Paddle, cloud sync. Zero.

**Day 7 checkpoint:** Give the APK to 5 freelancer friends. One real user finding a bug now saves 10 support tickets later.

---

### Week 2 — Days 8–14: Supabase Auth + Schema

**Goal:** Users can sign up, log in, and the free tier works identically to the offline app (Hive only). Cloud features are gated but not yet functional.

**Supabase project setup:**

```sql
-- Run in Supabase SQL editor

-- Profiles table (auto-created on signup via trigger)
create table public.profiles (
  id            uuid references auth.users(id) on delete cascade primary key,
  email         text not null,
  tier          text not null default 'free',       -- 'free' | 'pro'
  paddle_customer_id text,
  sub_status    text not null default 'inactive',   -- 'active' | 'inactive' | 'canceled' | 'past_due'
  sub_expires_at timestamptz,
  created_at    timestamptz default now(),
  updated_at    timestamptz default now()
);

-- Clients table
create table public.clients (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid references public.profiles(id) on delete cascade not null,
  name        text not null,
  email       text,
  phone       text,
  address     text,
  company     text,
  created_at  timestamptz default now(),
  updated_at  timestamptz default now()
);

-- Invoices table
create table public.invoices (
  id              uuid primary key default gen_random_uuid(),
  user_id         uuid references public.profiles(id) on delete cascade not null,
  client_id       uuid references public.clients(id) on delete set null,
  invoice_number  text not null,
  invoice_date    date not null,
  due_date        date not null,
  status          text not null default 'draft',
  subtotal        numeric(14,2) not null default 0,
  tax_rate        numeric(5,4) not null default 0,   -- e.g. 0.18 for 18%
  tax_amount      numeric(14,2) not null default 0,
  total           numeric(14,2) not null default 0,
  notes           text,
  payment_method  text,
  from_company    text,
  from_address    text,
  from_email      text,
  from_phone      text,
  items_snapshot  jsonb not null default '[]',       -- frozen line items at creation
  created_at      timestamptz default now(),
  updated_at      timestamptz default now()
);

-- Enforce unique invoice numbers per user
create unique index invoices_user_number_idx
  on public.invoices(user_id, invoice_number);

-- Row Level Security — users only ever see their own data
alter table public.profiles  enable row level security;
alter table public.clients   enable row level security;
alter table public.invoices  enable row level security;

create policy "profiles: own row only"
  on public.profiles for all
  using (auth.uid() = id);

create policy "clients: own rows only"
  on public.clients for all
  using (auth.uid() = user_id);

create policy "invoices: own rows only"
  on public.invoices for all
  using (auth.uid() = user_id);

-- Auto-create profile on signup
create or replace function public.handle_new_user()
returns trigger language plpgsql security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, email)
  values (new.id, new.email);
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();
```

**Storage bucket for PDFs (Pro only):**

```sql
-- In Supabase dashboard: Storage → New bucket
-- Name: invoice-pdfs
-- Public: NO (always private, access via signed URLs)

-- Storage RLS policy
create policy "Pro users can upload their own PDFs"
  on storage.objects for insert
  with check (
    bucket_id = 'invoice-pdfs'
    and auth.uid()::text = (storage.foldername(name))[1]
    and exists (
      select 1 from public.profiles
      where id = auth.uid() and tier = 'pro'
    )
  );

create policy "Users can read their own PDFs"
  on storage.objects for select
  using (
    bucket_id = 'invoice-pdfs'
    and auth.uid()::text = (storage.foldername(name))[1]
  );
```

**Flutter: Add Supabase and auth layer:**

```yaml
# pubspec.yaml — add these
dependencies:
  supabase_flutter: ^2.5.0
  flutter_secure_storage: ^9.2.2
  hive_flutter: ^1.1.0
  hive: ^2.2.3
  uuid: ^4.4.0
```

**Auth flow in Flutter:**

```dart
// lib/services/auth_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final _client = Supabase.instance.client;

  // Never expose the Supabase service role key in Flutter
  // anon key is safe — RLS enforces row-level isolation

  Future<AuthResponse> signUp(String email, String password) async {
    return await _client.auth.signUp(
      email: email,
      password: password,
    );
  }

  Future<AuthResponse> signIn(String email, String password) async {
    return await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  Session? get currentSession => _client.auth.currentSession;
  User? get currentUser => _client.auth.currentUser;
  bool get isSignedIn => currentSession != null;

  Stream<AuthState> get authStateChanges =>
      _client.auth.onAuthStateChange;
}
```

**`SyncPolicy` enum — the free/pro gate:**

```dart
// lib/core/sync_policy.dart
enum SyncPolicy { localOnly, cloudSync }

// lib/services/subscription_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';

class SubscriptionService {
  final _client = Supabase.instance.client;

  Future<SyncPolicy> getSyncPolicy() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return SyncPolicy.localOnly;

    final data = await _client
        .from('profiles')
        .select('tier, sub_status, sub_expires_at')
        .eq('id', userId)
        .single();

    final isPro = data['tier'] == 'pro' &&
        data['sub_status'] == 'active';

    return isPro ? SyncPolicy.cloudSync : SyncPolicy.localOnly;
  }
}
```

**`main.dart` — Session check on startup:**

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  // Register Hive adapters here

  await Supabase.initialize(
    url: const String.fromEnvironment('SUPABASE_URL'),
    anonKey: const String.fromEnvironment('SUPABASE_ANON_KEY'),
    // NEVER hardcode these — pass via --dart-define at build time
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => InvoiceService()),
        ChangeNotifierProvider(create: (_) => SubscriptionProvider()),
        Provider(create: (_) => AuthService()),
      ],
      child: const ShadeInvoiceApp(),
    ),
  );
}

class ShadeInvoiceApp extends StatelessWidget {
  const ShadeInvoiceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ShadeInvoice',
      // Listen to auth state — redirect to login if signed out
      home: StreamBuilder<AuthState>(
        stream: Supabase.instance.client.auth.onAuthStateChange,
        builder: (context, snapshot) {
          final session = snapshot.data?.session;
          if (session != null) return const HomeScreen();
          return const LoginScreen();
        },
      ),
    );
  }
}
```

**Day 14 checkpoint:** Signup/login works. Free users get Hive. Pro gate shows "Upgrade" banner. No data leaves the device for free users.

---

### Week 3 — Days 15–21: Paddle + Pro Cloud Sync

Full Paddle integration is in Section 2. Summary of what to build this week:

- [ ] Supabase Edge Function: `paddle-checkout` (generates checkout URL server-side)
- [ ] Supabase Edge Function: `paddle-webhook` (handles payment events, updates `profiles`)
- [ ] Supabase Edge Function: `send-invoice-email` (calls Resend API)
- [ ] Flutter `PaddleService` (calls Edge Functions, never Paddle directly)
- [ ] Flutter `UpgradeScreen` (paywall UI)
- [ ] Cloud sync for Pro users — `CloudInvoiceRepository` via Supabase client
- [ ] PDF upload to Supabase Storage for Pro users
- [ ] Signed URL generation for invoice sharing

**Day 21 checkpoint:** End-to-end paid flow works. Someone pays $2.99, gets cloud sync enabled, can email an invoice to their client with a PDF link.

---

### Week 4 — Days 22–30: Polish, App Stores, Launch

**Last-mile app features:**

- [ ] 3-screen onboarding (what it does, free vs pro, get started)
- [ ] Company logo stored in Supabase Storage for Pro users (local file for free)
- [ ] "Share invoice link" — Supabase Storage signed URL, 7-day expiry
- [ ] Currency selector (USD, EUR, GBP, INR, AUD — affects symbol only, no conversion)
- [ ] Annual plan option on `UpgradeScreen` ($29/yr — saves 2 months)
- [ ] In-app "Restore purchase" button (calls Paddle subscription check)
- [ ] Legal: Privacy Policy + Terms of Service links in Settings
- [ ] Legal: Disclaimer text on invoice creation screen:
  > "ShadeInvoice generates invoice documents only. You are responsible for tax compliance in your jurisdiction."

**App Store submissions:**

- Submit to Play Store (Day 22) — review: 1–3 days
- Submit to App Store (Day 22) — review: 1–7 days
- Allow buffer — don't promise launch before Day 27

**Landing page (`shadeinvoice.com`) — above fold only:**

```
Headline:  Invoice clients in 60 seconds.
Sub:       No account needed. PDF in your pocket. Cloud sync when you need it.
CTA:       Download free  →  [App Store] [Play Store]
Proof:     Works offline · GST + VAT ready · Payments via Paddle
```

**Where to get first 100 users — organic only, Day 22–30:**

| Channel | Post angle | Expected signups |
|---|---|---|
| Reddit r/freelance | "Built a free offline invoice app — no signup, works on plane" | 30–40 |
| Reddit r/webdev + r/design | Show the UI, ask for feedback | 20–30 |
| IndieHackers | Launch post with Day 30 MRR transparency | 15–20 |
| Product Hunt | Schedule for Day 28 | 20–30 |
| Twitter/X #buildinpublic | Build thread starting Day 1 — launch day push | 10–20 |

**Conversion target:** 15–20% of signups upgrade to Pro within 30 days.  
100 signups → 15–20 paid → ~$45–$60 MRR. Proof that someone pays.

---

### Month 2 Breakeven Model

| Month | New Paid/mo | Total Paid (5% churn) | Gross MRR | Paddle Fee (5.5%) | Net MRR | Infra | Net Cashflow |
|---|---|---|---|---|---|---|---|
| M1 | 20 | 20 | $60 | $3 | $57 | $0 (free tier) | **+$57** |
| **M2** | **40** | **57** | **$170** | **$9** | **$161** | **$25** | **+$136** |
| M3 | 60 | 114 | $341 | $19 | $322 | $25 | +$297 |
| M6 | 80 | 276 | $826 | $45 | $781 | $55 | +$726 |
| M12 | 120 | 780 | $2,334 | $128 | $2,206 | $80 | +$2,126 |
| M18 | 150 | 1,812 | $5,418 | $298 | $5,120 | $120 | +$5,000 |

> Month 2 breakeven is achievable because Supabase free tier covers you until ~500 users. Zero infra cost in M1.

---

## 2. Paddle + Supabase Integration (Flutter)

### Architecture

```
Flutter App
    │
    ├── Free user: Hive local storage only — zero network calls for data
    │
    └── Pro upgrade flow:
           │
           ▼
    Supabase Edge Function: paddle-checkout
    (TypeScript/Deno — Supabase hosts it at /functions/v1/paddle-checkout)
           │  Reads user JWT from Authorization header
           │  Calls Paddle API with secret key (never exposed to Flutter)
           │  Returns checkout URL
           ▼
         Paddle (Merchant of Record)
           │  Collects payment, handles VAT/GST/Sales Tax globally
           │  Issues compliant receipt to customer
           │  POSTs webhook events to your Edge Function
           ▼
    Supabase Edge Function: paddle-webhook
           │  Verifies Paddle signature (prevents spoofed events)
           │  Updates profiles table via Supabase admin client
           ▼
    Supabase Postgres: profiles.tier = 'pro'
           │
           ▼
    Flutter: SubscriptionProvider.refresh() → reads profiles table via RLS
```

**Security rules:**
- Flutter holds the Supabase **anon key** only — safe to embed
- Supabase **service role key** lives only in Edge Functions (env vars, never client-side)
- Paddle **API key** lives only in Edge Functions (env vars, never client-side)
- Paddle **webhook secret** lives only in the webhook Edge Function
- All database access from Flutter goes through RLS — users can only read/write their own rows
- Edge Functions verify the Supabase JWT on every call before doing anything

---

### Step 1 — Paddle Dashboard Setup

1. Sign up at [paddle.com](https://paddle.com) → Select "Software / SaaS"
2. **Catalog → Products → New product:**
   - Name: `ShadeInvoice Pro`
   - Type: Subscription
3. **Create prices under the product:**
   - `price_monthly`: $2.99 / month (USD) — Paddle auto-converts to local currency
   - `price_annual`: $29.00 / year (USD)
   - If you want a separate INR price: ₹99 / month (INR)
4. **Developer Tools → Authentication → API Keys:**
   - Copy `API Key` (server-side only)
   - Copy `Client-side token` (unused — you won't use Paddle.js)
5. **Notifications → Webhooks → Add endpoint:**
   - URL: `https://<your-project>.supabase.co/functions/v1/paddle-webhook`
   - Events: `subscription.created`, `subscription.updated`, `subscription.canceled`, `transaction.completed`, `subscription.past_due`
   - Copy the **webhook secret** shown after saving

---

### Step 2 — Supabase Edge Functions

**Install Supabase CLI:**

```bash
npm install -g supabase
supabase login
supabase init          # in your project root
supabase link --project-ref <your-project-ref>
```

**Set secrets (never in code, never in git):**

```bash
supabase secrets set PADDLE_API_KEY="your_paddle_api_key"
supabase secrets set PADDLE_WEBHOOK_SECRET="your_paddle_webhook_secret"
supabase secrets set PADDLE_PRICE_MONTHLY="pri_xxxxxxxxxxxxxxxx"
supabase secrets set PADDLE_PRICE_ANNUAL="pri_xxxxxxxxxxxxxxxx"
supabase secrets set SUPABASE_SERVICE_ROLE_KEY="your_service_role_key"
# SUPABASE_URL is injected automatically — don't set it manually
```

---

**Edge Function 1: `paddle-checkout`**

```bash
supabase functions new paddle-checkout
```

```typescript
// supabase/functions/paddle-checkout/index.ts
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const PADDLE_API_KEY = Deno.env.get("PADDLE_API_KEY")!;
const PRICE_MONTHLY  = Deno.env.get("PADDLE_PRICE_MONTHLY")!;
const PRICE_ANNUAL   = Deno.env.get("PADDLE_PRICE_ANNUAL")!;
const SUPABASE_URL   = Deno.env.get("SUPABASE_URL")!;
const SERVICE_KEY    = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

Deno.serve(async (req) => {
  // ── 1. CORS preflight ──────────────────────────────────────────
  if (req.method === "OPTIONS") {
    return new Response(null, {
      headers: {
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Headers": "authorization, content-type",
      },
    });
  }

  // ── 2. Verify caller is a real Supabase-authenticated user ─────
  const authHeader = req.headers.get("Authorization");
  if (!authHeader?.startsWith("Bearer ")) {
    return new Response(JSON.stringify({ error: "Unauthorized" }), {
      status: 401,
      headers: { "Content-Type": "application/json" },
    });
  }

  const supabase = createClient(SUPABASE_URL, SERVICE_KEY);
  const { data: { user }, error: authError } = await supabase.auth.getUser(
    authHeader.replace("Bearer ", "")
  );

  if (authError || !user) {
    return new Response(JSON.stringify({ error: "Invalid token" }), {
      status: 401,
      headers: { "Content-Type": "application/json" },
    });
  }

  // ── 3. Parse request body ─────────────────────────────────────
  let body: { plan?: string };
  try {
    body = await req.json();
  } catch {
    return new Response(JSON.stringify({ error: "Invalid JSON" }), {
      status: 400,
      headers: { "Content-Type": "application/json" },
    });
  }

  const priceId = body.plan === "annual" ? PRICE_ANNUAL : PRICE_MONTHLY;

  // ── 4. Call Paddle API ─────────────────────────────────────────
  // custom_data.user_id lets the webhook know which user paid
  const paddleRes = await fetch("https://api.paddle.com/transactions", {
    method: "POST",
    headers: {
      "Authorization": `Bearer ${PADDLE_API_KEY}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      items: [{ price_id: priceId, quantity: 1 }],
      customer: { email: user.email },
      custom_data: { user_id: user.id },   // critical — webhook reads this
      checkout: { url: "https://shadeinvoice.com/success" },
    }),
  });

  if (!paddleRes.ok) {
    const errBody = await paddleRes.text();
    console.error("Paddle API error:", errBody);
    return new Response(JSON.stringify({ error: "Paddle error" }), {
      status: 502,
      headers: { "Content-Type": "application/json" },
    });
  }

  const paddleData = await paddleRes.json();
  const checkoutUrl: string = paddleData.data?.checkout?.url;

  if (!checkoutUrl) {
    return new Response(JSON.stringify({ error: "No checkout URL" }), {
      status: 502,
      headers: { "Content-Type": "application/json" },
    });
  }

  return new Response(JSON.stringify({ checkout_url: checkoutUrl }), {
    headers: {
      "Content-Type": "application/json",
      "Access-Control-Allow-Origin": "*",
    },
  });
});
```

---

**Edge Function 2: `paddle-webhook`**

```bash
supabase functions new paddle-webhook
```

```typescript
// supabase/functions/paddle-webhook/index.ts
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const WEBHOOK_SECRET = Deno.env.get("PADDLE_WEBHOOK_SECRET")!;
const SUPABASE_URL   = Deno.env.get("SUPABASE_URL")!;
const SERVICE_KEY    = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

// Paddle signature verification using Web Crypto API
async function verifyPaddleSignature(
  rawBody: string,
  signatureHeader: string
): Promise<boolean> {
  // Paddle-Signature format: ts=<timestamp>;h1=<hmac>
  const parts = Object.fromEntries(
    signatureHeader.split(";").map((p) => p.split("=") as [string, string])
  );
  const timestamp = parts["ts"];
  const receivedHmac = parts["h1"];

  if (!timestamp || !receivedHmac) return false;

  // Replay attack prevention: reject events older than 5 minutes
  const age = Math.abs(Date.now() / 1000 - Number(timestamp));
  if (age > 300) {
    console.warn("Paddle webhook too old:", age, "seconds");
    return false;
  }

  const signedPayload = `${timestamp}:${rawBody}`;
  const encoder = new TextEncoder();
  const key = await crypto.subtle.importKey(
    "raw",
    encoder.encode(WEBHOOK_SECRET),
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["sign"]
  );
  const sig = await crypto.subtle.sign("HMAC", key, encoder.encode(signedPayload));
  const computedHmac = Array.from(new Uint8Array(sig))
    .map((b) => b.toString(16).padStart(2, "0"))
    .join("");

  // Constant-time comparison to prevent timing attacks
  if (computedHmac.length !== receivedHmac.length) return false;
  let diff = 0;
  for (let i = 0; i < computedHmac.length; i++) {
    diff |= computedHmac.charCodeAt(i) ^ receivedHmac.charCodeAt(i);
  }
  return diff === 0;
}

Deno.serve(async (req) => {
  if (req.method !== "POST") {
    return new Response("Method not allowed", { status: 405 });
  }

  const rawBody = await req.text();
  const signature = req.headers.get("Paddle-Signature") ?? "";

  // ── ALWAYS verify signature first — reject anything that doesn't verify ──
  const valid = await verifyPaddleSignature(rawBody, signature);
  if (!valid) {
    console.error("Paddle signature verification failed");
    return new Response("Forbidden", { status: 403 });
  }

  let event: Record<string, unknown>;
  try {
    event = JSON.parse(rawBody);
  } catch {
    return new Response("Bad JSON", { status: 400 });
  }

  const eventType = event.event_type as string;
  const data = event.data as Record<string, unknown>;
  const customData = data?.custom_data as Record<string, string> | undefined;
  const userId = customData?.user_id;

  if (!userId) {
    // Log but return 200 — Paddle retries on non-2xx
    console.warn("No user_id in custom_data for event:", eventType);
    return new Response("OK", { status: 200 });
  }

  const supabase = createClient(SUPABASE_URL, SERVICE_KEY);

  switch (eventType) {
    case "subscription.created":
    case "transaction.completed": {
      const scheduledChange = (data.scheduled_change as Record<string, unknown>);
      const expiresAt = scheduledChange?.effective_at as string | undefined;
      await supabase
        .from("profiles")
        .update({
          tier: "pro",
          sub_status: "active",
          sub_expires_at: expiresAt ?? null,
          paddle_customer_id: data.customer_id as string,
          updated_at: new Date().toISOString(),
        })
        .eq("id", userId);
      break;
    }

    case "subscription.canceled": {
      // Don't cut access immediately — let them use it until period ends
      await supabase
        .from("profiles")
        .update({
          sub_status: "canceled",
          updated_at: new Date().toISOString(),
        })
        .eq("id", userId);
      break;
    }

    case "subscription.past_due": {
      await supabase
        .from("profiles")
        .update({
          sub_status: "past_due",
          updated_at: new Date().toISOString(),
        })
        .eq("id", userId);
      break;
    }

    case "subscription.updated": {
      const status = data.status as string;
      await supabase
        .from("profiles")
        .update({
          sub_status: status,
          updated_at: new Date().toISOString(),
        })
        .eq("id", userId);
      break;
    }

    default:
      // Unknown event — log and return 200 so Paddle doesn't retry forever
      console.log("Unhandled Paddle event:", eventType);
  }

  return new Response("OK", { status: 200 });
});
```

---

**Edge Function 3: `send-invoice-email`**

```bash
supabase functions new send-invoice-email
```

```bash
# Add Resend API key to secrets
supabase secrets set RESEND_API_KEY="re_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
```

```typescript
// supabase/functions/send-invoice-email/index.ts
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const RESEND_API_KEY = Deno.env.get("RESEND_API_KEY")!;
const SUPABASE_URL   = Deno.env.get("SUPABASE_URL")!;
const SERVICE_KEY    = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response(null, {
      headers: {
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Headers": "authorization, content-type",
      },
    });
  }

  // ── 1. Verify auth ────────────────────────────────────────────
  const authHeader = req.headers.get("Authorization");
  if (!authHeader?.startsWith("Bearer ")) {
    return new Response(JSON.stringify({ error: "Unauthorized" }), { status: 401 });
  }

  const supabase = createClient(SUPABASE_URL, SERVICE_KEY);
  const { data: { user }, error } = await supabase.auth.getUser(
    authHeader.replace("Bearer ", "")
  );
  if (error || !user) {
    return new Response(JSON.stringify({ error: "Invalid token" }), { status: 401 });
  }

  // ── 2. Verify user is Pro ─────────────────────────────────────
  const { data: profile } = await supabase
    .from("profiles")
    .select("tier, sub_status")
    .eq("id", user.id)
    .single();

  if (profile?.tier !== "pro" || profile?.sub_status !== "active") {
    return new Response(JSON.stringify({ error: "Pro required" }), { status: 403 });
  }

  // ── 3. Parse and validate body ────────────────────────────────
  const { invoice_id, recipient_email, pdf_signed_url } = await req.json();

  if (!invoice_id || !recipient_email || !pdf_signed_url) {
    return new Response(JSON.stringify({ error: "Missing fields" }), { status: 400 });
  }

  // ── 4. Verify invoice belongs to this user ────────────────────
  const { data: invoice } = await supabase
    .from("invoices")
    .select("invoice_number, total, from_company")
    .eq("id", invoice_id)
    .eq("user_id", user.id)   // IMPORTANT: prevents IDOR
    .single();

  if (!invoice) {
    return new Response(JSON.stringify({ error: "Invoice not found" }), { status: 404 });
  }

  // ── 5. Send via Resend ────────────────────────────────────────
  const resendRes = await fetch("https://api.resend.com/emails", {
    method: "POST",
    headers: {
      "Authorization": `Bearer ${RESEND_API_KEY}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      from: "invoices@shadeinvoice.com",
      to: [recipient_email],
      subject: `Invoice ${invoice.invoice_number} from ${invoice.from_company}`,
      html: `
        <p>Please find your invoice attached.</p>
        <p><strong>Invoice:</strong> ${invoice.invoice_number}</p>
        <p><strong>Amount:</strong> $${invoice.total}</p>
        <p><a href="${pdf_signed_url}">View / Download PDF</a></p>
        <hr>
        <p style="color:#888;font-size:12px;">
          This invoice was created with ShadeInvoice. 
          ShadeInvoice is an invoice generation tool only and is not responsible 
          for the tax compliance of invoices created using this service.
        </p>
      `,
    }),
  });

  if (!resendRes.ok) {
    const errText = await resendRes.text();
    console.error("Resend error:", errText);
    return new Response(JSON.stringify({ error: "Email failed" }), { status: 502 });
  }

  return new Response(JSON.stringify({ success: true }), {
    headers: {
      "Content-Type": "application/json",
      "Access-Control-Allow-Origin": "*",
    },
  });
});
```

**Deploy all functions:**

```bash
supabase functions deploy paddle-checkout --no-verify-jwt
supabase functions deploy paddle-webhook  --no-verify-jwt
# send-invoice-email verifies JWT inside the function, so --no-verify-jwt here too
supabase functions deploy send-invoice-email --no-verify-jwt
```

> `--no-verify-jwt` disables Supabase's automatic JWT check at the gateway level so the function handles auth itself. Required for `paddle-webhook` since Paddle doesn't send a Supabase JWT — it sends its own signature. Required for `paddle-checkout` because the function does its own `getUser()` check.

---

### Step 3 — Flutter: PaddleService

```dart
// lib/services/paddle_service.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class PaddleService {
  final _supabase = Supabase.instance.client;

  // Returns the Supabase Edge Function base URL
  String get _fnBase =>
      '${_supabase.supabaseUrl}/functions/v1';

  // Flutter always calls Edge Functions via Supabase — never Paddle directly
  Future<void> startCheckout({
    required BuildContext context,
    required String plan, // 'monthly' | 'annual'
  }) async {
    final session = _supabase.auth.currentSession;
    if (session == null) throw Exception('Not signed in');

    final res = await _supabase.functions.invoke(
      'paddle-checkout',
      body: {'plan': plan},
    );

    if (res.status != 200) {
      throw Exception('Checkout failed: ${res.data}');
    }

    final checkoutUrl = res.data['checkout_url'] as String?;
    if (checkoutUrl == null) throw Exception('No checkout URL returned');

    final uri = Uri.parse(checkoutUrl);
    if (!await canLaunchUrl(uri)) throw Exception('Cannot open browser');

    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> sendInvoiceEmail({
    required String invoiceId,
    required String recipientEmail,
    required String pdfSignedUrl,
  }) async {
    final res = await _supabase.functions.invoke(
      'send-invoice-email',
      body: {
        'invoice_id': invoiceId,
        'recipient_email': recipientEmail,
        'pdf_signed_url': pdfSignedUrl,
      },
    );

    if (res.status != 200) {
      throw Exception('Email failed: ${res.data}');
    }
  }
}
```

---

### Step 4 — Flutter: SubscriptionProvider

```dart
// lib/providers/subscription_provider.dart
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SubscriptionProvider extends ChangeNotifier {
  final _supabase = Supabase.instance.client;

  bool _isPro = false;
  bool _isLoading = true;
  String _status = 'inactive'; // 'active' | 'inactive' | 'canceled' | 'past_due'

  bool get isPro => _isPro;
  bool get isLoading => _isLoading;
  String get status => _status;

  Future<void> refresh() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      _isPro = false;
      _isLoading = false;
      notifyListeners();
      return;
    }

    try {
      // Direct Postgres query via RLS — no Edge Function needed here
      final data = await _supabase
          .from('profiles')
          .select('tier, sub_status, sub_expires_at')
          .eq('id', userId)
          .single();

      final tier = data['tier'] as String? ?? 'free';
      _status = data['sub_status'] as String? ?? 'inactive';

      // Grace period: canceled subs stay Pro until expiry
      final expiresAt = data['sub_expires_at'] != null
          ? DateTime.tryParse(data['sub_expires_at'] as String)
          : null;

      final withinGracePeriod = expiresAt != null &&
          expiresAt.isAfter(DateTime.now());

      _isPro = tier == 'pro' &&
          (_status == 'active' ||
           (_status == 'canceled' && withinGracePeriod));
    } catch (e) {
      // On error, default to free — never grant unverified Pro access
      _isPro = false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
```

---

### Step 5 — Flutter: UpgradeScreen

```dart
// lib/screens/upgrade_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shadeinvoice/services/paddle_service.dart';
import 'package:shadeinvoice/providers/subscription_provider.dart';

class UpgradeScreen extends StatefulWidget {
  const UpgradeScreen({super.key});

  @override
  State<UpgradeScreen> createState() => _UpgradeScreenState();
}

class _UpgradeScreenState extends State<UpgradeScreen> {
  bool _loading = false;
  final _paddle = PaddleService();

  Future<void> _upgrade(String plan) async {
    setState(() => _loading = true);
    try {
      await _paddle.startCheckout(context: context, plan: plan);
      // Give Paddle webhook ~3s to process before refreshing
      await Future.delayed(const Duration(seconds: 3));
      if (mounted) {
        await context.read<SubscriptionProvider>().refresh();
        if (context.read<SubscriptionProvider>().isPro && mounted) {
          Navigator.pop(context); // Return to app — now Pro
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Upgrade to Pro')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('ShadeInvoice Pro',
                      style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: 8),
                  const Text(
                    'Cloud sync, email invoices, and invoice sharing — '
                    'across all your devices.',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 32),
                  _Feature(icon: Icons.cloud_sync, text: 'Cloud sync across all devices'),
                  _Feature(icon: Icons.email_outlined, text: 'Email invoices directly to clients'),
                  _Feature(icon: Icons.people_outline, text: 'Unlimited clients'),
                  _Feature(icon: Icons.link, text: 'Shareable invoice PDF links'),
                  _Feature(icon: Icons.business_outlined, text: 'Company logo in cloud'),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () => _upgrade('monthly'),
                      child: const Text('\$2.99 / month'),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => _upgrade('annual'),
                      child: const Text('\$29 / year  ·  Save 2 months'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Center(
                    child: Text(
                      'Cancel anytime. All taxes included.\nSecure checkout by Paddle.',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _Feature extends StatelessWidget {
  final IconData icon;
  final String text;
  const _Feature({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Text(text),
        ],
      ),
    );
  }
}
```

---

### Step 6 — Feature Gating

Gate at the service layer, not the UI layer:

```dart
// lib/services/cloud_invoice_repository.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shadeinvoice/providers/subscription_provider.dart';

class CloudInvoiceRepository {
  final _supabase = Supabase.instance.client;
  final SubscriptionProvider _subProvider;

  CloudInvoiceRepository(this._subProvider);

  Future<void> syncInvoice(Map<String, dynamic> invoiceData) async {
    // Guard at data layer — UI never has to think about this
    if (!_subProvider.isPro) {
      throw Exception('Cloud sync requires Pro');
    }

    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Not signed in');

    await _supabase.from('invoices').upsert({
      ...invoiceData,
      'user_id': userId,
      'updated_at': DateTime.now().toISOString(),
    });
  }

  Future<String?> uploadPdf(String invoiceId, List<int> pdfBytes) async {
    if (!_subProvider.isPro) return null;

    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return null;

    // Path: <userId>/<invoiceId>.pdf — matches Storage RLS policy
    final path = '$userId/$invoiceId.pdf';

    await _supabase.storage
        .from('invoice-pdfs')
        .uploadBinary(
          path,
          Uint8List.fromList(pdfBytes),
          fileOptions: const FileOptions(
            contentType: 'application/pdf',
            upsert: true,
          ),
        );

    // Signed URL valid for 7 days
    final signedUrl = await _supabase.storage
        .from('invoice-pdfs')
        .createSignedUrl(path, 60 * 60 * 24 * 7);

    return signedUrl;
  }
}
```

---

### Step 7 — Build-Time Secrets (Never Hardcode)

```bash
# Build Android
flutter build apk \
  --dart-define=SUPABASE_URL=https://xxxxx.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=your_anon_key_here

# Build iOS
flutter build ipa \
  --dart-define=SUPABASE_URL=https://xxxxx.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=your_anon_key_here
```

Use `const String.fromEnvironment('SUPABASE_URL')` in `main.dart` as shown above. Never put secrets in `pubspec.yaml`, `.env` files committed to git, or anywhere in the Flutter source.

---

### Security Checklist

- [ ] Supabase anon key in Flutter via `--dart-define` only
- [ ] Supabase service role key only in Edge Function env vars (via `supabase secrets set`)
- [ ] Paddle API key only in Edge Function env vars
- [ ] Paddle webhook signature verified with constant-time comparison + replay window check
- [ ] Paddle `custom_data.user_id` used to identify who paid — set server-side by your checkout function
- [ ] RLS enabled on all tables — tested by querying as a different user
- [ ] `send-invoice-email` checks `invoice.user_id = auth.uid()` before sending (prevents IDOR)
- [ ] `sub_status` check on every Pro feature — never trust tier alone
- [ ] Error default is always `free` — Pro is never granted on error
- [ ] No `print()` statements in production Flutter code
- [ ] Storage RLS: folder path must start with `auth.uid()` 
- [ ] All Edge Functions return 200 to Paddle webhook (prevents infinite retries)
- [ ] Legal disclaimer on invoice creation screen

---

## 3. Developer Setup & Antigravity skills.sh Skills

### One-Time Environment Setup

```bash
# ── Flutter ─────────────────────────────────────────────────────
# Download Flutter SDK from flutter.dev → add to PATH
flutter doctor          # all green before touching any code
flutter doctor --android-licenses   # accept Android licenses

# ── Node.js (for skills CLI + Supabase CLI) ──────────────────────
nvm install 20
nvm use 20
node --version          # should be 20.x

# ── Supabase CLI ────────────────────────────────────────────────
npm install -g supabase
supabase --version      # verify install
supabase login          # OAuth via browser

# ── Hive codegen ────────────────────────────────────────────────
dart pub global activate build_runner
dart pub global activate hive_generator

# ── Clone and init ──────────────────────────────────────────────
git clone https://github.com/Ninad0109/ShadeInvoice
cd ShadeInvoice

flutter pub get
supabase init           # creates supabase/ dir
supabase link --project-ref <your-project-ref>

# ── Local Supabase for development ─────────────────────────────
supabase start          # spins up local Postgres + Auth + Storage
# Local URLs printed: Studio at localhost:54323, API at localhost:54321

# ── Environment for local dev ───────────────────────────────────
# Create .env.local (add to .gitignore — NEVER commit)
cat > .env.local << 'EOF'
SUPABASE_URL=http://localhost:54321
SUPABASE_ANON_KEY=<local anon key from supabase start output>
EOF

# ── Run with local env ─────────────────────────────────────────
flutter run \
  --dart-define=SUPABASE_URL=http://localhost:54321 \
  --dart-define=SUPABASE_ANON_KEY=<local_anon_key>
```

---

### Git Strategy for Solo Founder (No Direct Commits to Main)

```bash
# .gitignore additions
.env.local
.env
*.key
supabase/.branches/
supabase/seed.sql    # only if it contains test secrets

# Branch naming
feature/<name>       # new features
fix/<name>           # bug fixes
chore/<name>         # tooling, deps

# Never commit directly to main
# Use: git checkout -b feature/paddle-integration
# Then: PR → squash merge → delete branch
```

---

### Project Structure (After Migration)

```
ShadeInvoice/
│
├── lib/
│   ├── main.dart
│   ├── theme.dart
│   ├── core/
│   │   └── sync_policy.dart
│   ├── models/
│   │   ├── invoice_model.dart        (+ taxRate, updatedAt, copyWith)
│   │   ├── client_model.dart
│   │   └── invoice_item_model.dart
│   ├── services/
│   │   ├── auth_service.dart          (NEW)
│   │   ├── paddle_service.dart        (NEW)
│   │   ├── subscription_service.dart  (NEW)
│   │   ├── local_invoice_repository.dart  (replaces local_storage_service)
│   │   ├── cloud_invoice_repository.dart  (NEW — Supabase direct)
│   │   ├── invoice_service.dart       (orchestrates local + cloud)
│   │   ├── export_service.dart
│   │   └── sample_data_service.dart
│   ├── providers/
│   │   └── subscription_provider.dart (NEW)
│   ├── screens/
│   │   ├── login_screen.dart          (NEW)
│   │   ├── signup_screen.dart         (NEW)
│   │   ├── upgrade_screen.dart        (NEW)
│   │   ├── home_screen.dart
│   │   ├── create_invoice_screen.dart
│   │   ├── invoice_preview_screen.dart
│   │   ├── client_management_screen.dart
│   │   └── settings_screen.dart
│   └── widgets/
│       ├── invoice_card.dart
│       └── client_card.dart
│
├── supabase/
│   ├── config.toml
│   ├── migrations/
│   │   └── 20260614000001_initial_schema.sql
│   └── functions/
│       ├── paddle-checkout/index.ts
│       ├── paddle-webhook/index.ts
│       └── send-invoice-email/index.ts
│
├── .skills/                           (auto-created by npx skills add)
│   ├── supabase-postgres-best-practices.md
│   ├── supabase.md
│   ├── dispatching-parallel-agents.md
│   └── ...
│
├── PLAN.md                            (Antigravity reads this)
├── ARCHITECTURE.md
├── .gitignore
└── pubspec.yaml
```

---

### skills.sh Skills for ShadeInvoice + Antigravity

Skills teach your agent how to operate: how to plan before acting, debug methodically, dispatch parallel subagents, and run autonomous task loops without supervision. They are the meta-skills that make every other skill more effective.

Install all skills from your project root. Skills are installed via the skills CLI into your repository so Antigravity can reference them across sessions.

#### Install Command (Run All at Once)

```bash
# ── Tier 1: Agent workflow — install these first ─────────────────
npx skills add obra/superpowers/writing-plans
npx skills add obra/superpowers/executing-plans
npx skills add obra/superpowers/dispatching-parallel-agents
npx skills add obra/superpowers/using-git-worktrees
npx skills add obra/superpowers/verification-before-completion
npx skills add obra/superpowers/systematic-debugging

# ── Tier 2: Supabase ────────────────────────────────────────────
npx skills add supabase/agent-skills/supabase-postgres-best-practices
npx skills add supabase/agent-skills/supabase

# ── Tier 3: Quality + finishing ─────────────────────────────────
npx skills add obra/superpowers/test-driven-development
npx skills add obra/superpowers/finishing-a-development-branch
npx skills add obra/superpowers/requesting-code-review

# ── Tier 4: Meta ────────────────────────────────────────────────
npx skills add vercel-labs/skills/find-skills
npx skills add mattpocock/skills/improve-codebase-architecture
npx skills add mattpocock/skills/diagnose
```

---

#### Skills Reference Table

| Skill | Install command | Used for |
|---|---|---|
| `writing-plans` | `obra/superpowers/writing-plans` | Plan before touching code — break feature into steps |
| `executing-plans` | `obra/superpowers/executing-plans` | Step-by-step execution with checkpoints |
| `dispatching-parallel-agents` | `obra/superpowers/dispatching-parallel-agents` | Flutter + Edge Function work in parallel |
| `using-git-worktrees` | `obra/superpowers/using-git-worktrees` | Two Antigravity sessions, two branches, same time |
| `verification-before-completion` | `obra/superpowers/verification-before-completion` | Force verify pass before marking any task done |
| `systematic-debugging` | `obra/superpowers/systematic-debugging` | Hypothesis-driven debug loop — stop random edits |
| `supabase-postgres-best-practices` | `supabase/agent-skills/supabase-postgres-best-practices` | RLS, schema, indexes, migrations |
| `supabase` | `supabase/agent-skills/supabase` | Auth, storage, realtime, edge functions |
| `test-driven-development` | `obra/superpowers/test-driven-development` | Write failing test first, then implement |
| `finishing-a-development-branch` | `obra/superpowers/finishing-a-development-branch` | Branch close: tests, commit message, PR |
| `find-skills` | `vercel-labs/skills/find-skills` | Discover + install new skills mid-session |
| `improve-codebase-architecture` | `mattpocock/skills/improve-codebase-architecture` | Architecture review suggestions |
| `diagnose` | `mattpocock/skills/diagnose` | Root cause analysis for complex bugs |

---

### Parallel Workflow in Antigravity

The `dispatching-parallel-agents` + `using-git-worktrees` combo lets you ship features twice as fast as a solo founder.

#### Example: Build Paddle + cloud sync simultaneously

```bash
# Terminal 1 — Agent A: Edge Functions
git worktree add ../shadeinvoice-backend feature/edge-functions
cd ../shadeinvoice-backend
# Start Antigravity here
# Prompt: "Build paddle-checkout, paddle-webhook, send-invoice-email Edge Functions
#          per ARCHITECTURE.md. Use PLAN.md for context. No secrets in code."

# Terminal 2 — Agent B: Flutter
git worktree add ../shadeinvoice-flutter feature/flutter-pro-tier
cd ../shadeinvoice-flutter
# Start second Antigravity here
# Prompt: "Build PaddleService, SubscriptionProvider, UpgradeScreen, and
#          CloudInvoiceRepository in Flutter per PLAN.md. Use supabase_flutter SDK."

# When both done:
git checkout main
git merge feature/edge-functions
git merge feature/flutter-pro-tier
```

#### Standard parallel split for ShadeInvoice

| Agent A (Supabase / Edge Functions) | Agent B (Flutter / UI) |
|---|---|
| SQL migrations + RLS policies | Model changes + Hive adapters |
| Edge Function: paddle-checkout | PaddleService + UpgradeScreen |
| Edge Function: paddle-webhook | SubscriptionProvider + feature gates |
| Storage bucket + RLS | PDF upload in CloudInvoiceRepository |
| Edge Function: send-invoice-email | Email button in InvoicePreviewScreen |

---

### PLAN.md Template (Antigravity reads this automatically)

Create this at repo root and update it every sprint:

```markdown
# ShadeInvoice — Current Sprint

## Stack
- Flutter (Dart) — mobile app
- Supabase (Postgres + Auth + Storage + Edge Functions) — entire backend
- Paddle — payment processing and MoR (all taxes handled by Paddle)
- No Spring Boot. No separate server. No Docker.

## Security Rules (non-negotiable)
- No secrets in Flutter source code — use --dart-define at build time
- No Paddle API key in Flutter — calls go through supabase/functions only
- No service role key in Flutter — only in Edge Function env vars
- All Supabase DB access from Flutter goes through RLS
- Edge Functions must verify auth before any DB writes

## Current Task
[Describe the feature]

## Constraints
- Free users: Hive local only — zero Supabase DB/storage calls
- Pro check: always read profiles.tier AND profiles.sub_status — both must be correct
- Error default is always free — never grant Pro on error or ambiguous state
- All monetary values frozen at invoice creation — never recalculate on open

## Files in scope
- lib/services/
- lib/providers/
- supabase/functions/
- supabase/migrations/

## Done when
- [ ] Works offline for free users (no network calls)
- [ ] Pro gate enforced at service layer not UI layer
- [ ] RLS tested — different user cannot access another user's rows
- [ ] Edge Function secrets verified via supabase secrets list (not in code)
- [ ] No print() in production code
- [ ] Verification pass complete
```

---

*ShadeInvoice Founder Playbook v2 — Supabase-Only — June 2026*  
*No Spring Boot · No separate server · No DevOps overhead · Ship fast, build right*
