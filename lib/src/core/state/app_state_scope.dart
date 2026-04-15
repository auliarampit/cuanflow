import 'package:flutter/material.dart';

import 'app_state.dart';

class AppStateScope extends InheritedNotifier<AppState> {
  const AppStateScope({
    super.key,
    required AppState state,
    required super.child,
  }) : super(notifier: state);

  static AppState of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<AppStateScope>();
    if (scope == null) {
      throw FlutterError('AppStateScope.of() called with no AppStateScope');
    }
    final state = scope.notifier;
    if (state == null) {
      throw FlutterError('AppStateScope has no notifier');
    }
    return state;
  }

  @override
  bool updateShouldNotify(covariant AppStateScope oldWidget) =>
      oldWidget.notifier != notifier;
}

extension AppStateContextExtension on BuildContext {
  AppState get appState => AppStateScope.of(this);
}
