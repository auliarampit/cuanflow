import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../app/routes.dart';
import '../../core/localization/transalation_extansions.dart';
import '../../core/models/user_profile.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dynamic_colors.dart';
import '../../core/ui/app_gradient_scaffold.dart';
import '../../core/ui/responsive_utils.dart';
import '../../shared/widgets/loading_dialog.dart';
import 'pin_input.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  String _pin = '';
  String _confirmPin = '';
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  bool get _canSubmit =>
      _nameController.text.trim().isNotEmpty &&
      _emailController.text.trim().isNotEmpty &&
      _pin.length == 6 &&
      _confirmPin.length == 6 &&
      !_isLoading;

  Future<void> _onRegister() async {
    if (!_canSubmit) return;

    if (_pin != _confirmPin) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(context.t('auth.register.pinMismatch')),
        backgroundColor: AppColors.negative,
      ));
      return;
    }

    setState(() => _isLoading = true);
    LoadingDialog.show(context);

    try {
      final email = _emailController.text.trim();
      final name = _nameController.text.trim();

      final response = await Supabase.instance.client.auth.signUp(
        email: email,
        password: _pin,
        data: {'full_name': name},
      );

      if (!mounted) return;

      final appState = context.appState;
      // Gunakan userId dari response agar profil tersimpan meski currentUser
      // belum di-set (misalnya saat email confirmation diaktifkan)
      await appState.updateProfile(
        UserProfile.empty().copyWith(fullName: name, email: email),
        userId: response.user?.id,
      );
      await appState.syncTransactions();

      if (mounted) {
        LoadingDialog.hide(context);
        Navigator.of(context).pushReplacementNamed(AppRoutes.modeSelection);
      }
    } on AuthException catch (e) {
      if (mounted) {
        LoadingDialog.hide(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.message),
          backgroundColor: AppColors.negative,
        ));
      }
    } catch (_) {
      if (mounted) {
        LoadingDialog.hide(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(context.t('auth.login.errorGeneric')),
          backgroundColor: AppColors.negative,
        ));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppGradientScaffold(
      showAd: false,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final bottomInset = MediaQuery.of(context).viewInsets.bottom;
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: AppBreakpoints.maxContentWidth),
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(22, 0, 22, bottomInset + 16),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight - 80),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      Text(
                        context.t('auth.register.title'),
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        context.t('auth.register.subtitle'),
                        style: TextStyle(
                          fontSize: 14,
                          color: context.appColors.textSecondary,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 32),
                      _FieldLabel(context.t('auth.register.nameLabel')),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _nameController,
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.person_outline),
                          hintText: context.t('auth.register.nameHint'),
                        ),
                      ),
                      const SizedBox(height: 18),
                      _FieldLabel(context.t('auth.login.phoneEmailLabel')),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _emailController,
                        onChanged: (_) => setState(() {}),
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.email_outlined),
                          hintText: context.t('auth.register.emailHint'),
                        ),
                      ),
                      const SizedBox(height: 18),
                      _FieldLabel(context.t('auth.register.pinLabel')),
                      const SizedBox(height: 8),
                      PinInput(
                        length: 6,
                        onChanged: (v) => setState(() => _pin = v),
                      ),
                      const SizedBox(height: 18),
                      _FieldLabel(context.t('auth.register.confirmPinLabel')),
                      const SizedBox(height: 8),
                      PinInput(
                        length: 6,
                        onChanged: (v) => setState(() => _confirmPin = v),
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _canSubmit ? _onRegister : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.brandBlue,
                            disabledBackgroundColor:
                                AppColors.brandBlue.withValues(alpha: 0.35),
                            foregroundColor: Colors.white,
                          ),
                          child: Text(context.t('auth.register.submit')),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
    );
  }
}
