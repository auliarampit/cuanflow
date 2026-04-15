import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/formatters/idr_formatter.dart';
import '../../../core/localization/transalation_extansions.dart';
import '../../../core/models/money_transaction.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dynamic_colors.dart';

class HistoryTransactionItem extends StatelessWidget {
  const HistoryTransactionItem({
    super.key,
    required this.transaction,
    required this.onTap,
  });

  final MoneyTransaction transaction;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isIncome = transaction.isIncome;
    final color = isIncome ? AppColors.positive : AppColors.negative;
    final icon = isIncome ? Icons.north_east : Icons.south_west;
    final amountPrefix = isIncome ? '+' : '-';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: context.appColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.appColors.outline.withOpacity(0.5)),
        ),
        child: Row(
          children: [
            // Icon Circle
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: context.appColors.cardSoft,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 16),

            // Title & Time
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.t(
                      transaction.category ??
                          (isIncome
                              ? 'history.transaction.income'
                              : 'history.transaction.expense'),
                    ),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: context.appColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  if (transaction.note != null &&
                      transaction.note!.isNotEmpty) ...[
                    Text(
                      transaction.note!,
                      style: TextStyle(
                        fontSize: 12,
                        color: context.appColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                  ],
                  Text(
                    DateFormat('HH:mm').format(transaction.createdAt.toLocal()),
                    style: TextStyle(
                      fontSize: 12,
                      color: context.appColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            // Amount
            Text(
              '$amountPrefix${IdrFormatter.format(transaction.amount)}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isIncome ? AppColors.positive : context.appColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
