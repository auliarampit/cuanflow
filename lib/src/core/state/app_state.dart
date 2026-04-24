import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:collection/collection.dart';

import '../models/app_settings.dart';
import '../models/budget_model.dart';
import '../models/debt_model.dart';
import '../models/money_transaction.dart';
import '../models/outlet_model.dart';
import '../models/product_model.dart';
import '../models/raw_material_model.dart';
import '../models/production_batch_model.dart';
import '../models/inventory_item.dart';
import '../models/quick_sale_preset.dart';
import '../models/recurring_transaction_model.dart';
import '../models/summary.dart';
import '../models/user_category.dart';
import '../models/user_profile.dart';
import '../models/wallet_model.dart';
import '../services/budget_sync_service.dart';
import '../services/category_sync_service.dart';
import '../services/debt_sync_service.dart';
import '../services/recurring_sync_service.dart';
import '../services/inventory_sync_service.dart';
import '../services/quick_sale_sync_service.dart';
import '../services/raw_material_sync_service.dart';
import '../services/production_batch_sync_service.dart';
import '../services/notification_service.dart';
import '../services/outlet_service.dart';
import '../services/profile_service.dart';
import '../services/transaction_sync_service.dart';
import '../services/wallet_sync_service.dart';
import '../storage/local_database.dart';

export '../models/budget_model.dart';
export '../models/debt_model.dart';
export '../models/recurring_transaction_model.dart';
export '../models/summary.dart';
export '../models/inventory_item.dart';
export '../models/quick_sale_preset.dart';
export '../models/raw_material_model.dart';
export '../models/production_batch_model.dart';
export '../models/wallet_model.dart';
export 'app_state_scope.dart';

class AppState extends ChangeNotifier {
  AppState({LocalDatabase? database})
      : _database = database ?? LocalDatabase();

  final LocalDatabase _database;

  late final _syncService = TransactionSyncService(supabase);
  late final _outletService = OutletService(supabase);
  late final _profileService = ProfileService(supabase);
  late final _categoryService = CategorySyncService(supabase);
  late final _budgetSyncService = BudgetSyncService(supabase);
  late final _walletSyncService = WalletSyncService(supabase);
  late final _debtSyncService = DebtSyncService(supabase);
  late final _recurringSyncService = RecurringSyncService(supabase);
  late final _inventorySyncService = InventorySyncService(supabase);
  late final _quickSaleSyncService = QuickSaleSyncService(supabase);
  late final _rawMaterialSyncService = RawMaterialSyncService(supabase);
  late final _productionBatchSyncService = ProductionBatchSyncService(supabase);

  bool _initialized = false;
  bool _isSyncing = false;
  Timer? _retryTimer;
  List<MoneyTransaction> _transactions = [];
  List<ProductModel> _products = [];
  List<OutletModel> _outlets = [];
  List<UserCategory> _categories = [];
  List<BudgetModel> _budgets = [];
  List<WalletModel> _wallets = [];
  List<DebtModel> _debts = [];
  List<RecurringTransactionModel> _recurring = [];
  List<InventoryItem> _inventory = [];
  List<QuickSalePreset> _quickSalePresets = [];
  List<RawMaterial> _rawMaterials = [];
  List<ProductionBatch> _productionBatches = [];
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
  List<BudgetModel> get budgets => _budgets;
  List<WalletModel> get wallets => _wallets;
  List<DebtModel> get debts => _debts;
  List<RecurringTransactionModel> get recurringTransactions => _recurring;
  List<InventoryItem> get inventoryItems => _inventory;
  List<QuickSalePreset> get quickSalePresets => _quickSalePresets;
  List<RawMaterial> get rawMaterials => _rawMaterials;
  List<ProductionBatch> get productionBatches => _productionBatches;
  List<InventoryItem> get lowStockItems =>
      _inventory.where((i) => i.isLowStock || i.isOutOfStock).toList();
  List<RawMaterial> get lowStockRawMaterials =>
      _rawMaterials.where((m) => m.isLowStock || m.isOutOfStock).toList();
  String? get selectedOutletId => _selectedOutletId;

  /// Saldo total kumulatif dari semua transaksi (atau per dompet jika ada).
  int get totalBalance {
    if (_wallets.isEmpty) {
      return _transactions.fold(
          0, (s, tx) => s + (tx.isIncome ? tx.amount : -tx.amount));
    }
    return _wallets.fold(0, (s, w) => s + balanceFor(w.id));
  }

  /// Saldo satu dompet = saldo awal + pemasukan - pengeluaran dari dompet tsb.
  int balanceFor(String walletId) {
    final wallet = _wallets.firstWhereOrNull((w) => w.id == walletId);
    if (wallet == null) return 0;
    final txBalance = _transactions
        .where((tx) => tx.walletId == walletId)
        .fold(0, (s, tx) => s + (tx.isIncome ? tx.amount : -tx.amount));
    return wallet.initialBalance + txBalance;
  }

  /// Jumlah utang yang belum lunas berdasarkan tipe.
  int totalDebt(DebtType type) => _debts
      .where((d) => d.type == type && !d.isPaid)
      .fold(0, (s, d) => s + d.amount);

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
    _products    = _parseList(raw['products'],     ProductModel.fromJson);
    _outlets     = _parseList(raw['outlets'],      OutletModel.fromJson);
    _categories  = _parseList(raw['categories'],   UserCategory.fromJson);
    _budgets     = _parseList(raw['budgets'],       BudgetModel.fromJson);
    _wallets     = _parseList(raw['wallets'],       WalletModel.fromJson);
    _debts       = _parseList(raw['debts'],         DebtModel.fromJson);
    _recurring   = _parseList(raw['recurring'],     RecurringTransactionModel.fromJson);
    _inventory          = _parseList(raw['inventory'],          InventoryItem.fromJson);
    _quickSalePresets   = _parseList(raw['quickSalePresets'],   QuickSalePreset.fromJson);
    _rawMaterials       = _parseList(raw['rawMaterials'],       RawMaterial.fromJson);
    _productionBatches  = _parseList(raw['productionBatches'],  ProductionBatch.fromJson);

    final profileMap = raw['profile'];
    if (profileMap is Map<String, dynamic>) {
      _profile = UserProfile.fromJson(profileMap);
    }
    final settingsMap = raw['settings'];
    if (settingsMap is Map<String, dynamic>) {
      _settings = AppSettings.fromJson(settingsMap);
    }

    if (_settings.dailyNotification) {
      unawaited(NotificationService.schedule(
        hour: _settings.notificationHour,
        minute: _settings.notificationMinute,
      ));
    }

    _transactions = _syncService.migrateOldIds(_transactions);
    await _processRecurring();

    _initialized = true;
    notifyListeners();

    if (currentUser != null) {
      unawaited(syncTransactions());
      unawaited(fetchProfile());
      unawaited(syncCategories());
      unawaited(syncBudgets());
      unawaited(syncWallets());
      unawaited(syncDebts());
      unawaited(syncRecurring());
      unawaited(syncInventory());
      unawaited(syncQuickSalePresets());
      unawaited(syncRawMaterials());
      unawaited(syncProductionBatches());
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
      _lastSyncError = _isNetworkError(e) ? '__no_internet__' : e.toString();
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

  Future<void> updateProfile(UserProfile updatedProfile, {String? userId}) async {
    _profile = updatedProfile;
    await _persist();
    notifyListeners();

    final id = userId ?? currentUser?.id;
    if (id != null) {
      try {
        await _profileService.updateProfile(id, updatedProfile);
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
    _categoryService.delete(id).ignore();
  }

  Future<void> updateCategoryStockFlag(String id, {required bool isStock}) async {
    final idx = _categories.indexWhere((c) => c.id == id);
    if (idx == -1) return;
    _categories[idx] = _categories[idx].copyWith(isStockPurchase: isStock);
    await _persist();
    notifyListeners();
    _categoryService.upsert(_categories[idx]).ignore();
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

  // ─── Budget CRUD ─────────────────────────────────────────────────────────────

  List<BudgetModel> budgetsFor(DateTime month) {
    final key = BudgetModel.monthYearOf(month);
    return _budgets.where((b) => b.monthYear == key).toList();
  }

  /// Jumlah aktual (transaksi bulan tsb) untuk satu budget entry.
  int actualFor(BudgetModel budget) {
    final range = _rangeFor(DateRangeType.month, DateTime(
      int.parse(budget.monthYear.split('-')[0]),
      int.parse(budget.monthYear.split('-')[1]),
    ));

    // tx.category menyimpan NAMA kategori, sedangkan budget.categoryId menyimpan
    // ID kategori. Perlu di-resolve dulu ke nama sebelum dibandingkan.
    String? budgetCategoryName;
    if (budget.categoryId != null) {
      for (final c in categoriesFor(budget.type)) {
        if (c.id == budget.categoryId) {
          budgetCategoryName = c.name;
          break;
        }
      }
      // Kategori sudah dihapus — tidak ada transaksi yang cocok
      if (budgetCategoryName == null) return 0;
    }

    var total = 0;
    for (final tx in _transactions) {
      final d = _stripTime(tx.effectiveDate);
      if (d.isBefore(range.start) || !d.isBefore(range.end)) continue;
      if (tx.type != budget.type) continue;
      if (budgetCategoryName != null && tx.category != budgetCategoryName) continue;
      total += tx.amount.abs();
    }
    return total;
  }

  Future<void> syncBudgets() async {
    final user = currentUser;
    if (user == null) return;
    try {
      final remote = await _budgetSyncService.fetchBudgets(user.id);
      if (remote.isNotEmpty) {
        _budgets = remote;
        await _persist();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('[BudgetSync] syncBudgets failed: $e');
    }
  }

  Future<void> addBudget(BudgetModel budget) async {
    _budgets = [budget, ..._budgets];
    await _persist();
    notifyListeners();
    final user = currentUser;
    if (user != null) {
      unawaited(_budgetSyncService.upsertBudget(user.id, budget));
    }
  }

  Future<void> updateBudget(BudgetModel budget) async {
    final index = _budgets.indexWhere((b) => b.id == budget.id);
    if (index != -1) {
      _budgets[index] = budget;
      await _persist();
      notifyListeners();
    }
    final user = currentUser;
    if (user != null) {
      unawaited(_budgetSyncService.upsertBudget(user.id, budget));
    }
  }

  Future<void> deleteBudget(String id) async {
    _budgets = _budgets.where((b) => b.id != id).toList();
    await _persist();
    notifyListeners();
    unawaited(_budgetSyncService.deleteBudget(id));
  }

  // ─── Transaction CRUD ────────────────────────────────────────────────────────

  Future<void> addIncome({
    required int amount,
    String? note,
    String? category,
    String? outletId,
    String? walletId,
    DateTime? effectiveDate,
  }) =>
      _addTransaction(
        type: MoneyTransactionType.income,
        amount: amount,
        note: note,
        category: category,
        outletId: outletId,
        walletId: walletId,
        effectiveDate: effectiveDate,
      );

  Future<void> addExpense({
    required int amount,
    String? note,
    String? category,
    String? outletId,
    String? walletId,
    DateTime? effectiveDate,
  }) =>
      _addTransaction(
        type: MoneyTransactionType.expense,
        amount: amount,
        note: note,
        category: category,
        outletId: outletId,
        walletId: walletId,
        effectiveDate: effectiveDate,
      );

  Future<void> _addTransaction({
    required MoneyTransactionType type,
    required int amount,
    String? note,
    String? category,
    String? outletId,
    String? walletId,
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
      walletId: walletId,
      effectiveDate: effectiveDate != null ? _stripTime(effectiveDate) : _stripTime(now),
      createdAt: now,
    );
    _transactions = [tx, ..._transactions];
    await _persist();
    notifyListeners();
    unawaited(syncTransactions());
  }

  // ─── Wallet CRUD ──────────────────────────────────────────────────────────────

  Future<void> syncWallets() async {
    if (currentUser == null) return;
    try {
      final remote = await _walletSyncService.fetchWallets();
      if (remote.isNotEmpty) {
        _wallets = remote;
        await _persist();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('[WalletSync] failed: $e');
    }
  }

  Future<void> addWallet(WalletModel wallet) async {
    if (currentUser != null) {
      try {
        final confirmed = await _walletSyncService.insertWallet(wallet);
        if (confirmed != null) {
          _wallets = [..._wallets, confirmed];
          await _persist();
          notifyListeners();
          return;
        }
      } catch (e) {
        debugPrint('[WalletSync] addWallet failed: $e');
      }
    }
    _wallets = [..._wallets, wallet];
    await _persist();
    notifyListeners();
  }

  Future<void> updateWallet(WalletModel wallet) async {
    final idx = _wallets.indexWhere((w) => w.id == wallet.id);
    if (idx == -1) return;
    _wallets[idx] = wallet;
    await _persist();
    notifyListeners();
    _walletSyncService.updateWallet(wallet).ignore();
  }

  Future<void> deleteWallet(String id) async {
    _wallets = _wallets.where((w) => w.id != id).toList();
    await _persist();
    notifyListeners();
    _walletSyncService.deleteWallet(id).ignore();
  }

  // ─── Debt CRUD ────────────────────────────────────────────────────────────────

  Future<void> syncDebts() async {
    if (currentUser == null) return;
    try {
      final remote = await _debtSyncService.fetchDebts();
      _debts = remote;
      await _persist();
      notifyListeners();
    } catch (e) {
      debugPrint('[DebtSync] failed: $e');
    }
  }

  Future<void> addDebt(DebtModel debt) async {
    _debts = [debt, ..._debts];
    await _persist();
    notifyListeners();
    _debtSyncService.upsertDebt(debt).ignore();
  }

  Future<void> updateDebt(DebtModel debt) async {
    final idx = _debts.indexWhere((d) => d.id == debt.id);
    if (idx == -1) return;
    _debts[idx] = debt;
    await _persist();
    notifyListeners();
    _debtSyncService.upsertDebt(debt).ignore();
  }

  Future<void> deleteDebt(String id) async {
    _debts = _debts.where((d) => d.id != id).toList();
    await _persist();
    notifyListeners();
    _debtSyncService.deleteDebt(id).ignore();
  }

  // ─── Recurring CRUD ───────────────────────────────────────────────────────────

  Future<void> syncRecurring() async {
    if (currentUser == null) return;
    try {
      final remote = await _recurringSyncService.fetchAll();
      if (remote.isNotEmpty) {
        _recurring = remote;
        await _persist();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('[RecurringSync] failed: $e');
    }
  }

  Future<void> addRecurring(RecurringTransactionModel r) async {
    _recurring = [r, ..._recurring];
    await _persist();
    notifyListeners();
    _recurringSyncService.upsert(r).ignore();
  }

  Future<void> updateRecurring(RecurringTransactionModel r) async {
    final idx = _recurring.indexWhere((e) => e.id == r.id);
    if (idx == -1) return;
    _recurring[idx] = r;
    await _persist();
    notifyListeners();
    _recurringSyncService.upsert(r).ignore();
  }

  Future<void> deleteRecurring(String id) async {
    _recurring = _recurring.where((r) => r.id != id).toList();
    await _persist();
    notifyListeners();
    _recurringSyncService.delete(id).ignore();
  }

  // ─── Inventory CRUD ───────────────────────────────────────────────────────────

  Future<void> syncInventory() async {
    if (currentUser == null) return;
    try {
      final remote = await _inventorySyncService.fetchAll();
      if (remote.isNotEmpty) {
        _inventory = remote;
        await _persist();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('[InventorySync] failed: $e');
    }
  }

  Future<void> addInventoryItem(InventoryItem item) async {
    _inventory = [item, ..._inventory];
    await _persist();
    notifyListeners();
    _inventorySyncService.upsert(item).ignore();
  }

  Future<void> updateInventoryItem(InventoryItem item) async {
    final idx = _inventory.indexWhere((i) => i.id == item.id);
    if (idx == -1) return;
    _inventory[idx] = item;
    await _persist();
    notifyListeners();
    _inventorySyncService.upsert(item).ignore();
  }

  Future<void> deleteInventoryItem(String id) async {
    _inventory = _inventory.where((i) => i.id != id).toList();
    await _persist();
    notifyListeners();
    _inventorySyncService.delete(id).ignore();
  }

  Future<void> adjustStock(String id, double delta) async {
    final idx = _inventory.indexWhere((i) => i.id == id);
    if (idx == -1) return;
    final item = _inventory[idx].copyWith(
      currentStock: (_inventory[idx].currentStock + delta).clamp(0, double.infinity),
    );
    _inventory[idx] = item;
    await _persist();
    notifyListeners();
    _inventorySyncService.upsert(item).ignore();
  }

  // ─── Quick Sale Preset CRUD ───────────────────────────────────────────────────

  Future<void> syncQuickSalePresets() async {
    if (currentUser == null) return;
    try {
      final remote = await _quickSaleSyncService.fetchAll();
      if (remote.isNotEmpty) {
        _quickSalePresets = remote;
        await _persist();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('[QuickSaleSync] failed: $e');
    }
  }

  Future<void> addQuickSalePreset(QuickSalePreset preset) async {
    _quickSalePresets = [..._quickSalePresets, preset];
    await _persist();
    notifyListeners();
    _quickSaleSyncService.upsert(preset).ignore();
  }

  Future<void> updateQuickSalePreset(QuickSalePreset preset) async {
    final idx = _quickSalePresets.indexWhere((p) => p.id == preset.id);
    if (idx == -1) return;
    _quickSalePresets[idx] = preset;
    await _persist();
    notifyListeners();
    _quickSaleSyncService.upsert(preset).ignore();
  }

  Future<void> deleteQuickSalePreset(String id) async {
    _quickSalePresets = _quickSalePresets.where((p) => p.id != id).toList();
    await _persist();
    notifyListeners();
    _quickSaleSyncService.delete(id).ignore();
  }

  // ─── Raw Material CRUD ────────────────────────────────────────────────────────

  Future<void> syncRawMaterials() async {
    if (currentUser == null) return;
    try {
      final remote = await _rawMaterialSyncService.fetchAll();
      if (remote.isNotEmpty) {
        _rawMaterials = remote;
        await _persist();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('[RawMaterialSync] failed: $e');
    }
  }

  Future<void> addRawMaterial(RawMaterial item) async {
    _rawMaterials = [item, ..._rawMaterials];
    await _persist();
    notifyListeners();
    _rawMaterialSyncService.upsert(item).ignore();
  }

  Future<void> updateRawMaterial(RawMaterial item) async {
    final idx = _rawMaterials.indexWhere((m) => m.id == item.id);
    if (idx == -1) return;
    _rawMaterials[idx] = item;
    await _persist();
    notifyListeners();
    _rawMaterialSyncService.upsert(item).ignore();
  }

  Future<void> deleteRawMaterial(String id) async {
    _rawMaterials = _rawMaterials.where((m) => m.id != id).toList();
    await _persist();
    notifyListeners();
    _rawMaterialSyncService.delete(id).ignore();
  }

  Future<void> adjustRawMaterialStock(String id, double delta) async {
    final idx = _rawMaterials.indexWhere((m) => m.id == id);
    if (idx == -1) return;
    final updated = _rawMaterials[idx].copyWith(
      currentStock:
          (_rawMaterials[idx].currentStock + delta).clamp(0, double.infinity),
    );
    _rawMaterials[idx] = updated;
    await _persist();
    notifyListeners();
    _rawMaterialSyncService.upsert(updated).ignore();
  }

  // ─── Production Batch CRUD ────────────────────────────────────────────────────

  Future<void> syncProductionBatches() async {
    if (currentUser == null) return;
    try {
      final remote = await _productionBatchSyncService.fetchAll();
      if (remote.isNotEmpty) {
        _productionBatches = remote;
        await _persist();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('[ProductionBatchSync] failed: $e');
    }
  }

  /// Record a production batch and deduct raw material stocks accordingly.
  Future<void> recordProduction(ProductionBatch batch) async {
    _productionBatches = [batch, ..._productionBatches];
    // Deduct raw material stocks
    for (final m in batch.materialsUsed) {
      await adjustRawMaterialStock(m.rawMaterialId, -m.quantity);
    }
    await _persist();
    notifyListeners();
    _productionBatchSyncService.upsert(batch).ignore();
  }

  Future<void> deleteProductionBatch(String id) async {
    _productionBatches = _productionBatches.where((b) => b.id != id).toList();
    await _persist();
    notifyListeners();
    _productionBatchSyncService.delete(id).ignore();
  }

  /// Jalankan recurring transactions yang sudah jatuh tempo saat app dibuka.
  Future<void> _processRecurring() async {
    if (_recurring.isEmpty) return;
    final now = DateTime.now();
    final today = _stripTime(now);
    var changed = false;
    final updated = <RecurringTransactionModel>[];

    for (final r in _recurring) {
      if (!r.isActive) { updated.add(r); continue; }

      final nextExec = _stripTime(r.nextExecute ?? r.createdAt);
      if (nextExec.isAfter(today)) { updated.add(r); continue; }

      // Buat transaksi untuk hari yang jatuh tempo
      final tx = MoneyTransaction(
        id: 'tx_${now.microsecondsSinceEpoch}_${r.id.hashCode.abs()}',
        type: r.type,
        amount: r.amount,
        note: r.name,
        category: r.category,
        walletId: r.walletId,
        effectiveDate: nextExec,
        createdAt: now,
      );
      _transactions = [tx, ..._transactions];
      updated.add(r.copyWith(
        lastExecuted: nextExec,
        nextExecute: r.computeNextExecute(nextExec),
      ));
      changed = true;
    }

    _recurring = updated;
    if (changed) {
      await _persist();
      unawaited(syncTransactions());
      // Push updated nextExecute / lastExecuted ke Supabase
      for (final r in updated) {
        _recurringSyncService.upsert(r).ignore();
      }
    }
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
    final stockNames = categoriesFor(MoneyTransactionType.expense)
        .where((c) => c.isStockPurchase)
        .map((c) => c.name)
        .toSet();
    var income = 0;
    var expense = 0;
    var stockExpense = 0;
    for (final tx in _filteredTransactions) {
      final d = _stripTime(tx.effectiveDate);
      if (d.isBefore(range.start) || !d.isBefore(range.end)) continue;
      if (tx.isIncome) {
        income += tx.amount;
      } else {
        final abs = tx.amount.abs();
        expense += abs;
        if (tx.category != null && stockNames.contains(tx.category)) {
          stockExpense += abs;
        }
      }
    }
    return Summary(totalIncome: income, totalExpense: expense, stockExpense: stockExpense);
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
        'budgets': _budgets.map((e) => e.toJson()).toList(),
        'wallets': _wallets.map((e) => e.toJson()).toList(),
        'debts': _debts.map((e) => e.toJson()).toList(),
        'recurring': _recurring.map((e) => e.toJson()).toList(),
        'inventory': _inventory.map((e) => e.toJson()).toList(),
        'quickSalePresets': _quickSalePresets.map((e) => e.toJson()).toList(),
        'rawMaterials': _rawMaterials.map((e) => e.toJson()).toList(),
        'productionBatches': _productionBatches.map((e) => e.toJson()).toList(),
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

  bool _isNetworkError(Object e) {
    if (e is SocketException) return true;
    final msg = e.toString().toLowerCase();
    return msg.contains('socketexception') ||
        msg.contains('connection refused') ||
        msg.contains('network is unreachable') ||
        msg.contains('failed host lookup');
  }
}

