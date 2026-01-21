import 'package:cari_untung/src/core/localization/transalation_extansions.dart';
import 'package:cari_untung/src/core/ui/app_gradient_scaffold.dart';
import 'package:cari_untung/src/features/home/home_screen.dart';
import 'package:flutter/material.dart';

import '../profile/profile_screen.dart';
import 'report_screen.dart';

class HomeShellScreen extends StatefulWidget {
  const HomeShellScreen({super.key});

  @override
  State<HomeShellScreen> createState() => _HomeShellScreenState();
}

class _HomeShellScreenState extends State<HomeShellScreen> {
  int _index = 0;

  void _onTap(int index) {
    setState(() => _index = index);
  }

  @override
  Widget build(BuildContext context) {
    final pages = const [
      HomeScreen(),
      ReportScreen(),
      ProfileScreen()
    ];
    return AppGradientScaffold(
      body: pages[_index],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: _onTap,
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.home_outlined),
            activeIcon: const Icon(Icons.home),
            label: context.t('nav.home'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.bar_chart_outlined),
            activeIcon: const Icon(Icons.bar_chart),
            label: context.t('nav.report'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.person_outlined),
            activeIcon: const Icon(Icons.person),
            label: context.t('nav.profile'),
          ),
        ],
      ),
    );
  }
}
