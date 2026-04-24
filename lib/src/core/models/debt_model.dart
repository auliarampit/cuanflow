enum DebtType {
  /// Saya berhutang ke orang lain
  iOwe,
  /// Orang lain berhutang ke saya
  theyOwe,
}

class DebtModel {
  DebtModel({
    required this.id,
    required this.personName,
    required this.amount,
    required this.type,
    required this.isPaid,
    required this.createdAt,
    this.notes,
    this.dueDate,
  });

  final String id;
  final String personName;
  final int amount;
  final DebtType type;
  final bool isPaid;
  final DateTime createdAt;
  final String? notes;
  final DateTime? dueDate;

  bool get isOverdue =>
      !isPaid && dueDate != null && dueDate!.isBefore(DateTime.now());

  DebtModel copyWith({
    String? personName,
    int? amount,
    DebtType? type,
    bool? isPaid,
    String? notes,
    DateTime? dueDate,
    bool clearDueDate = false,
  }) {
    return DebtModel(
      id: id,
      personName: personName ?? this.personName,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      isPaid: isPaid ?? this.isPaid,
      createdAt: createdAt,
      notes: notes ?? this.notes,
      dueDate: clearDueDate ? null : (dueDate ?? this.dueDate),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'personName': personName,
        'amount': amount,
        'type': type.name,
        'isPaid': isPaid,
        'createdAt': createdAt.toIso8601String(),
        'notes': notes,
        'dueDate': dueDate?.toIso8601String(),
      };

  factory DebtModel.fromJson(Map<String, dynamic> json) {
    return DebtModel(
      id: json['id'] as String,
      personName: json['personName'] as String? ??
          json['person_name'] as String? ??
          '',
      amount: (json['amount'] as num? ?? 0).toInt(),
      type: (json['type'] as String?) == 'theyOwe'
          ? DebtType.theyOwe
          : DebtType.iOwe,
      isPaid: json['isPaid'] as bool? ?? json['is_paid'] as bool? ?? false,
      createdAt: DateTime.tryParse(
              json['createdAt'] as String? ??
                  json['created_at'] as String? ??
                  '') ??
          DateTime.now(),
      notes: json['notes'] as String?,
      dueDate: json['dueDate'] != null
          ? DateTime.tryParse(json['dueDate'] as String)
          : json['due_date'] != null
              ? DateTime.tryParse(json['due_date'] as String)
              : null,
    );
  }
}
