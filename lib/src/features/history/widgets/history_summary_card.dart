import 'package:flutter/material.dart';

import '../../../core/formatters/idr_formatter.dart';
import '../../../core/localization/transalation_extansions.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dynamic_colors.dart';

class HistorySummaryCard extends StatelessWidget {
  const HistorySummaryCard({
    super.key,
    required this.totalIncome,
    required this.totalExpense,
    required this.totalProfit,
  });

  final int totalIncome;
  final int totalExpense;
  final int totalProfit;

  @override
  Widget build(BuildContext context) {
    final isProfit = totalProfit >= 0;
    final profitColor = isProfit ? AppColors.positive : AppColors.negative;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.appColors.cardSoft,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.appColors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Income & Expense row
          Row(
            children: [
              Expanded(
                child: _MiniStat(
                  icon: Icons.arrow_upward_rounded,
                  iconColor: AppColors.positive,
                  label: context.t('home.income'),
                  amount: IdrFormatter.format(totalIncome),
                  amountColor: AppColors.positive,
                ),
              ),
              Container(
                width: 1,
                height: 36,
                color: context.appColors.outline,
                margin: const EdgeInsets.symmetric(horizontal: 12),
              ),
              Expanded(
                child: _MiniStat(
                  icon: Icons.arrow_downward_rounded,
                  iconColor: AppColors.negative,
                  label: context.t('home.expense'),
                  amount: IdrFormatter.format(totalExpense),
                  amountColor: AppColors.negative,
                ),
              ),
            ],
          ),
          Divider(
            height: 20,
            color: context.appColors.outline,
          ),
          // Net profit row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: profitColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      isProfit
                          ? Icons.trending_up_rounded
                          : Icons.trending_down_rounded,
                      color: profitColor,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.t('history.summary.totalProfit'),
                        style: TextStyle(
                          color: context.appColors.textSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        IdrFormatter.format(totalProfit),
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: profitColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: profitColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isProfit ? 'Untung' : 'Rugi',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: profitColor,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.amount,
    required this.amountColor,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String amount;
  final Color amountColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor, size: 14),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
              Text(
                amount,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: amountColor,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
