# Development Log

> Update this file at the end of each coding session.
> Format: newest entries at the top.
> AI Agent: read this file when starting a new feature — it contains constraints
> and decisions that override or clarify the feature files.

---

## 2026-06-04 — Feature 05: Transaction History & CSV Import Completed

### What was built
- **Comprehensive History UI:** Built `HistoryScreen` featuring debounced real-time search, select chips for type filters (All, Income, Expense), dropdown picker for category filtering, date range filter, and sorting toggles (Newest/Oldest).
- **Edit Details Bottom Sheet:** Developed `EditTransactionSheet` to update transaction properties (amount, description, date, type, category, vendor, payment method) with inline validation. Invokes dashboard provider updates so changes instantly propagate.
- **Swipe-to-Delete with Undo:** Integrated swipe left Dismissible with a confirmation dialog. Soft-deletes from DB and shows a 5-second SnackBar containing an "Undo" action to restore the record.
- **Spreadsheet/CSV Import Wizard:** Implemented a multi-step wizard (`CsvImportScreen`):
  - *Step 1: Input:* Upload `.csv`/`.tsv`/`.txt` files via `file_picker` or copy-paste spreadsheet text directly (bypassing mobile storage permission dialogs). Delimiters (, ; \t) are auto-detected.
  - *Step 2: Column Mapping:* Match file columns to database columns, fully supporting separate income and expense columns as well as single amount columns.
  - *Step 3: Category Mapping & Preview:* Globally matches file category strings to Pawcket categories, displays a list of parsed rows highlighting warning/errors, shows total counts, and batch-inserts the records in a single DB transaction block.
- **CSV Parser Utility:** Created `CsvParser` with robust parsing logic for Indonesian and US formatting (e.g., `Rp 150.000`, `1,500.50`, `-Rp 5.000` auto-detected and parsed correctly).
- **Bug Fix for Step 3 Layout:** Resolved a bottom overflow issue of 103px and locked scroll on Step 3 by configuring the `AnimatedSwitcher`'s `layoutBuilder` to use `StackFit.expand`. This allows height constraints to propagate correctly, letting `Expanded` size the `CustomScrollView` properly and keeping action buttons pinned at the bottom.
- **Bug Fix for Onboarding Database Error:** Fixed a database crash (`UNIQUE constraint failed: users.device_id`) during onboarding when the database already contains a user record with the active `device_id`. In [local_db.dart](file:///c:/Users/fakhr/flutter%20projects/pawcket-prd/lib/services/database/local_db.dart), `createUser` now queries for an existing record, restores/reactivates it, and skips insertion if it exists. Additionally, `saveCategories` now uses `ConflictAlgorithm.ignore` to bypass conflicts on already-existing category names.
- **Cumulative Running Balance Support:** Refactored the dashboard to calculate the cumulative running balance up to the end of the selected month (all-time income minus all-time expense from epoch to target month) via `getCumulativeBalance` query in [local_db.dart](file:///c:/Users/fakhr/flutter%20projects/pawcket-prd/lib/services/database/local_db.dart). Added `cumulativeBalance` property to `DashboardData` and `SummaryCards`, so that the "Saldo" card reflects the user's actual running cumulative net balance at any point in time. Rearranged the dashboard layout in [dashboard_screen.dart](file:///c:/Users/fakhr/flutter%20projects/pawcket-prd/lib/screens/dashboard/dashboard_screen.dart) to always show the SummaryCards at the top of the screen (even when the selected month is empty), leaving only the list and charts to show the empty state when there are no transactions.
- **Unit Tests:** Created `csv_parser_test.dart` and `history_test.dart`, verifying that delimiter auto-detection, date/amount parsing, mapping logic, and state copies function correctly. All 32 unit tests now pass.

### Decisions made
- **Dual import options (File Picker & Copy-Paste):** Providing copy-paste alongside file selection ensures maximum compatibility across all operating systems without triggering painful runtime storage permission requests.
- **Global category mapping during import:** Scanning the spreadsheet for unique category names and mapping them globally prevents users from editing categories row-by-row, delivering a premium UX.
- **Expose db public getter in HistoryNotifier:** Renamed `_db` to `db` to allow screens to access database queries cleanly while preserving the centralized Riverpod structure.

---

## 2026-06-04 — Income Tracking & Dashboard Enhancement

### What was built
- **5 Income Categories:** Added `salary`, `bonus`, `investment`, `gift`, `otherIncome` to `PredefinedCategory` enum with unique icons (account_balance_wallet, star, trending_up, card_giftcard, attach_money) and green/teal color palette.
- **Silent Migration:** Created `ensureIncomeCategoriesExist()` in `LocalDb` that auto-seeds income categories for existing users on app start without requiring uninstall or reset.
- **Mr. Oyen Income Detection:** Updated `ChatApiService` system prompt so Mr. Oyen can classify income (gaji, bonus, hadiah, dll), respond with happy mood, and output `transaction_type: "income"` with correct category in `extracted_transaction`.
- **NLPParser Income Detection:** Updated Widget quick-input parser to also detect income vs expense via keyword recognition (e.g., "gajian", "dapat uang" → income).
- **ParsedTransaction Model:** Added `transactionType` field (`'expense'` or `'income'`) with default `'expense'` for backward compatibility.
- **4-Card Dashboard Summary:** Refactored `SummaryCards` from 2-card to 4-card layout: Pemasukan (green ↓), Pengeluaran (red ↑), Transaksi (blue count), Saldo/Balance (dynamic green/red).
- **Transaction List Color Coding:** Income shows green `+ Rp...`, expense shows red `- Rp...` in the recent transactions list.
- **DashboardData Model:** Added `totalTransactions` field; updated `getMonthlySummary` SQL query to include `COUNT(*)`.
- **Unit Tests:** Added 2 new income parsing tests (14 total, all passing).

### Decisions made
- **Income categories use `category_type` string (e.g., `'salary'`) in the database**, not the Dart enum constant name (`otherIncome`). This keeps DB queries and LLM prompts consistent.
- **Pie Chart stays expense-only.** Income sources are typically 1-2 categories (salary), so a pie chart adds no value. Income is represented by the summary card total instead.
- **Silent migration over schema version bump.** Since we only need to insert rows (not alter tables), we check-and-insert on every `getUser()` call. This is idempotent and avoids a database version migration.

---

## 2026-06-03 — Feature 04: Dashboard Completed + App Icon + Housekeeping

### What was built
- **Dashboard Analytics:** Implemented `DashboardNotifier` (Riverpod) with month-based navigation, pagination, and reactive data loading.
- **Summary Cards & Expense Chart:** Created `SummaryCards` (income vs expense) and `ExpenseChart` (fl_chart pie chart) widgets with category-color-coded legend.
- **Dashboard Screen Refactor:** Added month navigation (< / >), pull-to-refresh, paginated transaction list with load-more, and empty state with Mr. Oyen mascot.
- **Real-Time Dashboard Refresh:** `ChatProvider` now calls `ref.invalidate(dashboardProvider)` after every successful transaction insert from chat, so Dashboard reflects new data immediately.
- **App Icon:** Replaced default Flutter icon with custom `pawcket_logo.png` across all Android (`mipmap-*`) and iOS (`AppIcon.appiconset`) densities.
- **OpenRouter Model Updates:** Switched default model to `openai/gpt-oss-120b` with fallbacks to `google/gemma-4-26b-a4b-it:free`, `meta-llama/llama-3.3-70b-instruct:free`, `qwen/qwen3-coder:free`. Increased API timeout from 10s to 45s.
- **Security:** Added `.env` to `.gitignore`, removed hardcoded API key from `test_gemini.dart` to pass GitHub secret scanning.
- **Unit Tests:** 13 tests passing (including dashboard boundary and data calculation tests).

### Decisions made
- **fl_chart for pie chart visualization.** Lightweight, well-maintained, and supports animated donut charts with center labels.
- **Month-based navigation** instead of date-range picker — simpler UX for monthly budgeting mindset.
- **Empty state design** shows Mr. Oyen with a playful message encouraging users to start tracking.

### Deviations from spec
- Dashboard was spec'd as "⏳ Pending" in `00_master_plan.md` — now marked ✅ Done.

---

## 2026-06-03 — Feature 03: AI Chat Assistant Completed

### What was built
- **OpenRouter Model Auto-Fallback:** Implemented retry logic in `OpenRouterClient` that tries the primary model first (defaults to `google/gemini-2.5-flash:free`), then falls back to other free models (`google/gemini-2.0-flash-exp:free`, `meta-llama/llama-3-8b-instruct:free`, `qwen/qwen-2-7b-instruct:free`) if the previous one fails.
- **Chat Data Models:** Created `ChatMessage` and `ChatSession` mapping SQLite schemas into Dart.
- **Database Services:** Coded `ChatService` and added `getTransactionWithCategory`, `getMonthlyExpense`, `getRecentTransactions`, and `getActiveBudgets` methods inside `LocalDb` to retrieve financial context and link chat messages with transactions.
- **Chat API Orchestration:** Coded `ChatApiService` that pulls monthly spending, budgets, and last 5 transactions from SQLite database, feeds them dynamically into Mr. Oyen's system prompt context, sends messages to OpenRouter, parses structured responses (incorporating Oyen's response text, Oyen's mood, and automatic expense detection), and persists transactions to DB.
- **Chat State Management:** Implemented Riverpod-based state management (`chatProvider` & `ChatNotifier`) to manage chat histories, message queuing, mood states, session initialization, and database syncing.
- **UI Screen & Chat Bubble:** Built `ChatScreen` and `ChatBubble` displaying message flows, Oyen avatar expressions changing dynamically, micro-animated dots for typing status, receipt visualization for linked transactions, session menu actions, and voice dictation.
- **Main App Navigation & Tabs:** Refactored `DashboardScreen` into a tab-based navigation wrapper linking Dashboard (Category View), Mr. Oyen Chat Tab, and a Transaction History Tab (displaying detailed transaction logs from SQLite).
- **Unit and Integration Tests:** Created `chat_test.dart` verifying `ChatMessage` mapping. Upgraded `home_widget` package to version `0.9.2` to resolve external compilation errors on newer Flutter SDK. Updated `widget_test.dart` with `pumpAndSettle()` to support async onboarding state checks. All 11 unit/widget tests now pass cleanly.

### Decisions made
- **Single API Call for Chat & Expense Logging:** Instructed Gemini inside the chat system prompt to return a structured JSON mapping containing Oyen's sassy text response, Oyen's mood, and optional transaction parameters. This allows us to parse and save logged transactions in a single LLM API call, preventing double calls and latency.
- **Automatic Fallback Models:** Integrated a retry queue of 4 free high-quality models in `OpenRouterClient` so the chat assistant remains responsive even if one particular API endpoint is down.
- **Embedded Receipts in Chat Bubbles:** Designed custom transaction cards showing category icons, color schemes, amounts, and descriptions directly inside Mr. Oyen's chat bubble whenever an expense was successfully recorded.

---

## 2026-06-03 — Feature 02: Home Screen Widget Completed

### What was built
- **Android Home Screen Widget:** Created XML layout (`pawcket_widget.xml`) and drawable background assets with transparent glassmorphism styling.
- **Home Widget Native Bridge:** Created `PawcketWidgetProvider.kt` utilizing the `home_widget` package. Configured click actions to launch the Flutter app with custom parameters (`type_expense` and `voice_input`).
- **QuickInputView Overlay Screen:** Implemented `quick_input_view.dart` which renders a translucent glassmorphic overlay for rapid expense entry.
- **Speech-to-Text Integration:** Created `speech_service.dart` wrapping `speech_to_text` to transcribe Indonesian voice inputs.
- **OpenRouter LLM Parser:** Built `openrouter_client.dart` and `nlp_parser.dart` to make API calls to OpenRouter using `google/gemini-2.5-flash:free` to parse raw input into structured transaction JSON.
- **Dynamic Oyen Mascot Display:** Configured the mascot image (Lazyass, Thinking, Smirk, Angry) to update dynamically on both the widget and the QuickInputView depending on the transaction parsing state.
- **Database Integration:** Created `TransactionModel` and updated `LocalDb` with `verifyCategoryExists` and `insertTransaction` methods to persist parsed transactions.

### Decisions made
- **Widget as Launcher:** Due to Android limitations preventing active keyboard text inputs inside home screen widgets, the widget functions as a quick launcher. It opens a dedicated overlay screen (`QuickInputView`) with auto-focus keyboard or auto-trigger voice listening.
- **Native Drawable Mapping:** Copied Mr. Oyen mascot PNGs into Android's native `drawable` resource directory to allow rapid, latency-free updates in the home screen widget using resource IDs.
- **Auto-Reset Widget State:** Configured success state (`smirk_oyen`) to automatically revert back to idle state (`lazyass_oyen`) after 3 seconds on the home screen widget.

---

## 2026-06-02 — Mascot Assets Updated

### What was built
- **Mascot Asset Cleanup & Integration:** Removed the AI-generated `mr_oyen_happy.png` asset and updated `MrOyenAvatar` to dynamically map expressions (`angry`, `cunning`, `interogating`, `lazyass`, `mischievous`, `smirk`, `thinking`) to the new, custom-generated mascot assets supplied by the user.

### Decisions made
- Set `smirk_oyen.png` as the default mascot image when no expression (or a non-matching expression) is specified in `MrOyenAvatar`.

---

## 2026-06-02 — Feature 01: Onboarding Completed

### What was built
- **Flutter App Shell & Config:** Initialized the project shell, configured dependencies (sqflite, flutter_riverpod, path, uuid, shared_preferences) and mapped asset directories.
- **SQLite Database Integration:** Implemented `local_db.dart` mapping all tables, indexes, and views from `01a_database_schema.sql` (users, categories, transactions, budgets, chat sessions, chat messages, user preferences, sync state, and analytics views).
- **Mascot Asset Generation:** Generated the premium 3D Mr. Oyen mascot image (`mr_oyen_happy.png`) using AI and integrated it into the assets.
- **Data Models & State Providers:** Coded the `CategoryModel` and `UserModel`, and implemented Riverpod providers for onboarding state (`onboarding_provider.dart`) and category state (`category_provider.dart`).
- **UI Screens:** Developed the Onboarding Welcome view (`onboarding_screen.dart`), the multi-select Category Selection grid with inline custom category creation (`category_selection.dart`), and a Dashboard view (`dashboard_screen.dart`) that verifies the saved SQLite categories.
- **Tests:** Created unit test suite (`onboarding_test.dart`) for custom category name validation rules and updated the widget test (`widget_test.dart`) for the welcome screen.

### Decisions made
- **Modern State Management:** Adopted `flutter_riverpod` directly for local state mapping and reactive UI updates.
- **Premium Cards UI:** Used color-coded container highlights for selected categories instead of simple checklist boxes.
- **Mascot Integration:** Used `RadialGradient` and `BoxShadow` surrounding Mr. Oyen's avatar to give it a premium "glowing" aesthetic.
- **Developer Reset Utility:** Added an onboarding reset button in the dashboard app bar that purges database tables and configurations to easily re-test the onboarding process.

### Deviations from spec
- Changed deprecated `withOpacity(val)` usages to the modern `withValues(alpha: val)` to comply with newer Flutter version styling rules and avoid compile warnings.
- Substituted `CardTheme` with `CardThemeData` in `theme.dart` to solve a type-mismatch compiler error.

### Known issues or tech debt
- The command `flutter test` fails on Windows compilation because the directory path contains an apostrophe (`MY PRD's`), which breaks Flutter's internal temporary test listener script generation. All source files analyze clean (`flutter analyze` reports "No issues found!").

---

## 2026-06-02 — Project Initialization

### What was built
PRD structure and feature specs for Pawcket MVP. No code written yet; this is the planning phase.

### Decisions made
- **Tech Stack:** Flutter 3.19+ with Riverpod for state management, Provider for legacy support
- **Database:** SQLite 3.46+ for local-first architecture, Supabase schema prepared for optional v2 cloud
- **LLM API:** OpenRouter for flexibility and cost; fallback to Google Gemini if OpenRouter unavailable
- **Widget Library:** Android AppWidget (native) via Flutter platform channels; iOS deferred
- **Chart Library:** fl_chart for pie charts (Pub.dev, well-maintained)
- **Voice Input:** speech_to_text package with Indonesian locale support
- **Build Order:** Onboarding → Home Widget → AI Chat → Dashboard → History → Settings → Cloud (optional)
- **Design System:** Material 3 with custom color tokens; supports future dark mode migration
- **NLP Approach:** Hardcoded system prompts to LLM (not fine-tuned); strict JSON response format

### Deviations from spec
None yet (project just initialized).

### Constraints discovered
- Android home screen widgets are API 21+ only; iOS requires alternative input method (deferred)
- OpenRouter free tier has ~5 requests/min rate limit; implement exponential backoff
- Firebase is simpler for cloud sync but vendor lock-in; Supabase preferred for v2 but requires more setup
- speech_to_text has no offline fallback for v1; voice input requires internet (noted in UX)

### Known issues / tech debt
- [ ] No offline LLM model bundled (cloud-only for MVP; acceptable for target market)
- [ ] No encryption for local SQLite (acceptable since app data is on-device only)
- [ ] No analytics or telemetry (by design, privacy-first)

### Next session should start with
Set up Flutter project skeleton with folder structure from docs/01_technical_specs.md. Create pubspec.yaml with required dependencies:
- riverpod, riverpod_annotation
- sqflite, sqflite_common
- http (for OpenRouter API calls)
- speech_to_text
- fl_chart
- package_info_plus
- provider (if legacy compat needed)

Then implement Feature 01 (Onboarding) as the first vertical slice.

---

[Older entries below — none yet]

