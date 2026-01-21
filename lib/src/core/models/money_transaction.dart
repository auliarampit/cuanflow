import 'dart:convert';

enum MoneyTransactionType { income, expense }

class MoneyTransaction {
  MoneyTransaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.effectiveDate,
    required this.createdAt,
    this.note,
    this.category,
  });

  final String id;
  final MoneyTransactionType type;
  final int amount;
  final String? note;
  final String? category;
  final DateTime effectiveDate;
  final DateTime createdAt;

  bool get isIncome => type == MoneyTransactionType.income;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'type': type.name,
      'amount': amount,
      'note': note,
      'category': category,
      'effectiveDate': effectiveDate.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  static MoneyTransaction fromJson(Map<String, dynamic> jsonMap) {
    final rawType = jsonMap['type'] as String? ?? 'income';
    final parsedType = rawType == MoneyTransactionType.expense.name
        ? MoneyTransactionType.expense
        : MoneyTransactionType.income;

    return MoneyTransaction(
      id: jsonMap['id'] as String? ?? '',
      type: parsedType,
      amount: jsonMap['amount'] as int? ?? 0,
      note: jsonMap['note'] as String?,
      category: jsonMap['category'] as String?,
      effectiveDate: DateTime.parse(
        jsonMap['effectiveDate'] as String? ?? DateTime.now().toIso8601String(),
      ),
      createdAt: DateTime.parse(
        jsonMap['createdAt'] as String? ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  static List<MoneyTransaction> listFromJsonString(String raw) {
    if (raw.isEmpty) return <MoneyTransaction>[];
    final decoded = json.decode(raw);
    if (decoded is! List) return <MoneyTransaction>[];
    return decoded
        .whereType<Map<String, dynamic>>()
        .map(MoneyTransaction.fromJson)
        .toList();
  }

  static String listToJsonString(List<MoneyTransaction> list) {
    final encoded = list.map((e) => e.toJson()).toList(growable: false);
    return json.encode(encoded);
  }
}
