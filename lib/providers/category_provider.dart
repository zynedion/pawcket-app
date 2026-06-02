import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/category.dart';
import '../services/database/local_db.dart';

final categoryProvider = FutureProvider<List<CategoryModel>>((ref) async {
  final db = LocalDb.instance;
  final user = await db.getUser();
  if (user == null) return [];
  return await db.getCategories(user.userId!);
});
