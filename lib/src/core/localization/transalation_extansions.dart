import 'package:flutter/material.dart';

import 'app_localizations.dart';

extension TranslationExtension on BuildContext {
  String t(String key, [Map<String, String> params = const {}]) {
    return AppLocalizations.of(this).translations.tr(key, params);
  }

  /// Tampilkan SnackBar dengan tombol dismiss "OK".
  void showSnackBar(String message, {Color? backgroundColor}) {
    // Pakai messenger langsung (bukan via `this` di dalam callback) supaya
    // tetap valid walau screen sudah di-pop saat OK ditekan.
    final messenger = ScaffoldMessenger.of(this);
    messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        // SnackBarAction otomatis menutup snackbar saat ditekan; cukup no-op.
        // Sebelumnya memanggil ScaffoldMessenger.of(this) pada context yang
        // sudah mati → exception → auto-dismiss ke-skip → snackbar nyangkut.
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {},
        ),
      ),
    );
  }
}