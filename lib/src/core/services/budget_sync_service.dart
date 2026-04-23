import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/budget_model.dart';
import '../models/money_transaction.dart';

class BudgetSyncService {
  BudgetSyncService(this._supabase);

  final SupabaseClient _supabase;

  Future<List<BudgetModel>> fetchBudgets(String userId) async {
    try {
      final response = await _supabase
          .from('budgets')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      return (response as List)
          .map((e) => _fromRow(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (e) {
      debugPrint('[BudgetSync] fetchBudgets failed: $e');
      return [];
    }
  }

  Future<void> upsertBudget(String userId, BudgetModel budget) async {
    await _supabase.from('budgets').upsert({
      'id': budget.id,
      'user_id': userId,
      'type': budget.type.name,
      'category_id': budget.categoryId,
      'target_amount': budget.targetAmount,
      'month_year': budget.monthYear,
      'created_at': budget.createdAt.toIso8601String(),
    });
  }

  Future<void> deleteBudget(String budgetId) async {
    await _supabase.from('budgets').delete().eq('id', budgetId);
  }

  static BudgetModel _fromRow(Map<String, dynamic> row) {
    return BudgetModel(
      id: row['id'] as String,
      type: MoneyTransactionType.values.firstWhere(
        (e) => e.name == row['type'],
        orElse: () => MoneyTransactionType.expense,
      ),
      categoryId: row['category_id'] as String?,
      targetAmount: (row['target_amount'] as num?)?.toInt() ?? 0,
      monthYear: row['month_year'] as String? ?? '',
      createdAt: DateTime.tryParse(row['created_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}
