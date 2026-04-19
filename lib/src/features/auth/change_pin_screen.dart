import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/localization/transalation_extansions.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dynamic_colors.dart';
import '../../core/ui/app_gradient_scaffold.dart';
import '../../shared/widgets/loading_dialog.dart';
import 'pin_input.dart';

class ChangePinScreen extends StatefulWidget {
  const ChangePinScreen({super.key});

  @override
  State<ChangePinScreen> createState() => _ChangePinScreenState();
}

class _ChangePinScreenState extends State<ChangePinScreen> {
  String _currentPin = '';
  String _newPin = '';
  String _confirmPin = '';
  bool _isLoading = false;

  bool get _canSubmit =>
      _currentPin.length == 6 &&
      _newPin.length == 6 &&
      _confirmPin.length == 6 &&
      !_isLoading;

  Future<void> _changePin() async {
    if (!_canSubmit) return;

    if (_newPin != _confirmPin) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(context.t('auth.changePin.mismatch')),
        backgroundColor: AppColors.negative,
      ));
      return;
    }

    final email = context.appState.profile.email;
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(context.t('auth.changePin.error')),
        backgroundColor: AppColors.negative,
      ));
      return;
    }

    setState(() => _isLoading = true);
    LoadingDialog.show(context);

    // Step 1: Verifikasi PIN lama via signInWithPassword
    try {
      await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: _currentPin,
      );
    } on AuthException catch (e) {
      debugPrint('[ChangePIN] signIn AuthException: ${e.message}');
      if (!mounted) return;
      LoadingDialog.hide(context);
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(context.t('auth.changePin.wrongPin')),
        backgroundColor: AppColors.negative,
      ));
      return;
    } catch (e) {
      debugPrint('[ChangePIN] signIn error (${e.runtimeType}): $e');
      if (!mounted) return;
      LoadingDialog.hide(context);
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(context.t('auth.changePin.error')),
        backgroundColor: AppColors.negative,
      ));
      return;
    }

    // Step 2: Ganti ke PIN baru
    try {
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(password: _newPin),
      );

      if (!mounted) return;
      LoadingDialog.hide(context);
      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(context.t('auth.changePin.success')),
        backgroundColor: AppColors.positive,
      ));

      Navigator.of(context).pop();
    } on AuthException catch (e) {
      debugPrint('[ChangePIN] updateUser AuthException: ${e.message}');
      if (!mounted) return;
      LoadingDialog.hide(context);
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.message),
        backgroundColor: AppColors.negative,
      ));
    } catch (e) {
      debugPrint('[ChangePIN] updateUser error (${e.runtimeType}): $e');
      if (!mounted) return;
      LoadingDialog.hide(context);
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(context.t('auth.changePin.error')),
        backgroundColor: AppColors.negative,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppGradientScaffold(
      showAd: false,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(context.t('auth.changePin.title')),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          24,
          24,
          24,
          MediaQuery.of(context).viewInsets.bottom + 32,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon header
            Center(
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.brandBlue.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.lock_outline,
                  color: AppColors.brandBlue,
                  size: 32,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: Text(
                context.t('auth.changePin.subtitle'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: context.appColors.textSecondary,
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 32),

            // PIN Saat Ini
            _PinSection(
              label: context.t('auth.changePin.currentLabel'),
              onChanged: (v) => setState(() => _currentPin = v),
            ),
            const SizedBox(height: 24),

            // PIN Baru
            _PinSection(
              label: context.t('auth.changePin.newLabel'),
              onChanged: (v) => setState(() => _newPin = v),
            ),
            const SizedBox(height: 24),

            // Konfirmasi PIN Baru
            _PinSection(
              label: context.t('auth.changePin.confirmLabel'),
              onChanged: (v) => setState(() => _confirmPin = v),
            ),
            const SizedBox(height: 36),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _canSubmit ? _changePin : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brandBlue,
                  disabledBackgroundColor:
                      AppColors.brandBlue.withValues(alpha: 0.35),
                  foregroundColor: Colors.white,
                ),
                child: Text(
                  context.t('auth.changePin.submit'),
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PinSection extends StatelessWidget {
  const _PinSection({required this.label, required this.onChanged});

  final String label;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        PinInput(length: 6, onChanged: onChanged),
      ],
    );
  }
}
