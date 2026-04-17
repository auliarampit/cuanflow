import 'package:flutter/material.dart';

import '../../core/models/user_category.dart';
import '../../core/theme/app_dynamic_colors.dart';

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
                child: Text(
                  cat.name,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: accentColor,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ))
          .toList(),
      items: categories
          .map((cat) => DropdownMenuItem<UserCategory>(
                value: cat,
                child: Text(
                  cat.name,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: context.appColors.textPrimary,
                  ),
                ),
              ))
          .toList(),
      onChanged: onChanged,
    );
  }
}
