import 'package:flutter/material.dart';

import '../../core/models/subscription_tier.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dynamic_colors.dart';
import '../../core/ui/app_gradient_scaffold.dart';

class UpgradeScreen extends StatelessWidget {
  const UpgradeScreen({super.key});

  /// Tampilkan bottom sheet "upgrade required" dari mana saja.
  static void showUpgradeSheet(
    BuildContext context, {
    required SubscriptionTier required,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _UpgradeSheet(requiredTier: required),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentTier = context.appState.profile.subscriptionTier;

    return AppGradientScaffold(
      appBar: AppBar(title: const Text('Pilih Paket')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pilih paket yang sesuai kebutuhan bisnis kamu',
              style: TextStyle(
                fontSize: 14,
                color: context.appColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),

            // ── Paket Gratis ─────────────────────────────────────────────
            _PlanCard(
              tier: SubscriptionTier.free,
              isCurrentPlan: currentTier == SubscriptionTier.free,
              features: const [
                'Catat pemasukan & pengeluaran',
                'Budget & target bulanan',
                'Transaksi berulang (cicilan, dll)',
                'Laporan & history',
                'Iklan (AdMob)',
              ],
            ),
            const SizedBox(height: 14),

            // ── Paket Retail ─────────────────────────────────────────────
            _PlanCard(
              tier: SubscriptionTier.retail,
              isCurrentPlan: currentTier == SubscriptionTier.retail,
              isPopular: true,
              features: const [
                'Semua fitur Gratis',
                'Jual Cepat (preset produk)',
                'Stok barang & inventaris',
                'Analitik produk & kategori terlaris',
                'Utang & piutang',
                'Hari tersibuk & insight',
                'Tanpa iklan',
              ],
            ),
            const SizedBox(height: 14),

            // ── Paket Produsen ───────────────────────────────────────────
            _PlanCard(
              tier: SubscriptionTier.production,
              isCurrentPlan: currentTier == SubscriptionTier.production,
              features: const [
                'Semua fitur Retail',
                'Kalkulator HPP & daftar produk',
                'Manajemen bahan baku',
                'Batch produksi',
                'Multi outlet',
                'Analitik profit per produk',
              ],
            ),

            const SizedBox(height: 28),
            Center(
              child: Text(
                'Bisa ganti paket kapan saja · Tanpa kontrak',
                style: TextStyle(
                  fontSize: 12,
                  color: context.appColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Plan card ─────────────────────────────────────────────────────────────────

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.tier,
    required this.isCurrentPlan,
    required this.features,
    this.isPopular = false,
  });

  final SubscriptionTier tier;
  final bool isCurrentPlan;
  final bool isPopular;
  final List<String> features;

  Color _accentColor() {
    switch (tier) {
      case SubscriptionTier.free:
        return AppColors.brandBlue;
      case SubscriptionTier.retail:
        return AppColors.positive;
      case SubscriptionTier.production:
        return Colors.deepPurple;
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = _accentColor();
    final priceLabel = tier.pricePerMonth == 0
        ? 'Gratis selamanya'
        : 'Rp ${_formatPrice(tier.pricePerMonth)}/bulan';

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isCurrentPlan
                ? accent.withValues(alpha: 0.06)
                : context.appColors.card,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isCurrentPlan ? accent : context.appColors.outline,
              width: isCurrentPlan ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Text(
                    tier.label,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: accent,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    priceLabel,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: context.appColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Feature list
              ...features.map(
                (f) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.check_rounded,
                        size: 15,
                        color: accent,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          f,
                          style: TextStyle(
                            fontSize: 13,
                            color: context.appColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // CTA
              SizedBox(
                width: double.infinity,
                child: isCurrentPlan
                    ? OutlinedButton(
                        onPressed: null,
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: accent),
                          foregroundColor: accent,
                        ),
                        child: const Text('Paket Aktif'),
                      )
                    : ElevatedButton(
                        onPressed: () => _onSubscribe(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accent,
                          foregroundColor: Colors.white,
                        ),
                        child: Text(
                          tier == SubscriptionTier.free
                              ? 'Downgrade ke Gratis'
                              : 'Berlangganan',
                        ),
                      ),
              ),
            ],
          ),
        ),

        // Badge "Populer"
        if (isPopular)
          Positioned(
            top: -10,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: accent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Populer',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
      ],
    );
  }

  void _onSubscribe(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Segera Hadir'),
        content: Text(
          'Fitur berlangganan paket ${tier.label} sedang dalam pengembangan.\n\n'
          'Untuk informasi lebih lanjut, hubungi tim kami.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  static String _formatPrice(int price) {
    if (price >= 1000) {
      return '${(price / 1000).toStringAsFixed(0)}.000';
    }
    return price.toString();
  }
}

// ── Upgrade bottom sheet (shown from PaywallGate) ─────────────────────────────

class _UpgradeSheet extends StatelessWidget {
  const _UpgradeSheet({required this.requiredTier});

  final SubscriptionTier requiredTier;

  Color _accentColor() {
    switch (requiredTier) {
      case SubscriptionTier.free:
        return AppColors.brandBlue;
      case SubscriptionTier.retail:
        return AppColors.positive;
      case SubscriptionTier.production:
        return Colors.deepPurple;
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = _accentColor();
    final priceLabel = 'Rp ${_formatPrice(requiredTier.pricePerMonth)}/bulan';

    return Container(
      decoration: BoxDecoration(
        color: context.appColors.card,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        24,
        20,
        24,
        MediaQuery.of(context).padding.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: context.appColors.outline,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),

          // Icon
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.lock_outline, color: accent, size: 28),
          ),
          const SizedBox(height: 16),

          Text(
            'Fitur Paket ${requiredTier.label}',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            'Fitur ini tersedia mulai paket ${requiredTier.label} ($priceLabel).\n'
            'Upgrade untuk mengakses fitur ini.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: context.appColors.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pushNamed('/upgrade');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: accent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                'Lihat Paket ${requiredTier.label}',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Nanti saja',
              style: TextStyle(color: context.appColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  static String _formatPrice(int price) {
    if (price >= 1000) {
      return '${(price / 1000).toStringAsFixed(0)}.000';
    }
    return price.toString();
  }
}
