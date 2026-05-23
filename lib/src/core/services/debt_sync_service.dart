import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/debt_model.dart';

class DebtSyncService {
  DebtSyncService(this._supabase);

  final SupabaseClient _supabase;

  String? get _userId => _supabase.auth.currentUser?.id;

  Future<List<DebtModel>> fetchDebts({String? spaceId}) async {
    final uid = _userId;
    if (uid == null) return [];
    try {
      var query = _supabase.from('debts').select().eq('user_id', uid);
      if (spaceId != null && !spaceId.startsWith('space_')) {
        query = query.eq('space_id', spaceId);
      }
      final rows = await query.order('created_at', ascending: false);
      return rows.map((r) => DebtModel.fromJson(r)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> upsertDebt(DebtModel debt, {String? spaceId}) async {
    final uid = _userId;
    if (uid == null) return;
    try {
      await _supabase.from('debts').upsert(_buildPayload(debt, uid, spaceId: spaceId));
    } catch (_) {}
  }

  Future<void> deleteDebt(String id) async {
    try {
      await _supabase.from('debts').delete().eq('id', id);
    } catch (_) {}
  }

  Map<String, dynamic> _buildPayload(DebtModel d, String userId, {String? spaceId}) => {
        'id': d.id,
        'user_id': userId,
        'person_name': d.personName,
        'amount': d.amount,
        'type': d.type.name,
        'is_paid': d.isPaid,
        'notes': d.notes,
        'due_date': d.dueDate?.toIso8601String(),
        'created_at': d.createdAt.toIso8601String(),
        if (spaceId != null && !spaceId.startsWith('space_')) 'space_id': spaceId,
      };
}
