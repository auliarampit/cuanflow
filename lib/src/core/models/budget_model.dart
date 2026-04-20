import 'money_transaction.dart';

class BudgetModel {
  BudgetModel({
    required this.id,
    required this.type,
    required this.targetAmount,
    required this.monthYear,
    required this.createdAt,
    this.categoryId,
  });

  final String id;

  /// income = target pemasukan, expense = batas pengeluaran
  final MoneyTransactionType type;

  /// null = berlaku untuk semua kategori
  final String? categoryId;

  final int targetAmount;

  /// Format "YYYY-MM", contoh: "2026-04"
  final String monthYear;

  final DateTime createdAt;

  static String monthYearOf(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}';

  BudgetModel copyWith({
    String? id,
    MoneyTransactionType? type,
    String? categoryId,
    int? targetAmount,
    String? monthYear,
    DateTime? createdAt,
    bool clearCategory = false,
  }) {
    return BudgetModel(
      id: id ?? this.id,
      type: type ?? this.type,
      categoryId: clearCategory ? null : (categoryId ?? this.categoryId),
      targetAmount: targetAmount ?? this.targetAmount,
      monthYear: monthYear ?? this.monthYear,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'categoryId': categoryId,
        'targetAmount': targetAmount,
        'monthYear': monthYear,
        'createdAt': createdAt.toIso8601String(),
      };

  factory BudgetModel.fromJson(Map<String, dynamic> json) => BudgetModel(
        id: json['id'] as String,
        type: MoneyTransactionType.values.firstWhere(
          (e) => e.name == json['type'],
          orElse: () => MoneyTransactionType.expense,
        ),
        categoryId: json['categoryId'] as String?,
        targetAmount: json['targetAmount'] as int? ?? 0,
        monthYear: json['monthYear'] as String? ?? '',
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
            DateTime.now(),
      );
}
