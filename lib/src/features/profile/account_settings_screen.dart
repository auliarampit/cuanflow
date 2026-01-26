import 'package:flutter/material.dart';

import '../../core/localization/transalation_extansions.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/app_colors.dart';
import '../../core/ui/app_gradient_scaffold.dart';
import '../../shared/widgets/loading_dialog.dart';

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

  @override
  void initState() {
    super.initState();
    // Initialize controllers with current state immediately
    _updateControllersFromState();
    
    // Fetch latest profile from API after frame build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchLatestProfile();
    });
  }

  void _updateControllersFromState() {
    // Safe to access context.appState here if called from build or callbacks,
    // but in initState context might be unstable for InheritedWidget.
    // However, since we are using this inside initState, we need to be careful.
    // Better to use addPostFrameCallback for the initial fetch logic.
    // For now, we will leave the initial controller values empty or wait for the callback.
  }

  void _fetchLatestProfile() {
    final profile = context.appState.profile;
    debugPrint('Profile: ${profile.toJson()}');
    setState(() {
       _fullNameController.text = profile.fullName;
       _businessNameController.text = profile.businessName;
       _whatsappController.text = profile.whatsapp;
       _emailController.text = profile.email;
    });

    context.appState.fetchProfile().then((_) {
      if (mounted) {
        final updatedProfile = context.appState.profile;
        setState(() {
          _fullNameController.text = updatedProfile.fullName;
          _businessNameController.text = updatedProfile.businessName;
          _whatsappController.text = updatedProfile.whatsapp;
          _emailController.text = updatedProfile.email;
        });
      }
    });
  }

  void _onSave() async {
    LoadingDialog.show(context);
    try {
      final currentProfile = context.appState.profile;
      final newProfile = currentProfile.copyWith(
        fullName: _fullNameController.text.trim(),
        businessName: _businessNameController.text.trim(),
        whatsapp: _whatsappController.text.trim(),
        email: _emailController.text.trim(),
      );

      await context.appState.saveProfile(newProfile);

      if (mounted) {
        LoadingDialog.hide(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.t('accountSettings.successMessage')),
            backgroundColor: AppColors.positive,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        LoadingDialog.hide(context);
      }
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

  @override
  Widget build(BuildContext context) {
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
                        const CircleAvatar(
                          radius: 40,
                          backgroundColor: AppColors.chipBg,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          _fullNameController.text,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _businessNameController.text,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
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
                      onPressed: _onSave,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.brandBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(context.t('accountSettings.saveButton')),
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
