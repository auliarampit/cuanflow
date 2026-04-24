import 'package:flutter/material.dart';

import '../../../core/localization/transalation_extansions.dart';
import '../../../core/models/money_transaction.dart';
import '../../../core/state/app_state.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dynamic_colors.dart';

class AddCategorySheet extends StatefulWidget {
  const AddCategorySheet({
    super.key,
    required this.type,
    required this.onAdd,
  });

  final MoneyTransactionType type;
  final void Function(String name, bool isStockPurchase) onAdd;

  @override
  State<AddCategorySheet> createState() => _AddCategorySheetState();
}

class _AddCategorySheetState extends State<AddCategorySheet> {
  final _controller = TextEditingController();
  bool _isStockPurchase = false;

  bool get _canAdd => _controller.text.trim().isNotEmpty;
  bool get _isExpense => widget.type == MoneyTransactionType.expense;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _controller.text.trim();
    if (name.isEmpty) return;
    widget.onAdd(name, _isExpense && _isStockPurchase);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = _isExpense ? AppColors.negative : AppColors.positive;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(20, 20, 20, bottomInset + 24),
      decoration: BoxDecoration(
        color: context.appColors.card,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: context.appColors.outline,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Text(
            _isExpense
                ? context.t('category.add.titleExpense')
                : context.t('category.add.titleIncome'),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            onChanged: (_) => setState(() {}),
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            onSubmitted: (_) => _submit(),
            decoration: InputDecoration(
              hintText: context.t('category.add.nameHint'),
              prefixIcon: Icon(
                _isExpense
                    ? Icons.arrow_downward_rounded
                    : Icons.arrow_upward_rounded,
                color: accentColor,
              ),
            ),
          ),
          if (_isExpense && context.appState.profile.isBusinessMode) ...[
            const SizedBox(height: 12),
            InkWell(
              onTap: () => setState(() => _isStockPurchase = !_isStockPurchase),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: _isStockPurchase
                      ? const Color(0xFFFF9F00).withValues(alpha: 0.1)
                      : context.appColors.cardSoft,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _isStockPurchase
                        ? const Color(0xFFFF9F00).withValues(alpha: 0.4)
                        : context.appColors.outline,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.inventory_2_outlined,
                      size: 18,
                      color: _isStockPurchase
                          ? const Color(0xFFFF9F00)
                          : context.appColors.textSecondary,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.t('category.stockPurchaseLabel'),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: _isStockPurchase
                                  ? const Color(0xFFFF9F00)
                                  : context.appColors.textPrimary,
                            ),
                          ),
                          Text(
                            context.t('category.stockPurchaseHint'),
                            style: TextStyle(
                              fontSize: 10,
                              color: context.appColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: _isStockPurchase,
                      onChanged: (v) => setState(() => _isStockPurchase = v),
                      activeThumbColor: const Color(0xFFFF9F00),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _canAdd ? _submit : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: accentColor,
                foregroundColor: Colors.white,
                disabledBackgroundColor: accentColor.withValues(alpha: 0.3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                context.t('category.add.submit'),
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
