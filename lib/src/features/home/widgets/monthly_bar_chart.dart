import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../core/state/app_state.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dynamic_colors.dart';

/// Bar chart showing income vs expense for the last 6 months.
class MonthlyBarChart extends StatelessWidget {
  const MonthlyBarChart({
    super.key,
    required this.selectedDate,
    required this.appState,
  });

  final DateTime selectedDate;
  final AppState appState;

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
    'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
  ];

  @override
  Widget build(BuildContext context) {
    final data = _buildData();
    final maxY = _maxY(data);

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 16, 16, 12),
      decoration: BoxDecoration(
        color: context.appColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.appColors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Legend
          Row(
            children: [
              _LegendDot(color: AppColors.positive, label: 'Pemasukan'),
              const SizedBox(width: 16),
              _LegendDot(color: AppColors.negative, label: 'Pengeluaran'),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 160,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxY,
                minY: 0,
                barGroups: _barGroups(data),
                gridData: FlGridData(
                  drawVerticalLine: false,
                  horizontalInterval: maxY / 4,
                  getDrawingHorizontalLine: (v) => FlLine(
                    color: context.appColors.outline,
                    strokeWidth: 1,
                    dashArray: [4, 4],
                  ),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 44,
                      interval: maxY / 4,
                      getTitlesWidget: (value, _) => Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: Text(
                          _formatY(value),
                          style: TextStyle(
                            fontSize: 9,
                            color: context.appColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 22,
                      getTitlesWidget: (value, _) {
                        final idx = value.toInt();
                        if (idx < 0 || idx >= data.length) {
                          return const SizedBox.shrink();
                        }
                        return Text(
                          _months[data[idx].month - 1],
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: context.appColors.textSecondary,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final label =
                          rodIndex == 0 ? 'Pemasukan' : 'Pengeluaran';
                      final amount = _formatTooltip(rod.toY);
                      return BarTooltipItem(
                        '$label\n$amount',
                        const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Data helpers ────────────────────────────────────────────────────────

  List<_MonthData> _buildData() {
    final result = <_MonthData>[];
    for (int i = 5; i >= 0; i--) {
      final date = DateTime(selectedDate.year, selectedDate.month - i, 15);
      final summary =
          appState.summaryForDate(DateRangeType.month, date);
      result.add(_MonthData(
        month: date.month,
        income: summary.totalIncome.toDouble(),
        expense: summary.totalExpense.toDouble(),
      ));
    }
    return result;
  }

  double _maxY(List<_MonthData> data) {
    double max = 0;
    for (final d in data) {
      if (d.income > max) max = d.income;
      if (d.expense > max) max = d.expense;
    }
    if (max == 0) return 1000000;
    // Round up to a clean interval
    final magnitude = (max).floorToDouble();
    final step = _niceStep(magnitude);
    return ((magnitude / step).ceil() * step).toDouble();
  }

  double _niceStep(double max) {
    if (max <= 100000) return 25000;
    if (max <= 500000) return 100000;
    if (max <= 2000000) return 500000;
    if (max <= 10000000) return 2000000;
    if (max <= 50000000) return 10000000;
    return 20000000;
  }

  List<BarChartGroupData> _barGroups(List<_MonthData> data) {
    return List.generate(data.length, (i) {
      return BarChartGroupData(
        x: i,
        barsSpace: 4,
        barRods: [
          BarChartRodData(
            toY: data[i].income,
            color: AppColors.positive,
            width: 10,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(4),
            ),
          ),
          BarChartRodData(
            toY: data[i].expense,
            color: AppColors.negative,
            width: 10,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(4),
            ),
          ),
        ],
      );
    });
  }

  static String _formatY(double value) {
    if (value == 0) return '0';
    if (value >= 1000000000) return '${(value / 1000000000).toStringAsFixed(1)}M';
    if (value >= 1000000) {
      final v = value / 1000000;
      return v == v.truncate() ? '${v.toInt()}jt' : '${v.toStringAsFixed(1)}jt';
    }
    if (value >= 1000) {
      final v = value / 1000;
      return v == v.truncate() ? '${v.toInt()}rb' : '${v.toStringAsFixed(0)}rb';
    }
    return value.toInt().toString();
  }

  static String _formatTooltip(double value) {
    if (value >= 1000000) {
      return 'Rp ${(value / 1000000).toStringAsFixed(1)}jt';
    }
    if (value >= 1000) {
      return 'Rp ${(value / 1000).toStringAsFixed(0)}rb';
    }
    return 'Rp ${value.toInt()}';
  }
}

// ── Small helpers ────────────────────────────────────────────────────────────

class _MonthData {
  const _MonthData({
    required this.month,
    required this.income,
    required this.expense,
  });
  final int month;
  final double income;
  final double expense;
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: context.appColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
