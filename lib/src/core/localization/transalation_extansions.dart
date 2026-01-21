import 'package:flutter/widgets.dart';

import 'app_localizations.dart';

extension TranslationExtension on BuildContext {
  String t(String key, [Map<String, String> params = const {}]) {
    return AppLocalizations.of(this).translations.tr(key, params);
  }
}