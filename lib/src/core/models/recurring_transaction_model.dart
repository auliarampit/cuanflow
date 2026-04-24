import 'money_transaction.dart';

enum RecurringFrequency { daily, weekly, monthly }

extension RecurringFrequencyX on RecurringFrequency {
  String get displayName {
    switch (this) {
      case RecurringFrequency.daily:
        return 'Setiap Hari';
      case RecurringFrequency.weekly:
        return 'Setiap Minggu';
      case RecurringFrequency.monthly:
        return 'Setiap Bulan';
    }
  }
}

class RecurringTransactionModel {
  RecurringTransactionModel({
    required this.id,
    required this.name,
    required this.amount,
    required this.category,
    required this.type,
    required this.frequency,
    required this.isActive,
    required this.createdAt,
    this.walletId,
    this.dayOfMonth,
    this.lastExecuted,
    this.nextExecute,
  });

  final String id;
  final String name;
  final int amount;
  final String category;
  final MoneyTransactionType type;
  final RecurringFrequency frequency;
  final bool isActive;
  final DateTime createdAt;
  final String? walletId;

  /// Untuk monthly: tanggal berapa setiap bulan (1–28)
  final int? dayOfMonth;

  final DateTime? lastExecuted;
  final DateTime? nextExecute;

  RecurringTransactionModel copyWith({
    String? name,
    int? amount,
    String? category,
    MoneyTransactionType? type,
    RecurringFrequency? frequency,
    bool? isActive,
    String? walletId,
    int? dayOfMonth,
    DateTime? lastExecuted,
    DateTime? nextExecute,
  }) {
    return RecurringTransactionModel(
      id: id,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      type: type ?? this.type,
      frequency: frequency ?? this.frequency,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
      walletId: walletId ?? this.walletId,
      dayOfMonth: dayOfMonth ?? this.dayOfMonth,
      lastExecuted: lastExecuted ?? this.lastExecuted,
      nextExecute: nextExecute ?? this.nextExecute,
    );
  }

  /// Hitung tanggal eksekusi berikutnya berdasarkan frekuensi
  DateTime computeNextExecute(DateTime from) {
    switch (frequency) {
      case RecurringFrequency.daily:
        return from.add(const Duration(days: 1));
      case RecurringFrequency.weekly:
        return from.add(const Duration(days: 7));
      case RecurringFrequency.monthly:
        final day = dayOfMonth ?? 1;
        var next = DateTime(from.year, from.month + 1, 1);
        final lastDay = DateTime(next.year, next.month + 1, 0).day;
        return DateTime(next.year, next.month, day.clamp(1, lastDay));
    }
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'amount': amount,
        'category': category,
        'type': type.name,
        'frequency': frequency.name,
        'isActive': isActive,
        'createdAt': createdAt.toIso8601String(),
        'walletId': walletId,
        'dayOfMonth': dayOfMonth,
        'lastExecuted': lastExecuted?.toIso8601String(),
        'nextExecute': nextExecute?.toIso8601String(),
      };

  factory RecurringTransactionModel.fromJson(Map<String, dynamic> json) {
    RecurringFrequency parseFreq(String? v) {
      switch (v) {
        case 'weekly':
          return RecurringFrequency.weekly;
        case 'monthly':
          return RecurringFrequency.monthly;
        default:
          return RecurringFrequency.daily;
      }
    }

    return RecurringTransactionModel(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      amount: (json['amount'] as num? ?? 0).toInt(),
      category: json['category'] as String? ?? '',
      type: (json['type'] as String?) == 'income'
          ? MoneyTransactionType.income
          : MoneyTransactionType.expense,
      frequency: parseFreq(json['frequency'] as String?),
      isActive: json['isActive'] as bool? ?? true,
      createdAt: DateTime.tryParse(
              json['createdAt'] as String? ??
                  json['created_at'] as String? ??
                  '') ??
          DateTime.now(),
      walletId: json['walletId'] as String? ?? json['wallet_id'] as String?,
      dayOfMonth: (json['dayOfMonth'] as num?)?.toInt(),
      lastExecuted: json['lastExecuted'] != null
          ? DateTime.tryParse(json['lastExecuted'] as String)
          : null,
      nextExecute: json['nextExecute'] != null
          ? DateTime.tryParse(json['nextExecute'] as String)
          : null,
    );
  }
}
