# Development Log

> Update this file at the end of each coding session.
> Format: newest entries at the top.
> AI Agent: read this file when starting a new feature — it contains constraints
> and decisions that override or clarify the feature files.

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

