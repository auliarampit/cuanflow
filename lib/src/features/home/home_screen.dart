import 'package:cari_untung/src/app/routes.dart';
import 'package:cari_untung/src/core/formatters/idr_formatter.dart';
import 'package:cari_untung/src/core/localization/transalation_extansions.dart';
import 'package:cari_untung/src/core/ui/responsive_utils.dart';
import 'package:flutter/material.dart';

import '../../core/state/app_state.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dynamic_colors.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../shared/widgets/native_ad_card.dart';

class _TotalBalanceCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final appState = context.appState;
    final total = appState.totalBalance;
    final wallets = appState.wallets;
    final isNeg = total < 0;
    final color = isNeg ? AppColors.negative : AppColors.brandBlue;
    final label = wallets.isEmpty
        ? context.t('home.noWalletBalance')
        : context.t('home.totalBalance');

    return GestureDetector(
      onTap: () => Navigator.of(context).pushNamed(AppRoutes.wallets),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              color.withValues(alpha: 0.75),
              color.withValues(alpha: 0.45),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    IdrFormatter.format(total),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (wallets.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: wallets.take(3).map((w) {
                        final bal = appState.balanceFor(w.id);
                        return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            '${w.name}: ${IdrFormatter.format(bal)}',
                            style: const TextStyle(
                                color: Colors.white, fontSize: 11),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.white70),
          ],
        ),
      ),
    );
  }
}

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
                  style: TextStyle(color: context.appColors.textSecondary),
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
    final profile = context.appState.profile;
    final displayName = profile.isBusinessMode && profile.businessName.isNotEmpty
        ? profile.businessName
        : profile.fullName.isNotEmpty
            ? profile.fullName
            : 'Kamu';
    final greeting = context.t('home.greeting', {'name': displayName});
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

    final isTablet = context.isTablet;

    final isBusiness = profile.isBusinessMode;
    final dailyCard = _buildProfitCard(
      title: dailySummary.netProfit < 0
          ? context.t(isBusiness ? 'home.todayLoss' : 'home.todayDeficit')
          : context.t(isBusiness ? 'home.todayProfit' : 'home.todayBalance'),
      currentProfit: dailySummary.netProfit,
      prevProfit: prevDailySummary.netProfit,
      comparisonLabel: 'vs ${context.t('home.yesterday')}',
    );

    final weeklyCard = _buildProfitCard(
      title: weeklySummary.netProfit < 0
          ? context.t(isBusiness ? 'home.weeklyLoss' : 'home.weeklyDeficit')
          : context.t(isBusiness ? 'home.weeklyProfit' : 'home.weeklyBalance'),
      currentProfit: weeklySummary.netProfit,
      prevProfit: prevWeeklySummary.netProfit,
      comparisonLabel: 'vs ${context.t('home.lastWeek')}',
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.brandBlue.withValues(alpha: 0.18),
                child: Text(
                  profile.fullName.isNotEmpty
                      ? profile.fullName[0].toUpperCase()
                      : profile.businessName.isNotEmpty
                          ? profile.businessName[0].toUpperCase()
                          : '?',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.brandBlue,
                  ),
                ),
              ),
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
                      style: TextStyle(color: context.appColors.textSecondary),
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
          if (isTablet)
            Row(
              children: [
                Expanded(child: dailyCard),
                const SizedBox(width: 12),
                Expanded(child: weeklyCard),
              ],
            )
          else ...[
            SizedBox(
              height: 190,
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) => setState(() => _currentPage = index),
                children: [dailyCard, weeklyCard],
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
                        : context.appColors.textSecondary.withValues(alpha: 0.3),
                  ),
                );
              }),
            ),
          ],
          const SizedBox(height: 14),
          if (!isBusiness) _TotalBalanceCard(),
          if (!isBusiness) const SizedBox(height: 14),
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
                                style: TextStyle(
                                  color: context.appColors.textSecondary,
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
                                style: TextStyle(
                                  color: context.appColors.textSecondary,
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
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: const NativeAdCard(templateType: TemplateType.small),
          ),
          const SizedBox(height: 14),
          // ── Low-stock alert (business only) ──────────────────────────
          if (isBusiness) ...[
            Builder(
              builder: (context) {
                final lowStock = context.appState.lowStockItems;
                if (lowStock.isEmpty) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: GestureDetector(
                    onTap: () =>
                        Navigator.of(context).pushNamed(AppRoutes.inventory),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: Colors.orange.withValues(alpha: 0.4)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.warning_amber_rounded,
                              color: Colors.orange, size: 18),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              context.t('home.lowStockAlert',
                                  {'count': '${lowStock.length}'}),
                              style: const TextStyle(
                                  color: Colors.orange,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600),
                            ),
                          ),
                          Icon(Icons.chevron_right,
                              color: Colors.orange.withValues(alpha: 0.7),
                              size: 18),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
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
          // ── Quick sale shortcut (business only) ──────────────────────
          if (isBusiness) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () =>
                    Navigator.of(context).pushNamed(AppRoutes.quickSale),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brandBlue,
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.point_of_sale),
                label: Text(context.t('home.quickSale')),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
