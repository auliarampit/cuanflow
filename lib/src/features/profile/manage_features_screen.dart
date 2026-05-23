import 'package:flutter/material.dart';

import '../../core/config/feature_config.dart';
import '../../core/models/subscription_tier.dart';
import '../../core/models/user_profile.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dynamic_colors.dart';
import '../../core/ui/app_gradient_scaffold.dart';
import '../upgrade/upgrade_screen.dart';

class ManageFeaturesScreen extends StatelessWidget {
  const ManageFeaturesScreen({super.key});

  void _toggle(BuildContext context, UserProfile Function(UserProfile) fn) {
    final updated = fn(context.appState.profile);
    context.appState.updateProfile(updated);
  }

  void _showUpgrade(BuildContext context, SubscriptionTier required) {
    UpgradeScreen.showUpgradeSheet(context, required: required);
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.appState.profile;
    final tier = profile.subscriptionTier;
    final canRetail = tier.allows(Feature.quickSale);
    final canProduction = tier.allows(Feature.product);

    return AppGradientScaffold(
      appBar: AppBar(title: const Text('Atur Fitur')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionHeader(title: 'Laporan & Insight'),
            const SizedBox(height: 8),
            _FeatureToggleRow(
              icon: Icons.emoji_events_outlined,
              title: 'Kategori Terlaris',
              subtitle: 'Tampilkan produk terlaris di halaman laporan',
              value: profile.featureTopCategories,
              locked: !canRetail,
              onChanged: canRetail
                  ? (v) => _toggle(context, (p) => p.copyWith(featureTopCategories: v))
                  : (_) => _showUpgrade(context, SubscriptionTier.retail),
            ),
            const SizedBox(height: 8),
            _FeatureToggleRow(
              icon: Icons.calendar_today_outlined,
              title: 'Hari Tersibuk',
              subtitle: 'Tampilkan hari dengan transaksi terbanyak',
              value: profile.featureBusiestDay,
              locked: !canRetail,
              onChanged: canRetail
                  ? (v) => _toggle(context, (p) => p.copyWith(featureBusiestDay: v))
                  : (_) => _showUpgrade(context, SubscriptionTier.retail),
            ),
            const SizedBox(height: 8),
            _FeatureToggleRow(
              icon: Icons.bar_chart_outlined,
              title: 'Analitik Produk',
              subtitle: 'Laporan penjualan dan tren per produk',
              value: profile.featureProductAnalytics,
              locked: !canRetail,
              onChanged: canRetail
                  ? (v) => _toggle(context, (p) => p.copyWith(featureProductAnalytics: v))
                  : (_) => _showUpgrade(context, SubscriptionTier.retail),
            ),
            const SizedBox(height: 24),
            _SectionHeader(title: 'Fitur Transaksi'),
            const SizedBox(height: 8),
            _FeatureToggleRow(
              icon: Icons.point_of_sale,
              title: 'Jual Cepat',
              subtitle: 'Shortcut catat penjualan langsung dari preset',
              value: profile.featureQuickSale,
              locked: !canRetail,
              onChanged: canRetail
                  ? (v) => _toggle(context, (p) => p.copyWith(featureQuickSale: v))
                  : (_) => _showUpgrade(context, SubscriptionTier.retail),
            ),
            const SizedBox(height: 8),
            _FeatureToggleRow(
              icon: Icons.repeat_outlined,
              title: 'Transaksi Berulang',
              subtitle: 'Catat transaksi rutin secara otomatis',
              value: profile.featureRecurring,
              onChanged: (v) =>
                  _toggle(context, (p) => p.copyWith(featureRecurring: v)),
            ),
            const SizedBox(height: 8),
            _FeatureToggleRow(
              icon: Icons.account_balance_wallet_outlined,
              title: 'Utang & Piutang',
              subtitle: 'Catat dan pantau utang serta piutang',
              value: profile.featureDebt,
              locked: !canRetail,
              onChanged: canRetail
                  ? (v) => _toggle(context, (p) => p.copyWith(featureDebt: v))
                  : (_) => _showUpgrade(context, SubscriptionTier.retail),
            ),
            const SizedBox(height: 24),
            _SectionHeader(title: 'Fitur Bisnis'),
            const SizedBox(height: 8),
            _FeatureToggleRow(
              icon: Icons.savings_outlined,
              title: 'Budget & Target',
              subtitle: 'Atur dan pantau anggaran bulanan',
              value: profile.featureBudget,
              onChanged: (v) =>
                  _toggle(context, (p) => p.copyWith(featureBudget: v)),
            ),
            const SizedBox(height: 8),
            _FeatureToggleRow(
              icon: Icons.store_outlined,
              title: 'Multi Outlet',
              subtitle: 'Kelola beberapa cabang atau outlet',
              value: profile.featureOutlets,
              locked: !canProduction,
              onChanged: canProduction
                  ? (v) => _toggle(context, (p) => p.copyWith(featureOutlets: v))
                  : (_) => _showUpgrade(context, SubscriptionTier.production),
            ),
            const SizedBox(height: 8),
            _FeatureToggleRow(
              icon: Icons.warehouse_outlined,
              title: 'Stok Barang',
              subtitle: 'Kelola inventaris dan stok produk',
              value: profile.featureStock,
              locked: !canRetail,
              onChanged: canRetail
                  ? (v) => _toggle(context, (p) => p.copyWith(featureStock: v))
                  : (_) => _showUpgrade(context, SubscriptionTier.retail),
            ),
            const SizedBox(height: 24),
            _SectionHeader(title: 'Fitur Produksi'),
            const SizedBox(height: 8),
            _FeatureToggleRow(
              icon: Icons.inventory_2_outlined,
              title: 'HPP & Produk',
              subtitle: 'Hitung harga pokok produksi dan kelola produk',
              value: profile.featureProduct,
              locked: !canProduction,
              onChanged: canProduction
                  ? (v) => _toggle(context, (p) => p.copyWith(featureProduct: v))
                  : (_) => _showUpgrade(context, SubscriptionTier.production),
            ),
            const SizedBox(height: 8),
            _FeatureToggleRow(
              icon: Icons.science_outlined,
              title: 'Bahan Baku & Batch',
              subtitle: 'Catat bahan baku dan batch produksi',
              value: profile.featureProduction,
              locked: !canProduction,
              onChanged: canProduction
                  ? (v) => _toggle(context, (p) => p.copyWith(featureProduction: v))
                  : (_) => _showUpgrade(context, SubscriptionTier.production),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final appColors = context.appColors;
    return Text(
      title.toUpperCase(),
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
        color: appColors.textSecondary,
      ),
    );
  }
}

class _FeatureToggleRow extends StatelessWidget {
  const _FeatureToggleRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    this.locked = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool locked;

  @override
  Widget build(BuildContext context) {
    final appColors = context.appColors;

    final bgColor = locked
        ? appColors.cardSoft
        : value
            ? AppColors.brandBlue.withValues(alpha: 0.08)
            : appColors.card;
    final borderColor = locked
        ? appColors.outline
        : value
            ? AppColors.brandBlue.withValues(alpha: 0.3)
            : appColors.outline;
    final iconColor = locked
        ? appColors.textSecondary.withValues(alpha: 0.5)
        : value
            ? AppColors.brandBlue
            : appColors.textSecondary;

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => onChanged(!value),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: iconColor),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: locked
                          ? appColors.textSecondary.withValues(alpha: 0.6)
                          : null,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: appColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (locked)
              Icon(Icons.lock_outline,
                  size: 18,
                  color: appColors.textSecondary.withValues(alpha: 0.5))
            else
              Switch(
                value: value,
                onChanged: onChanged,
                activeThumbColor: AppColors.brandBlue,
              ),
          ],
        ),
      ),
    );
  }
}
