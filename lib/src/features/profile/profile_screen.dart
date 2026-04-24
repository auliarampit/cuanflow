import 'package:cari_untung/src/app/routes.dart';
import 'package:cari_untung/src/core/state/app_state.dart';
import 'package:cari_untung/src/features/outlets/manage_outlets_screen.dart';
import 'package:cari_untung/src/features/categories/manage_categories_screen.dart';
import 'package:cari_untung/src/features/product/product_list_screen.dart';
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
            if (profile.isBusinessMode) ...[
              const SizedBox(height: 4),
              Text(
                profile.businessName.isNotEmpty
                    ? profile.businessName
                    : context.t('profile.businessName'),
                style: TextStyle(color: context.appColors.textSecondary),
              ),
            ],
            const SizedBox(height: 28),

            // ── Section label ─────────────────────────────────────────────
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                context.t('profile.settingsSectionTitle'),
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.4,
                  fontSize: 12,
                  color: context.appColors.textSecondary,
                ),
              ),
            ),
            const SizedBox(height: 10),

            // ── Menu items ────────────────────────────────────────────────
            _ProfileMenuItem(
              icon: Icons.person_outline,
              title: context.t('profile.menu.accountSettings'),
              subtitle: context.t('profile.menu.accountSettingsSubtitle'),
              onTap: () => _openAccountSettings(context),
            ),
            const SizedBox(height: 8),

            // Dompet — hanya untuk personal (bisnis: tidak perlu)
            if (!profile.isBusinessMode) ...[
              _ProfileMenuItem(
                icon: Icons.account_balance_wallet_outlined,
                title: context.t('profile.menu.wallets'),
                subtitle: context.t('profile.menu.walletsSubtitle'),
                onTap: () => Navigator.of(context).pushNamed(AppRoutes.wallets),
              ),
              const SizedBox(height: 8),
            ],
            _ProfileMenuItem(
              icon: Icons.handshake_outlined,
              title: context.t('profile.menu.debt'),
              subtitle: context.t('profile.menu.debtSubtitle'),
              onTap: () => Navigator.of(context).pushNamed(AppRoutes.debt),
            ),
            const SizedBox(height: 8),
            _ProfileMenuItem(
              icon: Icons.repeat_outlined,
              title: context.t('profile.menu.recurring'),
              subtitle: context.t('profile.menu.recurringSubtitle'),
              onTap: () =>
                  Navigator.of(context).pushNamed(AppRoutes.recurring),
            ),
            const SizedBox(height: 8),
            _ProfileMenuItem(
              icon: Icons.savings_outlined,
              title: context.t('profile.menu.budget'),
              subtitle: context.t('profile.menu.budgetSubtitle'),
              onTap: () => Navigator.of(context).pushNamed(AppRoutes.budget),
            ),
            const SizedBox(height: 8),

            // Business-only menus (each gated by its own feature flag)
            if (profile.featureOutlets) ...[
              _ProfileMenuItem(
                icon: Icons.store_outlined,
                title: 'Kelola Outlet',
                subtitle:
                    '${context.appState.outlets.length} outlet terdaftar',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (_) => const ManageOutletsScreen()),
                ),
              ),
              const SizedBox(height: 8),
            ],
            if (profile.featureProduct) ...[
              _ProfileMenuItem(
                icon: Icons.inventory_2_outlined,
                title: context.t('profile.menu.product'),
                subtitle: context.t('profile.menu.productSubtitle'),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ProductListScreen()),
                ),
              ),
              const SizedBox(height: 8),
            ],
            if (profile.isBusinessMode) ...[
              _ProfileMenuItem(
                icon: Icons.warehouse_outlined,
                title: context.t('profile.menu.inventory'),
                subtitle: context.t('profile.menu.inventorySubtitle'),
                onTap: () =>
                    Navigator.of(context).pushNamed(AppRoutes.inventory),
              ),
              const SizedBox(height: 8),
              _ProfileMenuItem(
                icon: Icons.point_of_sale,
                title: context.t('profile.menu.quickSale'),
                subtitle: context.t('profile.menu.quickSaleSubtitle'),
                onTap: () =>
                    Navigator.of(context).pushNamed(AppRoutes.quickSale),
              ),
              const SizedBox(height: 8),
            ],

            _ProfileMenuItem(
              icon: Icons.category_outlined,
              title: 'Kelola Kategori',
              subtitle: 'Atur kategori pemasukan & pengeluaran',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (_) => const ManageCategoriesScreen()),
              ),
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
              onTap: () =>
                  Navigator.of(context).pushNamed(AppRoutes.changePin),
            ),
            const SizedBox(height: 8),
            _ProfileMenuItem(
              icon: Icons.language,
              title: context.t('profile.menu.language'),
              subtitle: context.t('profile.menu.languageValue'),
              onTap: () => Navigator.of(context).pushNamed(AppRoutes.settings),
            ),
            const SizedBox(height: 8),

            // ── Native Ad (styled as menu card) ───────────────────────────
            _ProfileAdCard(),
            const SizedBox(height: 24),

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
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                    ),
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
