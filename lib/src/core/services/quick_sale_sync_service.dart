import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/quick_sale_preset.dart';

class QuickSaleSyncService {
  QuickSaleSyncService(this._supabase);

  final SupabaseClient _supabase;

  String? get _userId => _supabase.auth.currentUser?.id;

  Future<List<QuickSalePreset>> fetchAll({String? spaceId}) async {
    final uid = _userId;
    if (uid == null) return [];
    try {
      var query = _supabase.from('quick_sale_presets').select().eq('user_id', uid);
      if (spaceId != null && !spaceId.startsWith('space_')) {
        query = query.eq('space_id', spaceId);
      }
      final rows = await query.order('sort_order');
      return rows.map((r) => QuickSalePreset.fromJson(_toLocal(r))).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> upsert(QuickSalePreset p, {String? spaceId}) async {
    final uid = _userId;
    if (uid == null) return;
    try {
      await _supabase.from('quick_sale_presets').upsert(_toRemote(p, uid, spaceId: spaceId));
    } catch (_) {}
  }

  Future<void> delete(String id) async {
    try {
      await _supabase.from('quick_sale_presets').delete().eq('id', id);
    } catch (_) {}
  }

  Map<String, dynamic> _toLocal(Map<String, dynamic> r) => {
        'id': r['id'],
        'name': r['name'],
        'price': r['sell_price'],
        'category': r['category'],
        'note': r['note'],
        'walletId': r['wallet_id'],
        'outletId': r['outlet_id'],
        'sortOrder': r['sort_order'],
      };

  Map<String, dynamic> _toRemote(QuickSalePreset p, String userId, {String? spaceId}) => {
        'id': p.id,
        'user_id': userId,
        'name': p.name,
        'sell_price': p.price,
        'category': p.category,
        'note': p.note,
        'wallet_id': p.walletId,
        'outlet_id': p.outletId,
        'sort_order': p.sortOrder,
        if (spaceId != null && !spaceId.startsWith('space_')) 'space_id': spaceId,
      };
}
