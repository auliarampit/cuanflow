import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/state/app_state.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dynamic_colors.dart';
import '../../core/ui/app_gradient_scaffold.dart';

class UpgradeScreen extends StatelessWidget {
  const UpgradeScreen({super.key});

  static void showUpgradeSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _UpgradeSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isPremium = context.appState.profile.isBusinessPremium;

    return AppGradientScaffold(
      appBar: AppBar(title: const Text('Business Premium')),
      body: Column(
        children: [
          // ── Scrollable content ──────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Header ─────────────────────────────────────────────
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.brandBlue.withValues(alpha: 0.85),
                          AppColors.brandBlue.withValues(alpha: 0.6),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.workspace_premium_outlined,
                          color: Colors.white,
                          size: 32,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Business Premium',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Rp 20.000 / bulan',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white70,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Buka semua fitur Ruang Warung & Produksi. Tanpa iklan.',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white.withValues(alpha: 0.85),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── Fitur Ruang Warung ──────────────────────────────────
                  _SectionHeader(
                      title: 'Ruang Warung', color: AppColors.positive),
                  const SizedBox(height: 10),
                  ..._storeFeatures.map((f) => _FeatureItem(text: f)),
                  const SizedBox(height: 20),

                  // ── Fitur Ruang Produksi ────────────────────────────────
                  _SectionHeader(
                      title: 'Ruang Produksi', color: Colors.deepPurple),
                  const SizedBox(height: 10),
                  ..._productionFeatures.map((f) => _FeatureItem(text: f)),
                  const SizedBox(height: 20),

                  // ── Selalu gratis ───────────────────────────────────────
                  _SectionHeader(
                    title: 'Selalu Gratis (semua Ruang)',
                    color: AppColors.brandBlue,
                  ),
                  const SizedBox(height: 10),
                  ..._freeFeatures.map((f) => _FeatureItem(text: f, isFree: true)),
                ],
              ),
            ),
          ),

          // ── Fixed footer: CTA ───────────────────────────────────────────
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isPremium)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.positive.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: AppColors.positive.withValues(alpha: 0.3),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle_outline,
                              color: AppColors.positive, size: 20),
                          SizedBox(width: 10),
                          Text(
                            'Business Premium Aktif',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: AppColors.positive,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => _onSubscribe(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.brandBlue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          'Berlangganan Business Premium',
                          style:
                              TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                        ),
                      ),
                    ),
                  const SizedBox(height: 8),
                  Text(
                    'Bisa batal kapan saja · Tanpa kontrak',
                    style: TextStyle(
                      fontSize: 12,
                      color: context.appColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _onSubscribe(BuildContext context) {
    final profile = context.appState.profile;
    _launchWhatsApp(fullName: profile.fullName, email: profile.email);
  }

  static Future<void> _launchWhatsApp({
    required String fullName,
    required String email,
  }) async {
    const waNumber = '6282277289593'; // ganti nomor WA owner
    final name = fullName.isNotEmpty ? fullName : '(belum diisi)';
    final msg = Uri.encodeComponent(
      'Halo, saya ingin berlangganan Business Premium CuanFlow.\n\n'
      'Nama: $name\n'
      'Email: $email\n\n'
      'Mohon konfirmasi langkah pembayaran selanjutnya. Terima kasih!',
    );
    final uri = Uri.parse('https://wa.me/$waNumber?text=$msg');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

const _storeFeatures = [
  'Jual Cepat (Quick Sale) — preset produk',
  'Utang & Piutang',
  'Stok Barang & Inventaris',
  'Multi Outlet',
  'Analitik Produk',
  'Kategori Terlaris & Hari Tersibuk',
];

const _productionFeatures = [
  'Kalkulator HPP & Daftar Produk',
  'Bahan Baku & Manajemen Stok',
  'Batch Produksi',
  'Multi Outlet',
  'Analitik Profit per Produk',
  'Budget & Target Bulanan',
];

const _freeFeatures = [
  'Catat pemasukan & pengeluaran',
  'Kategori custom',
  'Laporan harian & mingguan',
  'Transaksi berulang',
];

// ── Widgets ───────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.color});
  final String title;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 14,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _FeatureItem extends StatelessWidget {
  const _FeatureItem({required this.text, this.isFree = false});
  final String text;
  final bool isFree;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isFree ? Icons.check_circle_outline : Icons.check_rounded,
            size: 16,
            color: isFree
                ? AppColors.brandBlue.withValues(alpha: 0.7)
                : AppColors.positive,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                color: context.appColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Bottom sheet ──────────────────────────────────────────────────────────────

class _UpgradeSheet extends StatelessWidget {
  const _UpgradeSheet();

  @override
  Widget build(BuildContext context) {
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
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: context.appColors.outline,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.brandBlue.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.workspace_premium_outlined,
              color: AppColors.brandBlue,
              size: 28,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Business Premium',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            'Fitur ini membutuhkan Business Premium (Rp 20.000/bulan).\n'
            'Unlock semua fitur Warung & Produksi sekaligus.',
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
                backgroundColor: AppColors.brandBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'Upgrade ke Business Premium',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
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
}
