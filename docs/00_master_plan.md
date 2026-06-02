# Pawcket — Master Plan

## Vision
A playful, AI-powered personal finance tracker for Gen Z that transforms expense tracking from a chore into a natural conversation with Mr. Oyen, an expressive orange cat financial assistant.

## Problem
- **Pain point 1:** Gen Z finds traditional expense tracking apps tedious and boring — manual entry requires conscious effort and disrupts their workflow (~10-15 minutes/week lost to categorization)
- **Pain point 2:** Existing finance apps give users guilt without actionable advice — they show spending but don't help users understand patterns or budget better
- **Pain point 3:** Privacy concerns with cloud-first finance apps — users fear data breaches or unwanted tracking of personal financial data

## Solution
Pawcket provides frictionless expense input through a transparent home screen widget that accepts natural language ("Makan Gado-gado 15k") and instantly parses it into structured data via LLM. The app pairs this with Mr. Oyen, a sassy AI assistant who celebrates good spending but dramatically scolds overspending—delivering personality-driven insights without judgment. Local-first storage with optional cloud backup keeps users' financial data private by default.

## Target Users
| Persona | Role | Primary Goal | Key Pain Point |
|---------|------|--------------|----------------|
| Casual Spender | University student or junior professional (18-25) | Track spending without effort; understand where money goes | Existing apps feel clunky or invasive |
| Budget-Conscious Millennial | Entry-level professional (25-32) | Monitor expenses and get actionable advice to save more | Apps are boring; motivation fades quickly |
| Privacy-First User | Tech-savvy Gen Z who values autonomy | Track finances on their own device; sync optionally | Cloud-first apps require trusting centralized servers |

## Feature Roadmap (build order)
| # | Feature | Status | File | Depends On |
|---|---------|--------|------|------------|
| 1 | Onboarding & Category Selection | ✅ Done | 03_features/01_onboarding.md | — |
| 2 | Home Screen Widget (NLP Input) | ⏳ Pending | 03_features/02_home_widget_input.md | Onboarding (categories) |
| 3 | AI Chat Assistant with Mr. Oyen | ⏳ Pending | 03_features/03_ai_chat_assistant.md | Onboarding + Home Widget |
| 4 | Dashboard (Analytics & Summary) | ⏳ Pending | 03_features/04_dashboard.md | Home Widget (transactions) |
| 5 | Transaction History & Management | ⏳ Pending | 03_features/05_transaction_history.md | Home Widget |
| 6 | Profile & Settings | ⏳ Pending | 03_features/06_profile_settings.md | Onboarding |
| 7 | Cloud Backup & Sync (Optional) | ⏳ Pending | 03_features/07_cloud_backup.md | All core features |

## Global Constraints
- **Platform targets:** Android 10+ (primary MVP); iOS 15+ (post-MVP with alternative input method)
- **Performance:** Widget load time < 500ms; AI response time < 3 seconds for chat; dashboard render < 1s
- **Connectivity:** App must work fully offline; cloud backup is optional and deferred
- **Data Privacy:** No telemetry or analytics tracking; all financial data stored locally by default; encryption for backups
- **Accessibility:** Readable text sizes for older eyes; voice input support for physical accessibility
- **API Rate Limits:** OpenRouter free/cheap tier only; batch requests to minimize API calls

## Out of Scope (v1)
- iOS support (deferred to post-MVP; will require alternative input method to replace widget)
- Bank account integration or open banking (security/regulatory complexity)
- Recurring transactions or bill reminders (deferred to v2)
- Collaborative/family budgeting (single-user focus)
- Investment tracking or stock portfolio management
- Receipt OCR or expense categorization via image (voice + text sufficient for MVP)
- Advanced forecasting or predictive budgeting
- Multi-currency support (Indonesia rupiah only for MVP)
- Data export (CSV/JSON export deferred to v2)

## Success Metrics
| Metric | Target | Baseline | Measurement |
|--------|--------|----------|-------------|
| Time to first transaction input | < 10 seconds | N/A | Stopwatch from app open to successful entry |
| Daily active users (DAU) | > 10 | 0 | Analytics dashboard (local tracking) |
| Transaction accuracy (NLP parsing) | > 95% | N/A | Manual spot-check of parsed vs. intended category/amount |
| Chat response satisfaction | > 4.0/5 | N/A | In-app survey after chat interaction |
| App crash rate | < 0.1% | N/A | Exception logs aggregated monthly |
| Feature completion rate | 100% of defined scope | 0% | Definition of Done checklist per feature |

## Key Assumptions
> ⚠️ **ASSUMPTION:** OpenRouter provides a stable free/cheap tier API that supports Indonesian language NLP. Fallback: use Google Gemini API free tier if OpenRouter unreliable.

> ⚠️ **ASSUMPTION:** Flutter's platform channels can reliably access Android home screen widget APIs. If blockers arise, pivot to native Android + Kotlin for widget layer.

> ⚠️ **ASSUMPTION:** Users will enable voice input only when privacy-conscious; text input is primary. Voice library (e.g., `speech_to_text`) must handle offline fallback gracefully.

## Related Files
- Technical specs: `docs/01_technical_specs.md`
- Database schema: `docs/01a_database_schema.sql`
- Design guide: `docs/02_design_guide.md`
- Features: `docs/03_features/`
- Dev log: `docs/04_dev_log.md`
