import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../../models/category.dart';
import '../../models/user.dart';
import '../../models/transaction.dart';
import '../../utils/constants.dart';

class LocalDb {
  static final LocalDb instance = LocalDb._init();
  static Database? _database;

  LocalDb._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB(AppConstants.databaseName);
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: AppConstants.databaseVersion,
      onCreate: _createDB,
      onConfigure: _onConfigure,
    );
  }

  Future _onConfigure(Database db) async {
    // Enable foreign key support in SQLite
    await db.execute('PRAGMA foreign_keys = ON');
  }

  Future _createDB(Database db, int version) async {
    // 1. Users table
    await db.execute('''
      CREATE TABLE users (
        user_id INTEGER PRIMARY KEY AUTOINCREMENT,
        device_id TEXT UNIQUE NOT NULL,
        has_completed_onboarding INTEGER NOT NULL DEFAULT 0,
        created_at BIGINT NOT NULL,
        updated_at BIGINT NOT NULL,
        deleted_at BIGINT,
        CONSTRAINT users_valid_timestamps CHECK (created_at > 0 AND updated_at >= created_at)
      )
    ''');

    // 2. Categories table
    await db.execute('''
      CREATE TABLE categories (
        category_id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        category_name TEXT NOT NULL,
        category_type VARCHAR(50) NOT NULL,
        icon_name TEXT,
        color_hex TEXT,
        is_default INTEGER NOT NULL DEFAULT 0,
        created_at BIGINT NOT NULL,
        updated_at BIGINT NOT NULL,
        deleted_at BIGINT,
        FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
        UNIQUE (user_id, category_name),
        CONSTRAINT categories_valid_timestamps CHECK (created_at > 0 AND updated_at >= created_at)
      )
    ''');
    await db.execute('CREATE INDEX idx_categories_user_id ON categories(user_id)');

    // 3. Transactions table
    await db.execute('''
      CREATE TABLE transactions (
        transaction_id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        category_id INTEGER NOT NULL,
        transaction_type VARCHAR(20) NOT NULL DEFAULT 'expense',
        amount_idr INTEGER NOT NULL,
        description TEXT,
        vendor_name TEXT,
        payment_method VARCHAR(50),
        transaction_date BIGINT NOT NULL,
        created_at BIGINT NOT NULL,
        updated_at BIGINT NOT NULL,
        deleted_at BIGINT,
        is_synced_to_cloud INTEGER NOT NULL DEFAULT 0,
        nlp_confidence REAL DEFAULT 1.0,
        FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
        FOREIGN KEY (category_id) REFERENCES categories(category_id) ON DELETE RESTRICT,
        CONSTRAINT transactions_valid_amount CHECK (amount_idr > 0),
        CONSTRAINT transactions_valid_timestamps CHECK (transaction_date > 0 AND created_at > 0 AND updated_at >= created_at),
        CONSTRAINT transactions_valid_type CHECK (transaction_type IN ('expense', 'income')),
        CONSTRAINT transactions_valid_method CHECK (payment_method IS NULL OR payment_method IN ('cash', 'debit_card', 'e_wallet', 'bank_transfer'))
      )
    ''');
    await db.execute('CREATE INDEX idx_transactions_user_date ON transactions(user_id, transaction_date DESC)');
    await db.execute('CREATE INDEX idx_transactions_user_category ON transactions(user_id, category_id)');

    // 4. Budgets table
    await db.execute('''
      CREATE TABLE budgets (
        budget_id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        category_id INTEGER,
        limit_amount_idr INTEGER NOT NULL,
        period_type VARCHAR(20) NOT NULL DEFAULT 'monthly',
        is_active INTEGER NOT NULL DEFAULT 1,
        alert_threshold REAL DEFAULT 0.8,
        created_at BIGINT NOT NULL,
        updated_at BIGINT NOT NULL,
        deleted_at BIGINT,
        FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
        FOREIGN KEY (category_id) REFERENCES categories(category_id) ON DELETE SET NULL,
        CONSTRAINT budgets_valid_amount CHECK (limit_amount_idr > 0),
        CONSTRAINT budgets_valid_threshold CHECK (alert_threshold >= 0.0 AND alert_threshold <= 1.0)
      )
    ''');

    // 5. Chat sessions table
    await db.execute('''
      CREATE TABLE chat_sessions (
        session_id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        session_title TEXT,
        created_at BIGINT NOT NULL,
        updated_at BIGINT NOT NULL,
        deleted_at BIGINT,
        last_mood VARCHAR(50),
        FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
      )
    ''');
    await db.execute('CREATE INDEX idx_chat_sessions_user_date ON chat_sessions(user_id, created_at DESC)');

    // 6. Chat messages table
    await db.execute('''
      CREATE TABLE chat_messages (
        message_id INTEGER PRIMARY KEY AUTOINCREMENT,
        session_id INTEGER NOT NULL,
        sender_role VARCHAR(20) NOT NULL,
        content TEXT NOT NULL,
        transaction_id INTEGER,
        created_at BIGINT NOT NULL,
        FOREIGN KEY (session_id) REFERENCES chat_sessions(session_id) ON DELETE CASCADE,
        FOREIGN KEY (transaction_id) REFERENCES transactions(transaction_id) ON DELETE SET NULL,
        CONSTRAINT chat_messages_valid_role CHECK (sender_role IN ('user', 'assistant'))
      )
    ''');
    await db.execute('CREATE INDEX idx_chat_messages_session ON chat_messages(session_id, created_at ASC)');

    // 7. User preferences table
    await db.execute('''
      CREATE TABLE user_preferences (
        preference_id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER UNIQUE NOT NULL,
        currency_code VARCHAR(3) DEFAULT 'IDR',
        enable_voice_input INTEGER NOT NULL DEFAULT 1,
        enable_cloud_sync INTEGER NOT NULL DEFAULT 0,
        enable_notifications INTEGER NOT NULL DEFAULT 1,
        theme_mode VARCHAR(10) DEFAULT 'light',
        show_tutorial INTEGER NOT NULL DEFAULT 1,
        require_pin_unlock INTEGER NOT NULL DEFAULT 0,
        require_biometric INTEGER NOT NULL DEFAULT 0,
        created_at BIGINT NOT NULL,
        updated_at BIGINT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
      )
    ''');

    // 8. Sync state table
    await db.execute('''
      CREATE TABLE sync_state (
        sync_id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER UNIQUE NOT NULL,
        last_sync_time BIGINT,
        last_sync_direction VARCHAR(20),
        has_unsync_changes INTEGER NOT NULL DEFAULT 1,
        cloud_user_id TEXT,
        created_at BIGINT NOT NULL,
        updated_at BIGINT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
      )
    ''');

    // 9. Views
    await db.execute('''
      CREATE VIEW monthly_expense_summary AS
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
      ORDER BY total_amount DESC
    ''');

    await db.execute('''
      CREATE VIEW monthly_cashflow AS
      SELECT 
        COALESCE(SUM(CASE WHEN transaction_type = 'income' THEN amount_idr ELSE 0 END), 0) as total_income,
        COALESCE(SUM(CASE WHEN transaction_type = 'expense' THEN amount_idr ELSE 0 END), 0) as total_expense
      FROM transactions
      WHERE deleted_at IS NULL
        AND strftime('%Y-%m', datetime(transaction_date / 1000, 'unixepoch')) = strftime('%Y-%m', 'now')
    ''');
  }

  // Database Access Helper Methods for Onboarding

  /// Fetches the local user if they exist in the DB.
  Future<UserModel?> getUser() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'users',
      where: 'deleted_at IS NULL',
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return UserModel.fromMap(maps.first);
  }

  /// Creates a local user in the users table and seeds user_preferences.
  Future<UserModel> createUser(String deviceId) async {
    final db = await database;
    final now = DateTime.now().millisecondsSinceEpoch;

    // 1. Insert User
    final userId = await db.insert('users', {
      'device_id': deviceId,
      'has_completed_onboarding': 0,
      'created_at': now,
      'updated_at': now,
    });

    // 2. Insert User Preferences
    await db.insert('user_preferences', {
      'user_id': userId,
      'currency_code': 'IDR',
      'enable_voice_input': 1,
      'enable_cloud_sync': 0,
      'enable_notifications': 1,
      'theme_mode': 'light',
      'show_tutorial': 1,
      'require_pin_unlock': 0,
      'require_biometric': 0,
      'created_at': now,
      'updated_at': now,
    });

    return UserModel(
      userId: userId,
      deviceId: deviceId,
      hasCompletedOnboarding: false,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Sets has_completed_onboarding flag to 1 for the user.
  Future<void> updateOnboardingCompleted(int userId) async {
    final db = await database;
    final now = DateTime.now().millisecondsSinceEpoch;
    await db.update(
      'users',
      {
        'has_completed_onboarding': 1,
        'updated_at': now,
      },
      where: 'user_id = ?',
      whereArgs: [userId],
    );
  }

  /// Bulk inserts chosen categories for a user.
  Future<void> saveCategories(int userId, List<CategoryModel> categories) async {
    final db = await database;
    final batch = db.batch();
    for (var cat in categories) {
      batch.insert('categories', {
        'user_id': userId,
        'category_name': cat.categoryName,
        'category_type': cat.categoryType,
        'icon_name': cat.iconName,
        'color_hex': cat.colorHex,
        'is_default': cat.isDefault ? 1 : 0,
        'created_at': cat.createdAt,
        'updated_at': cat.updatedAt,
      });
    }
    await batch.commit(noResult: true);
  }

  /// Fetches saved categories for a user.
  Future<List<CategoryModel>> getCategories(int userId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'categories',
      where: 'user_id = ? AND deleted_at IS NULL',
      whereArgs: [userId],
    );
    return List.generate(maps.length, (i) => CategoryModel.fromMap(maps[i]));
  }

  /// Verifies if category exists, returning category ID. If not found, defaults to 'other' category ID.
  Future<int?> verifyCategoryExists(int userId, String categoryName) async {
    final db = await database;
    
    // Check case-insensitive match for type or name
    final List<Map<String, dynamic>> results = await db.query(
      'categories',
      columns: ['category_id'],
      where: 'user_id = ? AND (LOWER(category_name) = ? OR LOWER(category_type) = ?) AND deleted_at IS NULL',
      whereArgs: [userId, categoryName.toLowerCase(), categoryName.toLowerCase()],
      limit: 1,
    );

    if (results.isNotEmpty) {
      return results.first['category_id'] as int;
    }

    // Fallback: look for "other" category for this user
    final List<Map<String, dynamic>> fallbackResults = await db.query(
      'categories',
      columns: ['category_id'],
      where: 'user_id = ? AND category_type = ? AND deleted_at IS NULL',
      whereArgs: [userId, 'other'],
      limit: 1,
    );

    if (fallbackResults.isNotEmpty) {
      return fallbackResults.first['category_id'] as int;
    }

    return null;
  }

  /// Inserts a transaction into the DB.
  Future<int> insertTransaction(TransactionModel transaction) async {
    final db = await database;
    return await db.insert('transactions', transaction.toMap());
  }

  /// Fetches total monthly expense for a user.
  Future<int> getMonthlyExpense(int userId) async {
    final db = await database;
    final List<Map<String, dynamic>> results = await db.rawQuery('''
      SELECT SUM(amount_idr) as total 
      FROM transactions 
      WHERE user_id = ? 
        AND transaction_type = 'expense' 
        AND deleted_at IS NULL
        AND strftime('%Y-%m', datetime(transaction_date / 1000, 'unixepoch')) = strftime('%Y-%m', 'now')
    ''', [userId]);
    
    if (results.isEmpty || results.first['total'] == null) return 0;
    return results.first['total'] as int;
  }

  /// Fetches recent transactions for a user.
  Future<List<Map<String, dynamic>>> getRecentTransactions(int userId, {int limit = 5}) async {
    final db = await database;
    return await db.rawQuery('''
      SELECT t.*, c.category_name 
      FROM transactions t
      JOIN categories c ON t.category_id = c.category_id
      WHERE t.user_id = ? AND t.deleted_at IS NULL
      ORDER BY t.transaction_date DESC
      LIMIT ?
    ''', [userId, limit]);
  }

  /// Fetches active budgets for a user.
  Future<List<Map<String, dynamic>>> getActiveBudgets(int userId) async {
    final db = await database;
    return await db.rawQuery('''
      SELECT b.*, c.category_name 
      FROM budgets b
      LEFT JOIN categories c ON b.category_id = c.category_id
      WHERE b.user_id = ? AND b.is_active = 1
    ''', [userId]);
  }

  /// Fetches a transaction by ID joined with its category info.
  Future<Map<String, dynamic>?> getTransactionWithCategory(int transactionId) async {
    final db = await database;
    final List<Map<String, dynamic>> results = await db.rawQuery('''
      SELECT t.*, c.category_name, c.color_hex, c.icon_name
      FROM transactions t
      JOIN categories c ON t.category_id = c.category_id
      WHERE t.transaction_id = ? AND t.deleted_at IS NULL
    ''', [transactionId]);
    if (results.isEmpty) return null;
    return results.first;
  }

  /// Fetches monthly summary (income vs expense) for a user for a specific month (format: 'YYYY-MM').
  Future<Map<String, int>> getMonthlySummary(int userId, String monthStr) async {
    final db = await database;
    final List<Map<String, dynamic>> results = await db.rawQuery('''
      SELECT 
        COALESCE(SUM(CASE WHEN transaction_type = 'income' THEN amount_idr ELSE 0 END), 0) as total_income,
        COALESCE(SUM(CASE WHEN transaction_type = 'expense' THEN amount_idr ELSE 0 END), 0) as total_expense
      FROM transactions
      WHERE user_id = ? 
        AND deleted_at IS NULL
        AND strftime('%Y-%m', datetime(transaction_date / 1000, 'unixepoch')) = ?
    ''', [userId, monthStr]);

    if (results.isEmpty) return {'income': 0, 'expense': 0};
    final row = results.first;
    return {
      'income': row['total_income'] as int? ?? 0,
      'expense': row['total_expense'] as int? ?? 0,
    };
  }

  /// Fetches category spending breakdown for a user for a specific month (format: 'YYYY-MM').
  Future<List<Map<String, dynamic>>> getCategoryBreakdown(int userId, String monthStr) async {
    final db = await database;
    return await db.rawQuery('''
      SELECT 
        c.category_id,
        c.category_name,
        c.color_hex,
        c.icon_name,
        SUM(t.amount_idr) as total_amount,
        ROUND(100.0 * SUM(t.amount_idr) / (
          SELECT COALESCE(SUM(amount_idr), 1) 
          FROM transactions 
          WHERE user_id = ? AND transaction_type = 'expense' AND deleted_at IS NULL 
            AND strftime('%Y-%m', datetime(transaction_date / 1000, 'unixepoch')) = ?
        ), 1) as percentage
      FROM transactions t
      JOIN categories c ON t.category_id = c.category_id
      WHERE t.user_id = ? 
        AND t.transaction_type = 'expense'
        AND t.deleted_at IS NULL
        AND strftime('%Y-%m', datetime(t.transaction_date / 1000, 'unixepoch')) = ?
      GROUP BY c.category_id, c.category_name, c.color_hex, c.icon_name
      ORDER BY total_amount DESC
    ''', [userId, monthStr, userId, monthStr]);
  }

  /// Fetches transactions for a user for a specific month (format: 'YYYY-MM') with pagination limits.
  Future<List<Map<String, dynamic>>> getTransactionsForMonth(
    int userId, 
    String monthStr, {
    int limit = 10, 
    int offset = 0,
  }) async {
    final db = await database;
    return await db.rawQuery('''
      SELECT 
        t.transaction_id,
        t.category_id,
        c.category_name,
        c.color_hex,
        c.icon_name,
        t.description,
        t.amount_idr,
        t.transaction_date,
        t.is_synced_to_cloud
      FROM transactions t
      JOIN categories c ON t.category_id = c.category_id
      WHERE t.user_id = ? 
        AND t.deleted_at IS NULL
        AND strftime('%Y-%m', datetime(t.transaction_date / 1000, 'unixepoch')) = ?
      ORDER BY t.transaction_date DESC
      LIMIT ? OFFSET ?
    ''', [userId, monthStr, limit, offset]);
  }
}
