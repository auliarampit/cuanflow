import 'dart:math';

class ProductModel {
  final String id;
  final String name;
  final double yieldAmount; // Amount of units produced (e.g. 50 porsi)
  final String yieldUnit; // e.g. "porsi"
  final List<ProductIngredient> ingredients;
  final List<ProductCost> otherCosts;
  final double sellingPrice;

  ProductModel({
    required this.id,
    required this.name,
    required this.yieldAmount,
    required this.yieldUnit,
    required this.ingredients,
    required this.otherCosts,
    required this.sellingPrice,
  });

  static String _generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString() +
        Random().nextInt(1000).toString();
  }

  factory ProductModel.create({
    required String name,
    required double yieldAmount,
    required String yieldUnit,
    required List<ProductIngredient> ingredients,
    required List<ProductCost> otherCosts,
    required double sellingPrice,
  }) {
    return ProductModel(
      id: _generateId(),
      name: name,
      yieldAmount: yieldAmount,
      yieldUnit: yieldUnit,
      ingredients: ingredients,
      otherCosts: otherCosts,
      sellingPrice: sellingPrice,
    );
  }

  double get totalIngredientCost =>
      ingredients.fold(0, (sum, item) => sum + item.totalPrice);

  double get totalOtherCost =>
      otherCosts.fold(0, (sum, item) => sum + item.cost);

  double get totalProductionCost => totalIngredientCost + totalOtherCost;

  double get hppPerUnit {
    if (yieldAmount <= 0) return 0;
    return totalProductionCost / yieldAmount;
  }

  double get netProfitPerUnit => sellingPrice - hppPerUnit;

  double get marginPercentage {
    if (sellingPrice <= 0) return 0;
    return (netProfitPerUnit / sellingPrice) * 100;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'yieldAmount': yieldAmount,
      'yieldUnit': yieldUnit,
      'ingredients': ingredients.map((e) => e.toJson()).toList(),
      'otherCosts': otherCosts.map((e) => e.toJson()).toList(),
      'sellingPrice': sellingPrice,
    };
  }

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'] as String,
      name: json['name'] as String,
      yieldAmount: (json['yieldAmount'] as num).toDouble(),
      yieldUnit: json['yieldUnit'] as String,
      ingredients: (json['ingredients'] as List)
          .map((e) => ProductIngredient.fromJson(e))
          .toList(),
      otherCosts: (json['otherCosts'] as List)
          .map((e) => ProductCost.fromJson(e))
          .toList(),
      sellingPrice: (json['sellingPrice'] as num).toDouble(),
    );
  }
}

class ProductIngredient {
  final String id;
  final String name;
  final double quantity;
  final String unit;
  final double totalPrice;
  final String? note;

  String get amount =>
      "${quantity % 1 == 0 ? quantity.toInt() : quantity} $unit";

  ProductIngredient({
    required this.id,
    required this.name,
    required this.quantity,
    required this.unit,
    required this.totalPrice,
    this.note,
  });

  factory ProductIngredient.create({
    required String name,
    required double quantity,
    required String unit,
    required double totalPrice,
    String? note,
  }) {
    return ProductIngredient(
      id: ProductModel._generateId(),
      name: name,
      quantity: quantity,
      unit: unit,
      totalPrice: totalPrice,
      note: note,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'quantity': quantity,
      'unit': unit,
      'totalPrice': totalPrice,
      'note': note,
    };
  }

  factory ProductIngredient.fromJson(Map<String, dynamic> json) {
    return ProductIngredient(
      id: json['id'] as String,
      name: json['name'] as String,
      quantity: (json['quantity'] as num?)?.toDouble() ?? 0,
      unit: json['unit'] as String? ?? '',
      totalPrice: (json['totalPrice'] as num).toDouble(),
      note: json['note'] as String?,
    );
  }
}

class ProductCost {
  final String id;
  final String name;
  final double cost;

  ProductCost({
    required this.id,
    required this.name,
    required this.cost,
  });

  factory ProductCost.create({
    required String name,
    required double cost,
  }) {
    return ProductCost(
      id: ProductModel._generateId(),
      name: name,
      cost: cost,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'cost': cost,
    };
  }

  factory ProductCost.fromJson(Map<String, dynamic> json) {
    return ProductCost(
      id: json['id'] as String,
      name: json['name'] as String,
      cost: (json['cost'] as num).toDouble(),
    );
  }
}
