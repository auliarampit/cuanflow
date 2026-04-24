import 'package:cari_untung/src/shared/widgets/loading_dialog.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/formatters/idr_formatter.dart';
import '../../core/localization/transalation_extansions.dart';
import '../../core/models/money_transaction.dart';
import '../../core/services/report_pdf_service.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dynamic_colors.dart';
import 'widgets/monthly_bar_chart.dart';
import 'widgets/outlet_contribution_chart.dart';
import 'widgets/outlet_trend_chart.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  DateTime _selectedDate = DateTime.now();

  void _changeMonth(int offset) {
    setState(() {
      _selectedDate = DateTime(
        _selectedDate.year,
        _selectedDate.month + offset,
        15,
      );
    });
  }

  String _formatMonth(DateTime date) {
    final localeCode = context.appState.settings.localeCode;
    final locale = localeCode == 'en' ? 'en_US' : 'id_ID';
    return DateFormat('MMMM yyyy', locale).format(date);
  }

  void _exportPdf() async {
    final locale = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text(context.t('history.exportPdf')),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, 'id'),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(context.t('report.exportLangId')),
            ),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, 'en'),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(context.t('report.exportLangEn')),
            ),
          ),
        ],
      ),
    );

    if (locale == null) return;

    if (!mounted) return;
    LoadingDialog.show(context);
    final appState = context.appState;
    final summary = appState.summaryForDate(DateRangeType.month, _selectedDate);
    final history = appState.historyForDate(DateRangeType.month, _selectedDate);
    final profile = appState.profile;
    final monthName = _formatMonth(_selectedDate);

    await ReportPdfService().generateAndShowPdf(
      monthName,
      summary,
      history,
      profile,
      locale: locale,
      outlets: appState.outlets,
      selectedOutletId: appState.selectedOutletId,
    );

    if (mounted) LoadingDialog.hide(context);
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.appState;
    final selectedOutlet = appState.selectedOutlet;

    final summary = appState.summaryForDate(DateRangeType.month, _selectedDate);
    final prevDate =
        DateTime(_selectedDate.year, _selectedDate.month - 1, 15);
    final prevSummary =
        appState.summaryForDate(DateRangeType.month, prevDate);

    final totalIncome = summary.totalIncome;
    final totalExpense = summary.totalExpense;
    final netProfit = summary.netProfit;

    double? pctChange(int current, int previous) {
      if (previous == 0) return null;
      return ((current - previous) / previous.abs()) * 100;
    }

    final incomePct = pctChange(totalIncome, prevSummary.totalIncome);
    final profitPct = pctChange(netProfit, prevSummary.netProfit);

    final history = appState.historyForDate(DateRangeType.month, _selectedDate);

    // Group history by date for display
    final Map<DateTime, List<MoneyTransaction>> grouped = {};
    for (final tx in history) {
      final key = DateTime(
          tx.effectiveDate.year, tx.effectiveDate.month, tx.effectiveDate.day);
      grouped.putIfAbsent(key, () => []).add(tx);
    }
    final sortedDates = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    return SafeArea(
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Header ─────────────────────────────────────────────
                  Center(
                    child: Text(
                      context.t('report.titleMonthly'),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: context.appColors.textPrimary,
                      ),
                    ),
                  ),
                  if (selectedOutlet != null) ...[
                    const SizedBox(height: 6),
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.brandBlue.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                              color:
                                  AppColors.brandBlue.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.storefront_outlined,
                                size: 14, color: AppColors.brandBlue),
                            const SizedBox(width: 6),
                            Text(
                              selectedOutlet.name,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.brandBlue,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 20),

                  // ── Month navigation ────────────────────────────────────
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: context.appColors.cardSoft,
                      borderRadius: BorderRadius.circular(14),
                      border:
                          Border.all(color: context.appColors.outline),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          onPressed: () => _changeMonth(-1),
                          icon: Icon(Icons.chevron_left,
                              color: context.appColors.textSecondary),
                          visualDensity: VisualDensity.compact,
                        ),
                        Text(
                          _formatMonth(_selectedDate),
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: context.appColors.textPrimary,
                          ),
                        ),
                        IconButton(
                          onPressed: () => _changeMonth(1),
                          icon: Icon(Icons.chevron_right,
                              color: context.appColors.textSecondary),
                          visualDensity: VisualDensity.compact,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── Summary cards (di atas chart agar langsung terlihat) ──
                  Row(
                    children: [
                      Expanded(
                        child: _SummaryCard(
                          title: context.t('report.totalIncomeTitle'),
                          amount: IdrFormatter.format(totalIncome),
                          pctChange: incomePct,
                          accentColor: AppColors.positive,
                          icon: Icons.arrow_upward_rounded,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _SummaryCard(
                          title: context.t('report.totalExpenseTitle'),
                          amount: IdrFormatter.format(totalExpense),
                          ratioLabel: totalIncome > 0
                              ? '${((totalExpense / totalIncome) * 100).toStringAsFixed(1)}% ${context.t('report.ofIncome')}'
                              : null,
                          accentColor: AppColors.negative,
                          icon: Icons.arrow_downward_rounded,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _NetProfitCard(
                    amount: IdrFormatter.format(netProfit),
                    pctChange: profitPct,
                    isPositive: netProfit >= 0,
                  ),

                  // ── Budget bulan ini (hanya jika fitur aktif & ada budget) ─
                  if (appState.profile.featureBudget) ...[
                    const SizedBox(height: 16),
                    _BudgetSection(
                      budgets: appState.budgetsFor(_selectedDate),
                      appState: appState,
                    ),
                  ],

                  const SizedBox(height: 16),

                  // ── Bar chart dengan toggle harian/mingguan/bulanan ──────
                  MonthlyBarChart(
                    selectedDate: _selectedDate,
                    appState: appState,
                  ),

                  // ── Outlet charts (hanya saat Semua Outlet + ≥2 outlet) ─
                  if (selectedOutlet == null && appState.outlets.length >= 2) ...[
                    const SizedBox(height: 12),
                    OutletTrendChart(
                      outlets: appState.outlets,
                      selectedDate: _selectedDate,
                      appState: appState,
                      title: context.t('report.outletTrend'),
                    ),
                    const SizedBox(height: 12),
                    OutletContributionChart(
                      outlets: appState.outlets,
                      transactions: history,
                      title: context.t('report.outletContribution'),
                      subtitle: context.t('report.outletContributionSubtitle'),
                      otherLabel: context.t('report.outletOther'),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // ── Transaction detail header ───────────────────────────
                  Row(
                    children: [
                      Container(
                        width: 4,
                        height: 18,
                        decoration: BoxDecoration(
                          color: AppColors.brandBlue,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        context.t('report.transactionDetailsTitle'),
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: context.appColors.textPrimary,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.brandBlue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          context.t('report.transactionCount', {'count': '${history.length}'}),
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.brandBlue,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  if (history.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 32),
                        child: Text(
                          context.t('report.emptyMonth'),
                          style: TextStyle(
                              color: context.appColors.textSecondary),
                        ),
                      ),
                    )
                  else
                    ...sortedDates.map((date) {
                      final txs = grouped[date]!;
                      return _DaySection(date: date, transactions: txs);
                    }),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),

          // ── Export button ───────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 12),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _exportPdf,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.brandBlue,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: BorderSide(
                      color: AppColors.brandBlue.withValues(alpha: 0.5)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: const Icon(Icons.picture_as_pdf_outlined),
                label: Text(context.t('history.exportPdf'),
                    style: const TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Summary Card (Income / Expense) ──────────────────────────────────────
class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.title,
    required this.amount,
    required this.accentColor,
    required this.icon,
    this.pctChange,
    this.ratioLabel,
  });

  final String title;
  final String amount;
  final double? pctChange;
  final String? ratioLabel;
  final Color accentColor;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final changeIsPositive = (pctChange ?? 0) >= 0;
    final changeColor = changeIsPositive ? AppColors.positive : AppColors.negative;

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Left accent strip
            Container(width: 4, color: accentColor),
            // Content
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: context.appColors.card,
                  border: Border.all(color: context.appColors.outline),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: accentColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(icon, color: accentColor, size: 15),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            title,
                            style: TextStyle(
                              fontSize: 11,
                              color: context.appColors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      amount,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: context.appColors.textPrimary,
                      ),
                    ),
                    if (ratioLabel != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        ratioLabel!,
                        style: TextStyle(
                          fontSize: 10,
                          color: context.appColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ] else if (pctChange != null) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            changeIsPositive
                                ? Icons.arrow_upward_rounded
                                : Icons.arrow_downward_rounded,
                            size: 11,
                            color: changeColor,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            '${pctChange!.abs().toStringAsFixed(1)}% ${context.t('report.vsLastMonth')}',
                            style: TextStyle(
                              fontSize: 10,
                              color: changeColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Net Profit Card ────────────────────────────────────────────────────────
class _NetProfitCard extends StatelessWidget {
  const _NetProfitCard({
    required this.amount,
    required this.pctChange,
    required this.isPositive,
  });

  final String amount;
  final double? pctChange;
  final bool isPositive;

  @override
  Widget build(BuildContext context) {
    final accentColor = isPositive ? AppColors.positive : AppColors.negative;
    final changeIsPositive = (pctChange ?? 0) >= 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            accentColor.withValues(alpha: 0.12),
            accentColor.withValues(alpha: 0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accentColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isPositive
                  ? Icons.trending_up_rounded
                  : Icons.trending_down_rounded,
              color: accentColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.t('report.netProfitTitle'),
                  style: TextStyle(
                    fontSize: 12,
                    color: context.appColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  amount,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: accentColor,
                  ),
                ),
              ],
            ),
          ),
          if (pctChange != null)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: (changeIsPositive ? AppColors.positive : AppColors.negative)
                    .withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Icon(
                    changeIsPositive
                        ? Icons.arrow_upward_rounded
                        : Icons.arrow_downward_rounded,
                    size: 13,
                    color: changeIsPositive
                        ? AppColors.positive
                        : AppColors.negative,
                  ),
                  Text(
                    '${pctChange!.abs().toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: changeIsPositive
                          ? AppColors.positive
                          : AppColors.negative,
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

// ─── Day section ─────────────────────────────────────────────────────────────
class _DaySection extends StatelessWidget {
  const _DaySection({
    required this.date,
    required this.transactions,
  });

  final DateTime date;
  final List<MoneyTransaction> transactions;

  @override
  Widget build(BuildContext context) {
    final dateStr =
        DateFormat('EEEE, d MMMM', 'id_ID').format(date);
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
        // Day header
        Padding(
          padding: const EdgeInsets.only(bottom: 8, top: 4),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  dateStr,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: context.appColors.textSecondary,
                  ),
                ),
              ),
              Text(
                '${isPositive ? '+' : ''}${IdrFormatter.format(dailyNet)}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isPositive ? AppColors.positive : AppColors.negative,
                ),
              ),
            ],
          ),
        ),
        // Transaction rows
        Container(
          decoration: BoxDecoration(
            color: context.appColors.card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: context.appColors.outline),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: transactions.length,
            separatorBuilder: (_, i) =>
                Divider(height: 1, color: context.appColors.outline),
            itemBuilder: (context, index) {
              final tx = transactions[index];
              return _ReportRow(transaction: tx);
            },
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}

// ─── Report Row ───────────────────────────────────────────────────────────────
class _ReportRow extends StatelessWidget {
  const _ReportRow({required this.transaction});

  final MoneyTransaction transaction;

  @override
  Widget build(BuildContext context) {
    final isIncome = transaction.isIncome;
    final color = isIncome ? AppColors.positive : AppColors.negative;
    final amountText =
        '${isIncome ? '+' : '-'}${IdrFormatter.format(transaction.amount)}';

    final category = transaction.category ??
        (isIncome
            ? context.t('home.income')
            : context.t('home.expense'));
    final note = transaction.note;
    final time = DateFormat('HH:mm').format(transaction.effectiveDate.toLocal());

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isIncome
                  ? Icons.arrow_upward_rounded
                  : Icons.arrow_downward_rounded,
              color: color,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.t(category),
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: context.appColors.textPrimary,
                  ),
                ),
                if (note != null && note.isNotEmpty)
                  Text(
                    note,
                    style: TextStyle(
                      fontSize: 11,
                      color: context.appColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                Text(
                  time,
                  style: TextStyle(
                    fontSize: 10,
                    color: context.appColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            amountText,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Budget Section ───────────────────────────────────────────────────────────

class _BudgetSection extends StatelessWidget {
  const _BudgetSection({
    required this.budgets,
    required this.appState,
  });

  final List<BudgetModel> budgets;
  final AppState appState;

  @override
  Widget build(BuildContext context) {
    if (budgets.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.appColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.appColors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 4,
                height: 16,
                decoration: BoxDecoration(
                  color: AppColors.brandBlue,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                context.t('report.budgetSectionTitle'),
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: context.appColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Daftar budget
          ...budgets.map((b) => _BudgetRow(budget: b, appState: appState)),
        ],
      ),
    );
  }
}

class _BudgetRow extends StatelessWidget {
  const _BudgetRow({required this.budget, required this.appState});

  final BudgetModel budget;
  final AppState appState;

  @override
  Widget build(BuildContext context) {
    final actual = appState.actualFor(budget);
    final isIncome = budget.type == MoneyTransactionType.income;
    final ratio = budget.targetAmount > 0
        ? (actual / budget.targetAmount).clamp(0.0, 1.0)
        : 0.0;
    final percent = (ratio * 100).round();

    final Color barColor;
    if (isIncome) {
      barColor = ratio >= 1.0 ? AppColors.positive : AppColors.brandBlue;
    } else {
      barColor = ratio >= 1.0
          ? AppColors.negative
          : ratio >= 0.8
              ? Colors.orange
              : AppColors.brandBlue;
    }

    final categoryName = budget.categoryId == null
        ? context.t(isIncome ? 'budget.allIncome' : 'budget.allExpense')
        : _resolveName(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  categoryName,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 13),
                ),
              ),
              Text(
                '$percent%',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  color: barColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 6,
              backgroundColor: context.appColors.outline,
              valueColor: AlwaysStoppedAnimation<Color>(barColor),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                IdrFormatter.format(actual),
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: barColor),
              ),
              Text(
                '/ ${IdrFormatter.format(budget.targetAmount)}',
                style: TextStyle(
                    fontSize: 11,
                    color: context.appColors.textSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _resolveName(BuildContext context) {
    final cats = appState.categoriesFor(budget.type);
    for (final c in cats) {
      if (c.id == budget.categoryId) return c.name;
    }
    return budget.categoryId ?? '';
  }
}
