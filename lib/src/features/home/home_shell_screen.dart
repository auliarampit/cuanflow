import 'package:cari_untung/src/core/localization/transalation_extansions.dart';
import 'package:cari_untung/src/core/models/outlet_model.dart';
import 'package:cari_untung/src/core/state/app_state.dart';
import 'package:cari_untung/src/core/theme/app_colors.dart';
import 'package:cari_untung/src/core/theme/app_dynamic_colors.dart';
import 'package:cari_untung/src/core/ui/app_gradient_scaffold.dart';
import 'package:cari_untung/src/core/ui/responsive_utils.dart';
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
                    style: TextStyle(
                      fontSize: 11,
                      color: context.appColors.textSecondary,
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
      bannerColor = context.appColors.chipBg;
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
              style: TextStyle(
                fontSize: 12,
                color: context.appColors.textSecondary,
              ),
            ),
          ),
        ],
      );
    } else {
      // Pending tapi belum pernah coba (offline)
      bannerColor = context.appColors.chipBg;
      content = Row(
        children: [
          Icon(Icons.cloud_off_outlined,
              size: 16, color: context.appColors.textSecondary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '$pending transaksi belum tersimpan ke server',
              style: TextStyle(
                fontSize: 12,
                color: context.appColors.textSecondary,
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
              LinearProgressIndicator(
                minHeight: 2,
                backgroundColor: context.appColors.outline,
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
      backgroundColor: context.appColors.card,
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
    final isTablet = context.isTablet;

    final pages = const [
      HomeScreen(),
      ProductListScreen(),
      ReportScreen(),
      ProfileScreen(),
    ];

    final navItems = [
      (icon: Icons.home_outlined, activeIcon: Icons.home, label: context.t('nav.home')),
      (icon: Icons.inventory_2_outlined, activeIcon: Icons.inventory_2, label: context.t('nav.product')),
      (icon: Icons.bar_chart_outlined, activeIcon: Icons.bar_chart, label: context.t('nav.report')),
      (icon: Icons.person_outlined, activeIcon: Icons.person, label: context.t('nav.profile')),
    ];

    final contentColumn = Column(
      children: [
        if (appState.outlets.isNotEmpty)
          _OutletSwitcherBar(
            selectedOutlet: selectedOutlet,
            onTap: () => _showOutletPicker(context),
          ),
        const _SyncBanner(),
        Expanded(child: pages[_index]),
      ],
    );

    if (isTablet) {
      return AppGradientScaffold(
        body: Row(
          children: [
            NavigationRail(
              backgroundColor: Colors.transparent,
              selectedIndex: _index,
              onDestinationSelected: _onTap,
              labelType: NavigationRailLabelType.all,
              indicatorColor: AppColors.brandBlue.withValues(alpha: 0.15),
              selectedIconTheme: const IconThemeData(color: AppColors.brandBlue),
              unselectedIconTheme: IconThemeData(color: context.appColors.textSecondary),
              selectedLabelTextStyle: const TextStyle(
                color: AppColors.brandBlue,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
              unselectedLabelTextStyle: TextStyle(
                color: context.appColors.textSecondary,
                fontSize: 12,
              ),
              destinations: navItems
                  .map((item) => NavigationRailDestination(
                        icon: Icon(item.icon),
                        selectedIcon: Icon(item.activeIcon),
                        label: Text(item.label),
                      ))
                  .toList(),
            ),
            VerticalDivider(
              thickness: 1,
              width: 1,
              color: context.appColors.outline,
            ),
            Expanded(child: contentColumn),
          ],
        ),
      );
    }

    return AppGradientScaffold(
      body: contentColumn,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: _onTap,
        type: BottomNavigationBarType.fixed,
        items: navItems
            .map((item) => BottomNavigationBarItem(
                  icon: Icon(item.icon),
                  activeIcon: Icon(item.activeIcon),
                  label: item.label,
                ))
            .toList(),
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
        color: context.appColors.chipBg,
        child: Row(
          children: [
            const Icon(Icons.storefront_outlined,
                size: 18, color: AppColors.brandBlue),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                selectedOutlet?.name ?? context.t('outlet.allOutlets'),
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: context.appColors.textPrimary,
                ),
              ),
            ),
            Icon(Icons.unfold_more,
                size: 18, color: context.appColors.textSecondary),
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
        color: isSelected ? AppColors.brandBlue : context.appColors.textSecondary,
      ),
      title: Text(
        label,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
          color: isSelected ? AppColors.brandBlue : context.appColors.textPrimary,
        ),
      ),
      subtitle: subtitle != null
          ? Text(subtitle!,
              style: TextStyle(
                  fontSize: 12, color: context.appColors.textSecondary))
          : null,
      trailing: isSelected
          ? const Icon(Icons.check, color: AppColors.brandBlue, size: 18)
          : null,
      onTap: onTap,
    );
  }
}
