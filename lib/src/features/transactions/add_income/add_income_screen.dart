import 'package:cari_untung/src/core/ui/app_gradient_scaffold.dart';
import 'package:collection/collection.dart';
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
  final _amountController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  _QuickCategory? _selectedCategory;
  String? _selectedOutletId;
  bool _didInit = false;

  @override
  void initState() {
    super.initState();
    if (widget.transaction != null) {
      _amountController.text =
          CurrencyInputFormatter.formatVal(widget.transaction!.amount);
      _selectedDate = widget.transaction!.effectiveDate;
      _selectedOutletId = widget.transaction!.outletId;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didInit) return;
    _didInit = true;

    // Pre-fill outlet dari shell
    if (_selectedOutletId == null && widget.transaction == null) {
      _selectedOutletId = context.appState.selectedOutletId;
    }

    // Match kategori dari transaksi yang diedit —
    // support data lama (key: 'income.quick.sales') dan baru (label: 'Penjualan')
    if (widget.transaction?.category != null) {
      final cats = _buildCategories(context);
      final stored = widget.transaction!.category!;
      _selectedCategory = cats.firstWhereOrNull(
        (c) => c.key == stored || c.label == stored,
      );
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  List<_QuickCategory> _buildCategories(BuildContext context) {
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
    final categories = _buildCategories(context);
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
                      final isSelected = _selectedCategory?.key == e.key;
                      return ChoiceChip(
                        label: Text(e.label),
                        selected: isSelected,
                        onSelected: (_) =>
                            setState(() => _selectedCategory = e),
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
                  _OutletSelector(
                    selectedOutletId: _selectedOutletId,
                    onChanged: (id) => setState(() => _selectedOutletId = id),
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
                          if (_selectedCategory == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                    context.t('income.validation.categoryRequired')),
                                backgroundColor: AppColors.negative,
                              ),
                            );
                            return;
                          }

                          // note = nama outlet yang dipilih (bukan free text)
                          final outletName = context.appState.outlets
                              .firstWhereOrNull((o) => o.id == _selectedOutletId)
                              ?.name;

                          if (widget.transaction != null) {
                            final updatedTx = widget.transaction!.copyWith(
                              amount: amount,
                              note: outletName,
                              // kirim label (Penjualan), bukan key (income.quick.sales)
                              category: _selectedCategory!.label,
                              outletId: _selectedOutletId,
                              effectiveDate: _selectedDate,
                            );
                            context.appState.updateTransaction(updatedTx);
                          } else {
                            context.appState.addIncome(
                              amount: amount,
                              note: outletName,
                              category: _selectedCategory!.label,
                              outletId: _selectedOutletId,
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

class _OutletSelector extends StatelessWidget {
  const _OutletSelector({
    required this.selectedOutletId,
    required this.onChanged,
  });

  final String? selectedOutletId;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final outlets = context.appState.outlets;
    if (outlets.isEmpty) return const SizedBox.shrink();

    final selectedName = selectedOutletId == null
        ? 'Semua / Tidak ditentukan'
        : outlets
                .where((o) => o.id == selectedOutletId)
                .firstOrNull
                ?.name ??
            'Pilih Outlet';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Outlet',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        InkWell(
          onTap: () async {
            await showModalBottomSheet<void>(
              context: context,
              backgroundColor: AppColors.card,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              builder: (ctx) {
                return SafeArea(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Padding(
                        padding: EdgeInsets.fromLTRB(20, 20, 20, 8),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Pilih Outlet',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                      ListTile(
                        leading: const Icon(Icons.store_outlined),
                        title: const Text('Tidak ditentukan'),
                        trailing: selectedOutletId == null
                            ? const Icon(Icons.check, color: AppColors.brandBlue)
                            : null,
                        onTap: () {
                          onChanged(null);
                          Navigator.pop(ctx);
                        },
                      ),
                      const Divider(height: 1),
                      ...outlets.map((o) => ListTile(
                            leading: const Icon(Icons.storefront_outlined),
                            title: Text(o.name),
                            subtitle: o.address != null
                                ? Text(o.address!,
                                    style: const TextStyle(fontSize: 12))
                                : null,
                            trailing: selectedOutletId == o.id
                                ? const Icon(Icons.check,
                                    color: AppColors.brandBlue)
                                : null,
                            onTap: () {
                              onChanged(o.id);
                              Navigator.pop(ctx);
                            },
                          )),
                      const SizedBox(height: 8),
                    ],
                  ),
                );
              },
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.cardSoft,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.outline),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.storefront_outlined,
                  color: AppColors.brandBlue,
                ),
                const SizedBox(width: 10),
                Expanded(child: Text(selectedName)),
                const Icon(Icons.expand_more, color: AppColors.textSecondary),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
