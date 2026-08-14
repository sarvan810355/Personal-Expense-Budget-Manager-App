# Personal Expense & Budget Manager App — Architecture Document (v1)

Status: **PLANNING ONLY — no implementation code written yet.** Awaiting approval before Phase 1 build starts.

---

## 1. Tech Stack

| Layer | Choice | Why |
|---|---|---|
| Framework | Flutter (Dart, stable channel) | Cross-platform, single codebase, Material 3 support |
| UI system | Material 3, mobile-first, light/dark themes | Modern, matches "premium/minimal" requirement |
| State management | **Riverpod** (`flutter_riverpod` + `riverpod_generator`) | Compile-safe DI, testable, scales better than Bloc for this size without the ceremony |
| Local database | **Drift** (SQLite) | Type-safe SQL, migrations, reactive streams (`watch()`) map directly to Riverpod providers |
| Routing | `go_router` | Declarative, supports nested/bottom-nav shells, deep links (future) |
| Models | `freezed` + `json_serializable` | Immutable models, easy `copyWith`, future JSON (de)serialization for export/cloud sync |
| Charts | `fl_chart` | Pie/donut, bar, line charts, actively maintained |
| Images | `image_picker`, `path_provider`, `flutter_image_compress` | Receipt capture + compression |
| Export | `csv`, `syncfusion_flutter_xlsio` or `excel`, `pdf`/`printing` | CSV/Excel/PDF export |
| Notifications | `flutter_local_notifications` | Budget alerts, recurring expense reminders |
| Date/format | `intl` | Currency & date formatting |
| Testing | `flutter_test`, `mocktail`, `drift`'s in-memory test DB | Unit + widget tests |

**Backend (future-ready, not built in v1):** Repository interfaces are defined against abstract contracts so a `RemoteExpenseRepository` (Firebase/Supabase/REST) can be swapped in later without touching UI or business logic. Auth, sync, and conflict resolution are explicitly out of scope for v1.

---

## 2. Clean Architecture — Layering

```
presentation (UI, widgets, screens)
        ↓ watches
application (Riverpod providers/notifiers, use-cases)
        ↓ calls
domain (entities, repository interfaces, calculation services)
        ↓ implemented by
data (Drift tables/DAOs, repository implementations, mappers)
```

Rule: presentation never talks to Drift directly; it only depends on domain repository interfaces via providers. This is what makes future cloud-sync a drop-in repository swap.

---

## 3. Folder Structure

```
lib/
├── main.dart
├── app/
│   ├── app.dart                     # MaterialApp.router, theme wiring
│   ├── router/
│   │   ├── app_router.dart          # go_router config
│   │   └── routes.dart              # route name constants
│   └── theme/
│       ├── app_theme.dart           # Material3 ThemeData (light/dark)
│       ├── app_colors.dart
│       └── app_typography.dart
│
├── core/
│   ├── constants/                   # default categories, icons, currency list
│   ├── utils/                       # date_utils, currency_formatter
│   ├── errors/                      # Failure types, exceptions
│   ├── validation/                  # form validators (amount, date, etc.)
│   ├── services/
│   │   ├── calculation_service.dart # centralized financial math (see §7)
│   │   ├── notification_service.dart
│   │   ├── export_service.dart
│   │   └── seed_data_service.dart   # demo/dummy data generator
│   └── widgets/                     # EmptyState, LoadingView, ErrorView, AppCard, etc.
│
├── data/
│   ├── local/
│   │   ├── app_database.dart        # Drift @DriftDatabase
│   │   ├── tables/                  # one file per table (see §5)
│   │   └── daos/                    # ExpenseDao, BudgetDao, TripDao, ...
│   └── repositories/                # *RepositoryImpl, implements domain contracts
│
├── domain/
│   ├── entities/                    # freezed entities (Expense, Budget, Trip, ...)
│   └── repositories/                # abstract repository interfaces
│
├── features/
│   ├── dashboard/
│   │   ├── presentation/{screens,widgets}
│   │   └── application/ (providers)
│   ├── expenses/
│   ├── categories/
│   ├── budgets/
│   ├── trips/
│   ├── income/
│   ├── accounts/
│   ├── recurring/
│   ├── reports/
│   ├── calendar/
│   ├── search/
│   ├── settings/
│   └── backup_export/
│
└── l10n/ (future)

test/
├── unit/            # calculation_service, validators, repositories
├── widget/          # empty states, expense form, budget progress card
└── data/            # Drift DAO tests (in-memory db)
```

Each `features/<x>` folder is self-contained (screens, widgets, its own providers) and only imports from `core/`, `domain/`, and `data/` — never from another feature directly. This keeps modules independently buildable per phase, matching the phased delivery requirement.

---

## 4. Entity-Relationship Overview

```
Account 1───∞ Expense ∞───1 Category (self-ref parentCategoryId for subcategories)
Account 1───∞ Income   ∞───1 Category (type=income: Salary/Business/...)
Trip    1───∞ Expense                 (tripId nullable on Expense)
Trip    1───∞ TripCategoryBudget ∞───1 Category
Budget  1───∞ BudgetCategory     ∞───1 Category
RecurringExpense ∞───1 Category, ∞───1 Account
Expense ∞───∞ Tag  (via ExpenseTag join table)
```

Key design decisions:
- **Budget vs BudgetCategory**: a `Budget` is a period (e.g. "August 2026 Monthly Budget") with a total amount; `BudgetCategory` rows are the per-category envelopes shown in the mockups (Food ₹5,000, Transport ₹3,000, ...). This matches §9's nested example without duplicating the Budget concept.
- **Trip reuses the Category table** (Travel/Hotel/Food/... already exist as top-level or trip-context categories) rather than a separate taxonomy — avoids two parallel category systems.
- **Day-wise trip tracking** (§12) is a *derived view* (`GROUP BY date` over `Expense WHERE tripId = ?`), not a stored table — it's fully computable from existing data.
- **Category is self-referential** (`parentCategoryId`) to support the default category → subcategory hierarchy in §6 (Food → Restaurant/Grocery/...).

---

## 5. Database Schema (Drift tables)

```
Category
  id (pk), name, icon, color, type (expense|income),
  parentCategoryId (nullable, fk→Category.id), isDefault, sortOrder

Account
  id (pk), name, type (cash|bank|upi|card|wallet), balance,
  icon, color, isActive, createdAt

Expense
  id (pk), amount, title, categoryId (fk), accountId (fk),
  tripId (nullable, fk→Trip.id), date, time, note,
  paymentMethod, location, receiptPath, createdAt, updatedAt

Income
  id (pk), amount, source (enum), categoryId (nullable fk),
  accountId (fk), date, note, createdAt

Tag
  id (pk), name
ExpenseTag (join)
  expenseId (fk), tagId (fk)

Budget
  id (pk), name, periodType (weekly|monthly|custom),
  startDate, endDate, totalAmount, alertThresholds (json: [80,90,100]),
  createdAt
BudgetCategory
  id (pk), budgetId (fk), categoryId (fk), allocatedAmount

Trip
  id (pk), name, destination, startDate, endDate,
  totalBudget, notes, createdAt
TripCategoryBudget
  id (pk), tripId (fk), categoryId (fk), allocatedAmount

RecurringExpense
  id (pk), title, amount, categoryId (fk), accountId (fk),
  frequency (daily|weekly|monthly|yearly), startDate,
  nextDate, endDate (nullable), active, note

AppSettings (single row)
  id (pk=1), currencyCode, themeMode (light|dark|system),
  budgetAlertThresholds, notificationsEnabled, weekStartDay
```

Indexes: `Expense(date)`, `Expense(categoryId)`, `Expense(tripId)`, `Expense(accountId)` — the filter/report/calendar screens all query by these.

---

## 6. Navigation Map

```
Root (go_router ShellRoute — bottom nav persists)
├── /dashboard                 (tab 1)
├── /expenses                  (tab 2)
│    └── /expenses/:id         (detail)
├── /budgets                   (tab 3)
│    └── /budgets/:id
├── /reports                   (tab 4)
├── /more                      (tab 5 — grid/list menu)
│    ├── /income
│    ├── /trips
│    │    └── /trips/:id       (trip dashboard → expenses/day-wise/analytics tabs)
│    ├── /categories
│    ├── /accounts
│    ├── /recurring
│    ├── /export
│    └── /settings
│
├── /add-expense                (modal/full-screen, reached via global FAB)
├── /add-income
├── /calendar                   (reached from Dashboard quick action / date tap)
└── /search                     (reached via app bar icon, global)
```

FAB (Add Expense) floats above the bottom nav on every primary tab, per §22.

---

## 7. Screen List (~28 screens, v1)

1. Dashboard
2. Add/Edit Expense
3. Expense List
4. Expense Detail
5. Calendar View
6. Category List
7. Add/Edit Category
8. Budget List
9. Budget Detail (progress, per-category breakdown)
10. Create/Edit Budget
11. Trip List
12. Trip Detail (tabs: Overview / Expenses / Day-wise / Analytics)
13. Create/Edit Trip
14. Add Trip Expense
15. Income List
16. Add/Edit Income
17. Account List
18. Add/Edit Account
19. Recurring Expense List
20. Add/Edit Recurring Expense
21. Reports (period selector + report cards/charts)
22. Search (global)
23. Filter sheet (expenses)
24. Settings (theme, currency, alert thresholds, notifications)
25. Export/Backup
26. More menu
27. Receipt viewer (full-screen image)
28. Onboarding/empty-state first-run (optional, seeds demo data prompt)

---

## 8. Financial Calculation Service (centralized — §32)

All formulas live in `core/services/calculation_service.dart`, pure functions, unit-tested, never duplicated in widgets:

- `totalExpense(List<Expense>) → sum`
- `totalIncome(List<Income>) → sum`
- `savings(income, expense) → income - expense`
- `budgetRemaining(budget, spent) → amount - spent`
- `budgetPercentUsed(budget, spent) → (spent/amount)*100`
- `tripRemaining(trip, spent)`
- `averageDailyExpense(total, days)`
- `dayWiseBreakdown(expenses) → Map<DateTime, double>`
- `categoryBreakdown(expenses) → Map<Category, double>`
- `monthlyComparison(expenses, months)`

Screens only call this service and render results — no math in widgets.

---

## 9. Feature Dependency Map

```
Category ──┬─→ Expense ──┬─→ Budget/BudgetCategory ──→ Reports/Dashboard
Account  ──┘             ├─→ Trip (Expense.tripId)   ──→ Trip Dashboard/Day-wise
                          ├─→ Calendar
                          ├─→ Search
                          └─→ Recurring Expense (generates future Expenses)
Income ───────────────────────────────────────────────→ Dashboard/Reports (savings)
Calculation Service ──→ Dashboard, Budget, Trip, Reports (all consume it)
Notification Service ──→ Budget alerts, Recurring reminders (needs Budget + Recurring first)
Export Service ──→ needs full Expense/Income data model finalized
```

This ordering directly drives the phase sequence below: **Category & Account must exist before Expense; Expense must exist before Budget, Trip, Calendar, Reports.**

---

## 10. Development Phases (confirmed from brief, refined)

| Phase | Scope | Depends on |
|---|---|---|
| **1. Foundation** | Project setup, folder structure, theme (light/dark), Drift DB + all tables, go_router shell, core widgets, calculation service skeleton, seed/demo data service | — |
| **2. Expense System** | Category CRUD (with defaults from §6), Account CRUD (needed for Expense form), Add/Edit/Delete Expense, Expense List + filters, Calendar view, Search | Phase 1 |
| **3. Money Management** | Income CRUD, Account balance calculation, Payment method selection wiring | Phase 2 |
| **4. Budget** | Budget + BudgetCategory CRUD, progress bars, 80/90/100% alerts, notification wiring | Phase 2, 3 |
| **5. Trips** | Trip CRUD, TripCategoryBudget, trip-scoped expense entry, day-wise view, trip analytics | Phase 2, 4 |
| **6. Analytics** | Dashboard charts (donut/bar/line), Reports screen, monthly comparison, insights (rule-based, not ML) | Phase 2–5 |
| **7. Advanced** | Recurring expenses + generator, receipt capture/compression, CSV/Excel/PDF export, local notifications, empty-state polish, dark-mode audit | Phase 1–6 |

Every phase follows **BUILD → TEST → FIX → AUDIT** per §30/§31 before moving to the next.

---

## 11. Phase 1 Implementation Plan (ready to execute on approval)

1. `flutter create` project, set up Material 3 `ColorScheme.fromSeed` light/dark themes.
2. Add dependencies: `flutter_riverpod`, `riverpod_generator`, `drift`, `drift_dev`, `sqlite3_flutter_libs`, `go_router`, `freezed`, `json_serializable`, `intl`, `fl_chart`, `image_picker`, `path_provider`.
3. Create folder structure exactly as §3 above (empty placeholder files where needed).
4. Define Drift tables (§5) + `AppDatabase` with migration strategy (`schemaVersion = 1`).
5. Generate domain entities (freezed) mirroring tables + repository interfaces.
6. Implement repository impls backed by Drift DAOs (Expense, Category, Account, Budget, Trip, Income, Recurring, Settings).
7. Build `go_router` shell: bottom nav (Dashboard/Expenses/Budget/Reports/More) + global FAB route + placeholder screens per §7 (empty-state only, no real forms yet — those come in Phase 2).
8. Implement `calculation_service.dart` with unit tests (empty-input, single-item, multi-item cases).
9. Seed default categories (§6 full list) via a database migration/seed step; `seed_data_service.dart` for optional demo data (behind a Settings toggle, not auto-loaded in prod).
10. Core reusable widgets: `EmptyStateView`, `AppCard`, `LoadingView`, `ErrorView`, `SectionHeader`.
11. Acceptance checklist for Phase 1 (per §31, scoped to foundation): app launches to Dashboard shell, navigates all 5 tabs without crash, dark/light/system theme toggle works, DB opens and default categories are queryable, `flutter test` passes for calculation service and DB seed.

**Deliverable at end of Phase 1:** a running (but mostly empty-state) app with correct navigation, theme, and a fully seeded, tested database — no expense entry yet. That begins Phase 2.

---

*Waiting for approval to begin Phase 1 coding.*
