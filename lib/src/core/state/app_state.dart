import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/app_settings.dart';
import '../models/money_transaction.dart';
import '../models/outlet_model.dart';
import '../models/product_model.dart';
import '../models/summary.dart';
import '../models/user_category.dart';
import '../models/user_profile.dart';
import '../services/category_sync_service.dart';
import '../services/outlet_service.dart';
import '../services/profile_service.dart';
import '../services/transaction_sync_service.dart';
import '../storage/local_database.dart';

export '../models/summary.dart';
export 'app_state_scope.dart';

class AppState extends ChangeNotifier {
  AppState({LocalDatabase? database})
      : _database = database ?? LocalDatabase();

  final LocalDatabase _database;

  late final _syncService = TransactionSyncService(supabase);
  late final _outletService = OutletService(supabase);
  late final _profileService = ProfileService(supabase);
  late final _categoryService = CategorySyncService(supabase);

  bool _initialized = false;
  bool _isSyncing = false;
  Timer? _retryTimer;
  List<MoneyTransaction> _transactions = [];
  List<ProductModel> _products = [];
  List<OutletModel> _outlets = [];
  List<UserCategory> _categories = [];
  String? _selectedOutletId;
  UserProfile _profile = UserProfile.empty();
  AppSettings _settings = AppSettings.defaults();
  String? _lastSyncError;
  int _syncFailCount = 0;

  SupabaseClient get supabase => Supabase.instance.client;
  User? get currentUser => supabase.auth.currentUser;

  List<MoneyTransaction> get transactions => _filteredTransactions;
  List<MoneyTransaction> get allTransactions => _transactions;
  List<ProductModel> get products => _products;
  List<OutletModel> get outlets => _outlets;
  List<UserCategory> get categories => _categories;
  String? get selectedOutletId => _selectedOutletId;

  /// Semua kategori untuk tipe tertentu (default + custom), tanpa duplikat nama.
  List<UserCategory> categoriesFor(MoneyTransactionType type) {
    final defaults = UserCategory.defaultCategories
        .where((c) => c.type == type)
        .toList();
    final custom = _categories
        .where((c) => c.type == type)
        .toList();
    return [...defaults, ...custom];
  }
  OutletModel? get selectedOutlet =>
      _outlets.where((o) => o.id == _selectedOutletId).firstOrNull;
  UserProfile get profile => _profile;
  AppSettings get settings => _settings;
  bool get initialized => _initialized;
  bool get isSyncing => _isSyncing;
  String? get lastSyncError => _lastSyncError;
  bool get hasSyncError => _syncFailCount > 0 && !_isSyncing;
  int get pendingCount =>
      _transactions.where((t) => t.id.startsWith('tx_')).length;

  List<MoneyTransaction> get _filteredTransactions {
    if (_selectedOutletId == null) return _transactions;
    return _transactions
        .where((t) => t.outletId == _selectedOutletId)
        .toList();
  }

  // ─── Lifecycle ───────────────────────────────────────────────────────────────

  Future<void> init() async {
    if (_initialized) return;

    final raw = await _database.read();
    _transactions = _parseList(raw['transactions'], MoneyTransaction.fromJson);
    _products = _parseList(raw['products'], ProductModel.fromJson);
    _outlets = _parseList(raw['outlets'], OutletModel.fromJson);
    _categories = _parseList(raw['categories'], UserCategory.fromJson);

    final profileMap = raw['profile'];
    if (profileMap is Map<String, dynamic>) {
      _profile = UserProfile.fromJson(profileMap);
    }
    final settingsMap = raw['settings'];
    if (settingsMap is Map<String, dynamic>) {
      _settings = AppSettings.fromJson(settingsMap);
    }

    _transactions = _syncService.migrateOldIds(_transactions);

    _initialized = true;
    notifyListeners();

    if (currentUser != null) {
      unawaited(syncTransactions());
      unawaited(fetchProfile());
      unawaited(syncCategories());
    }
  }

  Future<void> onAppResumed() async {
    if (currentUser != null) await syncTransactions();
  }

  @override
  void dispose() {
    _retryTimer?.cancel();
    super.dispose();
  }

  // ─── Sync ────────────────────────────────────────────────────────────────────

  Future<void> syncTransactions() async {
    if (_isSyncing) return;
    final user = currentUser;
    if (user == null) return;

    _isSyncing = true;
    _lastSyncError = null;
    _retryTimer?.cancel();
    _retryTimer = null;
    notifyListeners();

    try {
      await _syncOutlets(user.id);

      await _syncService.pushPending(
        transactions: _transactions,
        userId: user.id,
        onSuccess: (local, confirmed) async {
          _transactions = _transactions
              .map((t) => t.id == local.id ? confirmed : t)
              .toList();
          _syncFailCount = 0;
          _lastSyncError = null;
          await _persist();
          notifyListeners();
        },
        onError: (error) {
          _syncFailCount++;
          _lastSyncError = error;
          notifyListeners();
        },
      );

      _transactions = await _syncService.pullAndMerge(
        local: _transactions,
        userId: user.id,
      );
      await _persist();
      notifyListeners();

      if (pendingCount == 0) {
        _syncFailCount = 0;
        _lastSyncError = null;
      }
    } catch (e) {
      _lastSyncError = e.toString();
      debugPrint('[Sync] syncTransactions failed: $e');
    } finally {
      _isSyncing = false;
      notifyListeners();
      _scheduleRetryIfNeeded();
    }
  }

  Future<void> _syncOutlets(String userId) async {
    final result = await _outletService.syncOutlets(
      outlets: _outlets,
      transactions: _transactions,
      userId: userId,
      selectedOutletId: _selectedOutletId,
    );
    _outlets = result.outlets;
    _transactions = result.transactions;
    _selectedOutletId = result.selectedOutletId;
    await _persist();
    notifyListeners();
  }

  void _scheduleRetryIfNeeded() {
    if (!_transactions.any((t) => t.id.startsWith('tx_'))) return;
    if (currentUser == null) return;
    debugPrint('[Sync] Masih ada pending, retry dalam 30 detik...');
    _retryTimer = Timer(const Duration(seconds: 30), syncTransactions);
  }

  // ─── Profile & Auth ──────────────────────────────────────────────────────────

  Future<void> fetchProfile() async {
    final user = currentUser;
    if (user == null) return;
    final fetched = await _profileService.fetchProfile(user.id);
    if (fetched != null) {
      _profile = fetched;
      await _persist();
      notifyListeners();
    }
  }

  Future<void> updateProfile(UserProfile updatedProfile) async {
    _profile = updatedProfile;
    await _persist();
    notifyListeners();

    final user = currentUser;
    if (user != null) {
      try {
        await _profileService.updateProfile(user.id, updatedProfile);
      } catch (e) {
        debugPrint('[API] Update profile failed: $e');
        rethrow;
      }
    }
  }

  Future<void> logout() async {
    try {
      await _profileService.signOut();
    } catch (e) {
      debugPrint('[Auth] signOut failed: $e');
      rethrow;
    }
    _profile = UserProfile.empty();
    await _persist();
    notifyListeners();
  }

  // ─── Outlet CRUD ─────────────────────────────────────────────────────────────

  void selectOutlet(String? outletId) {
    _selectedOutletId = outletId;
    notifyListeners();
  }

  Future<void> addOutlet({required String name, String? address}) async {
    final user = currentUser;
    final isFirst = _outlets.isEmpty;

    if (user != null) {
      try {
        final outlet = await _outletService.addOnServer(
          name: name,
          address: address,
          isDefault: isFirst,
          userId: user.id,
        );
        if (outlet != null) {
          _outlets = [..._outlets, outlet];
          await _persist();
          notifyListeners();
          return;
        }
      } catch (e) {
        debugPrint('[API] Add outlet failed: $e');
      }
    }

    // Offline fallback: simpan lokal, akan di-sync saat online
    _outlets = [
      ..._outlets,
      OutletModel(
        id: 'outlet_${DateTime.now().microsecondsSinceEpoch}',
        name: name,
        address: address,
        isDefault: isFirst,
      ),
    ];
    await _persist();
    notifyListeners();
  }

  Future<void> updateOutlet(OutletModel outlet) async {
    if (currentUser != null && !outlet.id.startsWith('outlet_')) {
      try {
        await _outletService.updateOnServer(outlet);
      } catch (e) {
        debugPrint('[API] Update outlet failed: $e');
      }
    }
    final index = _outlets.indexWhere((o) => o.id == outlet.id);
    if (index != -1) {
      _outlets[index] = outlet;
      await _persist();
      notifyListeners();
    }
  }

  Future<void> deleteOutlet(String outletId) async {
    if (currentUser != null && !outletId.startsWith('outlet_')) {
      try {
        await _outletService.deleteFromServer(outletId);
      } catch (e) {
        debugPrint('[API] Delete outlet failed: $e');
      }
    }
    _outlets = _outlets.where((o) => o.id != outletId).toList();
    if (_selectedOutletId == outletId) _selectedOutletId = null;
    await _persist();
    notifyListeners();
  }

  // ─── Category CRUD & Sync ────────────────────────────────────────────────────

  /// Merge local categories with Supabase. Local-only entries are uploaded first.
  Future<void> syncCategories() async {
    if (currentUser == null) return;
    try {
      final remote = await _categoryService.fetchAll();
      final remoteIds = remote.map((c) => c.id).toSet();
      // Upload any local-only categories that aren't on the server yet
      final localOnly = _categories.where((c) => !remoteIds.contains(c.id));
      for (final cat in localOnly) {
        await _categoryService.upsert(cat);
      }
      // Merge: server list + any local-only
      _categories = [...remote, ...localOnly];
      await _persist();
      notifyListeners();
    } catch (e) {
      debugPrint('[CategorySync] failed: $e');
    }
  }

  Future<void> addCategory(UserCategory category) async {
    _categories = [..._categories, category];
    await _persist();
    notifyListeners();
    // Best-effort server sync (non-blocking)
    _categoryService.upsert(category).ignore();
  }

  Future<void> deleteCategory(String id) async {
    _categories = _categories.where((c) => c.id != id).toList();
    await _persist();
    notifyListeners();
    // Best-effort server sync (non-blocking)
    _categoryService.delete(id).ignore();
  }

  // ─── Product CRUD ─────────────────────────────────────────────────────────────

  Future<void> addProduct(ProductModel product) async {
    _products = [product, ..._products];
    await _persist();
    notifyListeners();
  }

  Future<void> updateProduct(ProductModel product) async {
    final index = _products.indexWhere((p) => p.id == product.id);
    if (index != -1) {
      _products[index] = product;
      await _persist();
      notifyListeners();
    }
  }

  Future<void> deleteProduct(String id) async {
    _products = _products.where((p) => p.id != id).toList();
    await _persist();
    notifyListeners();
  }

  // ─── Transaction CRUD ────────────────────────────────────────────────────────

  Future<void> addIncome({
    required int amount,
    String? note,
    String? category,
    String? outletId,
    DateTime? effectiveDate,
  }) =>
      _addTransaction(
        type: MoneyTransactionType.income,
        amount: amount,
        note: note,
        category: category,
        outletId: outletId,
        effectiveDate: effectiveDate,
      );

  Future<void> addExpense({
    required int amount,
    String? note,
    String? category,
    String? outletId,
    DateTime? effectiveDate,
  }) =>
      _addTransaction(
        type: MoneyTransactionType.expense,
        amount: amount,
        note: note,
        category: category,
        outletId: outletId,
        effectiveDate: effectiveDate,
      );

  Future<void> _addTransaction({
    required MoneyTransactionType type,
    required int amount,
    String? note,
    String? category,
    String? outletId,
    DateTime? effectiveDate,
  }) async {
    final now = DateTime.now();
    final tx = MoneyTransaction(
      id: 'tx_${now.microsecondsSinceEpoch}',
      type: type,
      amount: amount,
      note: note,
      category: category,
      outletId: outletId,
      effectiveDate: effectiveDate != null ? _stripTime(effectiveDate) : _stripTime(now),
      createdAt: now,
    );
    _transactions = [tx, ..._transactions];
    await _persist();
    notifyListeners();
    unawaited(syncTransactions());
  }

  Future<void> deleteTransaction(String id) async {
    if (!id.startsWith('tx_')) {
      final user = currentUser;
      if (user != null) {
        try {
          await _syncService.deleteFromServer(id, user.id);
          debugPrint('[Sync] Delete OK: $id');
        } catch (e) {
          _syncFailCount++;
          _lastSyncError = _syncService.extractErrorMessage(e);
          debugPrint('[Sync] Delete GAGAL: $e');
          notifyListeners();
        }
      }
    }
    _transactions = _transactions.where((tx) => tx.id != id).toList();
    await _persist();
    notifyListeners();
  }

  Future<void> updateTransaction(MoneyTransaction updatedTx) async {
    final index = _transactions.indexWhere((tx) => tx.id == updatedTx.id);
    if (index == -1) return;
    _transactions[index] = updatedTx;
    await _persist();
    notifyListeners();

    if (!updatedTx.id.startsWith('tx_')) {
      final user = currentUser;
      if (user != null) {
        try {
          await _syncService.updateOnServer(updatedTx, user.id);
          debugPrint('[Sync] Update OK: ${updatedTx.id}');
        } catch (e) {
          _syncFailCount++;
          _lastSyncError = _syncService.extractErrorMessage(e);
          debugPrint('[Sync] Update GAGAL: $e');
          notifyListeners();
        }
      }
    }
  }

  Future<void> updateSettings(AppSettings newSettings) async {
    _settings = newSettings;
    await _persist();
    notifyListeners();
  }

  // ─── Summary & History ────────────────────────────────────────────────────────

  Summary summaryForDate(DateRangeType rangeType, DateTime date) =>
      _summaryForDate(rangeType, date);

  Summary summaryFor(DateRangeType rangeType) =>
      _summaryForDate(rangeType, DateTime.now());

  Summary previousSummaryFor(DateRangeType rangeType) {
    final now = DateTime.now();
    final date = switch (rangeType) {
      DateRangeType.day   => now.subtract(const Duration(days: 1)),
      DateRangeType.week  => now.subtract(const Duration(days: 7)),
      DateRangeType.month => DateTime(now.year, now.month - 1, 15),
    };
    return _summaryForDate(rangeType, date);
  }

  List<MoneyTransaction> historyForDate(DateRangeType rangeType, DateTime date) {
    final range = _rangeFor(rangeType, date);
    return _filteredTransactions.where((tx) {
      final d = _stripTime(tx.effectiveDate);
      return !d.isBefore(range.start) && d.isBefore(range.end);
    }).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  List<MoneyTransaction> historyFor(DateRangeType rangeType) =>
      historyForDate(rangeType, DateTime.now());

  Summary _summaryForDate(DateRangeType rangeType, DateTime refDate) {
    final range = _rangeFor(rangeType, refDate);
    var income = 0;
    var expense = 0;
    for (final tx in _filteredTransactions) {
      final d = _stripTime(tx.effectiveDate);
      if (d.isBefore(range.start) || !d.isBefore(range.end)) continue;
      if (tx.isIncome) {
        income += tx.amount;
      } else {
        expense += tx.amount.abs();
      }
    }
    return Summary(totalIncome: income, totalExpense: expense);
  }

  DateTimeRange _rangeFor(DateRangeType type, DateTime now) {
    final today = _stripTime(now);
    if (type == DateRangeType.day) {
      return DateTimeRange(
        start: today,
        end: today.add(const Duration(days: 1)),
      );
    }
    if (type == DateRangeType.week) {
      final start = today.subtract(Duration(days: today.weekday - 1));
      return DateTimeRange(start: start, end: start.add(const Duration(days: 7)));
    }
    return DateTimeRange(
      start: DateTime(today.year, today.month),
      end: DateTime(today.year, today.month + 1),
    );
  }

  // ─── Persistence & Utilities ─────────────────────────────────────────────────

  Future<void> _persist() => _database.write({
        'transactions': _transactions.map((e) => e.toJson()).toList(),
        'products': _products.map((e) => e.toJson()).toList(),
        'outlets': _outlets.map((e) => e.toJson()).toList(),
        'categories': _categories.map((e) => e.toJson()).toList(),
        'profile': _profile.toJson(),
        'settings': _settings.toJson(),
      });

  static List<T> _parseList<T>(
    dynamic raw,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    if (raw is! List) return [];
    return raw.whereType<Map<String, dynamic>>().map(fromJson).toList();
  }

  DateTime _stripTime(DateTime input) =>
      DateTime(input.year, input.month, input.day);
}

