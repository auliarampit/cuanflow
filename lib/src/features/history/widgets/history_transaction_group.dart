import 'package:cari_untung/src/shared/widgets/native_ad_card.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:intl/intl.dart';

import '../../../core/formatters/idr_formatter.dart';
import '../../../core/models/money_transaction.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dynamic_colors.dart';
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
    final dateString = DateFormat(
      'EEEE, d MMM yyyy',
      'id_ID',
    ).format(date).toUpperCase();

    // Calculate daily totals
    int dailyIncome = 0;
    int dailyExpense = 0;
    for (final tx in transactions) {
      if (tx.isIncome) {
        dailyIncome += tx.amount;
      } else {
        dailyExpense += tx.amount;
      }
    }
    final dailyNet = dailyIncome - dailyExpense;
    final isPositive = dailyNet >= 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _HistoryAdCard(),
        const SizedBox(height: 8),
        // Date header with daily summary
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: context.appColors.chipBg,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  dateString,
                  style: TextStyle(
                    color: context.appColors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              // Daily net amount
              Row(
                children: [
                  Icon(
                    isPositive
                        ? Icons.trending_up_rounded
                        : Icons.trending_down_rounded,
                    size: 13,
                    color: isPositive ? AppColors.positive : AppColors.negative,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${isPositive ? '+' : ''}${IdrFormatter.format(dailyNet)}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isPositive
                          ? AppColors.positive
                          : AppColors.negative,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: transactions.length,
          separatorBuilder: (_, i) => const SizedBox(height: 8),
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

class _HistoryAdCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(14)),
      clipBehavior: Clip.hardEdge,
      child: const NativeAdCard(templateType: TemplateType.small),
    );
  }
}
