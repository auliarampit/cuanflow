import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Banner iklan 320×50 (standard banner) yang ditampilkan di bawah tiap screen.
///
/// Gunakan ID test selama development. Ganti dengan ID asli sebelum release:
///   Android : ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX
///   iOS     : ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX
class AppBannerAd extends StatefulWidget {
  const AppBannerAd({super.key});

  @override
  State<AppBannerAd> createState() => _AppBannerAdState();
}

class _AppBannerAdState extends State<AppBannerAd> {
  BannerAd? _ad;
  bool _adLoaded = false;

  // ── Ad Unit IDs ───────────────────────────────────────────────────────────
  // Test IDs (development only):
  //   Android: ca-app-pub-3940256099942544/6300978111
  //   iOS:     ca-app-pub-3940256099942544/2934735716
  static const _androidUnitId = 'ca-app-pub-9716883963480834/9216821139';
  static const _iosUnitId = 'ca-app-pub-9716883963480834/1677229159';

  String get _adUnitId => Platform.isIOS ? _iosUnitId : _androidUnitId;

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  void _loadAd() {
    final ad = BannerAd(
      adUnitId: _adUnitId,
      size: AdSize.banner, // 320×50 — paling kecil & tidak mengganggu
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (mounted) setState(() => _adLoaded = true);
        },
        onAdFailedToLoad: (failedAd, error) {
          debugPrint('[AppBannerAd] failed to load: $error');
          failedAd.dispose();
          _ad = null;
        },
      ),
    )..load();
    _ad = ad;
  }

  @override
  void dispose() {
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_adLoaded || _ad == null) return const SizedBox.shrink();
    return SizedBox(
      width: double.infinity,
      height: _ad!.size.height.toDouble(),
      child: AdWidget(ad: _ad!),
    );
  }
}
