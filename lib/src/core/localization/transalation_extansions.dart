import 'package:flutter/material.dart';

import 'app_localizations.dart';

extension TranslationExtension on BuildContext {
  String t(String key, [Map<String, String> params = const {}]) {
    return AppLocalizations.of(this).translations.tr(key, params);
  }

  /// Tampilkan SnackBar dengan tombol dismiss "OK".
  void showSnackBar(String message, {Color? backgroundColor}) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () =>
              ScaffoldMessenger.of(this).hideCurrentSnackBar(),
        ),
      ),
    );
  }
}