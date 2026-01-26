import 'package:cari_untung/src/app/routes.dart';
import 'package:cari_untung/src/shared/widgets/loading_dialog.dart';
import 'package:flutter/material.dart';

import '../../core/localization/transalation_extansions.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/app_colors.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  void _openAccountSettings(BuildContext context) {
    Navigator.of(context).pushNamed(AppRoutes.accountSettings);
  }

  void _onLogout(BuildContext context) async {
    LoadingDialog.show(context);
    await context.appState.logout();
    if (context.mounted) {
      LoadingDialog.hide(context);
      Navigator.of(
        context,
      ).pushReplacementNamed(AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 24, 18, 16),
        child: Column(
          children: [
            const CircleAvatar(radius: 40, backgroundColor: AppColors.chipBg),
            const SizedBox(height: 16),
            Text(
              context.appState.profile.fullName,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              context.appState.profile.businessName,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                context.t('profile.settingsSectionTitle'),
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.4,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            const SizedBox(height: 12),
            _ProfileMenuItem(
              icon: Icons.person_outline,
              title: context.t('profile.menu.accountSettings'),
              subtitle: context.t('profile.menu.accountSettingsSubtitle'),
              onTap: () => _openAccountSettings(context),
            ),
            const SizedBox(height: 10),
            // _ProfileMenuItem(
            //   icon: Icons.lock_outline,
            //   title: context.t('profile.menu.changePin'),
            //   subtitle: context.t('profile.menu.changePinSubtitle'),
            //   onTap: () {},
            // ),
            const SizedBox(height: 10),
            _ProfileMenuItem(
              icon: Icons.language,
              title: context.t('profile.menu.language'),
              subtitle: context.t('profile.menu.languageValue'),
              onTap: () {
                Navigator.of(context).pushNamed(AppRoutes.settings);
              },
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _onLogout(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.negative,
                  foregroundColor: Colors.white,
                ),
                child: Text(context.t('profile.menu.logout')),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              context.t('profile.versionLabel'),
              style: const TextStyle(
                color: AppColors.textSecondary,
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
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.outline),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.cardSoft,
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
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}
