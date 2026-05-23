import 'package:flutter/material.dart';

import '../../../core/config/feature_config.dart';
import '../../../core/formatters/idr_formatter.dart';
import '../../../core/models/money_transaction.dart';
import '../../../core/state/app_state.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dynamic_colors.dart';

/// Kartu kesehatan bisnis di halaman laporan.
///
/// Menampilkan:
/// 1. Margin bersih bulan ini dengan indikator status
/// 2. Status budget (jika fitur budget aktif dan ada budget)
/// 3. Status stok barang (jika fitur stock aktif)
/// 4. Ranking outlet (jika fitur outlet aktif, "semua outlet" dipilih, ≥2 outlet)
class OutletHealthCard extends StatelessWidget {
  const OutletHealthCard({
    super.key,
    required this.summary,
    required this.selectedDate,
    required this.appState,
    required this.history,
  });

  final Summary summary;
  final DateTime selectedDate;
  final AppState appState;
  final List<MoneyTransaction> history;

  // ── Status helpers ─────────────────────────────────────────────────────────

  _HealthStatus _marginStatus() {
    if (summary.totalIncome == 0 && summary.totalExpense == 0) {
      return _HealthStatus.noData;
    }
    if (summary.netProfit < 0) return _HealthStatus.danger;
    if (summary.totalIncome == 0) return _HealthStatus.warning;
    final margin = summary.netProfit / summary.totalIncome;
    if (margin < 0.10) return _HealthStatus.warning;
    return _HealthStatus.ok;
  }

  String _marginLabel() {
    if (summary.totalIncome == 0 && summary.totalExpense == 0) {
      return 'Belum ada data';
    }
    if (summary.totalIncome == 0) return 'Tidak ada pemasukan';
    final pct = (summary.netProfit / summary.totalIncome * 100);
    return '${pct.toStringAsFixed(1)}%';
  }

  _HealthStatus _budgetStatus() {
    final budgets = appState.budgetsFor(selectedDate);
    if (budgets.isEmpty) return _HealthStatus.noData;
    var hasWarning = false;
    for (final b in budgets) {
      final actual = appState.actualFor(b);
      if (actual > b.targetAmount) return _HealthStatus.danger;
      if (actual >= b.targetAmount * 0.8) hasWarning = true;
    }
    return hasWarning ? _HealthStatus.warning : _HealthStatus.ok;
  }

  String _budgetLabel() {
    final budgets = appState.budgetsFor(selectedDate);
    if (budgets.isEmpty) return 'Belum diatur';
    var over = 0;
    var near = 0;
    for (final b in budgets) {
      final actual = appState.actualFor(b);
      if (actual > b.targetAmount) {
        over++;
      } else if (actual >= b.targetAmount * 0.8) {
        near++;
      }
    }
    if (over > 0) return '$over budget terlampaui';
    if (near > 0) return '$near mendekati batas';
    return 'Semua dalam target';
  }

  _HealthStatus _stockStatus() {
    final low = appState.lowStockItems;
    if (low.isEmpty) return _HealthStatus.ok;
    final outOfStock = low.where((i) => i.currentStock <= 0).length;
    if (outOfStock > 0) return _HealthStatus.danger;
    return _HealthStatus.warning;
  }

  String _stockLabel() {
    final low = appState.lowStockItems;
    if (low.isEmpty) return 'Semua stok aman';
    final outOfStock = low.where((i) => i.currentStock <= 0).length;
    if (outOfStock > 0) return '$outOfStock item habis · ${low.length} perlu restok';
    return '${low.length} item stok rendah';
  }

  // ── Per-outlet income dari history bulan ini ────────────────────────────────

  List<_OutletStat> _outletStats() {
    final outlets = appState.outlets;
    if (outlets.isEmpty) return [];

    // Akumulasi income per outletId dari history transaksi bulan ini
    final incomeMap = <String, int>{};
    for (final tx in history) {
      if (tx.outletId != null && tx.isIncome) {
        incomeMap[tx.outletId!] = (incomeMap[tx.outletId!] ?? 0) + tx.amount;
      }
    }

    // Hanya tampilkan outlet yang ada di incomeMap
    final stats = outlets
        .where((o) => incomeMap.containsKey(o.id))
        .map((o) => _OutletStat(name: o.name, income: incomeMap[o.id] ?? 0))
        .toList()
      ..sort((a, b) => b.income.compareTo(a.income));

    return stats;
  }

  // ── Overall status (worst of all active metrics) ───────────────────────────

  _HealthStatus _overallStatus(bool showBudget, bool showStock) {
    final statuses = [_marginStatus()];
    if (showBudget) statuses.add(_budgetStatus());
    if (showStock) statuses.add(_stockStatus());

    if (statuses.any((s) => s == _HealthStatus.danger)) return _HealthStatus.danger;
    if (statuses.any((s) => s == _HealthStatus.warning)) return _HealthStatus.warning;
    if (statuses.every((s) => s == _HealthStatus.noData)) return _HealthStatus.noData;
    return _HealthStatus.ok;
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final profile = appState.profile;
    final showBudget =
        useFeature(Feature.budget, profile) &&
        appState.budgetsFor(selectedDate).isNotEmpty;
    final showStock = useFeature(Feature.stock, profile);
    final showOutletRanking = useFeature(Feature.outlets, profile) &&
        appState.selectedOutlet == null &&
        appState.outlets.length >= 2;

    final overall = _overallStatus(showBudget, showStock);
    final outletStats = showOutletRanking ? _outletStats() : <_OutletStat>[];

    return Container(
      decoration: BoxDecoration(
        color: context.appColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.appColors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 18,
                  decoration: BoxDecoration(
                    color: overall.accentColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Kesehatan Bisnis',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: context.appColors.textPrimary,
                  ),
                ),
                const Spacer(),
                _StatusChip(
                  label: overall.headerLabel,
                  status: overall,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // ── Divider ──────────────────────────────────────────────────────
          Divider(height: 1, color: context.appColors.outline),

          // ── Metrik ───────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Column(
              children: [
                _HealthRow(
                  icon: Icons.trending_up_rounded,
                  label: 'Margin bersih',
                  value: _marginLabel(),
                  status: _marginStatus(),
                ),
                if (showBudget) ...[
                  const SizedBox(height: 10),
                  _HealthRow(
                    icon: Icons.savings_outlined,
                    label: 'Status budget',
                    value: _budgetLabel(),
                    status: _budgetStatus(),
                  ),
                ],
                if (showStock) ...[
                  const SizedBox(height: 10),
                  _HealthRow(
                    icon: Icons.inventory_2_outlined,
                    label: 'Stok barang',
                    value: _stockLabel(),
                    status: _stockStatus(),
                  ),
                ],
              ],
            ),
          ),

          // ── Outlet ranking ────────────────────────────────────────────────
          if (outletStats.isNotEmpty) ...[
            Divider(height: 1, color: context.appColors.outline),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pemasukan per Outlet',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: context.appColors.textSecondary,
                      letterSpacing: 0.4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...outletStats.asMap().entries.map((entry) {
                    final rank = entry.key;
                    final stat = entry.value;
                    return _OutletRankRow(
                      rank: rank,
                      stat: stat,
                      isFirst: rank == 0,
                      isLast: rank == outletStats.length - 1 && outletStats.length > 1,
                    );
                  }),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Health row ───────────────────────────────────────────────────────────────

class _HealthRow extends StatelessWidget {
  const _HealthRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.status,
  });

  final IconData icon;
  final String label;
  final String value;
  final _HealthStatus status;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: context.appColors.textSecondary),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: context.appColors.textSecondary,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: context.appColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
        _StatusChip(label: status.statusLabel, status: status),
      ],
    );
  }
}

// ─── Outlet rank row ──────────────────────────────────────────────────────────

class _OutletRankRow extends StatelessWidget {
  const _OutletRankRow({
    required this.rank,
    required this.stat,
    required this.isFirst,
    required this.isLast,
  });

  final int rank;
  final _OutletStat stat;
  final bool isFirst;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final Color rankColor;
    final IconData rankIcon;
    if (isFirst) {
      rankColor = AppColors.positive;
      rankIcon = Icons.emoji_events_rounded;
    } else if (isLast) {
      rankColor = AppColors.negative;
      rankIcon = Icons.arrow_downward_rounded;
    } else {
      rankColor = context.appColors.textSecondary;
      rankIcon = Icons.remove_rounded;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(rankIcon, size: 14, color: rankColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              stat.name,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
          Text(
            IdrFormatter.format(stat.income),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.positive,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Status chip ──────────────────────────────────────────────────────────────

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.status});

  final String label;
  final _HealthStatus status;

  @override
  Widget build(BuildContext context) {
    if (status == _HealthStatus.noData) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: status.accentColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: status.accentColor,
        ),
      ),
    );
  }
}

// ─── Data models ──────────────────────────────────────────────────────────────

class _OutletStat {
  const _OutletStat({required this.name, required this.income});
  final String name;
  final int income;
}

enum _HealthStatus {
  ok,
  warning,
  danger,
  noData;

  Color get accentColor {
    switch (this) {
      case _HealthStatus.ok:
        return AppColors.positive;
      case _HealthStatus.warning:
        return Colors.orange;
      case _HealthStatus.danger:
        return AppColors.negative;
      case _HealthStatus.noData:
        return Colors.grey;
    }
  }

  String get statusLabel {
    switch (this) {
      case _HealthStatus.ok:
        return 'Baik';
      case _HealthStatus.warning:
        return 'Waspada';
      case _HealthStatus.danger:
        return 'Perhatian';
      case _HealthStatus.noData:
        return '';
    }
  }

  String get headerLabel {
    switch (this) {
      case _HealthStatus.ok:
        return 'Sehat';
      case _HealthStatus.warning:
        return 'Perlu Perhatian';
      case _HealthStatus.danger:
        return 'Ada Masalah';
      case _HealthStatus.noData:
        return 'Belum Ada Data';
    }
  }
}
