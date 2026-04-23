import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../core/models/outlet_model.dart';
import '../../../core/state/app_state.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dynamic_colors.dart';

/// Line chart: tren income per outlet selama 6 bulan terakhir.
/// Hanya ditampilkan saat "Semua Outlet" aktif dan ada ≥ 2 outlet.
class OutletTrendChart extends StatefulWidget {
  const OutletTrendChart({
    super.key,
    required this.outlets,
    required this.selectedDate,
    required this.appState,
    required this.title,
  });

  final List<OutletModel> outlets;
  final DateTime selectedDate;
  final AppState appState;
  final String title;

  @override
  State<OutletTrendChart> createState() => _OutletTrendChartState();
}

class _OutletTrendChartState extends State<OutletTrendChart> {
  static const _palette = [
    AppColors.brandBlue,
    AppColors.positive,
    Color(0xFFF59E0B),
    Color(0xFF8B5CF6),
    Color(0xFFEF4444),
    Color(0xFF06B6D4),
  ];

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
    'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
  ];

  @override
  Widget build(BuildContext context) {
    final monthDates = List.generate(6, (i) {
      final d = widget.selectedDate;
      return DateTime(d.year, d.month - (5 - i), 15);
    });

    // Income per outlet per bulan dari allTransactions (tidak difilter outlet)
    final allTx = widget.appState.allTransactions;

    double maxY = 0;
    final outletLines = widget.outlets.map((outlet) {
      final spots = <FlSpot>[];
      for (int i = 0; i < monthDates.length; i++) {
        final date = monthDates[i];
        final income = allTx
            .where((t) =>
                t.isIncome &&
                t.outletId == outlet.id &&
                t.effectiveDate.year == date.year &&
                t.effectiveDate.month == date.month)
            .fold(0.0, (sum, t) => sum + t.amount);
        if (income > maxY) maxY = income;
        spots.add(FlSpot(i.toDouble(), income));
      }
      return _OutletLine(outlet: outlet, spots: spots);
    }).toList();

    if (maxY == 0) return const SizedBox.shrink();

    final yInterval = _niceStep(maxY) / 2;

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
          Text(
            widget.title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: context.appColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          // Legend
          Wrap(
            spacing: 14,
            runSpacing: 6,
            children: outletLines.asMap().entries.map((entry) {
              final color = _palette[entry.key % _palette.length];
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 24,
                    height: 3,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    entry.value.outlet.name,
                    style: TextStyle(
                      fontSize: 11,
                      color: context.appColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 160,
            child: LineChart(
              LineChartData(
                minX: 0,
                maxX: 5,
                minY: 0,
                maxY: maxY * 1.15,
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (spots) {
                      return spots.map((spot) {
                        final outletIdx = outletLines.indexWhere(
                          (l) => l.spots.any(
                            (s) => s.x == spot.x && s.y == spot.y,
                          ),
                        );
                        final name = outletIdx >= 0
                            ? outletLines[outletIdx].outlet.name
                            : '';
                        return LineTooltipItem(
                          '$name\n${_formatY(spot.y)}',
                          const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        );
                      }).toList();
                    },
                  ),
                ),
                gridData: FlGridData(
                  drawVerticalLine: false,
                  horizontalInterval: yInterval > 0 ? yInterval : maxY / 4,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: context.appColors.outline,
                    strokeWidth: 1,
                    dashArray: [4, 4],
                  ),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 44,
                      interval: yInterval > 0 ? yInterval : maxY / 4,
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
                      interval: 1,
                      getTitlesWidget: (value, _) {
                        final idx = value.toInt();
                        if (idx < 0 || idx >= monthDates.length) {
                          return const SizedBox.shrink();
                        }
                        return Text(
                          _months[monthDates[idx].month - 1],
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
                lineBarsData: outletLines.asMap().entries.map((entry) {
                  final color = _palette[entry.key % _palette.length];
                  return LineChartBarData(
                    spots: entry.value.spots,
                    isCurved: true,
                    curveSmoothness: 0.3,
                    color: color,
                    barWidth: 2.5,
                    dotData: FlDotData(
                      getDotPainter: (spot, _, _, _) =>
                          FlDotCirclePainter(
                        radius: 3,
                        color: color,
                        strokeWidth: 1.5,
                        strokeColor: Colors.white,
                      ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: color.withValues(alpha: 0.06),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  double _niceStep(double max) {
    if (max <= 100000) return 50000;
    if (max <= 500000) return 200000;
    if (max <= 2000000) return 1000000;
    if (max <= 10000000) return 4000000;
    if (max <= 50000000) return 20000000;
    return 40000000;
  }

  static String _formatY(double value) {
    if (value == 0) return '0';
    if (value >= 1000000) {
      final v = value / 1000000;
      return '${v.toStringAsFixed(v == v.truncate() ? 0 : 1)}jt';
    }
    if (value >= 1000) {
      final v = value / 1000;
      return '${v.toStringAsFixed(0)}rb';
    }
    return value.toInt().toString();
  }
}

class _OutletLine {
  const _OutletLine({required this.outlet, required this.spots});
  final OutletModel outlet;
  final List<FlSpot> spots;
}
