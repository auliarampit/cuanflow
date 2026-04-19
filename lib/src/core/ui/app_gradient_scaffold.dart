import 'package:cari_untung/src/core/theme/app_colors.dart';
import 'package:cari_untung/src/shared/widgets/app_banner_ad.dart';
import 'package:flutter/material.dart';

class AppGradientScaffold extends StatelessWidget {
  const AppGradientScaffold({
    super.key,
    this.appBar,
    required this.body,
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.showAd = true,
  });

  final PreferredSizeWidget? appBar;
  final Widget body;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  /// Tampilkan banner iklan di bawah layar. Default: true.
  /// Set false untuk layar auth (login, register, ganti PIN).
  final bool showAd;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final gradient = isDark
        ? const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.backgroundTop, AppColors.backgroundBottom],
          )
        : const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF5F7FB), Color(0xFFEAEFF8)],
          );

    return DecoratedBox(
      decoration: BoxDecoration(gradient: gradient),
      child: Scaffold(
        appBar: appBar,
        backgroundColor: Colors.transparent,
        body: SafeArea(child: body),
        bottomNavigationBar: showAd
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const AppBannerAd(),
                  if (bottomNavigationBar != null) bottomNavigationBar!,
                ],
              )
            : bottomNavigationBar,
        floatingActionButton: floatingActionButton,
        floatingActionButtonLocation: floatingActionButtonLocation,
      ),
    );
  }
}
