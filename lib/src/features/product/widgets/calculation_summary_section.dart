import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/formatters/currency_input_formatter.dart';
import '../../../core/formatters/idr_formatter.dart';
import '../../../core/localization/transalation_extansions.dart';
import '../../../core/theme/app_colors.dart';

class CalculationSummarySection extends StatelessWidget {
  const CalculationSummarySection({
    super.key,
    required this.hppPerUnit,
    required this.sellingPriceController,
    required this.onChanged,
  });

  final double hppPerUnit;
  final TextEditingController sellingPriceController;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // HPP / Unit Box
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF16262E),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.05)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.t('product.calc.hppPerUnit').toUpperCase(),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  IdrFormatter.format(hppPerUnit.round()),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        // Selling Price Input Box
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF16262E),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.brandBlue.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.t('product.calc.sellingPriceLabel').toUpperCase(),
                  style: const TextStyle(
                    color: AppColors.brandBlue,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                TextField(
                  controller: sellingPriceController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    CurrencyInputFormatter(),
                  ],
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.only(top: 8, bottom: 4),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    prefixText: 'Rp ',
                    prefixStyle: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.brandBlue,
                    ),
                    hintText: '0',
                    hintStyle: TextStyle(color: Colors.white24),
                  ),
                  onChanged: (_) => onChanged(),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
