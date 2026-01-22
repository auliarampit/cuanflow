import 'package:flutter/material.dart';

import '../../core/formatters/idr_formatter.dart';
import '../../core/localization/transalation_extansions.dart';
import '../../core/services/report_pdf_service.dart';
import '../../core/state/app_state.dart';

import '../../core/theme/app_colors.dart';

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
    final months = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  void _exportPdf() async {
    final summary = context.appState.summaryForDate(
      DateRangeType.month,
      _selectedDate,
    );
    final history = context.appState.historyForDate(
      DateRangeType.month,
      _selectedDate,
    );
    final profile = context.appState.profile;

    final monthName = _formatMonth(_selectedDate);
    await ReportPdfService().generateAndShowPdf(
      monthName,
      summary,
      history,
      profile,
    );
  }

  @override
  Widget build(BuildContext context) {
    final summary = context.appState.summaryForDate(
      DateRangeType.month,
      _selectedDate,
    );
    // Get previous month's summary for comparison
    final prevDate = DateTime(_selectedDate.year, _selectedDate.month - 1, 15);
    final prevSummary = context.appState.summaryForDate(
      DateRangeType.month,
      prevDate,
    );

    final totalIncome = summary.totalIncome;
    final totalExpense = summary.totalExpense;
    final netProfit = summary.netProfit;

    // Helper to calc percentage
    String calcPercent(int current, int previous) {
      if (previous == 0) {
        if (current == 0) return '0%';
        // If previous is 0, we can't calculate percentage growth normally.
        // For expense (passed as negative), if it goes 0 -> -100, it's -100% (bad).
        // For income, 0 -> 100 is +100% (good).
        return current > 0 ? '+100%' : '-100%';
      }
      final percent = ((current - previous) / previous.abs()) * 100;
      final prefix = percent >= 0 ? '+' : '';
      return '$prefix${percent.toStringAsFixed(1)}%';
    }

    final incomeChange = calcPercent(totalIncome, prevSummary.totalIncome);
    // Pass expense as negative because increase in expense is "bad" (negative change)
    final expenseChange = calcPercent(-totalExpense, -prevSummary.totalExpense);
    final profitChange = calcPercent(netProfit, prevSummary.netProfit);

    final history = context.appState.historyForDate(
      DateRangeType.month,
      _selectedDate,
    );

    return SafeArea(
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Text(
                      context.t('report.titleMonthly'),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        onPressed: () => _changeMonth(-1),
                        icon: const Icon(Icons.chevron_left),
                      ),
                      Text(
                        _formatMonth(_selectedDate),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      IconButton(
                        onPressed: () => _changeMonth(1),
                        icon: const Icon(Icons.chevron_right),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: _SummaryCard(
                          title: context.t('report.totalIncomeTitle'),
                          amount: IdrFormatter.format(totalIncome),
                          changeLabel: incomeChange,
                          accentColor: AppColors.positive,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _SummaryCard(
                          title: context.t('report.totalExpenseTitle'),
                          amount: IdrFormatter.format(totalExpense),
                          changeLabel: expenseChange,
                          accentColor: AppColors.negative,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _SummaryCard(
                    title: context.t('report.netProfitTitle'),
                    amount: IdrFormatter.format(netProfit),
                    changeLabel: profitChange,
                    accentColor: AppColors.positive,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    context.t('report.transactionDetailsTitle'),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 10),
                  ...history.map((tx) {
                    return _ReportRow(
                      title:
                          tx.category ??
                          (tx.isIncome
                              ? context.t('home.income')
                              : context.t('home.expense')),
                      subtitle: tx.note ?? '-',
                      amount: IdrFormatter.format(
                        tx.isIncome ? tx.amount : -tx.amount,
                      ),
                    );
                  }),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: OutlinedButton.icon(
              onPressed: () => _exportPdf(),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.brandBlue,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 15,
                ),
                side: const BorderSide(color: AppColors.outline),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: const Icon(Icons.picture_as_pdf_outlined),
              label: Text(context.t('history.exportPdf')),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.title,
    required this.amount,
    required this.changeLabel,
    required this.accentColor,
  });

  final String title;
  final String amount;
  final String changeLabel;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 10),
            Text(
              amount,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(changeLabel, style: TextStyle(color: accentColor)),
          ],
        ),
      ),
    );
  }
}

class _ReportRow extends StatelessWidget {
  const _ReportRow({
    required this.title,
    required this.subtitle,
    required this.amount,
  });

  final String title;
  final String subtitle;
  final String amount;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            amount,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: amount.startsWith('-')
                  ? AppColors.negative
                  : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
