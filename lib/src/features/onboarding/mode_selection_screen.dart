import 'package:flutter/material.dart';

import '../../app/routes.dart';
import '../../core/localization/transalation_extansions.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dynamic_colors.dart';

class ModeSelectionScreen extends StatefulWidget {
  const ModeSelectionScreen({super.key});

  @override
  State<ModeSelectionScreen> createState() => _ModeSelectionScreenState();
}

class _ModeSelectionScreenState extends State<ModeSelectionScreen> {
  String? _selected;

  Future<void> _confirm() async {
    if (_selected == null) return;
    final isBusiness = _selected == 'business';
    final profile = context.appState.profile;
    await context.appState.updateProfile(
      profile.copyWith(
        featureProduct: isBusiness,
        featureOutlets: isBusiness,
        featureBudget: isBusiness,
        onboardingComplete: true,
      ),
    );
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed(AppRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 40, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              Text(
                context.t('onboarding.question'),
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                context.t('onboarding.subtitle'),
                style: TextStyle(
                  color: context.appColors.textSecondary,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 40),
              _ModeCard(
                selected: _selected == 'personal',
                icon: Icons.account_balance_wallet_outlined,
                title: context.t('onboarding.personalTitle'),
                subtitle: context.t('onboarding.personalSubtitle'),
                features: [
                  context.t('onboarding.personalFeature1'),
                  context.t('onboarding.personalFeature2'),
                  context.t('onboarding.personalFeature3'),
                  context.t('onboarding.personalFeature4'),
                ],
                onTap: () => setState(() => _selected = 'personal'),
              ),
              const SizedBox(height: 16),
              _ModeCard(
                selected: _selected == 'business',
                icon: Icons.storefront_outlined,
                title: context.t('onboarding.businessTitle'),
                subtitle: context.t('onboarding.businessSubtitle'),
                features: [
                  context.t('onboarding.businessFeature1'),
                  context.t('onboarding.businessFeature2'),
                  context.t('onboarding.businessFeature3'),
                  context.t('onboarding.businessFeature4'),
                ],
                onTap: () => setState(() => _selected = 'business'),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _selected != null ? _confirm : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.brandBlue,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor:
                        AppColors.brandBlue.withValues(alpha: 0.3),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    context.t('onboarding.start'),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  const _ModeCard({
    required this.selected,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.features,
    required this.onTap,
  });

  final bool selected;
  final IconData icon;
  final String title;
  final String subtitle;
  final List<String> features;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final borderColor =
        selected ? AppColors.brandBlue : context.appColors.outline;
    final bgColor = selected
        ? AppColors.brandBlue.withValues(alpha: 0.07)
        : context.appColors.card;

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: selected ? 2 : 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: selected
                        ? AppColors.brandBlue.withValues(alpha: 0.15)
                        : context.appColors.cardSoft,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: selected
                        ? AppColors.brandBlue
                        : context.appColors.textSecondary,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: selected
                          ? AppColors.brandBlue
                          : context.appColors.textPrimary,
                    ),
                  ),
                ),
                if (selected)
                  const Icon(Icons.check_circle,
                      color: AppColors.brandBlue, size: 22),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              subtitle,
              style: TextStyle(
                color: context.appColors.textSecondary,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 10),
            ...features.map(
              (f) => Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  children: [
                    Icon(Icons.check, size: 14, color: AppColors.positive),
                    const SizedBox(width: 6),
                    Text(
                      f,
                      style: TextStyle(
                        fontSize: 13,
                        color: context.appColors.textSecondary,
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
