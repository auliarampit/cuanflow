import 'package:flutter/material.dart';

import '../../core/localization/transalation_extansions.dart';
import '../../core/theme/app_colors.dart';
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
                          context.t('profile.ownerName'),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          context.t('profile.businessName'),
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
                      onPressed: () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.positive,
                        foregroundColor: Colors.black,
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
