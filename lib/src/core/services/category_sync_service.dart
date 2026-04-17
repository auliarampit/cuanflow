import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/user_category.dart';
import '../models/money_transaction.dart';

/// Handles read/write of custom categories to the `user_categories` Supabase table.
///
/// SQL migration (run once in Supabase SQL editor):
/// ```sql
/// create table if not exists public.user_categories (
///   id          text        primary key,
///   user_id     uuid        not null references auth.users(id) on delete cascade,
///   name        text        not null,
///   type        text        not null check (type in ('income','expense')),
///   created_at  timestamptz not null default now()
/// );
/// alter table public.user_categories enable row level security;
/// create policy "users_own_categories" on public.user_categories
///   for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
/// create index if not exists user_categories_user_id_idx
///   on public.user_categories(user_id);
/// ```
class CategorySyncService {
  CategorySyncService(this._client);
  final SupabaseClient _client;

  static const _table = 'user_categories';

  /// Fetch all custom categories for the current user from Supabase.
  Future<List<UserCategory>> fetchAll() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];

    final rows = await _client
        .from(_table)
        .select('id, name, type')
        .eq('user_id', userId)
        .order('created_at');

    return (rows as List)
        .map((row) => _fromRow(row as Map<String, dynamic>))
        .toList();
  }

  /// Insert or update a single category.
  Future<void> upsert(UserCategory category) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    await _client.from(_table).upsert({
      'id': category.id,
      'user_id': userId,
      'name': category.name,
      'type': category.type.name,
    });
  }

  /// Delete a category by id.
  Future<void> delete(String id) async {
    await _client.from(_table).delete().eq('id', id);
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  static UserCategory _fromRow(Map<String, dynamic> row) {
    return UserCategory(
      id: row['id'] as String,
      name: row['name'] as String,
      type: row['type'] == 'expense'
          ? MoneyTransactionType.expense
          : MoneyTransactionType.income,
    );
  }
}
