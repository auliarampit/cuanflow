import 'package:flutter/material.dart';

class AppBreakpoints {
  /// Layar ≥ 600dp dianggap tablet
  static const double tablet = 600;

  /// Lebar maksimum konten form/halaman di tablet
  static const double maxContentWidth = 560;
}

extension ResponsiveContext on BuildContext {
  double get screenWidth => MediaQuery.sizeOf(this).width;

  bool get isTablet => screenWidth >= AppBreakpoints.tablet;
}

/// Membungkus [child] dengan batasan lebar maksimum dan memusatkannya.
/// Hanya aktif di layar tablet (≥ 600dp). Di mobile, [child] dikembalikan apa adanya.
class TabletConstraint extends StatelessWidget {
  const TabletConstraint({
    super.key,
    required this.child,
    this.maxWidth = AppBreakpoints.maxContentWidth,
  });

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    if (!context.isTablet) return child;
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}
