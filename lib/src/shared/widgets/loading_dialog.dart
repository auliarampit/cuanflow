import 'package:flutter/material.dart';
import 'package:cari_untung/src/core/theme/app_colors.dart';
import 'package:cari_untung/src/core/theme/app_dynamic_colors.dart';

class LoadingDialog extends StatelessWidget {
  const LoadingDialog({super.key});

  /// Menampilkan loading modal
  static void show(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black54,
      builder: (_) => const LoadingDialog(),
    );
  }

  /// Menutup loading modal
  static void hide(BuildContext context) {
    if (Navigator.canPop(context)) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    // PopScope mencegah user menutup dialog dengan tombol back android
    return PopScope(
      canPop: false,
      child: Center(
        child: Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: context.appColors.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: context.appColors.outline),
          ),
          padding: const EdgeInsets.all(20),
          child: const CircularProgressIndicator(
            color: AppColors.brandBlue,
            strokeWidth: 3,
          ),
        ),
      ),
    );
  }
}
