import 'package:flutter/material.dart';

import '../features/history/history_screen.dart';
import '../features/profile/profile_screen.dart';
import '../features/home/report_screen.dart';
import '../features/profile/account_settings_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/transactions/add_expense/add_expense_screen.dart';
import '../features/transactions/add_income/add_income_screen.dart';
import '../features/home/home_shell_screen.dart';
import '../features/auth/login_screen.dart';
import '../features/splash/splash_screen.dart';



import 'routes.dart';

final class AppRouter {
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.splash:
        return MaterialPageRoute(builder: (_) => const SplashScreen());
      case AppRoutes.login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case AppRoutes.home:
        return MaterialPageRoute(builder: (_) => const HomeShellScreen());
      case AppRoutes.addIncome:
        return MaterialPageRoute(builder: (_) => const AddIncomeScreen());
      case AppRoutes.addExpense:
        return MaterialPageRoute(builder: (_) => const AddExpenseScreen());
      case AppRoutes.history:
        return MaterialPageRoute(builder: (_) => const HistoryScreen());
      case AppRoutes.report:
        return MaterialPageRoute(builder: (_) => const ReportScreen());
      case AppRoutes.profile:
        return MaterialPageRoute(builder: (_) => const ProfileScreen());
      case AppRoutes.accountSettings:
        return MaterialPageRoute(builder: (_) => const AccountSettingsScreen());
      case AppRoutes.settings:
        return MaterialPageRoute(builder: (_) => const SettingsScreen());
      default:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
    }
  }
}
