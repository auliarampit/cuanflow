import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../core/localization/transalation_extansions.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dynamic_colors.dart';
import '../../core/ui/app_gradient_scaffold.dart';

class AboutAppScreen extends StatefulWidget {
  const AboutAppScreen({super.key});

  @override
  State<AboutAppScreen> createState() => _AboutAppScreenState();
}

class _AboutAppScreenState extends State<AboutAppScreen> {
  String _version = '';

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() => _version = '${info.version}+${info.buildNumber}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppGradientScaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(context.t('about.title')),
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          // ── Logo & App name ─────────────────────────────────────
          Center(
            child: Column(
              children: [
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F2A44),
                    borderRadius: BorderRadius.circular(26),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.savings,
                    color: AppColors.brandBlue,
                    size: 44,
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Cuan Flow',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  context.t('about.tagline'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: context.appColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: context.appColors.chipBg,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _version.isNotEmpty
                        ? 'v$_version'
                        : context.t('about.loadingVersion'),
                    style: const TextStyle(
                      color: AppColors.brandBlue,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),
          _SectionTitle(context.t('about.sectionApp')),
          const SizedBox(height: 10),

          // ── Info list ────────────────────────────────────────────
          _InfoTile(
            icon: Icons.info_outline,
            label: context.t('about.labelDescription'),
            value: context.t('about.descriptionValue'),
          ),
          _InfoTile(
            icon: Icons.code_outlined,
            label: context.t('about.labelVersion'),
            value: _version.isNotEmpty ? _version : '—',
          ),
          _InfoTile(
            icon: Icons.business_outlined,
            label: context.t('about.labelDeveloper'),
            value: 'Cari Untung Team',
          ),
          _InfoTile(
            icon: Icons.email_outlined,
            label: context.t('about.labelContact'),
            value: 'support@cuanflow.app',
            onTap: () {
              Clipboard.setData(
                const ClipboardData(text: 'support@cuanflow.app'),
              );
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(context.t('about.emailCopied')),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
          ),

          const SizedBox(height: 24),
          _SectionTitle(context.t('about.sectionLegal')),
          const SizedBox(height: 10),

          _LinkTile(
            icon: Icons.privacy_tip_outlined,
            label: context.t('about.privacyPolicy'),
            onTap: () {
              // TODO: buka URL privacy policy
            },
          ),
          _LinkTile(
            icon: Icons.gavel_outlined,
            label: context.t('about.termsOfService'),
            onTap: () {
              // TODO: buka URL terms of service
            },
          ),

          const SizedBox(height: 32),
          Center(
            child: Text(
              context.t('about.copyright'),
              style: TextStyle(
                color: context.appColors.textSecondary,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Private widgets ──────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
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

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: context.appColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.appColors.outline),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: AppColors.brandBlue, size: 22),
        title: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: context.appColors.textSecondary,
          ),
        ),
        subtitle: Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: context.appColors.textPrimary,
          ),
        ),
        trailing: onTap != null
            ? Icon(
                Icons.copy_outlined,
                size: 16,
                color: context.appColors.textSecondary,
              )
            : null,
      ),
    );
  }
}

class _LinkTile extends StatelessWidget {
  const _LinkTile({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: context.appColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.appColors.outline),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: AppColors.brandBlue, size: 22),
        title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 14,
          color: context.appColors.textSecondary,
        ),
      ),
    );
  }
}
