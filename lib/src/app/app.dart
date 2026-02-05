import 'package:cari_untung/src/features/splash/splash_screen.dart';
import 'package:flutter/material.dart';

import '../core/state/app_state.dart';
import '../core/theme/app_theme.dart';
import '../core/localization/app_localizations.dart';
import 'router.dart';

class CariUntungApp extends StatefulWidget {
  const CariUntungApp({super.key});

  @override
  State<CariUntungApp> createState() => _CariUntungAppState();
}

class _CariUntungAppState extends State<CariUntungApp> {
  final AppState _state = AppState();

  @override
  void initState() {
    super.initState();
    _state.init();
  }

  @override
  Widget build(BuildContext context) {
    return AppStateScope(
      state: _state,
      child: AnimatedBuilder(
        animation: _state,
        builder: (context, child) {
          return MaterialApp(
            title: 'Cuan Flow',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.dark,
            locale: Locale(_state.settings.localeCode),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            onGenerateRoute: AppRouter.onGenerateRoute,
            home: const SplashScreen(),
          );
        },
      ),
    );
  }
}
