-- Pawcket Database Schema
-- SQLite 3.46+
-- All monetary amounts in IDR (Indonesian Rupiah) as integers (no decimals)
-- All timestamps in UTC milliseconds
-- Soft deletes via deleted_at column

-- ============================================================================
-- USERS & AUTHENTICATION
-- ============================================================================

CREATE TABLE IF NOT EXISTS users (
  user_id INTEGER PRIMARY KEY AUTOINCREMENT,
  -- User identification (local auth; no sign-up required)
  device_id TEXT UNIQUE NOT NULL,
  -- Unique device identifier for cloud sync (optional)
  
  -- Onboarding state
  has_completed_onboarding INTEGER NOT NULL DEFAULT 0,
  -- 0 = incomplete, 1 = completed (skip if reappear)
  
  -- Metadata
  created_at BIGINT NOT NULL,           -- Timestamp (ms) when user first opened app
  updated_at BIGINT NOT NULL,           -- Timestamp (ms) of last update
  deleted_at BIGINT,                    -- Soft delete; null if active
  
  CONSTRAINT users_valid_timestamps CHECK (created_at > 0 AND updated_at >= created_at)
);

-- ============================================================================
-- CATEGORIES (Predefined + User-Custom)
-- ============================================================================

CREATE TABLE IF NOT EXISTS categories (
  category_id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id INTEGER NOT NULL,
  
  -- Category metadata
  category_name TEXT NOT NULL,          -- e.g., "Food", "Transport", "Custom Hobby"
  category_type VARCHAR(50) NOT NULL,   -- e.g., "food", "transport", "entertainment"
  
  -- Appearance & UI
  icon_name TEXT,                       -- Flutter icon name for UI (e.g., "fastfood", "directions_car")
  color_hex TEXT,                       -- Color for pie chart: #FF5733
  
  -- Category origin
  is_default INTEGER NOT NULL DEFAULT 0, -- 1 = predefined by app, 0 = user-created
  
  -- Soft metadata
  created_at BIGINT NOT NULL,
  updated_at BIGINT NOT NULL,
  deleted_at BIGINT,
  
  FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
  UNIQUE (user_id, category_name),     -- Prevent duplicate category names per user
  CONSTRAINT categories_valid_timestamps CHECK (created_at > 0 AND updated_at >= created_at)
);

CREATE INDEX idx_categories_user_id ON categories(user_id);
-- Index serves: fetching all categories for dashboard + pie chart categorization

-- ============================================================================
-- TRANSACTIONS (Core Expense/Income Records)
-- ============================================================================

CREATE TABLE IF NOT EXISTS transactions (
  transaction_id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id INTEGER NOT NULL,
  
  -- Transaction details
  category_id INTEGER NOT NULL,        -- Foreign key to categories table
  transaction_type VARCHAR(20) NOT NULL DEFAULT 'expense', -- 'expense' or 'income'
  amount_idr INTEGER NOT NULL,         -- Amount in IDR (positive value only)
  
  -- Transaction metadata
  description TEXT,                    -- User's raw input or notes (e.g., "Makan di Gado-gado 15k")
  vendor_name TEXT,                    -- Vendor/merchant name (parsed from NLP or manual entry)
  payment_method VARCHAR(50),          -- 'cash', 'debit_card', 'e_wallet', etc. (future feature)
  
  -- Timestamps
  transaction_date BIGINT NOT NULL,    -- When the transaction occurred (ms)
  created_at BIGINT NOT NULL,          -- When the transaction was recorded in app
  updated_at BIGINT NOT NULL,
  deleted_at BIGINT,                   -- Soft delete marker
  
  -- Metadata
  is_synced_to_cloud INTEGER NOT NULL DEFAULT 0, -- 1 = backed up to cloud, 0 = local only
  nlp_confidence REAL DEFAULT 1.0,     -- 0.0-1.0: how confident was NLP parsing (1.0 = manual/corrected)
  
  FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
  FOREIGN KEY (category_id) REFERENCES categories(category_id) ON DELETE RESTRICT,
  -- ON DELETE RESTRICT: never allow deleting a category with transactions
  
  CONSTRAINT transactions_valid_amount CHECK (amount_idr > 0),
  CONSTRAINT transactions_valid_timestamps CHECK (transaction_date > 0 AND created_at > 0 AND updated_at >= created_at),
  CONSTRAINT transactions_valid_type CHECK (transaction_type IN ('expense', 'income')),
  CONSTRAINT transactions_valid_method CHECK (payment_method IS NULL OR payment_method IN ('cash', 'debit_card', 'e_wallet', 'bank_transfer'))
);

CREATE INDEX idx_transactions_user_date ON transactions(user_id, transaction_date DESC);
-- Index serves: fetching recent transactions for dashboard, monthly summary

CREATE INDEX idx_transactions_user_category ON transactions(user_id, category_id);
-- Index serves: pie chart by category aggregation

-- ============================================================================
-- BUDGETS (Optional; Deferred to v2)
-- ============================================================================

CREATE TABLE IF NOT EXISTS budgets (
  budget_id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id INTEGER NOT NULL,
  category_id INTEGER,                 -- Nullable: null = overall budget, else = category-specific
  
  -- Budget details
  limit_amount_idr INTEGER NOT NULL,   -- Monthly limit
  period_type VARCHAR(20) NOT NULL DEFAULT 'monthly', -- 'monthly', 'weekly', 'annual' (v2)
  
  -- State
  is_active INTEGER NOT NULL DEFAULT 1,
  alert_threshold REAL DEFAULT 0.8,    -- Alert at 80% of budget (v2 feature)
  
  -- Metadata
  created_at BIGINT NOT NULL,
  updated_at BIGINT NOT NULL,
  deleted_at BIGINT,
  
  FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
  FOREIGN KEY (category_id) REFERENCES categories(category_id) ON DELETE SET NULL,
  
  CONSTRAINT budgets_valid_amount CHECK (limit_amount_idr > 0),
  CONSTRAINT budgets_valid_threshold CHECK (alert_threshold >= 0.0 AND alert_threshold <= 1.0)
);

-- ============================================================================
-- AI CHAT SESSIONS & MESSAGES
-- ============================================================================

CREATE TABLE IF NOT EXISTS chat_sessions (
  session_id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id INTEGER NOT NULL,
  
  -- Session metadata
  session_title TEXT,                  -- Optional title (e.g., "Budget Discussion - Jan 2025")
  created_at BIGINT NOT NULL,
  updated_at BIGINT NOT NULL,
  deleted_at BIGINT,
  
  -- Mr. Oyen's mood state (based on spending)
  last_mood VARCHAR(50),               -- 'happy', 'neutral', 'concerned', 'angry' (for UI)
  
  FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
);

CREATE INDEX idx_chat_sessions_user_date ON chat_sessions(user_id, created_at DESC);
-- Index serves: fetching recent chat sessions, loading session history

CREATE TABLE IF NOT EXISTS chat_messages (
  message_id INTEGER PRIMARY KEY AUTOINCREMENT,
  session_id INTEGER NOT NULL,
  
  -- Message content
  sender_role VARCHAR(20) NOT NULL,    -- 'user' or 'assistant' (Mr. Oyen)
  content TEXT NOT NULL,               -- Message body
  
  -- Optional: Link to transaction (if message triggered transaction creation)
  transaction_id INTEGER,
  
  -- Metadata
  created_at BIGINT NOT NULL,
  
  FOREIGN KEY (session_id) REFERENCES chat_sessions(session_id) ON DELETE CASCADE,
  FOREIGN KEY (transaction_id) REFERENCES transactions(transaction_id) ON DELETE SET NULL,
  
  CONSTRAINT chat_messages_valid_role CHECK (sender_role IN ('user', 'assistant'))
);

CREATE INDEX idx_chat_messages_session ON chat_messages(session_id, created_at ASC);
-- Index serves: fetching messages for a chat session in chronological order

-- ============================================================================
-- USER PREFERENCES & SETTINGS
-- ============================================================================

CREATE TABLE IF NOT EXISTS user_preferences (
  preference_id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id INTEGER UNIQUE NOT NULL,
  
  -- Financial preferences
  currency_code VARCHAR(3) DEFAULT 'IDR', -- Indonesia rupiah only for v1
  
  -- Feature preferences
  enable_voice_input INTEGER NOT NULL DEFAULT 1,
  enable_cloud_sync INTEGER NOT NULL DEFAULT 0, -- Explicit opt-in for cloud backup
  enable_notifications INTEGER NOT NULL DEFAULT 1, -- Budget alerts (v2)
  
  -- UI preferences
  theme_mode VARCHAR(10) DEFAULT 'light', -- 'light', 'dark', 'auto'
  show_tutorial INTEGER NOT NULL DEFAULT 1,
  
  -- Privacy & security
  require_pin_unlock INTEGER NOT NULL DEFAULT 0, -- Local PIN authentication
  require_biometric INTEGER NOT NULL DEFAULT 0, -- Biometric unlock
  
  -- Metadata
  created_at BIGINT NOT NULL,
  updated_at BIGINT NOT NULL,
  
  FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
);

-- ============================================================================
-- CLOUD SYNC STATE (for optional cloud backup)
-- ============================================================================

CREATE TABLE IF NOT EXISTS sync_state (
  sync_id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id INTEGER UNIQUE NOT NULL,
  
  -- Last sync timestamps
  last_sync_time BIGINT,               -- Timestamp of last successful sync
  last_sync_direction VARCHAR(20),     -- 'push' (local→cloud) or 'pull' (cloud→local)
  
  -- Pending changes
  has_unsync_changes INTEGER NOT NULL DEFAULT 1, -- 1 = unsynced local changes exist
  
  -- Sync metadata
  cloud_user_id TEXT,                  -- Opaque cloud user ID (Firebase UID, Supabase, etc.)
  
  created_at BIGINT NOT NULL,
  updated_at BIGINT NOT NULL,
  
  FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
);

-- ============================================================================
-- VIEWS (for common queries)
-- ============================================================================

-- Current month's expense summary by category
CREATE VIEW IF NOT EXISTS monthly_expense_summary AS
SELECT 
  c.category_id,
  c.category_name,
  c.color_hex,
  SUM(t.amount_idr) as total_amount,
  COUNT(t.transaction_id) as transaction_count
FROM transactions t
JOIN categories c ON t.category_id = c.category_id
WHERE t.transaction_type = 'expense'
  AND t.deleted_at IS NULL
  AND strftime('%Y-%m', datetime(t.transaction_date / 1000, 'unixepoch')) = strftime('%Y-%m', 'now')
GROUP BY c.category_id, c.category_name, c.color_hex
ORDER BY total_amount DESC;

-- Total income and expense for dashboard
CREATE VIEW IF NOT EXISTS monthly_cashflow AS
SELECT 
  COALESCE(SUM(CASE WHEN transaction_type = 'income' THEN amount_idr ELSE 0 END), 0) as total_income,
  COALESCE(SUM(CASE WHEN transaction_type = 'expense' THEN amount_idr ELSE 0 END), 0) as total_expense
FROM transactions
WHERE deleted_at IS NULL
  AND strftime('%Y-%m', datetime(transaction_date / 1000, 'unixepoch')) = strftime('%Y-%m', 'now');

