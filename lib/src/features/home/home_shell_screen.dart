import 'package:cari_untung/src/core/localization/transalation_extansions.dart';
import 'package:cari_untung/src/core/state/app_state.dart';
import 'package:cari_untung/src/core/theme/app_colors.dart';
import 'package:cari_untung/src/core/ui/app_gradient_scaffold.dart';
import 'package:cari_untung/src/features/home/home_screen.dart';
import 'package:cari_untung/src/features/product/product_list_screen.dart';
import 'package:flutter/material.dart';

import '../profile/profile_screen.dart';
import 'report_screen.dart';

class HomeShellScreen extends StatefulWidget {
  const HomeShellScreen({super.key});

  @override
  State<HomeShellScreen> createState() => _HomeShellScreenState();
}

class _SyncBanner extends StatelessWidget {
  const _SyncBanner();

  @override
  Widget build(BuildContext context) {
    final state = context.appState;
    final isSyncing = state.isSyncing;
    final pending = state.pendingCount;

    if (!isSyncing && pending == 0) return const SizedBox.shrink();

    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: Container(
        width: double.infinity,
        color: AppColors.chipBg,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  if (isSyncing) ...[
                    const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.brandBlue,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        pending > 0
                            ? 'Mengirim $pending transaksi ke server...'
                            : 'Memperbarui data dari server...',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ] else ...[
                    const Icon(
                      Icons.cloud_off_outlined,
                      size: 16,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '$pending transaksi belum tersimpan ke server',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (isSyncing)
              const LinearProgressIndicator(
                minHeight: 2,
                backgroundColor: AppColors.outline,
                color: AppColors.brandBlue,
              ),
          ],
        ),
      ),
    );
  }
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
      ProductListScreen(),
      ReportScreen(),
      ProfileScreen()
    ];
    return AppGradientScaffold(
      body: Column(
        children: [
          const _SyncBanner(),
          Expanded(child: pages[_index]),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: _onTap,
        type: BottomNavigationBarType.fixed, // Ensure all items are shown
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.home_outlined),
            activeIcon: const Icon(Icons.home),
            label: context.t('nav.home'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.inventory_2_outlined),
            activeIcon: const Icon(Icons.inventory_2),
            label: context.t('nav.product'),
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
