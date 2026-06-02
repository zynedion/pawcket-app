# Technical Specifications

> AI Agent: attach this file to every coding session alongside the relevant feature file.
> Do not deviate from naming conventions or folder structure defined here.

## Tech Stack
| Layer | Technology | Version | Notes |
|-------|-----------|---------|-------|
| Frontend | Flutter | 3.19+ | Mobile app framework for Android + iOS |
| Backend | Dart (Shelf/Express backend optional) | 3.3+ | Logic runs locally in app; optional cloud backend for sync |
| Database | SQLite (local) | 3.46+ | Primary: local storage on device |
| Cloud DB | Firebase Realtime or Supabase | Latest | Optional: for cloud backup and sync |
| State Management | Provider / Riverpod | Latest | Local state and reactive UI updates |
| Authentication | Local auth (pin/biometric) + optional Firebase Auth | N/A | Users authenticate locally; cloud auth is optional |
| API / LLM | OpenRouter API | N/A | Wrapper for multiple LLM models (OpenAI, Anthropic, etc.) |
| Speech-to-Text | `speech_to_text` (Flutter package) | Latest | Voice input processing |
| Widget | Android home screen widget via platform channels | API 21+ | Native Android Kotlin layer for widget |
| UI Components | Flutter Material 3 / Riverpod UI | Latest | Standard Material Design tokens |
| Deployment | Google Play Store | N/A | Initial distribution channel |

## Folder Structure
```
pawcket/
├── lib/
│   ├── main.dart                          [App entry point]
│   ├── config/
│   │   ├── routes.dart                    [Named routes & navigation]
│   │   ├── theme.dart                     [Material 3 theme, colors, typography]
│   │   └── app_config.dart                [Feature flags, env variables]
│   ├── models/
│   │   ├── transaction.dart               [TransactionModel, serialization]
│   │   ├── category.dart                  [CategoryModel]
│   │   ├── budget.dart                    [BudgetModel]
│   │   └── ai_chat.dart                   [ChatMessage, ChatSession models]
│   ├── services/
│   │   ├── database/
│   │   │   ├── local_db.dart              [SQLite initialization & queries]
│   │   │   └── migrations.dart            [Schema versioning]
│   │   ├── api/
│   │   │   ├── openrouter_client.dart     [OpenRouter API wrapper]
│   │   │   ├── nlp_parser.dart            [LLM-powered transaction parsing]
│   │   │   └── ai_advisor.dart            [Mr. Oyen personality & responses]
│   │   ├── auth/
│   │   │   └── local_auth.dart            [Biometric + PIN authentication]
│   │   ├── storage/
│   │   │   └── cloud_sync.dart            [Optional Firebase/Supabase sync]
│   │   └── speech/
│   │       └── speech_service.dart        [Voice input processing]
│   ├── providers/
│   │   ├── transaction_provider.dart      [Riverpod: transaction state]
│   │   ├── category_provider.dart         [Riverpod: category state]
│   │   ├── budget_provider.dart           [Riverpod: budget state]
│   │   ├── chat_provider.dart             [Riverpod: chat session state]
│   │   └── auth_provider.dart             [Riverpod: auth state]
│   ├── screens/
│   │   ├── onboarding/
│   │   │   ├── onboarding_screen.dart     [Full onboarding flow]
│   │   │   └── category_selection.dart    [Category picker]
│   │   ├── dashboard/
│   │   │   ├── dashboard_screen.dart      [Main analytics view]
│   │   │   ├── expense_chart.dart         [Pie/bar chart widget]
│   │   │   └── summary_cards.dart         [Income/expense cards]
│   │   ├── chat/
│   │   │   ├── chat_screen.dart           [AI chat UI]
│   │   │   └── chat_bubble.dart           [Message bubble components]
│   │   ├── transaction_history/
│   │   │   ├── history_screen.dart        [Transaction list]
│   │   │   └── transaction_tile.dart      [Individual transaction UI]
│   │   ├── profile/
│   │   │   ├── profile_screen.dart        [User settings & info]
│   │   │   └── settings_page.dart         [App preferences]
│   │   └── widget_input/
│   │       └── quick_input_view.dart      [Lightweight input form]
│   ├── widgets/
│   │   ├── common/
│   │   │   ├── app_button.dart            [Custom button component]
│   │   │   ├── app_input_field.dart       [Custom input field]
│   │   │   └── mr_oyen_avatar.dart        [Mascot display widget]
│   │   └── [feature]/
│   │       ├── bottom_nav_bar.dart        [Navigation bar]
│   │       └── loading_indicator.dart     [Loading spinner]
│   ├── utils/
│   │   ├── constants.dart                 [App-wide constants]
│   │   ├── date_utils.dart                [Date formatting, parsing]
│   │   ├── currency_formatter.dart        [IDR formatting]
│   │   ├── validators.dart                [Input validation logic]
│   │   └── logger.dart                    [Logging helper]
│   └── types/
│       ├── exceptions.dart                [Custom exception classes]
│       └── enums.dart                     [Enums: TransactionType, Status, etc.]
├── android/
│   ├── app/
│   │   └── src/main/kotlin/
│   │       └── com/pawcket/
│   │           ├── MainActivity.kt        [Flutter activity]
│   │           └── WidgetProvider.kt      [Android home screen widget provider]
│   └── AndroidManifest.xml                [Permissions: RECORD_AUDIO, etc.]
├── ios/
│   └── [Standard iOS structure, placeholder for later]
├── pubspec.yaml                           [Dependencies & asset configuration]
├── pubspec.lock                           [Locked dependency versions]
├── test/
│   ├── unit/
│   │   ├── services/
│   │   │   ├── nlp_parser_test.dart
│   │   │   └── currency_formatter_test.dart
│   │   └── utils/
│   │       └── validators_test.dart
│   ├── integration/
│   │   ├── transaction_flow_test.dart
│   │   └── chat_flow_test.dart
│   └── widget/
│       ├── dashboard_widget_test.dart
│       └── chat_bubble_test.dart
├── docs/
│   ├── 00_master_plan.md
│   ├── 01_technical_specs.md
│   ├── 01a_database_schema.sql
│   ├── 02_design_guide.md
│   ├── 03_features/
│   └── 04_dev_log.md
└── README.md
```

## Naming Conventions
| Item | Convention | Example |
|------|-----------|---------|
| **Dart Classes** | PascalCase, noun-based | `TransactionModel`, `NLPParser`, `ChatProvider` |
| **Dart Functions** | camelCase, verb-based | `parseNLPInput()`, `fetchTransactions()`, `generateAdvisory()` |
| **Dart Variables** | camelCase, descriptive | `transactionsList`, `isLoading`, `userCategories` |
| **Dart Constants** | UPPER_SNAKE_CASE | `MAX_TRANSACTION_AMOUNT`, `API_TIMEOUT_MS`, `DEFAULT_CURRENCY` |
| **Database Tables** | snake_case, plural | `transactions`, `categories`, `chat_sessions`, `user_budgets` |
| **Database Columns** | snake_case, descriptive | `transaction_id`, `category_name`, `created_at`, `amount_idr` |
| **Filenames** | snake_case.dart | `transaction_model.dart`, `nlp_parser.dart`, `main_screen.dart` |
| **Packages / Imports** | lowercase.with.dots | `com.pawcket.widget`, `pawcket.services.database` |
| **Environment Variables** | UPPER_SNAKE_CASE, prefixed | `OPENROUTER_API_KEY`, `FLUTTER_ENV`, `ENABLE_CLOUD_SYNC` |

## Environment Variables
```env
# API & LLM Configuration
OPENROUTER_API_KEY=sk_xxx...              # OpenRouter API key for LLM calls
OPENROUTER_MODEL=meta-llama/llama-2-70b   # Selected LLM model (changeable per session)

# Database & Storage
DATABASE_NAME=pawcket_local.db             # SQLite database filename
ENABLE_CLOUD_SYNC=false                    # Feature flag: enable cloud backup (default: off)
FIREBASE_PROJECT_ID=pawcket-prod           # Optional Firebase project (if cloud sync enabled)
SUPABASE_URL=https://xxx.supabase.co       # Optional Supabase URL (if using Supabase instead)

# Feature Flags
ENABLE_VOICE_INPUT=true                    # Enable/disable voice input feature
ENABLE_ADVANCED_ANALYTICS=false             # Enable advanced insights (v2 feature)
ENABLE_RECURRING_TRANSACTIONS=false         # Recurring transactions feature (v2)

# Logging & Debugging
LOG_LEVEL=info                             # Levels: debug, info, warn, error
ENABLE_CRASH_REPORTING=false               # Local crash logs only (no external telemetry)
```

## API Response Format (OpenRouter)
All API calls to OpenRouter for NLP parsing and chat responses follow this format:

```javascript
// Request to OpenRouter
{
  "model": "meta-llama/llama-2-70b",
  "messages": [
    {
      "role": "user",
      "content": "Parse this expense: 'Makan Gado-gado 15k'"
    }
  ],
  "temperature": 0.7,
  "max_tokens": 256
}

// Response (successful)
{
  "choices": [
    {
      "message": {
        "role": "assistant",
        "content": "{\"category\": \"food\", \"amount\": 15000, \"vendor\": \"gado-gado stand\", \"date\": \"2025-01-15\", \"description\": \"Makan Gado-gado 15k\"}"
      }
    }
  ],
  "usage": { "prompt_tokens": 20, "completion_tokens": 50 }
}

// Response (error)
{
  "error": {
    "message": "Rate limit exceeded",
    "type": "rate_limit_error"
  }
}
```

## Error Handling
All errors follow a consistent structure. Custom exceptions are defined in `types/exceptions.dart`:

```dart
class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;
  AppException({required this.message, this.code, this.originalError});
}

class NLPParsingException extends AppException {
  NLPParsingException({required String message, dynamic originalError})
    : super(message: message, code: "NLP_PARSE_ERROR", originalError: originalError);
}

class DatabaseException extends AppException {
  DatabaseException({required String message, dynamic originalError})
    : super(message: message, code: "DB_ERROR", originalError: originalError);
}

class APIException extends AppException {
  APIException({required String message, dynamic originalError})
    : super(message: message, code: "API_ERROR", originalError: originalError);
}
```

All error responses in the UI show a user-friendly message:
- **NLP errors:** "I couldn't understand that. Try again?" (Mr. Oyen appears confused)
- **API errors:** "Network trouble. Please retry." (offline fallback to local input)
- **Database errors:** "Oops, something broke. Report this?" (local recovery + optional crash log)

## Database Constraints
- All monetary amounts stored as integers (IDR, no decimals): `amount_idr INT`
- All timestamps in UTC milliseconds: `created_at BIGINT`
- Categories are enum-like (predefined + user-custom): `category_type VARCHAR(50)`
- Soft deletes via `deleted_at` column (never hard-delete transactions)
- Foreign key cascade: deleting a category does NOT delete transactions (data preservation)

## Testing Strategy
- **Unit tests:** Service logic (NLP parser, formatters, validators) — 80%+ coverage
- **Widget tests:** UI components (buttons, forms, cards) — 60%+ coverage
- **Integration tests:** Full user flows (input → parse → save → display) — 3-5 critical paths
- **Manual testing:** Voice input, widget responsiveness, offline behavior

Run tests locally:
```bash
flutter test
flutter test --coverage
```

## Security & Privacy
- **No telemetry:** App does NOT collect or send analytics data to external servers
- **No cloud upload by default:** All data stays on-device unless user explicitly enables cloud sync
- **Encryption for backups:** If cloud sync is enabled, data is encrypted in transit (HTTPS) and at rest (Firebase rules)
- **Local authentication:** Biometric or PIN required to unlock app (optional per user)
- **No third-party tracking:** No Google Analytics, Mixpanel, Sentry, or similar
- **API key security:** OpenRouter API key stored in secure storage (Android Keystore, iOS Keychain) — never in code

## Performance Targets
- **App cold start:** < 2 seconds (including database initialization)
- **Widget load time:** < 500ms (for home screen widget)
- **LLM response time:** < 3 seconds (user waits for AI response)
- **Dashboard render:** < 1 second (analytics page load)
- **Database query time:** < 100ms (typical transaction lookup)
- **Memory usage:** < 150 MB at runtime (Flutter app baseline)

## Code Style & Quality
- **Language:** Dart 3.3+
- **Linting:** Use `analysis_options.yaml` with strict lint rules
  - Run: `flutter analyze`
  - Auto-format: `dart format lib/`
- **Type safety:** No dynamic typing; always use explicit types
- **Null safety:** Full null safety enabled (no `!` unless absolutely justified)
- **Comments:** Explain "why", not "what"; use doc comments (`///`) for public APIs

Example:
```dart
/// Parses natural language expense input into structured transaction data.
/// 
/// Takes a raw user input like "Makan gado-gado 15k" and returns a validated
/// Transaction object. If parsing fails, throws [NLPParsingException].
Future<Transaction> parseExpenseFromText(String rawInput) async {
  // Implementation
}
```

## Deployment & Versioning
- **Version scheme:** semver (major.minor.patch) — e.g., 1.0.0, 1.2.3
- **Build numbers:** Increment on every release; sync with Git commits
- **Release channels:** Alpha → Beta → Production (Google Play Store)
- **Database migrations:** Version in schema; auto-apply on app update
- **Backward compatibility:** Always support reading data from previous 2 versions

