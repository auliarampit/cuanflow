import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/space_model.dart';

class SpaceSyncService {
  SpaceSyncService(this._supabase);

  final SupabaseClient _supabase;

  String? get _userId => _supabase.auth.currentUser?.id;

  Future<List<SpaceModel>> fetchSpaces() async {
    final uid = _userId;
    if (uid == null) return [];
    try {
      final rows = await _supabase
          .from('spaces')
          .select()
          .eq('user_id', uid)
          .order('created_at', ascending: true);
      return rows.map((r) => SpaceModel.fromJson(r)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> upsertSpace(SpaceModel space) async {
    final uid = _userId;
    if (uid == null) return;
    try {
      await _supabase.from('spaces').upsert(_buildPayload(space, uid));
    } catch (_) {}
  }

  Future<void> deleteSpace(String id) async {
    try {
      await _supabase.from('spaces').delete().eq('id', id);
    } catch (_) {}
  }

  Map<String, dynamic> _buildPayload(SpaceModel s, String userId) => {
        'id': s.id,
        'user_id': userId,
        'type': s.type.name,
        'created_at': s.createdAt.toIso8601String(),
      };
}
