import 'package:flutter/material.dart';

import '../models/app_settings.dart';
import '../models/money_transaction.dart';
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
  UserProfile _profile = UserProfile.empty();
  AppSettings _settings = AppSettings.defaults();

  List<MoneyTransaction> get transactions => _transactions;
  UserProfile get profile => _profile;
  AppSettings get settings => _settings;
  bool get initialized => _initialized;

  Future<void> init() async {
    if (_initialized) return;

    final raw = await _database.read();
    final txList = raw['transactions'];
    final profileMap = raw['profile'];
    final settingsMap = raw['settings'];

    if (txList is List) {
      _transactions = txList
          .whereType<Map<String, dynamic>>()
          .map(MoneyTransaction.fromJson)
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
  }

  Future<void> _persist() async {
    final data = <String, dynamic>{
      'transactions': _transactions.map((e) => e.toJson()).toList(),
      'profile': _profile.toJson(),
      'settings': _settings.toJson(),
    };
    await _database.write(data);
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