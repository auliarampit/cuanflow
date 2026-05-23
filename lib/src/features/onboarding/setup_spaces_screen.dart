import 'package:flutter/material.dart';

import '../../app/routes.dart';
import '../../core/models/space_model.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dynamic_colors.dart';

class SetupSpacesScreen extends StatefulWidget {
  const SetupSpacesScreen({super.key});

  @override
  State<SetupSpacesScreen> createState() => _SetupSpacesScreenState();
}

class _SetupSpacesScreenState extends State<SetupSpacesScreen> {
  SpaceType? _selected;

  Future<void> _confirm() async {
    if (_selected == null) return;
    final appState = context.appState;

    await appState.addSpace(_selected!);
    await appState.updateProfile(
      appState.profile.copyWith(onboardingComplete: true),
    );

    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed(AppRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    const Text(
                      'Apa yang ingin kamu kelola?',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Pilih sesuai situasimu. Bisa tambah ruang lain kapan saja.',
                      style: TextStyle(
                        color: context.appColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 36),

                    _SpaceCard(
                      selected: _selected == SpaceType.personal,
                      emoji: '💰',
                      title: 'Keuangan pribadi',
                      subtitle: 'Pantau pengeluaran & pemasukan sehari-hari',
                      benefits: const [
                        'Catat pemasukan & pengeluaran',
                        'Lihat sisa uang & tren bulanan',
                        'Atur transaksi berulang (cicilan, dll)',
                      ],
                      accentColor: AppColors.brandBlue,
                      onTap: () => setState(() => _selected = SpaceType.personal),
                    ),
                    const SizedBox(height: 14),

                    _SpaceCard(
                      selected: _selected == SpaceType.store,
                      emoji: '🏪',
                      title: 'Warung atau toko',
                      subtitle: 'Pantau omzet harian, tahu untung atau rugi',
                      benefits: const [
                        'Jual cepat dengan preset produk',
                        'Pantau stok & analitik barang',
                        'Laporan harian & bulanan',
                      ],
                      accentColor: AppColors.positive,
                      onTap: () => setState(() => _selected = SpaceType.store),
                    ),
                    const SizedBox(height: 14),

                    _SpaceCard(
                      selected: _selected == SpaceType.production,
                      emoji: '🏭',
                      title: 'Usaha produksi',
                      subtitle: 'Hitung HPP, kelola bahan baku, pantau margin',
                      benefits: const [
                        'Kalkulator HPP & harga pokok produksi',
                        'Manajemen bahan baku & batch produksi',
                        'Analitik profit per produk',
                      ],
                      accentColor: Colors.deepPurple,
                      onTap: () => setState(() => _selected = SpaceType.production),
                    ),
                    const SizedBox(height: 24),

                    Center(
                      child: Text(
                        'Bisa tambah ruang lain kapan saja di Profil',
                        style: TextStyle(
                          fontSize: 12,
                          color: context.appColors.textSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),

            _ConfirmButton(enabled: _selected != null, onTap: _confirm),
          ],
        ),
      ),
    );
  }
}

// ─── Space card ───────────────────────────────────────────────────────────────

class _SpaceCard extends StatelessWidget {
  const _SpaceCard({
    required this.selected,
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.benefits,
    required this.accentColor,
    required this.onTap,
  });

  final bool selected;
  final String emoji;
  final String title;
  final String subtitle;
  final List<String> benefits;
  final Color accentColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: selected
              ? accentColor.withValues(alpha: 0.07)
              : context.appColors.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? accentColor : context.appColors.outline,
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: selected
                        ? accentColor.withValues(alpha: 0.15)
                        : context.appColors.cardSoft,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  alignment: Alignment.center,
                  child: Text(emoji, style: const TextStyle(fontSize: 24)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: selected
                              ? accentColor
                              : context.appColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: context.appColors.textSecondary,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                if (selected)
                  Icon(Icons.check_circle, color: accentColor, size: 22),
              ],
            ),
            const SizedBox(height: 14),
            ...benefits.map(
              (b) => Padding(
                padding: const EdgeInsets.only(top: 5),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.check_rounded,
                      size: 15,
                      color: selected
                          ? accentColor
                          : context.appColors.textSecondary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        b,
                        style: TextStyle(
                          fontSize: 13,
                          color: context.appColors.textSecondary,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Confirm button ───────────────────────────────────────────────────────────

class _ConfirmButton extends StatelessWidget {
  const _ConfirmButton({required this.enabled, required this.onTap});

  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        24,
        12,
        24,
        MediaQuery.of(context).padding.bottom > 0
            ? MediaQuery.of(context).padding.bottom
            : 24,
      ),
      decoration: BoxDecoration(
        color: context.appColors.card,
        border: Border(top: BorderSide(color: context.appColors.outline)),
      ),
      child: SizedBox(
        width: double.infinity,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: enabled ? 1.0 : 0.4,
          child: ElevatedButton(
            onPressed: enabled ? onTap : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.brandBlue,
              foregroundColor: Colors.white,
              disabledBackgroundColor: AppColors.brandBlue,
              disabledForegroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Mulai',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                SizedBox(width: 8),
                Icon(Icons.arrow_forward_rounded, size: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
