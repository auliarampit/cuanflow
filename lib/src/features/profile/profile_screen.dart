import 'package:cari_untung/src/app/routes.dart';
import 'package:cari_untung/src/core/config/space_features.dart';
import 'package:cari_untung/src/core/models/space_model.dart';
import 'package:cari_untung/src/core/state/app_state.dart';
import 'package:cari_untung/src/features/outlets/manage_outlets_screen.dart';
import 'package:cari_untung/src/shared/widgets/loading_dialog.dart';
import 'package:cari_untung/src/shared/widgets/native_ad_card.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart' show TemplateType;
import 'package:package_info_plus/package_info_plus.dart';

import '../../core/localization/transalation_extansions.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dynamic_colors.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _version = '';

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() {
        _version = '${info.version}+${info.buildNumber}';
      });
    }
  }

  void _openAccountSettings(BuildContext context) {
    Navigator.of(context).pushNamed(AppRoutes.accountSettings);
  }

  Future<void> _onLogout() async {
    final appState = context.appState;
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    LoadingDialog.show(context);
    try {
      await appState.logout();
      if (!mounted) return;
      LoadingDialog.hide(context);
      navigator.pushNamedAndRemoveUntil(AppRoutes.login, (route) => false);
    } catch (_) {
      if (!mounted) return;
      LoadingDialog.hide(context);
      messenger.showSnackBar(
        SnackBar(
          content: Text(context.t('profile.logoutError')),
          backgroundColor: AppColors.negative,
          action: SnackBarAction(
            label: 'OK',
            textColor: Colors.white,
            onPressed: () => messenger.hideCurrentSnackBar(),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.appState;
    final profile = appState.profile;
    final space = appState.activeSpace;
    final isPremium = profile.isBusinessPremium;

    return SafeArea(
      child: Column(
        children: [
          // ── Scrollable content ─────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 24, 18, 8),
              child: Column(
                children: [
                  // ── Avatar & nama ─────────────────────────────────────
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: context.appColors.chipBg,
                    child: Text(
                      profile.fullName.isNotEmpty
                          ? profile.fullName[0].toUpperCase()
                          : '?',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: context.appColors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    profile.fullName.isNotEmpty
                        ? profile.fullName
                        : context.t('profile.ownerName'),
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.w800),
                  ),
                  if (profile.businessName.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      profile.businessName,
                      style:
                          TextStyle(color: context.appColors.textSecondary),
                    ),
                  ],
                  const SizedBox(height: 12),

                  // ── Premium badge ─────────────────────────────────────
                  _PremiumBadge(isPremium: profile.isBusinessPremium),
                  const SizedBox(height: 12),
                  if (!isPremium) ...[
                    _UpgradeCtaCard(
                      onTap: () =>
                          Navigator.of(context).pushNamed(AppRoutes.upgrade),
                    ),
                  ],
                  const SizedBox(height: 16),

                  // ── Section: Ruang Aktif ──────────────────────────────
                  _SpacesSection(
                    spaces: appState.spaces,
                    activeSpaceId: appState.activeSpaceId,
                    onSwitch: (id) => appState.switchSpace(id),
                    onToggleActive: (id) => appState.toggleSpaceActive(id),
                    onAdd: () =>
                        Navigator.of(context).pushNamed(AppRoutes.setupSpaces),
                  ),
                  // ── Native Ad ─────────────────────────────────────────
                  _ProfileAdCard(),
                  const SizedBox(height: 16),

                  // ── Section: Akun ─────────────────────────────────────
                  _SectionLabel(context.t('profile.settingsSectionTitle')),
                  const SizedBox(height: 10),
                  _ProfileMenuItem(
                    icon: Icons.person_outline,
                    title: context.t('profile.menu.accountSettings'),
                    subtitle:
                        context.t('profile.menu.accountSettingsSubtitle'),
                    onTap: () => _openAccountSettings(context),
                  ),
                  const SizedBox(height: 8),
                  // Dompet — hanya untuk personal & store
                  if (!SpaceFeatures.canUseOutlets(space, isPremium)) ...[
                    _ProfileMenuItem(
                      icon: Icons.account_balance_wallet_outlined,
                      title: context.t('profile.menu.wallets'),
                      subtitle: context.t('profile.menu.walletsSubtitle'),
                      onTap: () =>
                          Navigator.of(context).pushNamed(AppRoutes.wallets),
                    ),
                    const SizedBox(height: 8),
                  ],

                  // ── Section: Fitur Aktif ──────────────────────────────
                  if (SpaceFeatures.canUseDebt(space, isPremium) ||
                      SpaceFeatures.canUseRecurring(space, isPremium) ||
                      SpaceFeatures.canUseBudget(space, isPremium) ||
                      SpaceFeatures.canUseOutlets(space, isPremium) ||
                      SpaceFeatures.canUseHpp(space, isPremium) ||
                      SpaceFeatures.canUseProductionBatch(space, isPremium) ||
                      SpaceFeatures.canUseStock(space, isPremium) ||
                      SpaceFeatures.canUseQuickSale(space, isPremium)) ...[
                    _SectionLabel('Fitur Aktif'),
                    const SizedBox(height: 10),
                  ],

                  if (SpaceFeatures.canUseDebt(space, isPremium)) ...[
                    _ProfileMenuItem(
                      icon: Icons.handshake_outlined,
                      title: context.t('profile.menu.debt'),
                      subtitle: context.t('profile.menu.debtSubtitle'),
                      onTap: () =>
                          Navigator.of(context).pushNamed(AppRoutes.debt),
                    ),
                    const SizedBox(height: 8),
                  ],
                  if (SpaceFeatures.canUseRecurring(space, isPremium)) ...[
                    _ProfileMenuItem(
                      icon: Icons.repeat_outlined,
                      title: context.t('profile.menu.recurring'),
                      subtitle: context.t('profile.menu.recurringSubtitle'),
                      onTap: () =>
                          Navigator.of(context).pushNamed(AppRoutes.recurring),
                    ),
                    const SizedBox(height: 8),
                  ],
                  if (SpaceFeatures.canUseBudget(space, isPremium)) ...[
                    _ProfileMenuItem(
                      icon: Icons.savings_outlined,
                      title: context.t('profile.menu.budget'),
                      subtitle: context.t('profile.menu.budgetSubtitle'),
                      onTap: () =>
                          Navigator.of(context).pushNamed(AppRoutes.budget),
                    ),
                    const SizedBox(height: 8),
                  ],
                  if (SpaceFeatures.canUseQuickSale(space, isPremium)) ...[
                    _ProfileMenuItem(
                      icon: Icons.point_of_sale,
                      title: context.t('profile.menu.quickSale'),
                      subtitle: context.t('profile.menu.quickSaleSubtitle'),
                      onTap: () =>
                          Navigator.of(context).pushNamed(AppRoutes.quickSale),
                    ),
                    const SizedBox(height: 8),
                  ],
                  if (SpaceFeatures.canUseOutlets(space, isPremium)) ...[
                    _ProfileMenuItem(
                      icon: Icons.store_outlined,
                      title: 'Kelola Outlet',
                      subtitle:
                          '${appState.outlets.length} outlet terdaftar',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const ManageOutletsScreen(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  if (SpaceFeatures.canUseHpp(space, isPremium)) ...[
                    _ProfileMenuItem(
                      icon: Icons.inventory_2_outlined,
                      title: context.t('profile.menu.product'),
                      subtitle: context.t('profile.menu.productSubtitle'),
                      onTap: () =>
                          Navigator.of(context).pushNamed(AppRoutes.productList),
                    ),
                    const SizedBox(height: 8),
                    _ProfileMenuItem(
                      icon: Icons.bar_chart,
                      title: 'Analitik Produk',
                      subtitle: 'Margin ranking & breakeven analysis',
                      onTap: () => Navigator.of(context)
                          .pushNamed(AppRoutes.productAnalytics),
                    ),
                    const SizedBox(height: 8),
                  ],
                  if (SpaceFeatures.canUseProductionBatch(
                      space, isPremium)) ...[
                    _ProfileMenuItem(
                      icon: Icons.science_outlined,
                      title: 'Bahan Baku',
                      subtitle:
                          '${appState.rawMaterials.length} bahan terdaftar',
                      onTap: () =>
                          Navigator.of(context).pushNamed(AppRoutes.rawMaterials),
                    ),
                    const SizedBox(height: 8),
                    _ProfileMenuItem(
                      icon: Icons.precision_manufacturing_outlined,
                      title: 'Batch Produksi',
                      subtitle:
                          '${appState.productionBatches.length} batch tercatat',
                      onTap: () => Navigator.of(context)
                          .pushNamed(AppRoutes.productionBatches),
                    ),
                    const SizedBox(height: 8),
                  ],
                  if (SpaceFeatures.canUseStock(space, isPremium)) ...[
                    _ProfileMenuItem(
                      icon: Icons.warehouse_outlined,
                      title: context.t('profile.menu.inventory'),
                      subtitle: context.t('profile.menu.inventorySubtitle'),
                      onTap: () =>
                          Navigator.of(context).pushNamed(AppRoutes.inventory),
                    ),
                    const SizedBox(height: 8),
                  ],

                  // ── Section: Pengaturan App ───────────────────────────
                  _SectionLabel('Pengaturan'),
                  const SizedBox(height: 10),
                  _ProfileMenuItem(
                    icon: Icons.category_outlined,
                    title: 'Kelola Kategori',
                    subtitle: 'Atur kategori pemasukan & pengeluaran',
                    onTap: () => Navigator.of(context)
                        .pushNamed(AppRoutes.manageCategories),
                  ),
                  const SizedBox(height: 8),
                  _ProfileMenuItem(
                    icon: Icons.notifications_outlined,
                    title: context.t('profile.menu.notifications'),
                    subtitle:
                        context.t('profile.menu.notificationsSubtitle'),
                    onTap: () => Navigator.of(context)
                        .pushNamed(AppRoutes.notificationSettings),
                  ),
                  const SizedBox(height: 8),
                  _ProfileMenuItem(
                    icon: Icons.lock_outline,
                    title: context.t('profile.menu.changePin'),
                    subtitle: context.t('profile.menu.changePinSubtitle'),
                    onTap: () =>
                        Navigator.of(context).pushNamed(AppRoutes.changePin),
                  ),
                  const SizedBox(height: 8),
                  _ProfileMenuItem(
                    icon: Icons.language,
                    title: context.t('profile.menu.language'),
                    subtitle: context.t('profile.menu.languageValue'),
                    onTap: () =>
                        Navigator.of(context).pushNamed(AppRoutes.settings),
                  ),
                ],
              ),
            ),
          ),

          // ── Fixed footer: Logout ───────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _onLogout,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.negative,
                      foregroundColor: Colors.white,
                    ),
                    child: Text(context.t('profile.menu.logout')),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  context.t('profile.versionLabel', {'version': _version}),
                  style: TextStyle(
                    color: context.appColors.textSecondary,
                    fontSize: 12,
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

class _ProfileMenuItem extends StatelessWidget {
  const _ProfileMenuItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.appColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.appColors.outline),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: context.appColors.cardSoft,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppColors.brandBlue),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: context.appColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: context.appColors.textSecondary),
          ],
        ),
      ),
    );
  }
}

class _ProfileAdCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70,
      decoration: BoxDecoration(
        color: context.appColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.appColors.outline),
      ),
      clipBehavior: Clip.hardEdge,
      child: const NativeAdCard(templateType: TemplateType.small),
    );
  }
}

// ── Section label ─────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontWeight: FontWeight.w700,
          letterSpacing: 1.4,
          fontSize: 11,
          color: context.appColors.textSecondary,
        ),
      ),
    );
  }
}

// ── Premium badge ─────────────────────────────────────────────────────────────

class _PremiumBadge extends StatelessWidget {
  const _PremiumBadge({required this.isPremium});

  final bool isPremium;

  @override
  Widget build(BuildContext context) {
    final color = isPremium ? AppColors.positive : AppColors.brandBlue;
    final icon = isPremium
        ? Icons.workspace_premium_outlined
        : Icons.person_outline;
    final label = isPremium ? 'Business Premium' : 'Gratis';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Ruang Aktif section ──────────────────────────────────────────────────────

class _SpacesSection extends StatelessWidget {
  const _SpacesSection({
    required this.spaces,
    required this.activeSpaceId,
    required this.onSwitch,
    required this.onToggleActive,
    required this.onAdd,
  });

  final List<SpaceModel> spaces;
  final String? activeSpaceId;
  final void Function(String id) onSwitch;
  final void Function(String id) onToggleActive;
  final VoidCallback onAdd;

  Color _accentColor(SpaceType type) => switch (type) {
        SpaceType.personal => AppColors.brandBlue,
        SpaceType.store => AppColors.positive,
        SpaceType.production => Colors.deepPurple,
      };

  String _emoji(SpaceType type) => switch (type) {
        SpaceType.personal => '💰',
        SpaceType.store => '🏪',
        SpaceType.production => '🏭',
      };

  @override
  Widget build(BuildContext context) {
    final activeCount = spaces.where((s) => s.isActive).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Ruang Aktif',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: context.appColors.textSecondary,
              ),
            ),
            if (spaces.length < 3)
              TextButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Tambah Ruang', style: TextStyle(fontSize: 13)),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        ...spaces.map((space) {
          final isCurrent = space.id == activeSpaceId;
          final isEnabled = space.isActive;
          final accent = _accentColor(space.type);
          final canDeactivate = isEnabled && activeCount > 1;

          return GestureDetector(
            onTap: isEnabled ? () => onSwitch(space.id) : null,
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isCurrent
                    ? accent.withValues(alpha: 0.08)
                    : context.appColors.card,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isCurrent
                      ? accent
                      : isEnabled
                          ? context.appColors.outline
                          : context.appColors.outline.withValues(alpha: 0.4),
                  width: isCurrent ? 1.5 : 1,
                ),
              ),
              child: Row(
                children: [
                  Text(
                    _emoji(space.type),
                    style: TextStyle(
                      fontSize: 20,
                      color: isEnabled ? null : const Color(0x66000000),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          space.type.displayName,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: isEnabled
                                ? (isCurrent
                                    ? accent
                                    : context.appColors.textPrimary)
                                : context.appColors.textSecondary,
                          ),
                        ),
                        if (!isEnabled)
                          Text(
                            'Non-aktif • Tap untuk aktifkan',
                            style: TextStyle(
                              fontSize: 11,
                              color: context.appColors.textSecondary,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (isCurrent)
                    Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: Icon(Icons.check_circle, color: accent, size: 18),
                    ),
                  // Tombol non-aktifkan / aktifkan
                  GestureDetector(
                    onTap: (!isEnabled || canDeactivate)
                        ? () => onToggleActive(space.id)
                        : null,
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Icon(
                        isEnabled
                            ? Icons.pause_circle_outline
                            : Icons.play_circle_outline,
                        size: 20,
                        color: !isEnabled
                            ? AppColors.positive
                            : canDeactivate
                                ? context.appColors.textSecondary
                                : context.appColors.outline,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}

// ── Upgrade CTA card ──────────────────────────────────────────────────────────

class _UpgradeCtaCard extends StatelessWidget {
  const _UpgradeCtaCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.positive.withValues(alpha: 0.85),
              AppColors.brandBlue.withValues(alpha: 0.85),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            const Icon(Icons.rocket_launch_outlined,
                color: Colors.white, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Upgrade Paket',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Akses fitur bisnis mulai Rp 20.000/bulan',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white),
          ],
        ),
      ),
    );
  }
}
