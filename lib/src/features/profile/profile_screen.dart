import 'package:cari_untung/src/app/routes.dart';
import 'package:cari_untung/src/core/models/space_model.dart';
import 'package:cari_untung/src/core/models/subscription_tier.dart';
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
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.appState.profile;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 24, 18, 24),
        child: Column(
          children: [
            // ── Avatar & nama ─────────────────────────────────────────────
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
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            if (profile.businessName.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                profile.businessName,
                style: TextStyle(color: context.appColors.textSecondary),
              ),
            ],
            const SizedBox(height: 12),

            // ── Tier badge ────────────────────────────────────────────────
            _TierBadge(tier: profile.subscriptionTier),
            const SizedBox(height: 16),

            // ── Section: Ruang Aktif ──────────────────────────────────────
            _SpacesSection(
              spaces: context.appState.spaces,
              activeSpaceId: context.appState.activeSpaceId,
              onSwitch: (id) => context.appState.switchSpace(id),
              onAdd: () => Navigator.of(context).pushNamed(AppRoutes.setupSpaces),
            ),
            const SizedBox(height: 16),

            // ── Upgrade CTA (hanya untuk free tier) ───────────────────────
            if (profile.subscriptionTier == SubscriptionTier.free) ...[
              _UpgradeCtaCard(
                onTap: () =>
                    Navigator.of(context).pushNamed(AppRoutes.upgrade),
              ),
              const SizedBox(height: 16),
            ],

            // ── Section: Akun ─────────────────────────────────────────────
            _SectionLabel(context.t('profile.settingsSectionTitle')),
            const SizedBox(height: 10),
            _ProfileMenuItem(
              icon: Icons.person_outline,
              title: context.t('profile.menu.accountSettings'),
              subtitle: context.t('profile.menu.accountSettingsSubtitle'),
              onTap: () => _openAccountSettings(context),
            ),
            const SizedBox(height: 8),
            // Dompet — hanya untuk personal & store (produksi pakai outlet)
            if (!profile.featureOutlets) ...[
              _ProfileMenuItem(
                icon: Icons.account_balance_wallet_outlined,
                title: context.t('profile.menu.wallets'),
                subtitle: context.t('profile.menu.walletsSubtitle'),
                onTap: () => Navigator.of(context).pushNamed(AppRoutes.wallets),
              ),
              const SizedBox(height: 8),
            ],

            // ── Section: Fitur Aktif ───────────────────────────────────────
            if (profile.featureDebt ||
                profile.featureRecurring ||
                profile.featureBudget ||
                profile.featureOutlets ||
                profile.featureProduct ||
                profile.featureProduction ||
                profile.featureStock ||
                profile.featureQuickSale) ...[
              _SectionLabel('Fitur Aktif'),
              const SizedBox(height: 10),
            ],

            if (profile.featureDebt) ...[
              _ProfileMenuItem(
                icon: Icons.handshake_outlined,
                title: context.t('profile.menu.debt'),
                subtitle: context.t('profile.menu.debtSubtitle'),
                onTap: () => Navigator.of(context).pushNamed(AppRoutes.debt),
              ),
              const SizedBox(height: 8),
            ],
            if (profile.featureRecurring) ...[
              _ProfileMenuItem(
                icon: Icons.repeat_outlined,
                title: context.t('profile.menu.recurring'),
                subtitle: context.t('profile.menu.recurringSubtitle'),
                onTap: () =>
                    Navigator.of(context).pushNamed(AppRoutes.recurring),
              ),
              const SizedBox(height: 8),
            ],
            if (profile.featureBudget) ...[
              _ProfileMenuItem(
                icon: Icons.savings_outlined,
                title: context.t('profile.menu.budget'),
                subtitle: context.t('profile.menu.budgetSubtitle'),
                onTap: () => Navigator.of(context).pushNamed(AppRoutes.budget),
              ),
              const SizedBox(height: 8),
            ],
            if (profile.featureQuickSale) ...[
              _ProfileMenuItem(
                icon: Icons.point_of_sale,
                title: context.t('profile.menu.quickSale'),
                subtitle: context.t('profile.menu.quickSaleSubtitle'),
                onTap: () =>
                    Navigator.of(context).pushNamed(AppRoutes.quickSale),
              ),
              const SizedBox(height: 8),
            ],
            if (profile.featureOutlets) ...[
              _ProfileMenuItem(
                icon: Icons.store_outlined,
                title: 'Kelola Outlet',
                subtitle: '${context.appState.outlets.length} outlet terdaftar',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const ManageOutletsScreen(),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
            if (profile.featureProduct) ...[
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
                onTap: () =>
                    Navigator.of(context).pushNamed(AppRoutes.productAnalytics),
              ),
              const SizedBox(height: 8),
            ],
            if (profile.featureProduction) ...[
              _ProfileMenuItem(
                icon: Icons.science_outlined,
                title: 'Bahan Baku',
                subtitle:
                    '${context.appState.rawMaterials.length} bahan terdaftar',
                onTap: () =>
                    Navigator.of(context).pushNamed(AppRoutes.rawMaterials),
              ),
              const SizedBox(height: 8),
              _ProfileMenuItem(
                icon: Icons.precision_manufacturing_outlined,
                title: 'Batch Produksi',
                subtitle:
                    '${context.appState.productionBatches.length} batch tercatat',
                onTap: () =>
                    Navigator.of(context).pushNamed(AppRoutes.productionBatches),
              ),
              const SizedBox(height: 8),
            ],
            if (profile.featureStock) ...[
              _ProfileMenuItem(
                icon: Icons.warehouse_outlined,
                title: context.t('profile.menu.inventory'),
                subtitle: context.t('profile.menu.inventorySubtitle'),
                onTap: () =>
                    Navigator.of(context).pushNamed(AppRoutes.inventory),
              ),
              const SizedBox(height: 8),
            ],

            // ── Native Ad ─────────────────────────────────────────────────
            _ProfileAdCard(),
            const SizedBox(height: 8),

            // ── Section: Pengaturan App ───────────────────────────────────
            _SectionLabel('Pengaturan'),
            const SizedBox(height: 10),
            _ProfileMenuItem(
              icon: Icons.category_outlined,
              title: 'Kelola Kategori',
              subtitle: 'Atur kategori pemasukan & pengeluaran',
              onTap: () =>
                  Navigator.of(context).pushNamed(AppRoutes.manageCategories),
            ),
            const SizedBox(height: 8),
            _ProfileMenuItem(
              icon: Icons.notifications_outlined,
              title: context.t('profile.menu.notifications'),
              subtitle: context.t('profile.menu.notificationsSubtitle'),
              onTap: () => Navigator.of(context)
                  .pushNamed(AppRoutes.notificationSettings),
            ),
            const SizedBox(height: 8),
            _ProfileMenuItem(
              icon: Icons.lock_outline,
              title: context.t('profile.menu.changePin'),
              subtitle: context.t('profile.menu.changePinSubtitle'),
              onTap: () => Navigator.of(context).pushNamed(AppRoutes.changePin),
            ),
            const SizedBox(height: 8),
            _ProfileMenuItem(
              icon: Icons.language,
              title: context.t('profile.menu.language'),
              subtitle: context.t('profile.menu.languageValue'),
              onTap: () => Navigator.of(context).pushNamed(AppRoutes.settings),
            ),
            const SizedBox(height: 8),

            // ── Logout ────────────────────────────────────────────────────
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
            const SizedBox(height: 12),
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

// ── Tier badge ────────────────────────────────────────────────────────────────

class _TierBadge extends StatelessWidget {
  const _TierBadge({required this.tier});

  final SubscriptionTier tier;

  Color _color() {
    switch (tier) {
      case SubscriptionTier.free:
        return AppColors.brandBlue;
      case SubscriptionTier.retail:
        return AppColors.positive;
      case SubscriptionTier.production:
        return Colors.deepPurple;
    }
  }

  IconData _icon() {
    switch (tier) {
      case SubscriptionTier.free:
        return Icons.person_outline;
      case SubscriptionTier.retail:
        return Icons.store_outlined;
      case SubscriptionTier.production:
        return Icons.factory_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _color();
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
          Icon(_icon(), size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            'Paket ${tier.label}',
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

// ── Upgrade CTA card (free tier only) ────────────────────────────────────────

class _UpgradeCtaCard extends StatelessWidget {
  const _UpgradeCtaCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
                    'Akses fitur bisnis mulai Rp 19.000/bulan',
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

// ─── Ruang Aktif section ──────────────────────────────────────────────────────

class _SpacesSection extends StatelessWidget {
  const _SpacesSection({
    required this.spaces,
    required this.activeSpaceId,
    required this.onSwitch,
    required this.onAdd,
  });

  final List<SpaceModel> spaces;
  final String? activeSpaceId;
  final void Function(String id) onSwitch;
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
          final isActive = space.id == activeSpaceId;
          final accent = _accentColor(space.type);
          return GestureDetector(
            onTap: () => onSwitch(space.id),
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: isActive
                    ? accent.withValues(alpha: 0.08)
                    : context.appColors.card,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isActive ? accent : context.appColors.outline,
                  width: isActive ? 1.5 : 1,
                ),
              ),
              child: Row(
                children: [
                  Text(_emoji(space.type),
                      style: const TextStyle(fontSize: 20)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      space.type.displayName,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: isActive ? accent : context.appColors.textPrimary,
                      ),
                    ),
                  ),
                  if (isActive)
                    Icon(Icons.check_circle, color: accent, size: 18),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}
