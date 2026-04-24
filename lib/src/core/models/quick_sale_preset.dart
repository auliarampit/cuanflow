class QuickSalePreset {
  QuickSalePreset({
    required this.id,
    required this.name,
    required this.price,
    required this.category,
    this.note,
    this.walletId,
    this.outletId,
    this.sortOrder = 0,
  });

  final String id;
  final String name;
  final int price;
  final String category;
  final String? note;
  final String? walletId;
  final String? outletId;
  final int sortOrder;

  QuickSalePreset copyWith({
    String? name,
    int? price,
    String? category,
    String? note,
    String? walletId,
    String? outletId,
    int? sortOrder,
  }) {
    return QuickSalePreset(
      id: id,
      name: name ?? this.name,
      price: price ?? this.price,
      category: category ?? this.category,
      note: note ?? this.note,
      walletId: walletId ?? this.walletId,
      outletId: outletId ?? this.outletId,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'price': price,
        'category': category,
        'note': note,
        'walletId': walletId,
        'outletId': outletId,
        'sortOrder': sortOrder,
      };

  factory QuickSalePreset.fromJson(Map<String, dynamic> json) {
    return QuickSalePreset(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      price: (json['price'] as num? ?? json['sell_price'] as num? ?? 0).toInt(),
      category: json['category'] as String? ?? '',
      note: json['note'] as String?,
      walletId: json['walletId'] as String? ?? json['wallet_id'] as String?,
      outletId: json['outletId'] as String? ?? json['outlet_id'] as String?,
      sortOrder: (json['sortOrder'] as num? ?? json['sort_order'] as num? ?? 0).toInt(),
    );
  }
}
