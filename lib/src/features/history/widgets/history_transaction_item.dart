import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/formatters/idr_formatter.dart';
import '../../../core/localization/transalation_extansions.dart';
import '../../../core/models/money_transaction.dart';
import '../../../core/state/app_state.dart';
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
    final icon = isIncome ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded;
    final amountPrefix = isIncome ? '+' : '-';

    // Resolve outlet name
    final outletName = transaction.outletId == null
        ? null
        : context.appState.outlets
            .where((o) => o.id == transaction.outletId)
            .map((o) => o.name)
            .firstOrNull;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: context.appColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.appColors.outline.withValues(alpha: 0.5)),
        ),
        child: Row(
          children: [
            // Icon Circle
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),

            // Title, Note & Meta
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category
                  Text(
                    context.t(
                      transaction.category ??
                          (isIncome
                              ? 'history.transaction.income'
                              : 'history.transaction.expense'),
                    ),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: context.appColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (transaction.note != null &&
                      transaction.note!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      transaction.note!,
                      style: TextStyle(
                        fontSize: 12,
                        color: context.appColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 4),
                  // Meta row: time · outlet
                  Row(
                    children: [
                      Icon(Icons.access_time_rounded,
                          size: 11,
                          color: context.appColors.textSecondary),
                      const SizedBox(width: 3),
                      Text(
                        DateFormat('HH:mm').format(
                            transaction.effectiveDate.toLocal()),
                        style: TextStyle(
                          fontSize: 11,
                          color: context.appColors.textSecondary,
                        ),
                      ),
                      if (outletName != null) ...[
                        Text(
                          '  ·  ',
                          style: TextStyle(
                              fontSize: 11,
                              color: context.appColors.textSecondary),
                        ),
                        Icon(Icons.storefront_outlined,
                            size: 11,
                            color: context.appColors.textSecondary),
                        const SizedBox(width: 3),
                        Flexible(
                          child: Text(
                            outletName,
                            style: TextStyle(
                              fontSize: 11,
                              color: context.appColors.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            // Amount
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$amountPrefix${IdrFormatter.format(transaction.amount)}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
                const SizedBox(height: 2),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    isIncome ? 'IN' : 'OUT',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: color,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
