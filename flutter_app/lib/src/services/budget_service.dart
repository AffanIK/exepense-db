import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/budget.dart';

class BudgetService {
  BudgetService._();
  static final BudgetService instance = BudgetService._();

  static const _key = 'budgets.v1';

  SharedPreferences? _prefs;
  List<Budget> _cache = const [];

  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
    final raw = _prefs!.getString(_key);
    if (raw == null) {
      _cache = kDefaultBudgetLimitsPkr.entries
          .map((e) => Budget(catId: e.key, limit: e.value))
          .toList();
      await _save();
    } else {
      final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
      _cache = list.map(Budget.fromJson).toList();
    }
  }

  List<Budget> get all => List.unmodifiable(_cache);

  double limitFor(String catId) =>
      _cache.firstWhere((b) => b.catId == catId,
          orElse: () => Budget(catId: catId, limit: 0)).limit;

  Future<void> setLimit(String catId, double limit) async {
    final idx = _cache.indexWhere((b) => b.catId == catId);
    if (idx == -1) {
      _cache = [..._cache, Budget(catId: catId, limit: limit)];
    } else {
      _cache = [..._cache];
      _cache[idx] = _cache[idx].copyWith(limit: limit);
    }
    await _save();
  }

  Future<void> _save() async {
    await _prefs!
        .setString(_key, jsonEncode(_cache.map((b) => b.toJson()).toList()));
  }

  // ── One-shot migration flag helpers used by DbService.
  static const _migrationKey = 'legacy_cats_migrated.v1';
  bool get legacyMigrated => _prefs?.getBool(_migrationKey) ?? false;
  Future<void> markLegacyMigrated() async =>
      _prefs!.setBool(_migrationKey, true);
}
