import 'dart:math';

class BatchMaterial {
  final String rawMaterialId;
  final String rawMaterialName;
  final double quantity;
  final String unit;
  final double costPerUnit;

  double get totalCost => quantity * costPerUnit;

  BatchMaterial({
    required this.rawMaterialId,
    required this.rawMaterialName,
    required this.quantity,
    required this.unit,
    required this.costPerUnit,
  });

  Map<String, dynamic> toJson() => {
        'rawMaterialId': rawMaterialId,
        'rawMaterialName': rawMaterialName,
        'quantity': quantity,
        'unit': unit,
        'costPerUnit': costPerUnit,
      };

  factory BatchMaterial.fromJson(Map<String, dynamic> json) => BatchMaterial(
        rawMaterialId: json['rawMaterialId'] as String,
        rawMaterialName: json['rawMaterialName'] as String,
        quantity: (json['quantity'] as num).toDouble(),
        unit: json['unit'] as String? ?? '',
        costPerUnit: (json['costPerUnit'] as num).toDouble(),
      );
}

class ProductionBatch {
  final String id;
  final String productId;
  final String productName;
  final DateTime date;
  final double qtyProduced;
  final List<BatchMaterial> materialsUsed;
  final String? notes;
  final DateTime createdAt;

  double get totalMaterialCost =>
      materialsUsed.fold(0.0, (sum, m) => sum + m.totalCost);

  double get costPerUnit {
    if (qtyProduced <= 0) return 0;
    return totalMaterialCost / qtyProduced;
  }

  ProductionBatch({
    required this.id,
    required this.productId,
    required this.productName,
    required this.date,
    required this.qtyProduced,
    required this.materialsUsed,
    this.notes,
    required this.createdAt,
  });

  static String _generateId() =>
      DateTime.now().millisecondsSinceEpoch.toString() +
      Random().nextInt(1000).toString();

  factory ProductionBatch.create({
    required String productId,
    required String productName,
    required DateTime date,
    required double qtyProduced,
    required List<BatchMaterial> materialsUsed,
    String? notes,
  }) {
    return ProductionBatch(
      id: _generateId(),
      productId: productId,
      productName: productName,
      date: date,
      qtyProduced: qtyProduced,
      materialsUsed: materialsUsed,
      notes: notes,
      createdAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'productId': productId,
        'productName': productName,
        'date': date.toIso8601String(),
        'qtyProduced': qtyProduced,
        'materialsUsed': materialsUsed.map((m) => m.toJson()).toList(),
        'notes': notes,
        'createdAt': createdAt.toIso8601String(),
      };

  factory ProductionBatch.fromJson(Map<String, dynamic> json) =>
      ProductionBatch(
        id: json['id'] as String,
        productId: json['productId'] as String,
        productName: json['productName'] as String,
        date: DateTime.parse(json['date'] as String),
        qtyProduced: (json['qtyProduced'] as num).toDouble(),
        materialsUsed: (json['materialsUsed'] as List? ?? [])
            .map((m) => BatchMaterial.fromJson(m as Map<String, dynamic>))
            .toList(),
        notes: json['notes'] as String?,
        createdAt: DateTime.tryParse(
                json['createdAt'] as String? ??
                    json['created_at'] as String? ??
                    '') ??
            DateTime.now(),
      );
}
