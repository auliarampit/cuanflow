import 'package:cari_untung/src/app/routes.dart';
import 'package:cari_untung/src/core/localization/transalation_extansions.dart';
import 'package:cari_untung/src/core/theme/app_colors.dart';
import 'package:cari_untung/src/core/ui/app_gradient_scaffold.dart';
import 'package:cari_untung/src/features/auth/pin_input.dart';
import 'package:flutter/material.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phoneOrEmailController = TextEditingController();
  String _pinValue = '';

  @override
  void dispose() {
    _phoneOrEmailController.dispose();
    super.dispose();
  }

  bool get _canSubmit {
    return _phoneOrEmailController.text.trim().isNotEmpty &&
        _pinValue.length == 6;
  }

  void _onLogin() {
    if (!_canSubmit) return;
    Navigator.of(context).pushReplacementNamed(AppRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    return AppGradientScaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final bottomInset = MediaQuery.of(context).viewInsets.bottom;
          return SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(22, 0, 22, bottomInset + 16),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Column(
                children: [
                  const SizedBox(height: 40),
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F2A44),
                      borderRadius: BorderRadius.circular(22),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.savings,
                      color: AppColors.brandBlue,
                      size: 34,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    context.t('auth.login.title'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    context.t('auth.login.subtitle'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 40),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      context.t('auth.login.phoneEmailLabel'),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _phoneOrEmailController,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.person_outline),
                      hintText: context.t('auth.login.phoneEmailHint'),
                    ),
                  ),
                  const SizedBox(height: 22),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      context.t('auth.login.pinLabel'),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  PinInput(
                    length: 6,
                    onChanged: (v) => setState(() => _pinValue = v),
                  ),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {},
                      child: Text(context.t('auth.login.forgotPin')),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _canSubmit ? _onLogin : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.brandBlue,
                        disabledBackgroundColor: AppColors.brandBlue.withValues(
                          alpha: 0.35,
                        ),
                        foregroundColor: Colors.white,
                      ),
                      child: Text(context.t('auth.login.submit')),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        context.t('auth.login.noAccount'),
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                      TextButton(
                        onPressed: () {},
                        child: Text(context.t('auth.login.register')),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
