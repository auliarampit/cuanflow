import 'money_transaction.dart';

class UserCategory {
  const UserCategory({
    required this.id,
    required this.name,
    required this.type,
    this.isDefault = false,
  });

  final String id;
  final String name;
  final MoneyTransactionType type;
  final bool isDefault; // kategori default tidak bisa dihapus

  bool get isIncome => type == MoneyTransactionType.income;

  /// Alias untuk kompatibilitas dengan kode lama yang pakai `.key` / `.label`
  String get key => id;
  String get label => name;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is UserCategory && other.id == id);

  @override
  int get hashCode => id.hashCode;

  UserCategory copyWith({String? name}) => UserCategory(
        id: id,
        name: name ?? this.name,
        type: type,
        isDefault: isDefault,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': type.name,
        'isDefault': isDefault,
      };

  static UserCategory fromJson(Map<String, dynamic> json) => UserCategory(
        id: json['id'] as String,
        name: json['name'] as String,
        type: json['type'] == 'expense'
            ? MoneyTransactionType.expense
            : MoneyTransactionType.income,
        isDefault: json['isDefault'] as bool? ?? false,
      );

  // ─── Kategori default ─────────────────────────────────────────────────────

  static List<UserCategory> get defaultCategories => [
        // Income
        UserCategory(id: 'def_inc_1', name: 'Penjualan', type: MoneyTransactionType.income, isDefault: true),
        UserCategory(id: 'def_inc_2', name: 'Gaji', type: MoneyTransactionType.income, isDefault: true),
        UserCategory(id: 'def_inc_3', name: 'Freelance', type: MoneyTransactionType.income, isDefault: true),
        UserCategory(id: 'def_inc_4', name: 'Investasi', type: MoneyTransactionType.income, isDefault: true),
        UserCategory(id: 'def_inc_5', name: 'Online/Digital', type: MoneyTransactionType.income, isDefault: true),
        UserCategory(id: 'def_inc_6', name: 'Bonus', type: MoneyTransactionType.income, isDefault: true),
        UserCategory(id: 'def_inc_7', name: 'Lainnya', type: MoneyTransactionType.income, isDefault: true),
        // Expense
        UserCategory(id: 'def_exp_1', name: 'Bahan Baku', type: MoneyTransactionType.expense, isDefault: true),
        UserCategory(id: 'def_exp_2', name: 'Transportasi', type: MoneyTransactionType.expense, isDefault: true),
        UserCategory(id: 'def_exp_3', name: 'Operasional', type: MoneyTransactionType.expense, isDefault: true),
        UserCategory(id: 'def_exp_4', name: 'Makan & Minum', type: MoneyTransactionType.expense, isDefault: true),
        UserCategory(id: 'def_exp_5', name: 'Belanja', type: MoneyTransactionType.expense, isDefault: true),
        UserCategory(id: 'def_exp_6', name: 'Cicilan', type: MoneyTransactionType.expense, isDefault: true),
        UserCategory(id: 'def_exp_7', name: 'Listrik & Air', type: MoneyTransactionType.expense, isDefault: true),
        UserCategory(id: 'def_exp_8', name: 'Hiburan', type: MoneyTransactionType.expense, isDefault: true),
        UserCategory(id: 'def_exp_9', name: 'Kesehatan', type: MoneyTransactionType.expense, isDefault: true),
        UserCategory(id: 'def_exp_10', name: 'Pendidikan', type: MoneyTransactionType.expense, isDefault: true),
        UserCategory(id: 'def_exp_11', name: 'Lainnya', type: MoneyTransactionType.expense, isDefault: true),
      ];
}
