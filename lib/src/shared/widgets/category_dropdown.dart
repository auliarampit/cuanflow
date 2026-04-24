import 'package:flutter/material.dart';

import '../../core/models/user_category.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/app_dynamic_colors.dart';

const _stockColor = Color(0xFFFF9F00);

/// Dropdown pilihan kategori yang hemat ruang.
/// Dipakai di add_income_screen dan add_expense_screen.
class CategoryDropdown extends StatelessWidget {
  const CategoryDropdown({
    super.key,
    required this.categories,
    required this.selected,
    required this.onChanged,
    required this.accentColor,
    this.hint = 'Pilih kategori...',
  });

  final List<UserCategory> categories;
  final UserCategory? selected;
  final ValueChanged<UserCategory?> onChanged;
  final Color accentColor;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<UserCategory>(
      initialValue: selected,
      isExpanded: true,
      decoration: InputDecoration(
        prefixIcon: Icon(Icons.category_outlined, color: accentColor, size: 20),
        hintText: hint,
        contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      ),
      dropdownColor: context.appColors.card,
      borderRadius: BorderRadius.circular(14),
      icon: Icon(Icons.keyboard_arrow_down_rounded,
          color: context.appColors.textSecondary),
      selectedItemBuilder: (context) => categories
          .map((cat) => Align(
                alignment: Alignment.centerLeft,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        cat.name,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: accentColor,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (cat.isStockPurchase && context.appState.profile.isBusinessMode) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: _stockColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          '📦 Stok',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: _stockColor,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ))
          .toList(),
      items: categories
          .map((cat) => DropdownMenuItem<UserCategory>(
                value: cat,
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        cat.name,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: context.appColors.textPrimary,
                        ),
                      ),
                    ),
                    if (cat.isStockPurchase && context.appState.profile.isBusinessMode)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: _stockColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: _stockColor.withValues(alpha: 0.3)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.inventory_2_outlined, size: 10, color: _stockColor),
                            SizedBox(width: 3),
                            Text(
                              'Stok',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: _stockColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ))
          .toList(),
      onChanged: onChanged,
    );
  }
}
