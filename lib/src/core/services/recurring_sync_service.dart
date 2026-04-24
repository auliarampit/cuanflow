import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/recurring_transaction_model.dart';

class RecurringSyncService {
  RecurringSyncService(this._supabase);

  final SupabaseClient _supabase;

  String? get _userId => _supabase.auth.currentUser?.id;

  Future<List<RecurringTransactionModel>> fetchAll() async {
    final uid = _userId;
    if (uid == null) return [];
    try {
      final rows = await _supabase
          .from('recurring_transactions')
          .select()
          .eq('user_id', uid)
          .order('created_at', ascending: false);
      return rows.map((r) => RecurringTransactionModel.fromJson(_toLocal(r))).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> upsert(RecurringTransactionModel r) async {
    final uid = _userId;
    if (uid == null) return;
    try {
      await _supabase.from('recurring_transactions').upsert(_toRemote(r, uid));
    } catch (_) {}
  }

  Future<void> delete(String id) async {
    try {
      await _supabase.from('recurring_transactions').delete().eq('id', id);
    } catch (_) {}
  }

  /// Snake_case → camelCase untuk fromJson model
  Map<String, dynamic> _toLocal(Map<String, dynamic> r) => {
        'id': r['id'],
        'name': r['name'],
        'amount': r['amount'],
        'category': r['category'],
        'type': r['type'],
        'frequency': r['frequency'],
        'isActive': r['is_active'],
        'createdAt': r['created_at'],
        'walletId': r['wallet_id'],
        'dayOfMonth': r['day_of_month'],
        'lastExecuted': r['last_executed'],
        'nextExecute': r['next_execute'],
      };

  Map<String, dynamic> _toRemote(RecurringTransactionModel r, String userId) => {
        'id': r.id,
        'user_id': userId,
        'name': r.name,
        'amount': r.amount,
        'category': r.category,
        'type': r.type.name,
        'frequency': r.frequency.name,
        'is_active': r.isActive,
        'created_at': r.createdAt.toIso8601String(),
        'wallet_id': r.walletId,
        'day_of_month': r.dayOfMonth,
        'last_executed': r.lastExecuted?.toIso8601String(),
        'next_execute': r.nextExecute?.toIso8601String(),
      };
}
