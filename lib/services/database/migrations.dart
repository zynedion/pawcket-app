import 'package:sqflite/sqflite.dart';

class DatabaseMigrations {
  // Map of version -> migration script to execute
  static final Map<int, Future<void> Function(Database db)> migrations = {
    // Migration from v1 to v2 will be added here
  };

  static Future<void> migrate(Database db, int oldVersion, int newVersion) async {
    for (var i = oldVersion + 1; i <= newVersion; i++) {
      if (migrations.containsKey(i)) {
        await migrations[i]!(db);
      }
    }
  }
}
