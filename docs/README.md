# Pawcket PRD Documentation

Welcome to the Pawcket Product Requirements Document (PRD). This folder contains the complete specification for building Pawcket — a playful, AI-powered personal finance tracker for Gen Z featuring Mr. Oyen, an expressive orange cat assistant.

## 📁 File Structure

```
docs/
├── 00_master_plan.md              ← Start here: product vision, roadmap, constraints
├── 01_technical_specs.md          ← Coding standards, tech stack, folder structure
├── 01a_database_schema.sql        ← SQLite schema (copy to your database layer)
├── 02_design_guide.md             ← Colors, typography, components, accessibility
├── 03_features/                   ← One file per feature (build in this order)
│   ├── 01_onboarding.md
│   ├── 02_home_widget_input.md
│   ├── 03_ai_chat_assistant.md
│   ├── 04_dashboard.md
│   ├── 05_transaction_history.md
│   ├── 06_profile_settings.md
│   └── 07_cloud_backup.md         ← Optional, post-MVP
└── 04_dev_log.md                  ← Living project memory (update after each session)
```

## 🚀 How to Use These Docs with an AI Coding Agent

### Every Coding Session — Always Attach:
1. **`00_master_plan.md`** — So the AI knows the direction and build order
2. **`01_technical_specs.md`** — So the AI follows your code standards
3. **`01a_database_schema.sql`** — So the AI knows your data model

### Per-Feature Sessions — Also Attach:
- **`03_features/[nn]_[feature-name].md`** — The specific feature being built
- **`02_design_guide.md`** — For UI/UX consistency

### Example Starting Prompt:
```
Read the attached docs. We are implementing Feature 01: Onboarding.

Follow the technical specs and build order exactly:
1. Start with database migrations (implement schema from 01a_database_schema.sql)
2. Implement service layer (NLP parser, database access, etc.)
3. Build UI screens (onboarding flow, category picker)
4. Add tests (unit, widget, integration)

Do not implement anything outside the scope section of 01_onboarding.md.

When done, update 04_dev_log.md with:
- What was built
- Decisions made
- Any deviations from spec
- Known issues or tech debt
```

### After Each Session:
1. Update `docs/04_dev_log.md` with what you built and decisions made
2. Update the Status column in `docs/00_master_plan.md` (✅ Done, 🔄 In Progress, etc.)
3. If spec changed during implementation, update the feature file too
4. Commit changes to git with a clear message

## 📋 Feature Build Order

Build features in this order (each depends on the previous):

1. **Onboarding & Category Selection** (Feature 01)
   - User creates categories on first launch
   - Prerequisite for everything else

2. **Home Screen Widget (NLP Input)** (Feature 02)
   - Primary input method; uses categories from Feature 01
   - Integrates with OpenRouter API

3. **AI Chat Assistant** (Feature 03)
   - Uses transactions created by Feature 02
   - Reads categories from Feature 01
   - Conversational interface with Mr. Oyen

4. **Dashboard (Analytics)** (Feature 04)
   - Visualizes transactions from Feature 02/03
   - Reads categories from Feature 01
   - Main analytics view

5. **Transaction History** (Feature 05)
   - Detail view of transactions created by Feature 02/03
   - Edit/delete transactions
   - Cross-feature utility

6. **Profile & Settings** (Feature 06)
   - User preferences
   - Toggles for features (voice input, cloud sync)
   - About & help screens

7. **Cloud Backup** (Feature 07 — Optional, Post-MVP)
   - Requires all previous features
   - Can be deferred to v2

## 🛠 Tech Stack Quick Reference

| Layer | Technology | Why |
|-------|-----------|-----|
| **Mobile Framework** | Flutter 3.19+ | Cross-platform, fast, excellent UI framework |
| **State Management** | Riverpod | Type-safe, testable, modern alternative to Provider |
| **Database** | SQLite + sqflite | Local-first, privacy, no server dependency |
| **LLM API** | OpenRouter | Flexible, cheap, supports multiple models |
| **Voice Input** | speech_to_text | Flutter ecosystem, Indonesian locale support |
| **Charts** | fl_chart | Lightweight, customizable, well-maintained |
| **Design System** | Material 3 | Google standard, accessibility built-in |

## 🎨 Design Philosophy

- **Local-first:** Data stays on device by default; cloud is opt-in
- **Privacy-first:** No telemetry, analytics, or tracking
- **Minimalist:** Simple, fast, no bloat — Gen Z appreciates this
- **Fun:** Mr. Oyen adds personality; not a sterile financial app
- **Accessible:** WCAG 2.1 AA compliance, readable text sizes

## ⚠️ Important Constraints

1. **Android Home Screen Widget:** Requires native Kotlin integration; iOS support deferred
2. **Voice Input:** Requires internet (no offline fallback in MVP)
3. **LLM Rate Limits:** OpenRouter free tier ~5 req/min; implement backoff
4. **Database Soft Deletes:** Never hard-delete transactions (data preservation)
5. **No External Telemetry:** No Google Analytics, Sentry, or similar
6. **Indonesian Language:** MVP supports Indonesian + English; multi-lang in v2

## 🔑 Key Decisions Made

### NLP Parsing
- **Approach:** Hardcoded system prompts to LLM (not fine-tuned)
- **Response Format:** Strict JSON (category, amount, description, date)
- **Fallback:** If parsing fails, ask user for clarification via chat/widget

### Mr. Oyen Personality
- **Mood States:** Happy (budget OK), Neutral (normal), Shocked (overspending), Angry (serious overspend)
- **Lazy by Default:** Expressive only when needed (overspending detected)
- **Assets:** 3D realistic render, multiple expressions, not animated

### Database Design
- **Local Storage:** SQLite on-device, all data private by default
- **Soft Deletes:** `deleted_at` column; data preserved for debugging/recovery
- **No Foreign Key Cascade:** Deleting a category doesn't delete transactions (safety)

### Architecture
- **Vertical Slicing:** Each feature built end-to-end (DB → API → UI → tests)
- **Riverpod Providers:** All state managed through providers for testability
- **Platform Channels:** Flutter ↔ Kotlin for Android widget integration

## 📱 MVP Scope (What's Included)

✅ Home screen widget with text + voice input (NLP)  
✅ AI chat with Mr. Oyen (conversational finance)  
✅ Dashboard with income/expense summary + pie chart  
✅ Transaction history with search/delete  
✅ Settings & profile  
✅ Local SQLite storage  
✅ Android support (iOS deferred)  

## ❌ Post-MVP (v2 and beyond)

❌ Cloud backup (framework ready, feature deferred)  
❌ Recurring transactions / bill reminders  
❌ Budget limits & alerts  
❌ Advanced forecasting / spending insights  
❌ Family/collaborative budgeting  
❌ Bank account integration  
❌ Receipt OCR / image upload  
❌ Data export (CSV, PDF)  
❌ iOS support (alternative input needed)  
❌ Dark mode (design tokens ready)  
❌ Multi-language (framework ready)  

## 🧪 Testing Strategy

Each feature must have:
- **Unit Tests:** Service logic, formatters, validators (80%+ coverage)
- **Widget Tests:** UI components, interactions (60%+ coverage)
- **Integration Tests:** Full user flows, database operations
- **Manual Testing:** On real devices (Android 10, 12, 14)

Run tests locally:
```bash
flutter test
flutter test --coverage
```

## 🚢 Deployment

### Development
```bash
flutter run -d <device_id>
```

### Testing Build (Beta)
```bash
flutter build apk --split-per-abi
# Upload to Google Play Internal Testing channel
```

### Production Release
```bash
flutter build appbundle
# Upload to Google Play Production
# Create release notes with Mr. Oyen emoji
```

Version scheme: `major.minor.patch` (e.g., 1.0.0 → 1.0.1 → 1.1.0)

## 📚 Additional Resources

- **Flutter Docs:** https://flutter.dev/docs
- **Riverpod Guide:** https://riverpod.dev
- **SQLite Best Practices:** https://www.sqlite.org/bestpractice.html
- **Material 3 Design:** https://m3.material.io
- **OpenRouter Docs:** https://openrouter.ai/docs

## ❓ FAQ

**Q: Can I change the tech stack?**  
A: No. The specs are written for Flutter + Riverpod. If you need to pivot (e.g., React Native), update `01_technical_specs.md` and all feature files before coding.

**Q: What if I find a bug in the spec?**  
A: Update the relevant feature file, add an entry to `04_dev_log.md`, and notify the team. Don't code around spec bugs; fix the spec.

**Q: Can I skip testing?**  
A: No. Each feature has specific test requirements. Update `Definition of Done` if you have to defer non-critical tests, but core functionality must be tested.

**Q: When should I implement cloud sync?**  
A: Post-MVP (v2). For now, build the UI toggle in Feature 06 (Settings) but don't implement actual sync.

**Q: What if OpenRouter goes down?**  
A: Have a fallback to Google Gemini API free tier. Update `lib/config/api_config.dart` with fallback URL and model.

## 🎯 Success Criteria (MVP Complete)

- [ ] All 7 feature files have Definition of Done ✅
- [ ] 95%+ transaction NLP parsing accuracy
- [ ] Dashboard loads in < 1 second
- [ ] Widget loads in < 500ms
- [ ] Chat response time < 3 seconds
- [ ] Zero crashes in 1000+ transactions test
- [ ] Android 10+ support verified
- [ ] All unit + integration tests passing
- [ ] No external telemetry or analytics
- [ ] Code follows linting rules (flutter analyze clean)
- [ ] README + onboarding docs complete for beta testers

## 🙏 Credits

- **Pawcket** — AI-powered finance tracker for Gen Z
- **Mr. Oyen** — The lazy but expressive orange cat assistant
- **Built with** ❤️ **using Flutter & Riverpod**

---

**Last Updated:** [PRD Generation Date]  
**Status:** Ready for Development (Feature 01 next)
