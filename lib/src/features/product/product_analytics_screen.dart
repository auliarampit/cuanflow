import 'package:flutter/material.dart';
import '../../core/formatters/idr_formatter.dart';
import '../../core/models/product_model.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dynamic_colors.dart';
import '../../core/ui/app_gradient_scaffold.dart';

class ProductAnalyticsScreen extends StatelessWidget {
  const ProductAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.appState;
    final rawMaterials = appState.rawMaterials;
    final products = List<ProductModel>.from(appState.products)
      ..sort((a, b) {
        final ma = a.liveHppPerUnit(rawMaterials) > 0
            ? ((a.sellingPrice - a.liveHppPerUnit(rawMaterials)) /
                    a.sellingPrice *
                    100)
                .round()
            : a.marginPercentage.round();
        final mb = b.liveHppPerUnit(rawMaterials) > 0
            ? ((b.sellingPrice - b.liveHppPerUnit(rawMaterials)) /
                    b.sellingPrice *
                    100)
                .round()
            : b.marginPercentage.round();
        return mb.compareTo(ma);
      });

    return AppGradientScaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Analitik Produk',
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: products.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.bar_chart,
                      size: 64, color: context.appColors.textSecondary),
                  const SizedBox(height: 16),
                  const Text('Belum ada produk',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 18)),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _SectionHeader('Ranking Margin (tertinggi → terendah)'),
                const SizedBox(height: 12),
                ...products.asMap().entries.map((e) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _ProductCard(
                        rank: e.key + 1,
                        product: e.value,
                        rawMaterials: rawMaterials,
                      ),
                    )),
                const SizedBox(height: 20),
                _SectionHeader('Breakeven Analysis'),
                const SizedBox(height: 12),
                ...products.map((p) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _BreakevenCard(
                        product: p,
                        rawMaterials: rawMaterials,
                      ),
                    )),
              ],
            ),
    );
  }
}

// ─── Widgets ──────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);
  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title.toUpperCase(),
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
        color: context.appColors.textSecondary,
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({
    required this.rank,
    required this.product,
    required this.rawMaterials,
  });

  final int rank;
  final ProductModel product;
  final List<RawMaterial> rawMaterials;

  @override
  Widget build(BuildContext context) {
    final liveHpp = product.liveHppPerUnit(rawMaterials);
    final hpp = liveHpp > 0 ? liveHpp : product.hppPerUnit;
    final profit = product.sellingPrice - hpp;
    final margin = product.sellingPrice > 0 ? (profit / product.sellingPrice * 100) : 0.0;
    final isLinked = product.ingredients.any((i) => i.rawMaterialId != null);

    Color marginColor;
    String marginLabel;
    if (margin >= 40) {
      marginColor = AppColors.brandGreen;
      marginLabel = 'SEHAT';
    } else if (margin >= 20) {
      marginColor = const Color(0xFFF59E0B);
      marginLabel = 'TIPIS';
    } else {
      marginColor = AppColors.negative;
      marginLabel = 'RUGI';
    }

    return Container(
      decoration: BoxDecoration(
        color: context.appColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.appColors.outline),
      ),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          // Rank
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: rank == 1
                  ? const Color(0xFFFFD700).withValues(alpha:0.15)
                  : context.appColors.cardSoft,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                rank == 1 ? '🏆' : '#$rank',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: rank == 1 ? 16 : 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(product.name,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 15)),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: marginColor.withValues(alpha:0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(marginLabel,
                          style: TextStyle(
                              color: marginColor,
                              fontSize: 10,
                              fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    _stat('HPP', IdrFormatter.format(hpp.round()),
                        sub: isLinked ? '(live)' : null),
                    const SizedBox(width: 16),
                    _stat('Jual',
                        IdrFormatter.format(product.sellingPrice.round())),
                    const SizedBox(width: 16),
                    _stat('Margin', '${margin.toStringAsFixed(1)}%',
                        color: marginColor),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _stat(String label, String value,
      {Color? color, String? sub}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                color: AppColors.textSecondary, fontSize: 10)),
        Row(
          children: [
            Text(value,
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: color)),
            if (sub != null) ...[
              const SizedBox(width: 3),
              Text(sub,
                  style: const TextStyle(
                      color: AppColors.brandGreen,
                      fontSize: 10)),
            ],
          ],
        ),
      ],
    );
  }
}

class _BreakevenCard extends StatelessWidget {
  const _BreakevenCard({
    required this.product,
    required this.rawMaterials,
  });

  final ProductModel product;
  final List<RawMaterial> rawMaterials;

  @override
  Widget build(BuildContext context) {
    final liveHpp = product.liveHppPerUnit(rawMaterials);
    final hpp = liveHpp > 0 ? liveHpp : product.hppPerUnit;
    final profit = product.sellingPrice - hpp;

    // BEP: total cost / profit per unit — using monthly fixed cost proxy = otherCosts
    final totalOther = product.totalOtherCost;
    final bepUnits = profit > 0 ? (totalOther / profit) : double.infinity;
    final bepRevenue = bepUnits.isFinite ? bepUnits * product.sellingPrice : 0.0;

    return Container(
      decoration: BoxDecoration(
        color: context.appColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.appColors.outline),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(product.name,
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 10),
          if (profit <= 0)
            const Text(
              '⚠ Harga jual lebih rendah dari HPP — produk merugi.',
              style: TextStyle(color: AppColors.negative, fontSize: 13),
            )
          else ...[
            _row('Profit per unit', IdrFormatter.format(profit.round())),
            _row(
              'BEP (unit)',
              bepUnits.isFinite
                  ? '${bepUnits.ceil()} unit'
                  : 'N/A — tidak ada biaya tetap',
              sub: 'untuk menutup biaya lain-lain',
            ),
            if (bepRevenue > 0)
              _row('BEP (omzet)',
                  IdrFormatter.format(bepRevenue.round())),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: product.sellingPrice > 0
                    ? (hpp / product.sellingPrice).clamp(0.0, 1.0)
                    : 0,
                backgroundColor: AppColors.brandGreen.withValues(alpha:0.2),
                valueColor:
                    const AlwaysStoppedAnimation(AppColors.brandBlue),
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'HPP = ${(hpp / product.sellingPrice * 100).toStringAsFixed(1)}% dari harga jual',
              style: TextStyle(
                  color: context.appColors.textSecondary, fontSize: 11),
            ),
          ],
        ],
      ),
    );
  }

  Widget _row(String label, String value, {String? sub}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 12)),
                if (sub != null)
                  Text(sub,
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 10)),
              ],
            ),
          ),
          Text(value,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }
}
