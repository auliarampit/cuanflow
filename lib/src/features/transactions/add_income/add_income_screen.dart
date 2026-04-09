import 'package:cari_untung/src/core/ui/app_gradient_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/formatters/currency_input_formatter.dart';
import '../../../core/localization/transalation_extansions.dart';
import '../../../core/models/money_transaction.dart';
import '../../../core/state/app_state.dart';
import '../../../core/theme/app_colors.dart';

class AddIncomeScreen extends StatefulWidget {
  const AddIncomeScreen({super.key, this.transaction});

  final MoneyTransaction? transaction;

  @override
  State<AddIncomeScreen> createState() => _AddIncomeScreenState();
}

class _AddIncomeScreenState extends State<AddIncomeScreen> {
  final _noteController = TextEditingController();
  final _amountController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  String? _selectedCategoryKey;

  @override
  void initState() {
    super.initState();
    if (widget.transaction != null) {
      final tx = widget.transaction!;
      _amountController.text = CurrencyInputFormatter.formatVal(tx.amount);
      _noteController.text = tx.note ?? '';
      _selectedDate = tx.effectiveDate;
      _selectedCategoryKey = tx.category;
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
        key: 'income.quick.sales',
        label: context.t('income.quick.sales'),
      ),
      _QuickCategory(
        key: 'income.quick.service',
        label: context.t('income.quick.service'),
      ),
      _QuickCategory(
        key: 'income.quick.other',
        label: context.t('income.quick.other'),
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
              ? context.t('income.edit.title')
              : context.t('income.add.title'),
        ),
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back),
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
                  Center(
                    child: Column(
                      children: [
                        TextField(
                          controller: _amountController,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 56,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            CurrencyInputFormatter(),
                          ],
                          decoration: InputDecoration(
                            hintText: '0',
                            hintStyle: TextStyle(
                              fontSize: 56,
                              fontWeight: FontWeight.w800,
                              color: Colors.white.withValues(alpha: 0.12),
                            ),
                            border: InputBorder.none,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          context.t('income.add.amountHint'),
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 26),
                  Text(
                    context.t('common.noteOptional'),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _noteController,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.edit_outlined),
                      hintText: context.t('income.add.noteHint'),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    context.t('income.quick.title'),
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
                      final isSelected = _selectedCategoryKey == e.key;
                      return ChoiceChip(
                        label: Text(e.label),
                        selected: isSelected,
                        onSelected: (_) =>
                            setState(() => _selectedCategoryKey = e.key),
                        selectedColor: AppColors.positive.withValues(
                          alpha: 0.18,
                        ),
                        backgroundColor: AppColors.cardSoft,
                        labelStyle: TextStyle(
                          color: isSelected
                              ? AppColors.positive
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
                  const SizedBox(height: 16),
                  Text(
                    context.t('common.date'),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 10),
                  InkWell(
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
                        horizontal: 14,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.cardSoft,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.outline),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.calendar_today_outlined,
                            color: AppColors.positive,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                            ),
                          ),
                          const Icon(
                            Icons.expand_more,
                            color: AppColors.textSecondary,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        final rawAmount = _amountController.text.replaceAll(
                          '.',
                          '',
                        );
                        final amount = int.tryParse(rawAmount) ?? 0;
                        if (amount > 0) {
                          if (_noteController.text.isEmpty ||
                              _selectedCategoryKey == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                    context.t('common.validation.mandatory')),
                                backgroundColor: AppColors.negative,
                              ),
                            );
                            return;
                          }

                          if (widget.transaction != null) {
                            final updatedTx = widget.transaction!.copyWith(
                              amount: amount,
                              note: _noteController.text,
                              category: _selectedCategoryKey,
                              effectiveDate: _selectedDate,
                            );
                            context.appState.updateTransaction(updatedTx);
                          } else {
                            context.appState.addIncome(
                              amount: amount,
                              note: _noteController.text,
                              category: _selectedCategoryKey,
                              effectiveDate: _selectedDate,
                            );
                          }

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content:
                                  Text(context.t('common.validation.success')),
                              backgroundColor: AppColors.positive,
                            ),
                          );

                          Navigator.of(context).pop();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.positive,
                        foregroundColor: Colors.black,
                      ),
                      child: Text(context.t('common.save')),
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
}

class _QuickCategory {
  const _QuickCategory({required this.key, required this.label});

  final String key;
  final String label;
}
