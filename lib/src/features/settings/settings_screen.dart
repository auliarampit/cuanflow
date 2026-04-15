import 'package:flutter/material.dart';

import '../../app/routes.dart';
import '../../core/localization/transalation_extansions.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dynamic_colors.dart';
import '../../core/ui/app_gradient_scaffold.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final settings = context.appState.settings;

    return AppGradientScaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(context.t('settings.title')),
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
        children: [
          _SectionLabel(context.t('settings.sectionPreferences')),
          const SizedBox(height: 8),

          // Tema
          _SettingsTile(
            icon: Icons.palette_outlined,
            title: context.t('settings.appTheme'),
            trailing: Text(
              _themeLabel(context, settings.themeMode),
              style: TextStyle(
                color: context.appColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            onTap: () => _showThemeSelector(context),
          ),
          const SizedBox(height: 10),

          // Bahasa
          _SettingsTile(
            icon: Icons.language_outlined,
            title: context.t('settings.language'),
            trailing: Text(
              settings.localeCode.toUpperCase(),
              style: TextStyle(
                color: context.appColors.textSecondary,
                fontWeight: FontWeight.bold,
              ),
            ),
            onTap: () => _showLanguageSelector(context),
          ),
          const SizedBox(height: 10),

          // Notifikasi
          _SettingsSwitchTile(
            icon: Icons.notifications_outlined,
            title: context.t('settings.dailyNotification'),
            value: settings.dailyNotification,
            onChanged: (v) {
              context.appState.updateSettings(
                settings.copyWith(dailyNotification: v),
              );
            },
          ),

          const SizedBox(height: 20),
          _SectionLabel(context.t('settings.sectionInfo')),
          const SizedBox(height: 8),

          // Tentang Aplikasi
          _SettingsTile(
            icon: Icons.info_outline,
            title: context.t('settings.aboutApp'),
            onTap: () =>
                Navigator.of(context).pushNamed(AppRoutes.aboutApp),
          ),
        ],
      ),
    );
  }

  String _themeLabel(BuildContext context, String themeMode) {
    return switch (themeMode) {
      'light' => context.t('settings.themeLight'),
      'dark' => context.t('settings.themeDark'),
      _ => context.t('settings.themeSystem'),
    };
  }

  void _showThemeSelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.appColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        final current = context.appState.settings.themeMode;
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 16),
              _BottomSheetHandle(),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
                child: Text(
                  context.t('settings.appTheme'),
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ),
              _ThemeOption(
                icon: Icons.brightness_auto_outlined,
                label: context.t('settings.themeSystem'),
                value: 'system',
                isSelected: current == 'system',
                onTap: () {
                  context.appState.updateSettings(
                    context.appState.settings.copyWith(themeMode: 'system'),
                  );
                  Navigator.pop(ctx);
                },
              ),
              _ThemeOption(
                icon: Icons.light_mode_outlined,
                label: context.t('settings.themeLight'),
                value: 'light',
                isSelected: current == 'light',
                onTap: () {
                  context.appState.updateSettings(
                    context.appState.settings.copyWith(themeMode: 'light'),
                  );
                  Navigator.pop(ctx);
                },
              ),
              _ThemeOption(
                icon: Icons.dark_mode_outlined,
                label: context.t('settings.themeDark'),
                value: 'dark',
                isSelected: current == 'dark',
                onTap: () {
                  context.appState.updateSettings(
                    context.appState.settings.copyWith(themeMode: 'dark'),
                  );
                  Navigator.pop(ctx);
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  void _showLanguageSelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.appColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 16),
              _BottomSheetHandle(),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
                child: Text(
                  context.t('settings.language'),
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ),
              _LanguageOption(
                label: 'Bahasa Indonesia',
                code: 'id',
                isSelected: context.appState.settings.localeCode == 'id',
                onTap: () {
                  context.appState.updateSettings(
                    context.appState.settings.copyWith(localeCode: 'id'),
                  );
                  Navigator.pop(ctx);
                },
              ),
              _LanguageOption(
                label: 'English',
                code: 'en',
                isSelected: context.appState.settings.localeCode == 'en',
                onTap: () {
                  context.appState.updateSettings(
                    context.appState.settings.copyWith(localeCode: 'en'),
                  );
                  Navigator.pop(ctx);
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }
}

// ── Private widgets ──────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        fontWeight: FontWeight.w700,
        fontSize: 11,
        letterSpacing: 1.4,
        color: context.appColors.textSecondary,
      ),
    );
  }
}

class _BottomSheetHandle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: context.appColors.outline,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.appColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.appColors.outline),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: AppColors.brandBlue, size: 22),
        title: Text(title, style: const TextStyle(fontSize: 15)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (trailing != null) trailing!,
            const SizedBox(width: 6),
            Icon(Icons.chevron_right, color: context.appColors.textSecondary),
          ],
        ),
      ),
    );
  }
}

class _SettingsSwitchTile extends StatelessWidget {
  const _SettingsSwitchTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: context.appColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.appColors.outline),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.brandBlue, size: 22),
          const SizedBox(width: 14),
          Expanded(child: Text(title, style: const TextStyle(fontSize: 15))),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _ThemeOption extends StatelessWidget {
  const _ThemeOption({
    required this.icon,
    required this.label,
    required this.value,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Icon(
        icon,
        color: isSelected ? AppColors.brandBlue : context.appColors.textSecondary,
      ),
      title: Text(
        label,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
          color: isSelected ? AppColors.brandBlue : context.appColors.textPrimary,
        ),
      ),
      trailing: isSelected
          ? const Icon(Icons.check, color: AppColors.brandBlue)
          : null,
    );
  }
}

class _LanguageOption extends StatelessWidget {
  const _LanguageOption({
    required this.label,
    required this.code,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final String code;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      title: Text(
        label,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? AppColors.brandBlue : context.appColors.textPrimary,
        ),
      ),
      trailing: isSelected
          ? const Icon(Icons.check, color: AppColors.brandBlue)
          : null,
    );
  }
}
