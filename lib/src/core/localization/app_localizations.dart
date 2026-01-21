import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'translations.dart';


class AppLocalizations {
  AppLocalizations(this.locale, this.translations);

  final Locale locale;
  final Translations translations;

  static const supportedLocales = <Locale>[
    Locale('en'),
    Locale('id'),
  ];

  static const localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    _AppLocalizationsDelegate(),
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ];

  static AppLocalizations of(BuildContext context) {
    final value = Localizations.of<AppLocalizations>(context, AppLocalizations);
    if (value == null) {
      throw FlutterError('AppLocalizations not found in context');
    }
    return value;
  }
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return AppLocalizations.supportedLocales
        .any((e) => e.languageCode == locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    final languageCode = locale.languageCode;
    final jsonString =
        await rootBundle.loadString('assets/i18n/$languageCode.json');
    final decoded = json.decode(jsonString);

    if (decoded is! Map<String, dynamic>) {
      throw FlutterError('Invalid i18n json for $languageCode');
    }

    final map = decoded.map((k, v) => MapEntry(k, v?.toString() ?? ''));
    return AppLocalizations(locale, Translations(map));
  }

  @override
  bool shouldReload(covariant LocalizationsDelegate<AppLocalizations> old) {
    return false;
  }
}
