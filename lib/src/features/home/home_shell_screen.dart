import 'package:cari_untung/src/core/localization/transalation_extansions.dart';
import 'package:cari_untung/src/core/models/outlet_model.dart';
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
    final hasError = state.hasSyncError;
    final errorMsg = state.lastSyncError;

    if (!isSyncing && pending == 0 && !hasError) return const SizedBox.shrink();

    // Tentukan warna dan konten berdasarkan state
    final Color bannerColor;
    final Widget content;

    if (hasError && pending > 0) {
      // Gagal sync — tampilkan error
      bannerColor = AppColors.negative.withValues(alpha: 0.15);
      content = Row(
        children: [
          const Icon(Icons.sync_problem_outlined,
              size: 16, color: AppColors.negative),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$pending transaksi gagal dikirim ke server',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.negative,
                  ),
                ),
                if (errorMsg != null)
                  Text(
                    errorMsg,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => context.appState.syncTransactions(),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              foregroundColor: AppColors.negative,
            ),
            child: const Text('Coba lagi',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
          ),
        ],
      );
    } else if (isSyncing) {
      // Sedang sinkron
      bannerColor = AppColors.chipBg;
      content = Row(
        children: [
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
        ],
      );
    } else {
      // Pending tapi belum pernah coba (offline)
      bannerColor = AppColors.chipBg;
      content = Row(
        children: [
          const Icon(Icons.cloud_off_outlined,
              size: 16, color: AppColors.textSecondary),
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
          TextButton(
            onPressed: () => context.appState.syncTransactions(),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              foregroundColor: AppColors.brandBlue,
            ),
            child: const Text('Sinkron',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
          ),
        ],
      );
    }

    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: Container(
        width: double.infinity,
        color: bannerColor,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: content,
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

  void _showOutletPicker(BuildContext context) {
    final appState = context.appState;
    final outlets = appState.outlets;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                child: Text(
                  context.t('outlet.selectOutlet'),
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ),
              // Opsi "Semua Outlet"
              _OutletTile(
                label: context.t('outlet.allOutlets'),
                icon: Icons.store_outlined,
                isSelected: appState.selectedOutletId == null,
                onTap: () {
                  appState.selectOutlet(null);
                  Navigator.pop(ctx);
                },
              ),
              if (outlets.isNotEmpty) const Divider(height: 1),
              ...outlets.map((outlet) => _OutletTile(
                    label: outlet.name,
                    icon: Icons.storefront_outlined,
                    subtitle: outlet.address,
                    isSelected: appState.selectedOutletId == outlet.id,
                    onTap: () {
                      appState.selectOutlet(outlet.id);
                      Navigator.pop(ctx);
                    },
                  )),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.appState;
    final selectedOutlet = appState.selectedOutlet;
    final pages = const [
      HomeScreen(),
      ProductListScreen(),
      ReportScreen(),
      ProfileScreen()
    ];
    return AppGradientScaffold(
      body: Column(
        children: [
          // Outlet switcher — hanya tampil jika ada outlet
          if (appState.outlets.isNotEmpty)
            _OutletSwitcherBar(
              selectedOutlet: selectedOutlet,
              onTap: () => _showOutletPicker(context),
            ),
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

class _OutletSwitcherBar extends StatelessWidget {
  const _OutletSwitcherBar({
    required this.selectedOutlet,
    required this.onTap,
  });

  final OutletModel? selectedOutlet;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        color: AppColors.chipBg,
        child: Row(
          children: [
            const Icon(Icons.storefront_outlined,
                size: 18, color: AppColors.brandBlue),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                selectedOutlet?.name ?? context.t('outlet.allOutlets'),
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const Icon(Icons.unfold_more,
                size: 18, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}

class _OutletTile extends StatelessWidget {
  const _OutletTile({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
    this.subtitle,
  });

  final String label;
  final IconData icon;
  final String? subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? AppColors.brandBlue : AppColors.textSecondary,
      ),
      title: Text(
        label,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
          color: isSelected ? AppColors.brandBlue : AppColors.textPrimary,
        ),
      ),
      subtitle: subtitle != null
          ? Text(subtitle!,
              style: const TextStyle(
                  fontSize: 12, color: AppColors.textSecondary))
          : null,
      trailing: isSelected
          ? const Icon(Icons.check, color: AppColors.brandBlue, size: 18)
          : null,
      onTap: onTap,
    );
  }
}
