import 'package:cari_untung/src/app/routes.dart';
import 'package:cari_untung/src/core/formatters/idr_formatter.dart';
import 'package:cari_untung/src/core/localization/transalation_extansions.dart';
import 'package:flutter/material.dart';

import '../../core/state/app_state.dart';
import '../../core/theme/app_colors.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goAddIncome() {
    Navigator.of(context).pushNamed(AppRoutes.addIncome);
  }

  void _goAddExpense() {
    Navigator.of(context).pushNamed(AppRoutes.addExpense);
  }

  void _goHistory() {
    Navigator.of(context).pushNamed(AppRoutes.history);
  }

  String _formatDate(DateTime date) {
    final days = [
      'Senin',
      'Selasa',
      'Rabu',
      'Kamis',
      'Jumat',
      'Sabtu',
      'Minggu',
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
      'Des',
    ];
    return '${days[date.weekday - 1]}, ${date.day} ${months[date.month - 1]} ${date.year}';
  }

  Widget _buildProfitCard({
    required String title,
    required int currentProfit,
    required int prevProfit,
    required String comparisonLabel,
  }) {
    // Calculate percentage change
    double percentChange = 0;
    if (prevProfit != 0) {
      percentChange = ((currentProfit - prevProfit) / prevProfit.abs()) * 100;
    } else if (currentProfit != 0) {
      percentChange = currentProfit > 0 ? 100 : -100;
    }

    final isProfitNegative = currentProfit < 0;
    // Value Color: Red if loss, Positive (Green) if profit
    final profitColor = isProfitNegative
        ? AppColors.negative
        : AppColors.positive;
    final profitIcon = isProfitNegative
        ? Icons.trending_down
        : Icons.trending_up;

    // Trend Color: Red if declined, Positive (Green) if growth
    final isTrendNegative = percentChange < 0;
    final trendColor = isTrendNegative
        ? AppColors.negative
        : AppColors.positive;

    final deltaPrefix = percentChange > 0 ? '+' : '';
    final deltaText =
        '$deltaPrefix${percentChange.toStringAsFixed(1)}% $comparisonLabel';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  title,
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: profitColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(profitIcon, color: profitColor),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              IdrFormatter.format(currentProfit),
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.w800,
                color: profitColor,
              ),
            ),
            const SizedBox(height: 6),
            Text(deltaText, style: TextStyle(color: trendColor)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final greeting = context.t('home.greeting', {'name': 'GenZ Dimsum'});
    final dateLabel = _formatDate(DateTime.now());

    final dailySummary = context.appState.summaryFor(DateRangeType.day);
    final prevDailySummary = context.appState.previousSummaryFor(
      DateRangeType.day,
    );

    final weeklySummary = context.appState.summaryFor(DateRangeType.week);
    final prevWeeklySummary = context.appState.previousSummaryFor(
      DateRangeType.week,
    );

    final income = dailySummary.totalIncome;
    final expense = dailySummary.totalExpense;

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
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
          SizedBox(
            height: 190,
            child: PageView(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                });
              },
              children: [
                _buildProfitCard(
                  title: dailySummary.netProfit < 0
                      ? context.t('home.todayLoss')
                      : context.t('home.todayProfit'),
                  currentProfit: dailySummary.netProfit,
                  prevProfit: prevDailySummary.netProfit,
                  comparisonLabel: 'vs ${context.t('home.yesterday')}',
                ),
                _buildProfitCard(
                  title: weeklySummary.netProfit < 0
                      ? context.t('home.weeklyLoss')
                      : context.t('home.weeklyProfit'),
                  currentProfit: weeklySummary.netProfit,
                  prevProfit: prevWeeklySummary.netProfit,
                  comparisonLabel: 'vs ${context.t('home.lastWeek')}',
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(2, (index) {
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _currentPage == index
                      ? AppColors.positive
                      : AppColors.textSecondary.withOpacity(0.3),
                ),
              );
            }),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: _goHistory,
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
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            IdrFormatter.format(income),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
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
                  onTap: _goHistory,
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
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            IdrFormatter.format(expense),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
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
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _goAddIncome,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.positive,
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.add),
              label: Text(context.t('home.addIncome')),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _goAddExpense,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.negative,
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.remove),
              label: Text(context.t('home.addExpense')),
            ),
          ),
          const SizedBox(height: 10),
          Center(
            child: TextButton(
              onPressed: _goHistory,
              child: Text(context.t('home.viewHistory')),
            ),
          ),
        ],
      ),
    );
  }
}
