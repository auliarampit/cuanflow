import 'package:flutter/material.dart';
import '../../../core/localization/transalation_extansions.dart';
import '../../../core/theme/app_colors.dart';

class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    required this.onAdd,
    required this.icon,
  });

  final String title;
  final VoidCallback onAdd;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.brandBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                size: 20,
                color: AppColors.brandBlue,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
        TextButton.icon(
          onPressed: onAdd,
          icon: const Icon(Icons.add_circle, size: 20),
          label: Text(
            context.t('product.calc.addItem'),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          style: TextButton.styleFrom(
            foregroundColor: AppColors.brandBlue,
          ),
        ),
      ],
    );
  }
}
