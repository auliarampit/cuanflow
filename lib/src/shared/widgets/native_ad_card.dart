import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../core/theme/app_colors.dart';

/// Native ad berbentuk card yang menyatu dengan desain aplikasi.
/// Gunakan [TemplateType.small] (~90px) untuk sisipan di list.
/// Gunakan [TemplateType.medium] (~200px) untuk card mandiri.
///
/// TODO: Ganti ID di bawah dengan Native ad unit dari AdMob setelah akun disetujui:
///   Android: buat ad unit → format "Native" → salin ID
///   iOS    : buat ad unit → format "Native" → salin ID
class NativeAdCard extends StatefulWidget {
  const NativeAdCard({
    super.key,
    this.templateType = TemplateType.small,
  });

  final TemplateType templateType;

  @override
  State<NativeAdCard> createState() => _NativeAdCardState();
}

class _NativeAdCardState extends State<NativeAdCard> {
  NativeAd? _ad;
  bool _adLoaded = false;
  bool _adRequested = false;

  // Test IDs (development only):
  //   Android: ca-app-pub-3940256099942544/2247696110
  //   iOS:     ca-app-pub-3940256099942544/3986624511
  static const _androidUnitId = 'ca-app-pub-9716883963480834/9883022233';
  static const _iosUnitId     = 'ca-app-pub-9716883963480834/9045430748';

  String get _adUnitId => Platform.isIOS ? _iosUnitId : _androidUnitId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_adRequested) {
      _adRequested = true;
      _loadAd();
    }
  }

  void _loadAd() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1E2235) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A2E);
    final subTextColor = isDark ? const Color(0xFF9E9E9E) : const Color(0xFF757575);

    final ad = NativeAd(
      adUnitId: _adUnitId,
      request: const AdRequest(),
      nativeTemplateStyle: NativeTemplateStyle(
        templateType: widget.templateType,
        mainBackgroundColor: bgColor,
        cornerRadius: 12.0,
        callToActionTextStyle: NativeTemplateTextStyle(
          textColor: Colors.white,
          backgroundColor: AppColors.brandBlue,
          style: NativeTemplateFontStyle.bold,
          size: 13.0,
        ),
        primaryTextStyle: NativeTemplateTextStyle(
          textColor: textColor,
          style: NativeTemplateFontStyle.bold,
          size: 14.0,
        ),
        secondaryTextStyle: NativeTemplateTextStyle(
          textColor: subTextColor,
          style: NativeTemplateFontStyle.normal,
          size: 12.0,
        ),
        tertiaryTextStyle: NativeTemplateTextStyle(
          textColor: subTextColor,
          style: NativeTemplateFontStyle.normal,
          size: 11.0,
        ),
      ),
      listener: NativeAdListener(
        onAdLoaded: (_) {
          if (mounted) setState(() => _adLoaded = true);
        },
        onAdFailedToLoad: (failedAd, error) {
          debugPrint('[NativeAdCard] failed: $error');
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

    final height = widget.templateType == TemplateType.small ? 90.0 : 260.0;

    return SizedBox(
      height: height,
      child: AdWidget(ad: _ad!),
    );
  }
}
