import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/wallet_model.dart';

class WalletSyncService {
  WalletSyncService(this._supabase);

  final SupabaseClient _supabase;

  String? get _userId => _supabase.auth.currentUser?.id;

  Future<List<WalletModel>> fetchWallets() async {
    final uid = _userId;
    if (uid == null) return [];
    try {
      final rows = await _supabase
          .from('wallets')
          .select()
          .eq('user_id', uid)
          .order('created_at');
      return rows.map((r) => WalletModel.fromJson(r)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<WalletModel?> insertWallet(WalletModel wallet) async {
    final uid = _userId;
    if (uid == null) return null;
    try {
      final rows = await _supabase
          .from('wallets')
          .insert(_buildPayload(wallet, uid))
          .select();
      if (rows.isEmpty) return null;
      return WalletModel.fromJson(rows.first);
    } catch (_) {
      return null;
    }
  }

  Future<void> updateWallet(WalletModel wallet) async {
    try {
      await _supabase
          .from('wallets')
          .update({
            'name': wallet.name,
            'type': wallet.type.name,
            'initial_balance': wallet.initialBalance,
            'is_default': wallet.isDefault,
          })
          .eq('id', wallet.id);
    } catch (_) {}
  }

  Future<void> deleteWallet(String id) async {
    try {
      await _supabase.from('wallets').delete().eq('id', id);
    } catch (_) {}
  }

  Map<String, dynamic> _buildPayload(WalletModel w, String userId) => {
        'id': w.id,
        'user_id': userId,
        'name': w.name,
        'type': w.type.name,
        'initial_balance': w.initialBalance,
        'is_default': w.isDefault,
        'created_at': w.createdAt.toIso8601String(),
      };
}
