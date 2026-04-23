import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../core/state/app_state.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dynamic_colors.dart';

enum _Period { daily, weekly, monthly }

/// Bar chart income vs expense dengan toggle Harian / Mingguan / Bulanan.
class MonthlyBarChart extends StatefulWidget {
  const MonthlyBarChart({
    super.key,
    required this.selectedDate,
    required this.appState,
  });

  final DateTime selectedDate;
  final AppState appState;

  @override
  State<MonthlyBarChart> createState() => _MonthlyBarChartState();
}

class _MonthlyBarChartState extends State<MonthlyBarChart> {
  _Period _period = _Period.monthly;

  static const _dayLabels = ['Sn', 'Sl', 'Rb', 'Km', 'Jm', 'Sb', 'Mg'];
  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
    'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
  ];

  // ── Bangun data sesuai periode ──────────────────────────────────────────

  List<_BarData> _buildData() {
    switch (_period) {
      case _Period.daily:
        return _buildDaily();
      case _Period.weekly:
        return _buildWeekly();
      case _Period.monthly:
        return _buildMonthly();
    }
  }

  List<_BarData> _buildDaily() {
    final today = DateTime.now();
    return List.generate(7, (i) {
      final date = today.subtract(Duration(days: 6 - i));
      final summary = widget.appState.summaryForDate(DateRangeType.day, date);
      return _BarData(
        label: _dayLabels[date.weekday - 1],
        income: summary.totalIncome.toDouble(),
        expense: summary.totalExpense.toDouble(),
      );
    });
  }

  List<_BarData> _buildWeekly() {
    final today = DateTime.now();
    // Senin pekan ini
    final thisMonday = today.subtract(Duration(days: today.weekday - 1));
    return List.generate(6, (i) {
      // pekan ke-(5-i) mundur dari pekan ini
      final monday = thisMonday.subtract(Duration(days: (5 - i) * 7));
      final summary = widget.appState.summaryForDate(DateRangeType.week, monday);
      final day = monday.day.toString().padLeft(2, '0');
      final mon = _months[monday.month - 1];
      return _BarData(
        label: '$day $mon',
        income: summary.totalIncome.toDouble(),
        expense: summary.totalExpense.toDouble(),
      );
    });
  }

  List<_BarData> _buildMonthly() {
    return List.generate(6, (i) {
      final date = DateTime(
          widget.selectedDate.year, widget.selectedDate.month - (5 - i), 15);
      final summary =
          widget.appState.summaryForDate(DateRangeType.month, date);
      return _BarData(
        label: _months[date.month - 1],
        income: summary.totalIncome.toDouble(),
        expense: summary.totalExpense.toDouble(),
      );
    });
  }

  // ── Build ────────────────────────────────────────────────────────────────

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
          // ── Header: legend + toggle ──────────────────────────────────
          Row(
            children: [
              Flexible(
                child: Wrap(
                  spacing: 12,
                  children: [
                    _LegendDot(color: AppColors.positive, label: 'Pemasukan'),
                    _LegendDot(color: AppColors.negative, label: 'Pengeluaran'),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _PeriodToggle(
                selected: _period,
                onChanged: (p) => setState(() => _period = p),
              ),
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
                          data[idx].label,
                          style: TextStyle(
                            fontSize: _period == _Period.weekly ? 8 : 10,
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

  // ── Helper ───────────────────────────────────────────────────────────────

  double _maxY(List<_BarData> data) {
    double max = 0;
    for (final d in data) {
      if (d.income > max) max = d.income;
      if (d.expense > max) max = d.expense;
    }
    if (max == 0) return 1000000;
    final step = _niceStep(max);
    return ((max / step).ceil() * step).toDouble();
  }

  double _niceStep(double max) {
    if (max <= 100000) return 25000;
    if (max <= 500000) return 100000;
    if (max <= 2000000) return 500000;
    if (max <= 10000000) return 2000000;
    if (max <= 50000000) return 10000000;
    return 20000000;
  }

  List<BarChartGroupData> _barGroups(List<_BarData> data) {
    return List.generate(data.length, (i) {
      return BarChartGroupData(
        x: i,
        barsSpace: 4,
        barRods: [
          BarChartRodData(
            toY: data[i].income,
            color: AppColors.positive,
            width: 10,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          ),
          BarChartRodData(
            toY: data[i].expense,
            color: AppColors.negative,
            width: 10,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          ),
        ],
      );
    });
  }

  static String _formatY(double value) {
    if (value == 0) return '0';
    if (value >= 1000000000) {
      return '${(value / 1000000000).toStringAsFixed(1)}M';
    }
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
    if (value >= 1000000) return 'Rp ${(value / 1000000).toStringAsFixed(1)}jt';
    if (value >= 1000) return 'Rp ${(value / 1000).toStringAsFixed(0)}rb';
    return 'Rp ${value.toInt()}';
  }
}

// ── Data model ───────────────────────────────────────────────────────────────

class _BarData {
  const _BarData({
    required this.label,
    required this.income,
    required this.expense,
  });
  final String label;
  final double income;
  final double expense;
}

// ── Period toggle ─────────────────────────────────────────────────────────────

class _PeriodToggle extends StatelessWidget {
  const _PeriodToggle({required this.selected, required this.onChanged});

  final _Period selected;
  final ValueChanged<_Period> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: context.appColors.cardSoft,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: context.appColors.outline),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Tab(label: 'Hari', active: selected == _Period.daily,
              onTap: () => onChanged(_Period.daily)),
          _Tab(label: 'Minggu', active: selected == _Period.weekly,
              onTap: () => onChanged(_Period.weekly)),
          _Tab(label: 'Bulan', active: selected == _Period.monthly,
              onTap: () => onChanged(_Period.monthly)),
        ],
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({required this.label, required this.active, required this.onTap});

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: active ? AppColors.brandBlue : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: active ? Colors.white : context.appColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

// ── Legend dot ────────────────────────────────────────────────────────────────

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
