# CapitalFlow — Smart IPO & Portfolio Management for NSE/BSE Investors

> **Status:** In active development · **Platform:** Android (Flutter) · **Backend:** Supabase  
> **Note:** This is a portfolio showcase. Core business logic is proprietary and not included.

---

## What Is CapitalFlow?

CapitalFlow is a production-grade Android application for Indian retail investors that simplifies:

- **IPO tracking** — live, upcoming, closed, and listed IPOs with IST-accurate status
- **Capital management** — blocked funds tracking, allotment, settlement, and P&L in one view
- **Portfolio accounts** — multi-account Zerodha/Upstox-style account management
- **Stock scanning** — 22 technical conditions across RSI, EMA, volume spikes, and breakouts
- **Offline-first** — all data available without internet; syncs silently when back online

---

## Feature List

| Category | Features |
|----------|----------|
| **IPO Pipeline** | Live/Upcoming/Closed/Listed tabs · IST-aware 5PM cutoff · Server-side status recalculation |
| **Capital Tracking** | Application → Allotment → Listing → Settlement lifecycle · Blocked amount per application |
| **Accounts** | Multi-broker account management · Transaction ledger · Running P&L |
| **Scanner** | Real-time NSE/BSE screener · Condition-based filtering · Customizable watchlists |
| **Security** | Biometric lock (Local Auth) · Secure storage for tokens · Per-user RLS on all tables |
| **Offline** | Drift SQLite local cache · Outbox-pattern sync queue · Last-good-data on network loss |
| **Export** | PDF reports via `printing` package · Share via native share sheet |

---

## Tech Stack

| Layer | Technology |
|-------|-----------|
| UI | Flutter 3.x · Material 3 · Google Fonts (Inter) |
| State | Riverpod 2.x (AsyncNotifier, StreamProvider) |
| Local DB | Drift (type-safe SQLite, code-generated DAOs) |
| Remote | Supabase (Postgres + Edge Functions + RLS) |
| Auth | Supabase Auth (OTP/Magic Link) + `local_auth` biometrics |
| PDF | `pdf` + `printing` packages |
| Charts | `fl_chart` |
| Navigation | `go_router` |

---

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        Flutter UI Layer                          │
│   Screens → Widgets → Riverpod Providers (watch / read / listen) │
└────────────────────────┬────────────────────────────────────────┘
                         │ reads/writes
┌────────────────────────▼────────────────────────────────────────┐
│                     Repository Layer                             │
│   IpoRepository · AccountsRepository · ScannerRepository        │
│   Pure Dart · No Flutter imports · Single responsibility         │
└──────────┬─────────────────────────────────┬────────────────────┘
           │ cache reads (streams)           │ sync writes
┌──────────▼─────────────┐       ┌──────────▼───────────────────┐
│   Local Cache (Drift)   │       │     Sync Service (outbox)    │
│   SQLite, type-safe     │◄──────│     Queue → retry → cloud    │
│   Reactive streams      │       │     Stamp user_id on login   │
└────────────────────────┘       └──────────┬───────────────────┘
                                            │ HTTPS / REST
                               ┌────────────▼───────────────────┐
                               │         Supabase                │
                               │  Postgres · Edge Functions      │
                               │  RLS (per-user isolation)       │
                               │  Auth (OTP + JWT)               │
                               └────────────────────────────────┘
```

---

## Key Engineering Decisions

### 1. Offline-First with Outbox Sync Pattern
Every write is committed to SQLite first (zero-latency UI feedback), then placed in a sync outbox queue. A background service drains the queue when online, retrying on failure. This guarantees data durability even on flaky 2G connections common in rural India.

### 2. Server-Side Row-Level Security (RLS)
Every user-owned table (`accounts`, `ipo_applications`, `ledger_transactions`, etc.) has Postgres RLS policies enforcing `auth.uid() = user_id`. The client **cannot** read or write another user's data even if it tried — the database itself enforces isolation.

### 3. IST-Aware IPO Status Engine
IPO status (Live/Upcoming/Closed) is computed in IST (Asia/Kolkata), with the NSE/BSE 5PM cutoff correctly handled. A server-side Postgres function recalculates all statuses every 4 hours via pg_cron. The Flutter client also runs a 15-second local clock tick to reclassify IPOs as their cutoff time passes — no polling needed.

### 4. Global IPO Market Feed (ipo_market)
A Supabase Edge Function (Deno/TypeScript) fetches data from IPO data providers, normalises it, and upserts into a global `ipo_market` table. Clients are read-only via RLS. The edge function runs server-side with service_role access — the API key never touches the client.

### 5. Technical Scanner Engine
A rule-based engine evaluates 22 configurable technical conditions (RSI, EMA crossovers, volume spikes, Bollinger Band squeezes, ATR-based breakouts) against live NSE/BSE tick data. Conditions are composable and threshold-configurable per user. All math is standard textbook indicators with no external data science libraries.

### 6. Drift Code-Generated DAOs
All local database access is through Drift's type-safe generated DAOs. Schema changes are versioned migrations. No raw SQL strings in Dart code. IDE autocomplete for every column.

---

## Project Structure (Sanitized Overview)

```
lib/
├── core/
│   ├── database/          # Drift schema + generated DAOs
│   ├── services/          # Sync service, outbox queue
│   └── utils/             # Logger, date helpers, formatters
├── features/
│   ├── auth/              # OTP login, splash, biometric lock
│   ├── ipos/              # IPO list, detail, apply, allotment
│   ├── accounts/          # Portfolio accounts, ledger, P&L
│   ├── scanner/           # Stock screener, watchlists
│   └── settings/          # Profile, backup, theme
├── providers/             # Riverpod provider declarations
├── models/                # Pure Dart data models
└── engine/                # Status engine, indicator math
```

---

## Screenshots

> _Screenshots and demo video coming soon._
> 
> | IPO Market | Portfolio | Scanner |
> |-----------|-----------|---------|
> | ![IPO screen placeholder](screenshots/ipo_screen.png) | ![Portfolio placeholder](screenshots/portfolio.png) | ![Scanner placeholder](screenshots/scanner.png) |

**Demo Video:** _[Link to be added]_

---

## Engineering Highlights for Evaluators

- **~15,000 lines** of production Dart across 80+ files
- **Zero external state management complexity** — Riverpod's compile-time safe providers
- **Full offline support** with reactive SQLite streams (no "loading" spinners after first run)
- **End-to-end encryption boundary** — Supabase service role key never leaves the server
- **Clean architecture** — UI has no knowledge of Supabase or Drift; speaks only to repositories

---

## License

See [LICENSE](./LICENSE). This showcase is for evaluation purposes only.  
**The full application source code is proprietary.**
