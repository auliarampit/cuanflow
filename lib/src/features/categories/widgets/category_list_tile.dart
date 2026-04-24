import 'package:flutter/material.dart';

import '../../../core/localization/transalation_extansions.dart';
import '../../../core/models/user_category.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dynamic_colors.dart';

const _stockColor = Color(0xFFFF9F00);

class CategoryListTile extends StatelessWidget {
  const CategoryListTile({
    super.key,
    required this.category,
    required this.accentColor,
    this.onDelete,
    this.onToggleStock,
  });

  final UserCategory category;
  final Color accentColor;
  final VoidCallback? onDelete;
  /// Callback untuk toggle isStockPurchase (hanya custom expense category).
  /// Null = tidak bisa di-toggle (default category atau income).
  final ValueChanged<bool>? onToggleStock;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: context.appColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.appColors.outline),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              category.isIncome
                  ? Icons.arrow_upward_rounded
                  : Icons.arrow_downward_rounded,
              color: accentColor,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category.name,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: context.appColors.textPrimary,
                  ),
                ),
                if (category.isStockPurchase) ...[
                  const SizedBox(height: 2),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.inventory_2_outlined, size: 10, color: _stockColor),
                      const SizedBox(width: 3),
                      Text(
                        context.t('category.stockBadge'),
                        style: const TextStyle(
                          fontSize: 10,
                          color: _stockColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          // Badge "Default" atau toggle stok + tombol hapus
          if (category.isDefault)
            _Badge(
              label: 'Default',
              color: context.appColors.textSecondary,
              bg: context.appColors.chipBg,
            )
          else ...[
            if (onToggleStock != null) ...[
              GestureDetector(
                onTap: () => onToggleStock!(!category.isStockPurchase),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: category.isStockPurchase
                        ? _stockColor.withValues(alpha: 0.15)
                        : context.appColors.chipBg,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: category.isStockPurchase
                          ? _stockColor.withValues(alpha: 0.4)
                          : context.appColors.outline,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.inventory_2_outlined,
                        size: 11,
                        color: category.isStockPurchase
                            ? _stockColor
                            : context.appColors.textSecondary,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        context.t('category.stockBadge'),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: category.isStockPurchase
                              ? _stockColor
                              : context.appColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 6),
            ],
            IconButton(
              icon: const Icon(Icons.delete_outline,
                  color: AppColors.negative, size: 20),
              onPressed: onDelete,
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.color, required this.bg});
  final String label;
  final Color color;
  final Color bg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
