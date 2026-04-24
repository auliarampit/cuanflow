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

  // Feature flags — hanya relevan jika mode bisnis dipilih
  bool _featureBudget = true;
  bool _featureOutlets = false;
  bool _featureProduct = false;

  bool get _isBusiness => _selected == 'business';

  Future<void> _confirm() async {
    if (_selected == null) return;
    final profile = context.appState.profile;
    await context.appState.updateProfile(
      profile.copyWith(
        featureProduct: _isBusiness ? _featureProduct : false,
        featureOutlets: _isBusiness ? _featureOutlets : false,
        featureBudget: _isBusiness ? _featureBudget : false,
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

              // ── Feature selection — muncul saat bisnis dipilih ─────────────
              AnimatedSize(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                child: _isBusiness
                    ? Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: _FeatureSelector(
                          featureBudget: _featureBudget,
                          featureOutlets: _featureOutlets,
                          featureProduct: _featureProduct,
                          onBudgetChanged: (v) =>
                              setState(() => _featureBudget = v),
                          onOutletsChanged: (v) =>
                              setState(() => _featureOutlets = v),
                          onProductChanged: (v) =>
                              setState(() => _featureProduct = v),
                        ),
                      )
                    : const SizedBox.shrink(),
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
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700),
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

// ── Feature selector — ditampilkan saat mode bisnis dipilih ──────────────────

class _FeatureSelector extends StatelessWidget {
  const _FeatureSelector({
    required this.featureBudget,
    required this.featureOutlets,
    required this.featureProduct,
    required this.onBudgetChanged,
    required this.onOutletsChanged,
    required this.onProductChanged,
  });

  final bool featureBudget;
  final bool featureOutlets;
  final bool featureProduct;
  final ValueChanged<bool> onBudgetChanged;
  final ValueChanged<bool> onOutletsChanged;
  final ValueChanged<bool> onProductChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.brandBlue.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: AppColors.brandBlue.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.t('onboarding.featureSelectTitle'),
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            context.t('onboarding.featureSelectHint'),
            style: TextStyle(
              fontSize: 11,
              color: context.appColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          _FeatureToggleRow(
            icon: Icons.savings_outlined,
            title: context.t('settings.featureBudget'),
            subtitle: context.t('settings.featureBudgetSubtitle'),
            value: featureBudget,
            onChanged: onBudgetChanged,
          ),
          const SizedBox(height: 8),
          _FeatureToggleRow(
            icon: Icons.store_outlined,
            title: context.t('settings.featureOutlets'),
            subtitle: context.t('settings.featureOutletsSubtitle'),
            value: featureOutlets,
            onChanged: onOutletsChanged,
          ),
          const SizedBox(height: 8),
          _FeatureToggleRow(
            icon: Icons.inventory_2_outlined,
            title: context.t('settings.featureProduct'),
            subtitle: context.t('settings.featureProductSubtitle'),
            value: featureProduct,
            onChanged: onProductChanged,
          ),
        ],
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
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () => onChanged(!value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: value
              ? AppColors.brandBlue.withValues(alpha: 0.08)
              : context.appColors.card,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: value
                ? AppColors.brandBlue.withValues(alpha: 0.35)
                : context.appColors.outline,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color:
                  value ? AppColors.brandBlue : context.appColors.textSecondary,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: value
                          ? AppColors.brandBlue
                          : context.appColors.textPrimary,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: context.appColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: value,
              onChanged: onChanged,
              activeThumbColor: AppColors.brandBlue,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Mode card ─────────────────────────────────────────────────────────────────

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
