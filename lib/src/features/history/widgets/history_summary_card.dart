import 'package:flutter/material.dart';

import '../../../core/formatters/idr_formatter.dart';
import '../../../core/localization/transalation_extansions.dart';
import '../../../core/theme/app_colors.dart';

class HistorySummaryCard extends StatelessWidget {
  const HistorySummaryCard({
    super.key,
    required this.totalProfit,
    this.percentageChange,
  });

  final int totalProfit;
  final double? percentageChange;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardSoft,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outline),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.t('history.summary.totalProfit'),
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                IdrFormatter.format(totalProfit),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          if (percentageChange != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: percentageChange! >= 0
                    ? AppColors.positive.withOpacity(0.2)
                    : AppColors.negative.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    percentageChange! >= 0 ? Icons.arrow_upward : Icons.arrow_downward,
                    size: 14,
                    color: percentageChange! >= 0 ? AppColors.positive : AppColors.negative,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${percentageChange!.abs().toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: percentageChange! >= 0 ? AppColors.positive : AppColors.negative,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
