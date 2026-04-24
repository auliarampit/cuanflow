import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/production_batch_model.dart';

class ProductionBatchSyncService {
  ProductionBatchSyncService(this._supabase);

  final SupabaseClient _supabase;

  String? get _userId => _supabase.auth.currentUser?.id;

  Future<List<ProductionBatch>> fetchAll() async {
    final uid = _userId;
    if (uid == null) return [];
    try {
      final rows = await _supabase
          .from('production_batches')
          .select()
          .eq('user_id', uid)
          .order('date', ascending: false);
      return rows.map((r) => ProductionBatch.fromJson(_toLocal(r))).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> upsert(ProductionBatch batch) async {
    final uid = _userId;
    if (uid == null) return;
    try {
      await _supabase
          .from('production_batches')
          .upsert(_toRemote(batch, uid));
    } catch (_) {}
  }

  Future<void> delete(String id) async {
    try {
      await _supabase.from('production_batches').delete().eq('id', id);
    } catch (_) {}
  }

  Map<String, dynamic> _toLocal(Map<String, dynamic> r) => {
        'id': r['id'],
        'productId': r['product_id'],
        'productName': r['product_name'],
        'date': r['date'],
        'qtyProduced': r['qty_produced'],
        'materialsUsed': r['materials_used'] is String
            ? jsonDecode(r['materials_used'] as String)
            : r['materials_used'] ?? [],
        'notes': r['notes'],
        'createdAt': r['created_at'],
      };

  Map<String, dynamic> _toRemote(ProductionBatch batch, String userId) => {
        'id': batch.id,
        'user_id': userId,
        'product_id': batch.productId,
        'product_name': batch.productName,
        'date': batch.date.toIso8601String(),
        'qty_produced': batch.qtyProduced,
        'materials_used':
            jsonEncode(batch.materialsUsed.map((m) => m.toJson()).toList()),
        'notes': batch.notes,
        'created_at': batch.createdAt.toIso8601String(),
      };
}
