import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/money_transaction.dart';
import '../models/outlet_model.dart';

class OutletSyncResult {
  const OutletSyncResult({
    required this.outlets,
    required this.transactions,
    this.selectedOutletId,
  });

  final List<OutletModel> outlets;
  final List<MoneyTransaction> transactions;
  final String? selectedOutletId;
}

class OutletService {
  OutletService(this._supabase);

  final SupabaseClient _supabase;

  /// Push pending outlets, update local references, then pull from server.
  Future<OutletSyncResult> syncOutlets({
    required List<OutletModel> outlets,
    required List<MoneyTransaction> transactions,
    required String userId,
    required String? selectedOutletId,
  }) async {
    var currentOutlets = [...outlets];
    var currentTransactions = [...transactions];
    var currentSelectedId = selectedOutletId;

    final pendingOutlets =
        outlets.where((o) => o.id.startsWith('outlet_')).toList();

    for (final outlet in pendingOutlets) {
      try {
        final response = await _supabase.from('outlets').insert({
          'user_id': userId,
          'name': outlet.name,
          'address': outlet.address,
          'is_default': outlet.isDefault,
        }).select().single();

        final serverOutlet = OutletModel.fromJson(
          Map<String, dynamic>.from(response as Map),
        );
        final oldId = outlet.id;

        // Replace local ID with server UUID in outlets + transactions
        currentOutlets = currentOutlets
            .map((o) => o.id == oldId ? serverOutlet : o)
            .toList();
        currentTransactions = currentTransactions.map((tx) {
          return tx.outletId == oldId
              ? tx.copyWith(outletId: serverOutlet.id)
              : tx;
        }).toList();
        if (currentSelectedId == oldId) currentSelectedId = serverOutlet.id;

        // Patch server transactions that were pushed without outlet_id
        await _patchMissingOutletId(
          transactions: currentTransactions,
          serverOutletId: serverOutlet.id,
          userId: userId,
        );
        debugPrint('[Sync] Outlet pushed: $oldId → ${serverOutlet.id}');
      } catch (e) {
        debugPrint('[Sync] Push pending outlet failed: $e');
      }
    }

    // Pull latest outlets from server
    try {
      final response = await _supabase
          .from('outlets')
          .select()
          .eq('user_id', userId)
          .order('created_at');
      currentOutlets = (response as List)
          .map((e) => OutletModel.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (e) {
      debugPrint('[Sync] Fetch outlets failed: $e');
    }

    return OutletSyncResult(
      outlets: currentOutlets,
      transactions: currentTransactions,
      selectedOutletId: currentSelectedId,
    );
  }

  Future<OutletModel?> addOnServer({
    required String name,
    required String? address,
    required bool isDefault,
    required String userId,
  }) async {
    final response = await _supabase.from('outlets').insert({
      'user_id': userId,
      'name': name,
      'address': address,
      'is_default': isDefault,
    }).select().single();
    return OutletModel.fromJson(Map<String, dynamic>.from(response as Map));
  }

  Future<void> updateOnServer(OutletModel outlet) => _supabase
      .from('outlets')
      .update({
        'name': outlet.name,
        'address': outlet.address,
        'is_default': outlet.isDefault,
      })
      .eq('id', outlet.id);

  Future<void> deleteFromServer(String outletId) =>
      _supabase.from('outlets').delete().eq('id', outletId);

  /// Update outlet_id on server for confirmed transactions that were pushed
  /// before their outlet was synced (outlet_id was omitted at insert time).
  Future<void> _patchMissingOutletId({
    required List<MoneyTransaction> transactions,
    required String serverOutletId,
    required String userId,
  }) async {
    final ids = transactions
        .where((tx) =>
            !tx.id.startsWith('tx_') && tx.outletId == serverOutletId)
        .map((tx) => tx.id)
        .toList();
    if (ids.isEmpty) return;

    try {
      await _supabase
          .from('transactions')
          .update({'outlet_id': serverOutletId})
          .eq('user_id', userId)
          .inFilter('id', ids);
      debugPrint(
        '[Sync] Patched outlet_id for ${ids.length} server transactions',
      );
    } catch (e) {
      debugPrint('[Sync] Patch outlet_id failed: $e');
    }
  }
}
