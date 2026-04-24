class InventoryItem {
  InventoryItem({
    required this.id,
    required this.name,
    required this.unit,
    required this.currentStock,
    required this.createdAt,
    this.minStock = 0,
    this.costPrice,
    this.sellPrice,
    this.category,
  });

  final String id;
  final String name;
  final String unit;
  final double currentStock;
  final double minStock;
  final int? costPrice;
  final int? sellPrice;
  final String? category;
  final DateTime createdAt;

  bool get isLowStock => currentStock <= minStock && minStock > 0;
  bool get isOutOfStock => currentStock <= 0;

  int? get marginPct {
    if (costPrice == null || sellPrice == null || costPrice! <= 0) return null;
    return (((sellPrice! - costPrice!) / costPrice!) * 100).round();
  }

  InventoryItem copyWith({
    String? name,
    String? unit,
    double? currentStock,
    double? minStock,
    int? costPrice,
    int? sellPrice,
    String? category,
    bool clearCostPrice = false,
    bool clearSellPrice = false,
  }) {
    return InventoryItem(
      id: id,
      name: name ?? this.name,
      unit: unit ?? this.unit,
      currentStock: currentStock ?? this.currentStock,
      minStock: minStock ?? this.minStock,
      costPrice: clearCostPrice ? null : (costPrice ?? this.costPrice),
      sellPrice: clearSellPrice ? null : (sellPrice ?? this.sellPrice),
      category: category ?? this.category,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'unit': unit,
        'currentStock': currentStock,
        'minStock': minStock,
        'costPrice': costPrice,
        'sellPrice': sellPrice,
        'category': category,
        'createdAt': createdAt.toIso8601String(),
      };

  factory InventoryItem.fromJson(Map<String, dynamic> json) {
    return InventoryItem(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      unit: json['unit'] as String? ?? 'pcs',
      currentStock: (json['currentStock'] as num? ??
              json['current_stock'] as num? ??
              0)
          .toDouble(),
      minStock:
          (json['minStock'] as num? ?? json['min_stock'] as num? ?? 0).toDouble(),
      costPrice: (json['costPrice'] as num? ?? json['cost_price'] as num?)?.toInt(),
      sellPrice: (json['sellPrice'] as num? ?? json['sell_price'] as num?)?.toInt(),
      category: json['category'] as String?,
      createdAt: DateTime.tryParse(
              json['createdAt'] as String? ??
                  json['created_at'] as String? ??
                  '') ??
          DateTime.now(),
    );
  }
}
