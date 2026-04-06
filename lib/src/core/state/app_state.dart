import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/app_settings.dart';
import '../models/money_transaction.dart';
import '../models/product_model.dart';
import '../models/user_profile.dart';
import '../storage/local_database.dart';

enum DateRangeType {
  day,
  week,
  month,
}

class Summary {
  Summary({
    required this.totalIncome,
    required this.totalExpense,
  });

  final int totalIncome;
  final int totalExpense;

  int get netProfit => totalIncome - totalExpense;
}

class AppState extends ChangeNotifier {
  AppState({LocalDatabase? database})
      : _database = database ?? LocalDatabase();

  final LocalDatabase _database;

  bool _initialized = false;
  List<MoneyTransaction> _transactions = <MoneyTransaction>[];
  List<ProductModel> _products = <ProductModel>[];
  UserProfile _profile = UserProfile.empty();
  AppSettings _settings = AppSettings.defaults();

  SupabaseClient get supabase => Supabase.instance.client;
  User? get currentUser => supabase.auth.currentUser;

  List<MoneyTransaction> get transactions => _transactions;
  List<ProductModel> get products => _products;
  UserProfile get profile => _profile;
  AppSettings get settings => _settings;
  bool get initialized => _initialized;

  Future<void> init() async {
    if (_initialized) return;

    final raw = await _database.read();
    final txList = raw['transactions'];
    final productList = raw['products'];
    final profileMap = raw['profile'];
    final settingsMap = raw['settings'];

    if (txList is List) {
      _transactions = txList
          .whereType<Map<String, dynamic>>()
          .map(MoneyTransaction.fromJson)
          .toList();
    }

    if (productList is List) {
      _products = productList
          .whereType<Map<String, dynamic>>()
          .map(ProductModel.fromJson)
          .toList();
    }

    if (profileMap is Map<String, dynamic>) {
      _profile = UserProfile.fromJson(profileMap);
    }

    if (settingsMap is Map<String, dynamic>) {
      _settings = AppSettings.fromJson(settingsMap);
    }

    _initialized = true;
    notifyListeners();

    if (currentUser != null) {
      unawaited(syncTransactions());
      unawaited(fetchProfile());
    }
  }

  /// Dipanggil saat app kembali aktif (mis. setelah Supabase unpause) untuk
  /// mendorong transaksi lokal `tx_*` dan menggabungkan data remote.
  Future<void> onAppResumed() async {
    if (currentUser != null) {
      await syncTransactions();
    }
  }

  Future<void> fetchProfile() async {
    try {
      final user = currentUser;
      if (user == null) return;

      final response = await supabase
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (response != null) {
        _profile = UserProfile.fromJson(
          Map<String, dynamic>.from(response as Map),
        );
        await _persist();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('[API] Fetch profile failed: $e');
    }
  }

  Future<void> logout() async {
    try {
      await supabase.auth.signOut();
    } catch (e) {
      debugPrint('[Auth] signOut failed: $e');
      rethrow;
    }
    _profile = UserProfile.empty();
    await _persist();
    notifyListeners();
  }

  /// Sinkron: dorong dulu transaksi lokal yang belum ada di server (`tx_*`),
  /// lalu tarik dari server dan gabungkan — tidak menimpa seluruh data lokal.
  Future<void> syncTransactions() async {
    final user = currentUser;
    if (user == null) return;

    try {
      await _pushPendingLocalTransactions();
      await _pullAndMergeRemoteTransactions();
    } catch (e) {
      debugPrint('[Sync] syncTransactions failed: $e');
    }
  }

  Future<void> _pushPendingLocalTransactions() async {
    final user = currentUser;
    if (user == null) return;

    var changed = false;
    final next = <MoneyTransaction>[];

    for (final tx in _transactions) {
      if (!tx.id.startsWith('tx_')) {
        next.add(tx);
        continue;
      }
      try {
        final response = await supabase.from('transactions').insert({
          'user_id': user.id,
          'type': tx.type.name,
          'amount': tx.amount,
          'category': tx.category,
          'note': tx.note,
          'effective_date': tx.effectiveDate.toIso8601String(),
        }).select().single();

        next.add(MoneyTransaction.fromJson(response));
        changed = true;
      } catch (e) {
        debugPrint('[Sync] Push pending failed for ${tx.id}: $e');
        next.add(tx);
      }
    }

    if (changed) {
      _transactions = next;
      await _persist();
      notifyListeners();
    }
  }

  Future<void> _pullAndMergeRemoteTransactions() async {
    final user = currentUser;
    if (user == null) return;

    try {
      final response = await supabase
          .from('transactions')
          .select()
          .eq('user_id', user.id)
          .order('effective_date', ascending: false);

      final remote = (response as List)
          .map(
            (e) => MoneyTransaction.fromJson(
              Map<String, dynamic>.from(e as Map),
            ),
          )
          .toList();

      final pending =
          _transactions.where((t) => t.id.startsWith('tx_')).toList();
      final merged = <MoneyTransaction>[...remote, ...pending];
      merged.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      _transactions = merged;
      await _persist();
      notifyListeners();
    } catch (e) {
      debugPrint('[Sync] Pull/merge failed: $e');
    }
  }

  Future<void> _persist() async {
    final data = <String, dynamic>{
      'transactions': _transactions.map((e) => e.toJson()).toList(),
      'products': _products.map((e) => e.toJson()).toList(),
      'profile': _profile.toJson(),
      'settings': _settings.toJson(),
    };
    await _database.write(data);
  }

  Future<void> addProduct(ProductModel product) async {
    _products = <ProductModel>[product, ..._products];
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

  Future<void> addIncome({
    required int amount,
    String? note,
    String? category,
    DateTime? effectiveDate,
  }) async {
    await _addTransaction(
      type: MoneyTransactionType.income,
      amount: amount,
      note: note,
      category: category,
      effectiveDate: effectiveDate,
    );
  }

  Future<void> addExpense({
    required int amount,
    String? note,
    String? category,
    DateTime? effectiveDate,
  }) async {
    await _addTransaction(
      type: MoneyTransactionType.expense,
      amount: amount,
      note: note,
      category: category,
      effectiveDate: effectiveDate,
    );
  }

  Future<void> _addTransaction({
    required MoneyTransactionType type,
    required int amount,
    String? note,
    String? category,
    DateTime? effectiveDate,
  }) async {
    final now = DateTime.now();
    final dateOnly =
        effectiveDate != null ? _stripTime(effectiveDate) : _stripTime(now);

    final user = currentUser;
    if (user != null) {
      try {
        final response = await supabase.from('transactions').insert({
          'user_id': user.id,
          'type': type.name,
          'amount': amount,
          'category': category,
          'note': note,
          'effective_date': dateOnly.toIso8601String(),
        }).select().single();

        final tx = MoneyTransaction.fromJson(response);
        _transactions = <MoneyTransaction>[tx, ..._transactions];
        await _persist();
        notifyListeners();
        return;
      } catch (e) {
        debugPrint('[API] Supabase insert failed, menyimpan lokal: $e');
      }
    }

    final id = 'tx_${now.microsecondsSinceEpoch}';
    final tx = MoneyTransaction(
      id: id,
      type: type,
      amount: amount,
      note: note,
      category: category,
      effectiveDate: dateOnly,
      createdAt: now,
    );

    _transactions = <MoneyTransaction>[tx, ..._transactions];
    await _persist();
    notifyListeners();
  }

  Future<void> deleteTransaction(String id) async {
    _transactions = _transactions.where((tx) => tx.id != id).toList();
    await _persist();
    notifyListeners();
  }

  Future<void> updateTransaction(MoneyTransaction updatedTx) async {
    final index = _transactions.indexWhere((tx) => tx.id == updatedTx.id);
    if (index != -1) {
      _transactions[index] = updatedTx;
      await _persist();
      notifyListeners();
    }
  }

  Future<void> updateSettings(AppSettings newSettings) async {
    _settings = newSettings;
    await _persist();
    notifyListeners();
  }

  Summary summaryForDate(DateRangeType rangeType, DateTime date) {
    return _summaryForDate(rangeType, date);
  }

  Summary summaryFor(DateRangeType rangeType) {
    return _summaryForDate(rangeType, DateTime.now());
  }

  Summary previousSummaryFor(DateRangeType rangeType) {
    final now = DateTime.now();
    DateTime date;
    if (rangeType == DateRangeType.day) {
      date = now.subtract(const Duration(days: 1));
    } else if (rangeType == DateRangeType.week) {
      date = now.subtract(const Duration(days: 7));
    } else {
      date = DateTime(now.year, now.month - 1, 15);
    }
    return _summaryForDate(rangeType, date);
  }

  Summary _summaryForDate(DateRangeType rangeType, DateTime refDate) {
    final range = _rangeFor(rangeType, refDate);
    var income = 0;
    var expense = 0;

    for (final tx in _transactions) {
      final date = _stripTime(tx.effectiveDate);
      final inRange =
          !date.isBefore(range.start) && date.isBefore(range.end);
      if (!inRange) continue;

      if (tx.isIncome) {
        income += tx.amount;
      } else {
        expense += tx.amount.abs();
      }
    }

    return Summary(totalIncome: income, totalExpense: expense);
  }

  List<MoneyTransaction> historyForDate(DateRangeType rangeType, DateTime date) {
    final range = _rangeFor(rangeType, date);
    final list = _transactions.where((tx) {
      final tDate = _stripTime(tx.effectiveDate);
      return !tDate.isBefore(range.start) && tDate.isBefore(range.end);
    }).toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  List<MoneyTransaction> historyFor(DateRangeType rangeType) {
    final now = DateTime.now();
    final range = _rangeFor(rangeType, now);

    final list = _transactions.where((tx) {
      final date = _stripTime(tx.effectiveDate);
      return !date.isBefore(range.start) && date.isBefore(range.end);
    }).toList();

    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
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
      final weekday = today.weekday;
      final start = today.subtract(Duration(days: weekday - 1));
      final end = start.add(const Duration(days: 7));
      return DateTimeRange(start: start, end: end);
    }

    final startMonth = DateTime(today.year, today.month, 1);
    final nextMonth =
        DateTime(today.year, today.month + 1, 1);
    return DateTimeRange(start: startMonth, end: nextMonth);
  }

  DateTime _stripTime(DateTime input) {
    return DateTime(input.year, input.month, input.day);
  }
}

class AppStateScope extends InheritedNotifier<AppState> {
  const AppStateScope({
    super.key,
    required AppState state,
    required super.child,
  }) : super(notifier: state);

  static AppState of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<AppStateScope>();
    if (scope == null) {
      throw FlutterError('AppStateScope.of() called with no AppStateScope');
    }
    final state = scope.notifier;
    if (state == null) {
      throw FlutterError('AppStateScope has no notifier');
    }
    return state;
  }

  @override
  bool updateShouldNotify(covariant AppStateScope oldWidget) {
    return oldWidget.notifier != notifier;
  }
}

extension AppStateContextExtension on BuildContext {
  AppState get appState => AppStateScope.of(this);
}