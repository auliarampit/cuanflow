import 'package:cari_untung/src/shared/widgets/loading_dialog.dart';
import 'package:flutter/material.dart';

import 'package:flutter/services.dart';
import '../../../core/formatters/currency_input_formatter.dart';
import '../../../core/localization/transalation_extansions.dart';
import '../../../core/models/money_transaction.dart';
import '../../../core/state/app_state.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/ui/app_gradient_scaffold.dart';

class AddExpenseScreen extends StatefulWidget {
  const AddExpenseScreen({super.key, this.transaction});

  final MoneyTransaction? transaction;

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _noteController = TextEditingController();
  final _amountController = TextEditingController();
  String? _selectedQuickCategoryKey;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    if (widget.transaction != null) {
      final tx = widget.transaction!;
      _amountController.text = CurrencyInputFormatter.formatVal(tx.amount);
      _noteController.text = tx.note ?? '';
      _selectedQuickCategoryKey = tx.category;
      _selectedDate = tx.effectiveDate;
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  List<_QuickCategory> _categories(BuildContext context) {
    return [
      _QuickCategory(
        key: 'expense.quick.material',
        label: context.t('expense.quick.material'),
      ),
      _QuickCategory(
        key: 'expense.quick.transport',
        label: context.t('expense.quick.transport'),
      ),
      _QuickCategory(
        key: 'expense.quick.operational',
        label: context.t('expense.quick.operational'),
      ),
      _QuickCategory(
        key: 'expense.quick.salary',
        label: context.t('expense.quick.salary'),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final categories = _categories(context);

    return AppGradientScaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          widget.transaction != null
              ? context.t('expense.edit.title')
              : context.t('expense.add.title'),
          style: const TextStyle(
            color: AppColors.negative,
            fontWeight: FontWeight.w800,
          ),
        ),
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.close),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final bottomInset = MediaQuery.of(context).viewInsets.bottom;
          return SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(18, 18, 18, bottomInset + 24),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Align(
                    alignment: Alignment.center,
                    child: InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _selectedDate,
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          setState(() => _selectedDate = picked);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.cardSoft,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: AppColors.outline),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.calendar_today_outlined,
                              size: 18,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  Text(
                    context.t('expense.add.amountLabel'),
                    style: const TextStyle(
                      letterSpacing: 2,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.cardSoft,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: AppColors.negative.withValues(alpha: 0.5),
                        width: 2,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: AppColors.negative.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          alignment: Alignment.center,
                          child: const Icon(
                            Icons.remove,
                            color: AppColors.negative,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                context.t('expense.add.currencyLabel'),
                                style: const TextStyle(
                                  color: AppColors.negative,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 6),
                              TextField(
                                controller: _amountController,
                                keyboardType: TextInputType.number,
                                style: const TextStyle(
                                  fontSize: 44,
                                  fontWeight: FontWeight.w900,
                                ),
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                  CurrencyInputFormatter(),
                                ],
                                decoration: InputDecoration(
                                  hintText: '0',
                                  hintStyle: TextStyle(
                                    fontSize: 44,
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.textPrimary
                                        .withValues(alpha: 0.3),
                                  ),
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.unfold_more,
                          color: AppColors.textSecondary,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    context.t('common.note'),
                    style: const TextStyle(
                      letterSpacing: 2,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _noteController,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.edit_outlined),
                      hintText: context.t('expense.add.noteHint'),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    context.t('expense.quick.title'),
                    style: const TextStyle(
                      letterSpacing: 2,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: categories.map((e) {
                      final isSelected = _selectedQuickCategoryKey == e.label;
                      return ChoiceChip(
                        label: Text(e.label),
                        selected: isSelected,
                        onSelected: (_) =>
                            setState(() => _selectedQuickCategoryKey = e.label),
                        selectedColor: AppColors.negative.withValues(
                          alpha: 0.18,
                        ),
                        backgroundColor: AppColors.cardSoft,
                        labelStyle: TextStyle(
                          color: isSelected
                              ? AppColors.negative
                              : AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: AppColors.outline.withValues(alpha: 0.7),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _saveExpense(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.negative,
                        foregroundColor: Colors.white,
                      ),
                      icon: const Icon(Icons.save_outlined),
                      label: Text(context.t('expense.add.save')),
                    ),
                  ),
                  const SizedBox(height: 18),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _saveExpense(BuildContext context) async {
    final rawAmount = _amountController.text.replaceAll('.', '');
    final amount = int.tryParse(rawAmount) ?? 0;
    if (amount > 0) {
      if (_noteController.text.isEmpty || _selectedQuickCategoryKey == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.t('common.validation.mandatory')),
            backgroundColor: AppColors.negative,
          ),
        );
        return;
      }

      LoadingDialog.show(context);

      if (widget.transaction != null) {
        final updatedTx = widget.transaction!.copyWith(
          amount: amount,
          note: _noteController.text,
          category: _selectedQuickCategoryKey,
          effectiveDate: _selectedDate,
        );
        await context.appState.updateTransaction(updatedTx);
      } else {
        await context.appState.addExpense(
          amount: amount,
          note: _noteController.text,
          category: _selectedQuickCategoryKey,
          effectiveDate: _selectedDate,
        );
      }

      if (context.mounted) {
        LoadingDialog.hide(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.t('common.validation.success')),
            backgroundColor: AppColors.positive,
          ),
        );

        Navigator.of(context).pop();
      }
    }
  }
}

class _QuickCategory {
  const _QuickCategory({required this.key, required this.label});

  final String key;
  final String label;
}
