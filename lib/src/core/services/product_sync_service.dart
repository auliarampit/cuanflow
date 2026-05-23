import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/product_model.dart';

class ProductSyncService {
  ProductSyncService(this._supabase);

  final SupabaseClient _supabase;

  String? get _userId => _supabase.auth.currentUser?.id;

  Future<List<ProductModel>> fetchAll({String? spaceId}) async {
    final uid = _userId;
    if (uid == null) return [];
    try {
      var query = _supabase.from('products').select().eq('user_id', uid);
      if (spaceId != null && !spaceId.startsWith('space_')) {
        query = query.eq('space_id', spaceId);
      }
      final rows = await query.order('name');
      return rows.map((r) => ProductModel.fromJson(_toLocal(r))).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> upsert(ProductModel item, {String? spaceId}) async {
    final uid = _userId;
    if (uid == null) return;
    try {
      await _supabase.from('products').upsert(_toRemote(item, uid, spaceId: spaceId));
    } catch (_) {}
  }

  Future<void> delete(String id) async {
    try {
      await _supabase.from('products').delete().eq('id', id);
    } catch (_) {}
  }

  Map<String, dynamic> _toLocal(Map<String, dynamic> r) => {
        'id': r['id'],
        'name': r['name'],
        'yieldAmount': (r['yield_qty'] as num?)?.toDouble() ?? 1.0,
        'yieldUnit': r['yield_unit'] ?? 'Porsi',
        'sellingPrice': (r['selling_price'] as num?)?.toDouble() ?? 0.0,
        'ingredients': r['ingredients'] is String
            ? jsonDecode(r['ingredients'] as String)
            : r['ingredients'] ?? [],
        'otherCosts': r['other_costs'] is String
            ? jsonDecode(r['other_costs'] as String)
            : r['other_costs'] ?? [],
      };

  Map<String, dynamic> _toRemote(ProductModel item, String userId, {String? spaceId}) => {
        'id': item.id,
        'user_id': userId,
        'name': item.name,
        'yield_qty': item.yieldAmount,
        'yield_unit': item.yieldUnit,
        'selling_price': item.sellingPrice.round(),
        'ingredients': item.ingredients.map((e) => e.toJson()).toList(),
        'other_costs': item.otherCosts.map((e) => e.toJson()).toList(),
        if (spaceId != null && !spaceId.startsWith('space_')) 'space_id': spaceId,
      };
}
