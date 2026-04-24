import 'dart:math';

class RawMaterial {
  final String id;
  final String name;
  final String unit;
  final double currentStock;
  final double minStock;
  final double costPerUnit;
  final String? supplierName;
  final String? category;
  final DateTime createdAt;

  bool get isOutOfStock => currentStock <= 0;
  bool get isLowStock =>
      !isOutOfStock && minStock > 0 && currentStock <= minStock;

  RawMaterial({
    required this.id,
    required this.name,
    required this.unit,
    required this.currentStock,
    required this.minStock,
    required this.costPerUnit,
    this.supplierName,
    this.category,
    required this.createdAt,
  });

  static String _generateId() =>
      DateTime.now().millisecondsSinceEpoch.toString() +
      Random().nextInt(1000).toString();

  factory RawMaterial.create({
    required String name,
    required String unit,
    required double costPerUnit,
    double currentStock = 0,
    double minStock = 0,
    String? supplierName,
    String? category,
  }) {
    return RawMaterial(
      id: _generateId(),
      name: name,
      unit: unit,
      currentStock: currentStock,
      minStock: minStock,
      costPerUnit: costPerUnit,
      supplierName: supplierName,
      category: category,
      createdAt: DateTime.now(),
    );
  }

  RawMaterial copyWith({
    String? name,
    String? unit,
    double? currentStock,
    double? minStock,
    double? costPerUnit,
    String? supplierName,
    String? category,
  }) {
    return RawMaterial(
      id: id,
      name: name ?? this.name,
      unit: unit ?? this.unit,
      currentStock: currentStock ?? this.currentStock,
      minStock: minStock ?? this.minStock,
      costPerUnit: costPerUnit ?? this.costPerUnit,
      supplierName: supplierName ?? this.supplierName,
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
        'costPerUnit': costPerUnit,
        'supplierName': supplierName,
        'category': category,
        'createdAt': createdAt.toIso8601String(),
      };

  factory RawMaterial.fromJson(Map<String, dynamic> json) => RawMaterial(
        id: json['id'] as String,
        name: json['name'] as String,
        unit: json['unit'] as String? ?? '',
        currentStock: (json['currentStock'] as num?)?.toDouble() ?? 0,
        minStock: (json['minStock'] as num?)?.toDouble() ?? 0,
        costPerUnit: (json['costPerUnit'] as num?)?.toDouble() ?? 0,
        supplierName: json['supplierName'] as String?,
        category: json['category'] as String?,
        createdAt: DateTime.tryParse(
                json['createdAt'] as String? ??
                    json['created_at'] as String? ??
                    '') ??
            DateTime.now(),
      );
}
