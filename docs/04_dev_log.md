# Development Log

> Update this file at the end of each coding session.
> Format: newest entries at the top.
> AI Agent: read this file when starting a new feature — it contains constraints
> and decisions that override or clarify the feature files.

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

