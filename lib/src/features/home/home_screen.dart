import 'package:cari_untung/src/app/routes.dart';
import 'package:cari_untung/src/core/formatters/idr_formatter.dart';
import 'package:cari_untung/src/core/localization/transalation_extansions.dart';
import 'package:flutter/material.dart';

import '../../core/state/app_state.dart';
import '../../core/theme/app_colors.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _goAddIncome(BuildContext context) {
    Navigator.of(context).pushNamed(AppRoutes.addIncome);
  }

  String _formatDate(DateTime date) {
    final days = [
      'Senin',
      'Selasa',
      'Rabu',
      'Kamis',
      'Jumat',
      'Sabtu',
      'Minggu'
    ];
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agust',
      'Sept',
      'Okt',
      'Nov',
      'Des'
    ];
    return '${days[date.weekday - 1]}, ${date.day} ${months[date.month - 1]} ${date.year}';
  }

  void _goAddExpense(BuildContext context) {
    Navigator.of(context).pushNamed(AppRoutes.addExpense);
  }

  void _goHistory(BuildContext context) {
    Navigator.of(context).pushNamed(AppRoutes.history);
  }

  @override
  Widget build(BuildContext context) {
    final greeting = context.t('home.greeting', {'name': 'GenZ Dimsum'});
    final dateLabel = _formatDate(DateTime.now());

    final summary = context.appState.summaryFor(DateRangeType.day);
    final prevSummary = context.appState.previousSummaryFor(DateRangeType.day);
    
    final income = summary.totalIncome;
    final expense = summary.totalExpense;
    final todayProfit = summary.netProfit;
    final prevProfit = prevSummary.netProfit;

    // Calculate percentage change
    double percentChange = 0;
    if (prevProfit != 0) {
      percentChange = ((todayProfit - prevProfit) / prevProfit.abs()) * 100;
    } else if (todayProfit != 0) {
      percentChange = 100;
    }

    final isProfitNegative = todayProfit < 0;
    final profitColor = isProfitNegative ? AppColors.negative : AppColors.positive;
    final profitIcon = isProfitNegative ? Icons.trending_down : Icons.trending_up;
    
    final deltaPrefix = percentChange >= 0 ? '+' : '';
    final deltaText = '$deltaPrefix${percentChange.toStringAsFixed(1)}% vs yesterday';

    return Padding(
      padding: EdgeInsets.fromLTRB(18, 18, 18, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(radius: 18, backgroundColor: AppColors.chipBg),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      greeting,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      dateLabel,
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () {
                  Navigator.of(context).pushNamed(AppRoutes.settings);
                },
                icon: const Icon(Icons.settings_outlined),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        context.t('home.todayProfit'),
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: profitColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          profitIcon,
                          color: profitColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    IdrFormatter.format(todayProfit),
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w800,
                      color: profitColor,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    deltaText,
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () {
                    Navigator.of(context).pushNamed(AppRoutes.history);
                  },
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.positive.withValues(
                                    alpha: 0.12,
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.arrow_upward,
                                  size: 18,
                                  color: AppColors.positive,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                context.t('home.income'),
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            IdrFormatter.format(income),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: InkWell(
                  onTap: () {
                    Navigator.of(context).pushNamed(AppRoutes.history);
                  },
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.negative.withValues(
                                    alpha: 0.12,
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.arrow_downward,
                                  size: 18,
                                  color: AppColors.negative,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                context.t('home.expense'),
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            IdrFormatter.format(expense),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _goAddIncome(context),
              icon: const Icon(Icons.add_circle_outline),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.positive,
                foregroundColor: Colors.black,
              ),
              label: Text(context.t('home.addIncome')),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _goAddExpense(context),
              icon: const Icon(Icons.remove_circle_outline),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.negative,
                foregroundColor: Colors.white,
              ),
              label: Text(context.t('home.addExpense')),
            ),
          ),
          const SizedBox(height: 10),
          Center(
            child: TextButton(
              onPressed: () => _goHistory(context),
              child: Text(context.t('home.viewHistory')),
            ),
          ),
        ],
      ),
    );
  }
}
