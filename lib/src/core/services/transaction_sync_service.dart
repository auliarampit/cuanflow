import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/money_transaction.dart';

class TransactionSyncService {
  TransactionSyncService(this._supabase);

  final SupabaseClient _supabase;

  static final _supabaseUuid = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  );

  static bool isPending(MoneyTransaction tx) => tx.id.startsWith('tx_');
  static bool isConfirmed(String id) => _supabaseUuid.hasMatch(id);

  /// One-time migration: tag old non-UUID IDs as pending so they get pushed.
  List<MoneyTransaction> migrateOldIds(List<MoneyTransaction> transactions) {
    var migrated = false;
    final result = transactions.map((tx) {
      if (tx.id.startsWith('tx_')) return tx;
      if (_supabaseUuid.hasMatch(tx.id)) return tx;
      migrated = true;
      return tx.copyWith(id: 'tx_${tx.id}');
    }).toList();
    if (migrated) {
      debugPrint('[Migration] Transaksi lama ditandai sebagai pending sync');
    }
    return result;
  }

  /// Push all pending (tx_*) transactions to server.
  /// [onSuccess] is awaited after each successful push for incremental UI updates.
  /// [onError] is called with a readable message on individual failure.
  Future<void> pushPending({
    required List<MoneyTransaction> transactions,
    required String userId,
    required Future<void> Function(MoneyTransaction local, MoneyTransaction confirmed)
        onSuccess,
    required void Function(String error) onError,
  }) async {
    final pending = transactions.where(isPending).toList();
    debugPrint('[Sync] Push pending: ${pending.length} transaksi...');

    for (final tx in pending) {
      try {
        final response = await _supabase
            .from('transactions')
            .insert(_buildPayload(tx, userId))
            .select()
            .single();

        final confirmed = MoneyTransaction.fromJson(
          Map<String, dynamic>.from(response as Map),
        );
        debugPrint('[Sync] Push OK: ${tx.id} → ${confirmed.id}');
        await onSuccess(tx, confirmed);
      } catch (e) {
        debugPrint('[Sync] Push GAGAL untuk ${tx.id}: $e');
        onError(extractErrorMessage(e));
      }
    }
  }

  /// Pull from server and merge with local pending transactions.
  /// Server data is source of truth for confirmed transactions.
  Future<List<MoneyTransaction>> pullAndMerge({
    required List<MoneyTransaction> local,
    required String userId,
  }) async {
    final response = await _supabase
        .from('transactions')
        .select()
        .eq('user_id', userId)
        .order('effective_date', ascending: false);

    final remote = (response as List)
        .map((e) => MoneyTransaction.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();

    final pending = local.where(isPending).toList();
    return [...remote, ...pending]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<void> deleteFromServer(String id, String userId) => _supabase
      .from('transactions')
      .delete()
      .eq('id', id)
      .eq('user_id', userId);

  Future<void> updateOnServer(MoneyTransaction tx, String userId) {
    final payload = _buildPayload(tx, userId)..remove('user_id');
    return _supabase
        .from('transactions')
        .update(payload)
        .eq('id', tx.id)
        .eq('user_id', userId);
  }

  Map<String, dynamic> _buildPayload(MoneyTransaction tx, String userId) {
    return {
      'user_id': userId,
      'type': tx.type.name,
      'amount': tx.amount,
      'category': tx.category,
      'note': tx.note,
      'effective_date': tx.effectiveDate.toIso8601String(),
      // Only include outlet_id if it's a server UUID — prevents FK violation
      if (tx.outletId != null && !tx.outletId!.startsWith('outlet_'))
        'outlet_id': tx.outletId,
    };
  }

  String extractErrorMessage(Object e) {
    final raw = e.toString();
    final match = RegExp(r'message:\s*([^,\)]+)').firstMatch(raw);
    if (match != null) return match.group(1)!.trim();
    return raw.length > 120 ? '${raw.substring(0, 120)}...' : raw;
  }
}
