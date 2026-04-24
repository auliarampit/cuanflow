enum WalletType { cash, bank, ewallet }

extension WalletTypeX on WalletType {
  String get displayName {
    switch (this) {
      case WalletType.cash:
        return 'Tunai';
      case WalletType.bank:
        return 'Bank / Rekening';
      case WalletType.ewallet:
        return 'Dompet Digital';
    }
  }
}

class WalletModel {
  WalletModel({
    required this.id,
    required this.name,
    required this.type,
    required this.initialBalance,
    required this.isDefault,
    required this.createdAt,
  });

  final String id;
  final String name;
  final WalletType type;
  /// Saldo awal saat dompet dibuat (tidak berubah setelah itu)
  final int initialBalance;
  final bool isDefault;
  final DateTime createdAt;

  WalletModel copyWith({
    String? name,
    WalletType? type,
    int? initialBalance,
    bool? isDefault,
  }) {
    return WalletModel(
      id: id,
      name: name ?? this.name,
      type: type ?? this.type,
      initialBalance: initialBalance ?? this.initialBalance,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': type.name,
        'initialBalance': initialBalance,
        'isDefault': isDefault,
        'createdAt': createdAt.toIso8601String(),
      };

  factory WalletModel.fromJson(Map<String, dynamic> json) {
    WalletType parseType(String? v) {
      switch (v) {
        case 'bank':
          return WalletType.bank;
        case 'ewallet':
          return WalletType.ewallet;
        default:
          return WalletType.cash;
      }
    }

    return WalletModel(
      id: json['id'] as String,
      name: json['name'] as String,
      type: parseType(json['type'] as String?),
      initialBalance: (json['initialBalance'] as num? ??
              json['initial_balance'] as num? ??
              0)
          .toInt(),
      isDefault: json['isDefault'] as bool? ??
          json['is_default'] as bool? ??
          false,
      createdAt: DateTime.tryParse(
              json['createdAt'] as String? ??
                  json['created_at'] as String? ??
                  '') ??
          DateTime.now(),
    );
  }
}
