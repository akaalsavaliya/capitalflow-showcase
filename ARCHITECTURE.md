# CapitalFlow — Architecture Deep Dive

> This document describes the design in words. No schema, no SQL policies, no API keys, no Supabase URLs are included in this showcase.

---

## Design Philosophy

**Three non-negotiable constraints drove every decision:**

1. **The app must work offline.** Indian retail investors often operate on intermittent mobile data. The app cannot be unusable without connectivity.
2. **User data must be strictly isolated.** Multiple users may share a device. No user can ever see another's IPO applications, accounts, or transactions.
3. **Sensitive operations must run server-side.** API keys for IPO data providers, scanner data feeds, and admin operations must never reach the client device.

---

## Layered Architecture

### Layer 1 — Presentation (Flutter Widgets + Screens)
- Built with Flutter Material 3 and a custom design system (tokens for color, typography, spacing, elevation)
- State is managed exclusively through **Riverpod providers** — no `setState`, no `InheritedWidget` complexity
- Screens declare `ref.watch(someProvider)` and rebuild reactively on data change
- The UI layer has **zero knowledge** of Supabase, SQLite, or HTTP — it speaks only to providers

### Layer 2 — Providers (Riverpod)
- `StreamProvider` for reactive SQLite streams (Drift)
- `AsyncNotifier` for operations with loading/error/data states
- `Provider` for synchronous derived state (e.g., filtered IPO lists, computed status)
- All providers are declared in a single directory, making the dependency graph explicit

### Layer 3 — Repository
- One repository per domain: `IpoRepository`, `AccountsRepository`, `ScannerRepository`, `ProfileRepository`
- Repositories are pure Dart classes — no Flutter, no Supabase, no Drift leaked to the caller
- They own the decision of "read from cache or fetch from network" and "write locally then sync"
- Dependency injection via Riverpod (no service locator / GetIt)

### Layer 4 — Local Cache (Drift / SQLite)
- All user data lives first in a local SQLite database managed by **Drift** (a type-safe Dart ORM)
- Schema is declared in Dart as typed table definitions; Drift generates all DAO code at build time
- Database migrations are versioned — no raw `ALTER TABLE` strings scattered in code
- Reactive streams (`watchAll()`, `watchByStatus()`) mean the UI automatically refreshes when data changes, with zero polling

### Layer 5 — Sync Service (Outbox Pattern)
- When the user is offline, writes are queued in a local outbox table
- On reconnection, the sync service drains the queue in order, with exponential backoff on failure
- On first login, the service "stamps" any local records (created as guest) with the authenticated `user_id`, then pushes them to the cloud
- This pattern ensures **no data loss** and **no duplicate records** across online/offline transitions

### Layer 6 — Supabase (Backend)
- **Postgres** for relational storage with Row Level Security (RLS) enforced at the database level
- **Edge Functions** (Deno/TypeScript) for server-only operations: IPO market data sync, admin notifications
- **Auth** (OTP / Magic Link via email) with JWT-based session management
- **Realtime** not used — the outbox pattern is simpler and more reliable on mobile

---

## Data Flow: IPO Market Feed

```
[ipoalerts.in API]
        │  HTTP (server-side only, key in Supabase secret)
        ▼
[sync-ipo-market Edge Function]  ← runs every 4 hours via pg_cron
        │  normalise, validate, deduplicate
        ▼
[ipo_market table]  ← service_role writes; client is read-only (RLS)
        │  SELECT via anon/authenticated role
        ▼
[IST status views]  ← ipo_market_live, ipo_market_upcoming, ipo_market_closed
        │  Supabase PostgREST read
        ▼
[SupabaseIpoService.dart]  ← maps columns → IpoApiModel
        │  upsert into SQLite
        ▼
[Drift ipoApiCache table]  ← reactive stream
        │  watch()
        ▼
[IpoBucketNotifier]  ← 15-second clock tick reclassifies status in memory
        │  provides live/upcoming/closed lists
        ▼
[IPO Screen Widgets]  ← rebuilds on stream change
```

---

## Data Flow: User IPO Application (Offline-First)

```
User taps "Apply"
        │
        ▼
IpoRepository.saveIpoApplication()
        │  immediate: write to Drift SQLite (status: pending_sync)
        │  immediate: return success to UI (zero-latency feedback)
        ▼
UI updates (optimistic)
        │  background:
        ▼
SyncService.enqueue(IpoApplicationSyncJob)
        │  when online:
        ▼
Supabase upsert (ipo_applications table)
        │  RLS ensures auth.uid() = user_id
        ▼
Update local record status: pending_sync → synced
```

---

## Security Model

| Threat | Mitigation |
|--------|-----------|
| User reads another user's data | RLS policy: `USING (auth.uid() = user_id)` on every table |
| API key leaked to client | IPO data API keys stored as Supabase secrets, used only in Edge Functions |
| Supabase service role key leaked | Never in client bundle; only in Edge Function environment |
| Sensitive data on device | `flutter_secure_storage` (Android Keystore / iOS Keychain) for tokens |
| Unauthorized app access | Biometric lock on app resume (`local_auth`); optional PIN fallback |
| SQL injection | Drift generates parameterized queries; no raw SQL string interpolation |

---

## Technical Scanner Design (Overview)

The scanner evaluates stocks against a library of technical conditions. The architecture is:

- **Condition interface**: each condition is a pure function `(List<Candle>) → bool`
- **Indicator library**: RSI, EMA, SMA, ATR, Bollinger Bands implemented as stateless math functions
- **Condition engine**: takes a list of active conditions and returns `Map<Stock, List<MatchedCondition>>`
- **Configurable thresholds**: users can adjust RSI levels, EMA periods, and volume multipliers
- **No external libraries**: all math is implemented from scratch using standard textbook formulas

The specific condition definitions, their threshold defaults, and the engine's evaluation order are **proprietary and not included in this showcase**.

---

## Why These Choices?

| Decision | Alternatives Considered | Why This Choice |
|----------|------------------------|-----------------|
| Riverpod | BLoC, Provider, GetX | Compile-time safety, no BuildContext required, testable |
| Drift | sqflite raw, Hive, Isar | Type safety, code generation, SQL joins, migrations |
| Supabase | Firebase, custom REST | Postgres (full SQL), RLS, Edge Functions, Auth in one |
| Outbox sync | Optimistic update only | Durability: data survives app kill between write and sync |
| OTP auth | Password, Google Sign-In | No password to forget; works on feature phones |
| pg_cron | Client polling | Server-side scheduling; 0 client battery drain |
