import 'package:flutter/material.dart';

import '../../core/config/space_features.dart';
import '../../core/models/space_model.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dynamic_colors.dart';
import '../../core/ui/app_gradient_scaffold.dart';

class ManageFeaturesScreen extends StatelessWidget {
  const ManageFeaturesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.appState;
    final space = appState.activeSpace;
    final isPremium = appState.profile.isBusinessPremium;

    void goUpgrade() =>
        Navigator.of(context).pushNamed('/upgrade');

    return AppGradientScaffold(
      appBar: AppBar(title: const Text('Fitur Aktif')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (space == null)
              const _InfoBanner(
                icon: Icons.info_outline,
                message: 'Pilih Ruang di halaman utama untuk melihat fitur yang tersedia.',
              )
            else ...[
              _InfoBanner(
                icon: Icons.info_outline,
                message:
                    'Fitur ditentukan berdasarkan jenis Ruang aktif (${space.type.displayName}) dan status Business Premium.',
              ),
              const SizedBox(height: 16),
              _SectionHeader(title: 'Laporan & Insight'),
              const SizedBox(height: 8),
              _FeatureRow(
                icon: Icons.emoji_events_outlined,
                title: 'Kategori Terlaris',
                subtitle: 'Tampilkan kategori terlaris di laporan',
                enabled: SpaceFeatures.canUseTopCategories(space, isPremium),
                onUpgrade: goUpgrade,
              ),
              const SizedBox(height: 8),
              _FeatureRow(
                icon: Icons.calendar_today_outlined,
                title: 'Hari Tersibuk',
                subtitle: 'Tampilkan hari dengan transaksi terbanyak',
                enabled: SpaceFeatures.canUseBusiestDay(space, isPremium),
                onUpgrade: goUpgrade,
              ),
              const SizedBox(height: 8),
              _FeatureRow(
                icon: Icons.bar_chart_outlined,
                title: 'Analitik Produk',
                subtitle: 'Laporan penjualan dan tren per produk',
                enabled: SpaceFeatures.canUseProductAnalytics(space, isPremium),
                onUpgrade: goUpgrade,
              ),
              const SizedBox(height: 24),
              _SectionHeader(title: 'Fitur Transaksi'),
              const SizedBox(height: 8),
              _FeatureRow(
                icon: Icons.point_of_sale,
                title: 'Jual Cepat',
                subtitle: 'Shortcut catat penjualan dari preset',
                enabled: SpaceFeatures.canUseQuickSale(space, isPremium),
                onUpgrade: goUpgrade,
              ),
              const SizedBox(height: 8),
              _FeatureRow(
                icon: Icons.repeat_outlined,
                title: 'Transaksi Berulang',
                subtitle: 'Catat transaksi rutin secara otomatis',
                enabled: SpaceFeatures.canUseRecurring(space, isPremium),
                onUpgrade: goUpgrade,
              ),
              const SizedBox(height: 8),
              _FeatureRow(
                icon: Icons.account_balance_wallet_outlined,
                title: 'Utang & Piutang',
                subtitle: 'Catat dan pantau utang serta piutang',
                enabled: SpaceFeatures.canUseDebt(space, isPremium),
                onUpgrade: goUpgrade,
              ),
              const SizedBox(height: 24),
              _SectionHeader(title: 'Fitur Bisnis'),
              const SizedBox(height: 8),
              _FeatureRow(
                icon: Icons.savings_outlined,
                title: 'Budget & Target',
                subtitle: 'Atur dan pantau anggaran bulanan',
                enabled: SpaceFeatures.canUseBudget(space, isPremium),
                onUpgrade: goUpgrade,
              ),
              const SizedBox(height: 8),
              _FeatureRow(
                icon: Icons.store_outlined,
                title: 'Multi Outlet',
                subtitle: 'Kelola beberapa cabang atau outlet',
                enabled: SpaceFeatures.canUseOutlets(space, isPremium),
                onUpgrade: goUpgrade,
              ),
              const SizedBox(height: 8),
              _FeatureRow(
                icon: Icons.warehouse_outlined,
                title: 'Stok Barang',
                subtitle: 'Kelola inventaris dan stok produk',
                enabled: SpaceFeatures.canUseStock(space, isPremium),
                onUpgrade: goUpgrade,
              ),
              const SizedBox(height: 24),
              _SectionHeader(title: 'Fitur Produksi'),
              const SizedBox(height: 8),
              _FeatureRow(
                icon: Icons.inventory_2_outlined,
                title: 'HPP & Produk',
                subtitle: 'Hitung harga pokok produksi dan kelola produk',
                enabled: SpaceFeatures.canUseHpp(space, isPremium),
                onUpgrade: goUpgrade,
              ),
              const SizedBox(height: 8),
              _FeatureRow(
                icon: Icons.science_outlined,
                title: 'Bahan Baku & Batch',
                subtitle: 'Catat bahan baku dan batch produksi',
                enabled: SpaceFeatures.canUseProductionBatch(space, isPremium),
                onUpgrade: goUpgrade,
              ),
              const SizedBox(height: 24),
              if (!isPremium) ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: goUpgrade,
                    icon: const Icon(Icons.workspace_premium_outlined),
                    label: const Text('Upgrade ke Business Premium'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.brandBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ],
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

class _InfoBanner extends StatelessWidget {
  const _InfoBanner({required this.icon, required this.message});
  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.brandBlue.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.brandBlue.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.brandBlue),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 12,
                color: context.appColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.enabled,
    required this.onUpgrade,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool enabled;
  final VoidCallback onUpgrade;

  @override
  Widget build(BuildContext context) {
    final appColors = context.appColors;
    final bgColor = enabled
        ? AppColors.brandBlue.withValues(alpha: 0.08)
        : appColors.cardSoft;
    final borderColor = enabled
        ? AppColors.brandBlue.withValues(alpha: 0.3)
        : appColors.outline;
    final iconColor =
        enabled ? AppColors.brandBlue : appColors.textSecondary.withValues(alpha: 0.5);

    return Container(
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
                    color: enabled ? null : appColors.textSecondary.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 11, color: appColors.textSecondary),
                ),
              ],
            ),
          ),
          if (enabled)
            const Icon(Icons.check_circle_outline, size: 18, color: AppColors.positive)
          else
            GestureDetector(
              onTap: onUpgrade,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.lock_outline,
                      size: 16,
                      color: appColors.textSecondary.withValues(alpha: 0.5)),
                  const SizedBox(width: 4),
                  Text(
                    'Upgrade',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: appColors.textSecondary.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
