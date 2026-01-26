import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../app/routes.dart';
import '../../core/localization/transalation_extansions.dart';
import '../../core/theme/app_colors.dart';
import '../../core/ui/app_gradient_scaffold.dart';
import '../../shared/widgets/loading_dialog.dart';
import 'pin_input.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _emailController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _businessNameController = TextEditingController();
  final _whatsappController = TextEditingController();
  String _pinValue = '';
  
  final bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _fullNameController.dispose();
    _businessNameController.dispose();
    _whatsappController.dispose();
    super.dispose();
  }

  bool get _canSubmit {
    return _emailController.text.trim().isNotEmpty &&
        _fullNameController.text.trim().isNotEmpty &&
        _businessNameController.text.trim().isNotEmpty &&
        _whatsappController.text.trim().isNotEmpty &&
        _pinValue.length == 6 &&
        !_isLoading;
  }

  Future<void> _onRegister() async {
    if (!_canSubmit) return;

    final email = _emailController.text.trim();
    // Simple email validation regex
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.t('auth.register.error.emailInvalid')), backgroundColor: AppColors.negative),
      );
      return;
    }

    LoadingDialog.show(context);
    try {
      final password = _pinValue; // Using PIN as password
      final fullName = _fullNameController.text.trim();
      final businessName = _businessNameController.text.trim();
      final whatsapp = _whatsappController.text.trim();

      debugPrint('[Auth] Registering user: $email');

      final authResponse = await Supabase.instance.client.auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': fullName,
          'business_name': businessName,
          'whatsapp': whatsapp,
        },
      );

      // Attempt to create profile in 'profiles' table
      if (authResponse.user != null) {
        try {
          debugPrint('[Auth] Creating user profile in public table...');
          await Supabase.instance.client.from('profiles').upsert({
            'id': authResponse.user!.id,
            'full_name': fullName,
            'business_name': businessName,
            'whatsapp': whatsapp,
            'email': email,
            'updated_at': DateTime.now().toIso8601String(),
          });
          debugPrint('[Auth] Profile created successfully');
        } catch (e) {
          // If this fails (e.g., due to RLS or email verification pending), 
          // we log it but don't fail the registration flow.
          // The profile might be created later or via database trigger.
          debugPrint('[Auth] Profile creation warning: $e');
        }
      }

      debugPrint('[Auth] Registration success');

      if (mounted) {
        LoadingDialog.hide(context);
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text(context.t('auth.register.success')), backgroundColor: AppColors.positive),
        );
        Navigator.of(context).pushReplacementNamed(AppRoutes.login);
      }
    } on AuthException catch (e) {
      debugPrint('[Auth] Registration AuthException: ${e.message} (code: ${e.statusCode})');
      if (mounted) {
        LoadingDialog.hide(context);
        
        String errorMessage = e.message;
        if (e.message.toLowerCase().contains('rate limit')) {
          errorMessage = context.t('auth.register.error.rateLimit');
        } else if (e.message.toLowerCase().contains('password')) {
          errorMessage = context.t('auth.register.error.weakPassword');
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage), backgroundColor: AppColors.negative),
        );
      }
    } catch (e) {
      debugPrint('[Auth] Registration General Error: $e');
      if (mounted) {
        LoadingDialog.hide(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Registration failed: $e'), backgroundColor: AppColors.negative),
        );
      }
    }
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
                      Icons.person_add,
                      color: AppColors.brandBlue,
                      size: 34,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    context.t('auth.register.title'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    context.t('auth.register.subtitle'),
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
                      context.t('auth.register.fullNameLabel'),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _fullNameController,
                    onChanged: (_) => setState(() {}),
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.person_outline),
                      hintText: context.t('auth.register.fullNameHint'),
                    ),
                  ),
                  const SizedBox(height: 22),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      context.t('auth.register.businessNameLabel'),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _businessNameController,
                    onChanged: (_) => setState(() {}),
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.store_outlined),
                      hintText: context.t('auth.register.businessNameHint'),
                    ),
                  ),
                  const SizedBox(height: 22),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      context.t('auth.register.whatsappLabel'),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _whatsappController,
                    onChanged: (_) => setState(() {}),
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.phone_android_outlined),
                      hintText: context.t('auth.register.whatsappHint'),
                    ),
                  ),
                  const SizedBox(height: 22),
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
                    controller: _emailController,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.email_outlined),
                      hintText: context.t('auth.login.phoneEmailHint'),
                    ),
                    keyboardType: TextInputType.emailAddress,
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
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _canSubmit ? _onRegister : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.brandBlue,
                        disabledBackgroundColor: AppColors.brandBlue.withOpacity(0.35),
                        foregroundColor: Colors.white,
                      ),
                      child: Text(context.t('auth.register.submit')),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        context.t('auth.register.haveAccount'),
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pushReplacementNamed(AppRoutes.login),
                        child: Text(context.t('auth.register.login')),
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
