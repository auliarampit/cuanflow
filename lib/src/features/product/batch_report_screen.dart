import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/formatters/idr_formatter.dart';
import '../../core/models/product_model.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dynamic_colors.dart';
import '../../core/ui/app_gradient_scaffold.dart';

enum _Period { thisMonth, threeMonths, all }

class BatchReportScreen extends StatefulWidget {
  const BatchReportScreen({super.key});

  @override
  State<BatchReportScreen> createState() => _BatchReportScreenState();
}

class _BatchReportScreenState extends State<BatchReportScreen> {
  _Period _period = _Period.thisMonth;

  List<ProductionBatch> _filtered(List<ProductionBatch> all) {
    final now = DateTime.now();
    return switch (_period) {
      _Period.thisMonth => all
          .where((b) => b.date.year == now.year && b.date.month == now.month)
          .toList(),
      _Period.threeMonths => all
          .where((b) =>
              b.date.isAfter(DateTime(now.year, now.month - 2, 1)))
          .toList(),
      _Period.all => all,
    };
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.appState;
    final batches = _filtered(appState.productionBatches);
    final products = appState.products;

    // ── Aggregasi global ────────────────────────────────────────────────────
    final totalUnits =
        batches.fold(0.0, (s, b) => s + b.qtyProduced);
    final totalCost =
        batches.fold(0.0, (s, b) => s + b.totalMaterialCost);
    final totalRevenue = batches.fold(0.0, (s, b) {
      final p = products.cast<ProductModel?>().firstWhere(
            (p) => p?.id == b.productId,
            orElse: () => null,
          );
      return s + (p?.sellingPrice ?? 0) * b.qtyProduced;
    });
    final totalProfit = totalRevenue - totalCost;
    final overallMargin =
        totalRevenue > 0 ? (totalProfit / totalRevenue * 100) : 0.0;

    // ── Aggregasi per produk ────────────────────────────────────────────────
    final Map<String, List<ProductionBatch>> byProduct = {};
    for (final b in batches) {
      byProduct.putIfAbsent(b.productId, () => []).add(b);
    }
    // Urutkan: produk dengan total profit tertinggi di atas
    final productGroups = byProduct.entries.toList()
      ..sort((a, b) {
        final profitA = _groupProfit(a.value, products);
        final profitB = _groupProfit(b.value, products);
        return profitB.compareTo(profitA);
      });

    return AppGradientScaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Laporan Profit Batch',
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: batches.isEmpty
          ? _EmptyState(period: _period, onChangePeriod: (p) => setState(() => _period = p))
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                // ── Filter chips ─────────────────────────────────────────
                _PeriodFilter(
                  selected: _period,
                  onChanged: (p) => setState(() => _period = p),
                ),
                const SizedBox(height: 16),

                // ── Summary card ─────────────────────────────────────────
                _SummaryCard(
                  batchCount: batches.length,
                  totalUnits: totalUnits,
                  totalCost: totalCost,
                  totalRevenue: totalRevenue,
                  totalProfit: totalProfit,
                  overallMargin: overallMargin,
                ),
                const SizedBox(height: 24),

                // ── Per-produk ────────────────────────────────────────────
                Text(
                  'PER PRODUK',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                    color: context.appColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                ...productGroups.map((entry) {
                  final product = products.cast<ProductModel?>().firstWhere(
                        (p) => p?.id == entry.key,
                        orElse: () => null,
                      );
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _ProductBatchCard(
                      productName: entry.value.first.productName,
                      batches: entry.value,
                      sellingPrice: product?.sellingPrice,
                    ),
                  );
                }),
              ],
            ),
    );
  }

  double _groupProfit(List<ProductionBatch> batches, List<ProductModel> products) {
    return batches.fold(0.0, (s, b) {
      final p = products.cast<ProductModel?>().firstWhere(
            (p) => p?.id == b.productId,
            orElse: () => null,
          );
      final revenue = (p?.sellingPrice ?? 0) * b.qtyProduced;
      return s + revenue - b.totalMaterialCost;
    });
  }
}

// ─── Period filter ────────────────────────────────────────────────────────────

class _PeriodFilter extends StatelessWidget {
  const _PeriodFilter({required this.selected, required this.onChanged});
  final _Period selected;
  final ValueChanged<_Period> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _Chip(label: 'Bulan Ini', active: selected == _Period.thisMonth,
            onTap: () => onChanged(_Period.thisMonth)),
        const SizedBox(width: 8),
        _Chip(label: '3 Bulan', active: selected == _Period.threeMonths,
            onTap: () => onChanged(_Period.threeMonths)),
        const SizedBox(width: 8),
        _Chip(label: 'Semua', active: selected == _Period.all,
            onTap: () => onChanged(_Period.all)),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.active, required this.onTap});
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: active
              ? AppColors.brandBlue
              : context.appColors.cardSoft,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active ? AppColors.brandBlue : context.appColors.outline,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: active ? Colors.white : context.appColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

// ─── Summary card ─────────────────────────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.batchCount,
    required this.totalUnits,
    required this.totalCost,
    required this.totalRevenue,
    required this.totalProfit,
    required this.overallMargin,
  });

  final int batchCount;
  final double totalUnits;
  final double totalCost;
  final double totalRevenue;
  final double totalProfit;
  final double overallMargin;

  Color get _profitColor {
    if (totalRevenue == 0) return Colors.grey;
    if (overallMargin >= 30) return AppColors.brandGreen;
    if (overallMargin >= 10) return const Color(0xFFF59E0B);
    return AppColors.negative;
  }

  @override
  Widget build(BuildContext context) {
    final hasRevenue = totalRevenue > 0;

    return Container(
      decoration: BoxDecoration(
        color: context.appColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.appColors.outline),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 4,
                height: 18,
                decoration: BoxDecoration(
                  color: _profitColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Ringkasan Produksi',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: context.appColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Stat grid baris 1
          Row(
            children: [
              _StatBox(
                label: 'Total Batch',
                value: '$batchCount batch',
                icon: Icons.layers_outlined,
              ),
              const SizedBox(width: 10),
              _StatBox(
                label: 'Total Unit',
                value: '${totalUnits.toInt()} unit',
                icon: Icons.inventory_2_outlined,
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Stat grid baris 2
          Row(
            children: [
              _StatBox(
                label: 'Total Biaya Bahan',
                value: IdrFormatter.format(totalCost.round()),
                icon: Icons.shopping_bag_outlined,
                valueColor: context.appColors.textPrimary,
              ),
              const SizedBox(width: 10),
              _StatBox(
                label: 'Est. Revenue',
                value: hasRevenue
                    ? IdrFormatter.format(totalRevenue.round())
                    : '—',
                icon: Icons.payments_outlined,
                valueColor: hasRevenue ? AppColors.brandGreen : null,
                footnote: hasRevenue ? null : 'Tambah harga jual di produk',
              ),
            ],
          ),

          // Profit highlight
          if (hasRevenue) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: _profitColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _profitColor.withValues(alpha: 0.25)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Est. Total Profit',
                        style: TextStyle(
                          fontSize: 11,
                          color: context.appColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        IdrFormatter.format(totalProfit.round()),
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: _profitColor,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _profitColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Margin ${overallMargin.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: _profitColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  const _StatBox({
    required this.label,
    required this.value,
    required this.icon,
    this.valueColor,
    this.footnote,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color? valueColor;
  final String? footnote;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: context.appColors.cardSoft,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 16, color: context.appColors.textSecondary),
            const SizedBox(height: 6),
            Text(label,
                style: TextStyle(
                    fontSize: 10, color: context.appColors.textSecondary)),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: valueColor ?? context.appColors.textPrimary,
              ),
            ),
            if (footnote != null)
              Text(footnote!,
                  style: TextStyle(
                      fontSize: 9, color: context.appColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}

// ─── Per-product batch card ───────────────────────────────────────────────────

class _ProductBatchCard extends StatelessWidget {
  const _ProductBatchCard({
    required this.productName,
    required this.batches,
    this.sellingPrice,
  });

  final String productName;
  final List<ProductionBatch> batches;
  final double? sellingPrice;

  double get _totalUnits =>
      batches.fold(0.0, (s, b) => s + b.qtyProduced);

  double get _totalCost =>
      batches.fold(0.0, (s, b) => s + b.totalMaterialCost);

  double get _avgHpp => _totalUnits > 0 ? _totalCost / _totalUnits : 0;

  double get _avgMargin {
    final sp = sellingPrice ?? 0;
    if (sp <= 0 || _avgHpp <= 0) return 0;
    return (sp - _avgHpp) / sp * 100;
  }

  /// HPP trend: bandingkan batch pertama vs terakhir (urut tanggal)
  /// Positif = HPP naik (buruk), negatif = HPP turun (efisien)
  double? get _hppTrend {
    if (batches.length < 2) return null;
    final sorted = List<ProductionBatch>.from(batches)
      ..sort((a, b) => a.date.compareTo(b.date));
    return sorted.last.costPerUnit - sorted.first.costPerUnit;
  }

  Color get _marginColor {
    final m = _avgMargin;
    if (sellingPrice == null || sellingPrice == 0) return Colors.grey;
    if (m >= 30) return AppColors.brandGreen;
    if (m >= 10) return const Color(0xFFF59E0B);
    return AppColors.negative;
  }

  @override
  Widget build(BuildContext context) {
    final trend = _hppTrend;
    final hasPrice = sellingPrice != null && sellingPrice! > 0;
    final latestBatch = (List<ProductionBatch>.from(batches)
          ..sort((a, b) => b.date.compareTo(a.date)))
        .first;

    return Container(
      decoration: BoxDecoration(
        color: context.appColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: hasPrice
              ? _marginColor.withValues(alpha: 0.35)
              : context.appColors.outline,
          width: hasPrice ? 1.5 : 1,
        ),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Nama + jumlah batch ──────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: Text(
                  productName,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: context.appColors.cardSoft,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${batches.length} batch',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: context.appColors.textSecondary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // ── Stats row ────────────────────────────────────────────────
          Row(
            children: [
              _mini('Unit', '${_totalUnits.toInt()}'),
              _mini('Total Biaya', IdrFormatter.format(_totalCost.round())),
              _mini('HPP Rata-rata', IdrFormatter.format(_avgHpp.round())),
              if (hasPrice)
                _mini('Margin', '${_avgMargin.toStringAsFixed(1)}%',
                    color: _marginColor),
            ],
          ),

          // ── HPP trend ────────────────────────────────────────────────
          if (trend != null) ...[
            const SizedBox(height: 10),
            const Divider(height: 1),
            const SizedBox(height: 8),
            _TrendRow(trend: trend, batchCount: batches.length),
          ],

          // ── Batch terakhir ───────────────────────────────────────────
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.access_time_rounded,
                  size: 12, color: context.appColors.textSecondary),
              const SizedBox(width: 4),
              Text(
                'Terakhir: ${DateFormat('d MMM yyyy').format(latestBatch.date)} · HPP ${IdrFormatter.format(latestBatch.costPerUnit.round())}',
                style: TextStyle(
                    fontSize: 11, color: context.appColors.textSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _mini(String label, String value, {Color? color}) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 10)),
          Text(value,
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: color)),
        ],
      ),
    );
  }
}

// ─── HPP Trend row ────────────────────────────────────────────────────────────

class _TrendRow extends StatelessWidget {
  const _TrendRow({required this.trend, required this.batchCount});

  final double trend;
  final int batchCount;

  @override
  Widget build(BuildContext context) {
    final isDown = trend < 0;
    final isFlat = trend.abs() < 50; // < Rp50 dianggap stabil
    final color = isFlat
        ? context.appColors.textSecondary
        : isDown
            ? AppColors.brandGreen
            : AppColors.negative;
    final icon = isFlat
        ? Icons.trending_flat_rounded
        : isDown
            ? Icons.trending_down_rounded
            : Icons.trending_up_rounded;
    final label = isFlat
        ? 'HPP stabil'
        : isDown
            ? 'HPP turun ${IdrFormatter.format(trend.abs().round())} dari batch pertama → efisiensi naik'
            : 'HPP naik ${IdrFormatter.format(trend.abs().round())} dari batch pertama → waspadai kenaikan biaya';

    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Empty state ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.period, required this.onChangePeriod});
  final _Period period;
  final ValueChanged<_Period> onChangePeriod;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _PeriodFilter(selected: period, onChanged: onChangePeriod),
        Expanded(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.bar_chart_rounded,
                    size: 64, color: context.appColors.textSecondary),
                const SizedBox(height: 16),
                Text(
                  period == _Period.thisMonth
                      ? 'Belum ada batch bulan ini'
                      : period == _Period.threeMonths
                          ? 'Belum ada batch 3 bulan terakhir'
                          : 'Belum ada batch produksi',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(
                  'Catat batch produksi dulu\nagar laporan bisa ditampilkan',
                  textAlign: TextAlign.center,
                  style:
                      TextStyle(color: context.appColors.textSecondary),
                ),
                if (period != _Period.all) ...[
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => onChangePeriod(_Period.all),
                    child: const Text('Lihat semua periode'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
