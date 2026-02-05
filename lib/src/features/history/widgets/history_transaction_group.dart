import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/models/money_transaction.dart';
import '../../../core/theme/app_colors.dart';
import 'history_transaction_item.dart';

class HistoryTransactionGroup extends StatelessWidget {
  const HistoryTransactionGroup({
    super.key,
    required this.date,
    required this.transactions,
    required this.onItemTap,
  });

  final DateTime date;
  final List<MoneyTransaction> transactions;
  final Function(MoneyTransaction) onItemTap;

  @override
  Widget build(BuildContext context) {
    final dateString = DateFormat('EEEE, d MMM', 'id_ID').format(date).toUpperCase();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(
            dateString,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
            ),
          ),
        ),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: transactions.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final tx = transactions[index];
            return HistoryTransactionItem(
              transaction: tx,
              onTap: () => onItemTap(tx),
            );
          },
        ),
      ],
    );
  }
}
