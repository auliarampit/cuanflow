import 'package:flutter/material.dart';

import '../../core/localization/transalation_extansions.dart';
import '../../core/models/user_profile.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dynamic_colors.dart';
import '../../core/ui/app_gradient_scaffold.dart';

class AccountSettingsScreen extends StatefulWidget {
  const AccountSettingsScreen({super.key});

  @override
  State<AccountSettingsScreen> createState() => _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends State<AccountSettingsScreen> {
  final _fullNameController = TextEditingController();
  final _businessNameController = TextEditingController();
  final _whatsappController = TextEditingController();
  final _emailController = TextEditingController();

  bool _isSaving = false;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      final profile = context.appState.profile;
      _fullNameController.text = profile.fullName;
      _businessNameController.text = profile.businessName;
      _whatsappController.text = profile.whatsapp;
      _emailController.text = profile.email;
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _businessNameController.dispose();
    _whatsappController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    final updatedProfile = UserProfile(
      fullName: _fullNameController.text.trim(),
      businessName: _businessNameController.text.trim(),
      whatsapp: _whatsappController.text.trim(),
      email: _emailController.text.trim(),
      photoPath: context.appState.profile.photoPath,
    );

    try {
      await context.appState.updateProfile(updatedProfile);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.t('accountSettings.saveSuccess')),
          backgroundColor: AppColors.positive,
        ),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.t('accountSettings.saveError')),
          backgroundColor: AppColors.negative,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.appState.profile;

    return AppGradientScaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(context.t('accountSettings.title')),
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final bottomInset = MediaQuery.of(context).viewInsets.bottom;
          return SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(18, 18, 18, bottomInset + 24),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundColor: context.appColors.chipBg,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          profile.fullName.isNotEmpty
                              ? profile.fullName
                              : context.t('profile.ownerName'),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          profile.businessName.isNotEmpty
                              ? profile.businessName
                              : context.t('profile.businessName'),
                          style: TextStyle(
                            color: context.appColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    context.t('accountSettings.fullNameLabel'),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _fullNameController,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(
                      hintText: context.t('accountSettings.fullNameLabel'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    context.t('accountSettings.businessNameLabel'),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _businessNameController,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(
                      hintText: context.t('accountSettings.businessNameLabel'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    context.t('accountSettings.whatsappLabel'),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _whatsappController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      hintText: context.t('accountSettings.whatsappLabel'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    context.t('accountSettings.emailLabel'),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      hintText: context.t('accountSettings.emailLabel'),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.positive,
                        disabledBackgroundColor:
                            AppColors.positive.withValues(alpha: 0.4),
                        foregroundColor: Colors.black,
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.black54,
                              ),
                            )
                          : Text(context.t('accountSettings.saveButton')),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
