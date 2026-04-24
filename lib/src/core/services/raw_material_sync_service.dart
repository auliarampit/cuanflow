import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/raw_material_model.dart';

class RawMaterialSyncService {
  RawMaterialSyncService(this._supabase);

  final SupabaseClient _supabase;

  String? get _userId => _supabase.auth.currentUser?.id;

  Future<List<RawMaterial>> fetchAll() async {
    final uid = _userId;
    if (uid == null) return [];
    try {
      final rows = await _supabase
          .from('raw_materials')
          .select()
          .eq('user_id', uid)
          .order('name');
      return rows.map((r) => RawMaterial.fromJson(_toLocal(r))).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> upsert(RawMaterial item) async {
    final uid = _userId;
    if (uid == null) return;
    try {
      await _supabase.from('raw_materials').upsert(_toRemote(item, uid));
    } catch (_) {}
  }

  Future<void> delete(String id) async {
    try {
      await _supabase.from('raw_materials').delete().eq('id', id);
    } catch (_) {}
  }

  Map<String, dynamic> _toLocal(Map<String, dynamic> r) => {
        'id': r['id'],
        'name': r['name'],
        'unit': r['unit'],
        'currentStock': r['current_stock'],
        'minStock': r['min_stock'],
        'costPerUnit': r['cost_per_unit'],
        'supplierName': r['supplier_name'],
        'category': r['category'],
        'createdAt': r['created_at'],
      };

  Map<String, dynamic> _toRemote(RawMaterial item, String userId) => {
        'id': item.id,
        'user_id': userId,
        'name': item.name,
        'unit': item.unit,
        'current_stock': item.currentStock,
        'min_stock': item.minStock,
        'cost_per_unit': item.costPerUnit,
        'supplier_name': item.supplierName,
        'category': item.category,
        'created_at': item.createdAt.toIso8601String(),
      };
}
