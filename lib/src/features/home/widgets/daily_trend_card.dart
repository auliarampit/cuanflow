import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/formatters/idr_formatter.dart';
import '../../../core/state/app_state.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dynamic_colors.dart';

/// Kartu tren 7 hari terakhir — net (pemasukan - pengeluaran) per hari.
/// Ditampilkan di home untuk mode personal & production.
class DailyTrendCard extends StatelessWidget {
  const DailyTrendCard({super.key});

  static const _dayLabels = ['Sn', 'Sl', 'Rb', 'Km', 'Jm', 'Sb', 'Mg'];

  @override
  Widget build(BuildContext context) {
    final appState = context.appState;
    final now = DateTime.now();

    final days = List.generate(7, (i) {
      final date = now.subtract(Duration(days: 6 - i));
      final s = appState.summaryForDate(DateRangeType.day, date);
      return _DayData(
        label: _dayLabels[date.weekday - 1],
        net: s.totalIncome - s.totalExpense,
        isToday: i == 6,
      );
    });

    final maxAbs = days.fold<int>(
      1,
      (prev, d) => math.max(prev, d.net.abs()),
    );

    // Hitung rata-rata net untuk ringkasan
    final avgNet = days.fold<int>(0, (s, d) => s + d.net) ~/ 7;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
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
              Text(
                '7 Hari Terakhir',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: context.appColors.textPrimary,
                ),
              ),
              const Spacer(),
              Text(
                avgNet >= 0
                    ? '+${IdrFormatter.format(avgNet)}/hari'
                    : '${IdrFormatter.format(avgNet)}/hari',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: avgNet >= 0 ? AppColors.positive : AppColors.negative,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Bar chart
          SizedBox(
            height: 80,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: days
                  .map((d) => _DayBar(data: d, maxAbs: maxAbs))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Bar item per hari ─────────────────────────────────────────────────────────

class _DayBar extends StatelessWidget {
  const _DayBar({required this.data, required this.maxAbs});

  final _DayData data;
  final int maxAbs;

  static const _barMaxHeight = 52.0;
  static const _labelHeight = 16.0;
  static const _gapHeight = 4.0;

  @override
  Widget build(BuildContext context) {
    final isPositive = data.net >= 0;
    final color = isPositive ? AppColors.positive : AppColors.negative;
    final todayColor = data.isToday ? color : color.withValues(alpha: 0.5);
    final barHeight = maxAbs == 0
        ? 2.0
        : math.max(2.0, (data.net.abs() / maxAbs) * _barMaxHeight);

    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Nilai di atas bar (hanya hari ini)
          SizedBox(
            height: _barMaxHeight,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: double.infinity,
                height: barHeight,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  color: todayColor,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(4),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: _gapHeight),
          // Label hari
          SizedBox(
            height: _labelHeight,
            child: Text(
              data.label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10,
                fontWeight:
                    data.isToday ? FontWeight.w800 : FontWeight.w500,
                color: data.isToday
                    ? context.appColors.textPrimary
                    : context.appColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Data model ────────────────────────────────────────────────────────────────

class _DayData {
  const _DayData({
    required this.label,
    required this.net,
    required this.isToday,
  });

  final String label;
  final int net;
  final bool isToday;
}
