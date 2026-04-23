import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../core/formatters/idr_formatter.dart';
import '../../../core/models/money_transaction.dart';
import '../../../core/models/outlet_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dynamic_colors.dart';

/// Pie chart: kontribusi income per outlet untuk bulan yang dipilih.
/// Hanya ditampilkan saat "Semua Outlet" aktif dan ada ≥ 2 outlet.
class OutletContributionChart extends StatefulWidget {
  const OutletContributionChart({
    super.key,
    required this.outlets,
    required this.transactions,
    required this.title,
    required this.subtitle,
    required this.otherLabel,
  });

  final List<OutletModel> outlets;
  final List<MoneyTransaction> transactions;
  final String title;
  final String subtitle;
  final String otherLabel;

  @override
  State<OutletContributionChart> createState() =>
      _OutletContributionChartState();
}

class _OutletContributionChartState extends State<OutletContributionChart> {
  int _touchedIndex = -1;

  static const _palette = [
    AppColors.brandBlue,
    AppColors.positive,
    Color(0xFFF59E0B), // amber
    Color(0xFF8B5CF6), // purple
    Color(0xFFEF4444), // red
    Color(0xFF06B6D4), // cyan
  ];

  @override
  Widget build(BuildContext context) {
    final slices = _buildSlices();
    if (slices.isEmpty) return const SizedBox.shrink();

    final total = slices.fold(0, (sum, s) => sum + s.value);
    if (total == 0) return const SizedBox.shrink();

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
          Text(
            widget.title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: context.appColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            widget.subtitle,
            style: TextStyle(
              fontSize: 11,
              color: context.appColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              // Pie chart
              SizedBox(
                width: 130,
                height: 130,
                child: PieChart(
                  PieChartData(
                    pieTouchData: PieTouchData(
                      touchCallback: (event, response) {
                        setState(() {
                          if (!event.isInterestedForInteractions ||
                              response == null ||
                              response.touchedSection == null) {
                            _touchedIndex = -1;
                            return;
                          }
                          _touchedIndex = response
                              .touchedSection!.touchedSectionIndex;
                        });
                      },
                    ),
                    sections: slices.asMap().entries.map((entry) {
                      final i = entry.key;
                      final slice = entry.value;
                      final isTouched = i == _touchedIndex;
                      final pct = (slice.value / total * 100);
                      final color = _palette[i % _palette.length];

                      return PieChartSectionData(
                        color: color,
                        value: slice.value.toDouble(),
                        title: '${pct.toStringAsFixed(0)}%',
                        radius: isTouched ? 58 : 50,
                        titleStyle: TextStyle(
                          fontSize: isTouched ? 13 : 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      );
                    }).toList(),
                    borderData: FlBorderData(show: false),
                    sectionsSpace: 2,
                    centerSpaceRadius: 28,
                  ),
                ),
              ),
              const SizedBox(width: 20),
              // Legend
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: slices.asMap().entries.map((entry) {
                    final i = entry.key;
                    final slice = entry.value;
                    final color = _palette[i % _palette.length];
                    final pct = (slice.value / total * 100);
                    final isTouched = i == _touchedIndex;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  slice.label,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: isTouched
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    color: context.appColors.textPrimary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  '${pct.toStringAsFixed(1)}% · ${IdrFormatter.format(slice.value)}',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: context.appColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<_Slice> _buildSlices() {
    final result = <_Slice>[];
    for (final outlet in widget.outlets) {
      final income = widget.transactions
          .where((t) => t.isIncome && t.outletId == outlet.id)
          .fold(0, (sum, t) => sum + t.amount);
      if (income > 0) {
        result.add(_Slice(label: outlet.name, value: income));
      }
    }
    // Income tanpa outlet
    final other = widget.transactions
        .where((t) =>
            t.isIncome &&
            (t.outletId == null ||
                !widget.outlets.any((o) => o.id == t.outletId)))
        .fold(0, (sum, t) => sum + t.amount);
    if (other > 0) {
      result.add(_Slice(label: widget.otherLabel, value: other));
    }
    return result;
  }
}

class _Slice {
  const _Slice({required this.label, required this.value});
  final String label;
  final int value;
}
