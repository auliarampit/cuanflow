import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_dynamic_colors.dart';

/// Card placeholder untuk fitur yang terkunci — tampil di tempat fitur
/// yang belum di-unlock oleh user (butuh Business Premium).
class LockedFeatureCard extends StatelessWidget {
  const LockedFeatureCard({
    super.key,
    required this.featureName,
    this.description,
    this.onUpgradeTap,
    this.compact = false,
  });

  final String featureName;
  final String? description;
  final VoidCallback? onUpgradeTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final appColors = context.appColors;

    if (compact) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: appColors.cardSoft,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: appColors.outline),
        ),
        child: Row(
          children: [
            Icon(Icons.lock_outline,
                size: 16, color: appColors.textSecondary.withValues(alpha: 0.6)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '$featureName — Perlu Business Premium',
                style: TextStyle(
                  fontSize: 12,
                  color: appColors.textSecondary,
                ),
              ),
            ),
            if (onUpgradeTap != null)
              GestureDetector(
                onTap: onUpgradeTap,
                child: const Text(
                  'Upgrade',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.brandBlue,
                  ),
                ),
              ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: appColors.cardSoft,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: appColors.outline),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.lock_outline,
              size: 32, color: appColors.textSecondary.withValues(alpha: 0.5)),
          const SizedBox(height: 8),
          Text(
            featureName,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: appColors.textSecondary,
            ),
          ),
          if (description != null) ...[
            const SizedBox(height: 4),
            Text(
              description!,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: appColors.textSecondary,
              ),
            ),
          ],
          const SizedBox(height: 8),
          Text(
            'Perlu Business Premium',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: appColors.textSecondary.withValues(alpha: 0.7),
            ),
          ),
          if (onUpgradeTap != null) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: onUpgradeTap,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.brandBlue,
                  side: const BorderSide(color: AppColors.brandBlue),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Lihat Paket Premium',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
