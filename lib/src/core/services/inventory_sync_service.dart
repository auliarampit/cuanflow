import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/inventory_item.dart';

class InventorySyncService {
  InventorySyncService(this._supabase);

  final SupabaseClient _supabase;

  String? get _userId => _supabase.auth.currentUser?.id;

  Future<List<InventoryItem>> fetchAll() async {
    final uid = _userId;
    if (uid == null) return [];
    try {
      final rows = await _supabase
          .from('inventory_items')
          .select()
          .eq('user_id', uid)
          .order('name');
      return rows.map((r) => InventoryItem.fromJson(_toLocal(r))).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> upsert(InventoryItem item) async {
    final uid = _userId;
    if (uid == null) return;
    try {
      await _supabase.from('inventory_items').upsert(_toRemote(item, uid));
    } catch (_) {}
  }

  Future<void> delete(String id) async {
    try {
      await _supabase.from('inventory_items').delete().eq('id', id);
    } catch (_) {}
  }

  Map<String, dynamic> _toLocal(Map<String, dynamic> r) => {
        'id': r['id'],
        'name': r['name'],
        'unit': r['unit'],
        'currentStock': r['current_stock'],
        'minStock': r['min_stock'],
        'costPrice': r['cost_price'],
        'sellPrice': r['sell_price'],
        'category': r['category'],
        'createdAt': r['created_at'],
      };

  Map<String, dynamic> _toRemote(InventoryItem item, String userId) => {
        'id': item.id,
        'user_id': userId,
        'name': item.name,
        'unit': item.unit,
        'current_stock': item.currentStock,
        'min_stock': item.minStock,
        'cost_price': item.costPrice,
        'sell_price': item.sellPrice,
        'category': item.category,
        'created_at': item.createdAt.toIso8601String(),
      };
}
