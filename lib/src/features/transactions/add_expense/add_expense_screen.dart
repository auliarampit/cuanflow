import 'package:collection/collection.dart';
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
  _QuickCategory? _selectedCategory;
  String? _selectedOutletId;
  DateTime _selectedDate = DateTime.now();
  bool _didInit = false;

  @override
  void initState() {
    super.initState();
    if (widget.transaction != null) {
      final tx = widget.transaction!;
      _amountController.text = CurrencyInputFormatter.formatVal(tx.amount);
      _noteController.text = tx.note ?? '';
      _selectedOutletId = tx.outletId;
      _selectedDate = tx.effectiveDate;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didInit) return;
    _didInit = true;

    if (_selectedOutletId == null && widget.transaction == null) {
      _selectedOutletId = context.appState.selectedOutletId;
    }

    // Match kategori dari transaksi yang diedit —
    // support data lama (key: 'expense.quick.material') dan baru (label: 'Bahan Baku')
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
    _noteController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  List<_QuickCategory> _buildCategories(BuildContext context) {
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
                  _OutletSelector(
                    selectedOutletId: _selectedOutletId,
                    onChanged: (id) => setState(() => _selectedOutletId = id),
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
                      final isSelected = _selectedCategory?.key == e.key;
                      return ChoiceChip(
                        label: Text(e.label),
                        selected: isSelected,
                        onSelected: (_) =>
                            setState(() => _selectedCategory = e),
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

  void _saveExpense(BuildContext context) {
    final rawAmount = _amountController.text.replaceAll('.', '');
    final amount = int.tryParse(rawAmount) ?? 0;
    if (amount > 0) {
      if (_selectedCategory == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.t('common.validation.mandatory')),
            backgroundColor: AppColors.negative,
          ),
        );
        return;
      }

      if (widget.transaction != null) {
        final updatedTx = widget.transaction!.copyWith(
          amount: amount,
          note: _noteController.text.isEmpty ? null : _noteController.text,
          // kirim label (Bahan Baku), bukan key (expense.quick.material)
          category: _selectedCategory!.label,
          outletId: _selectedOutletId,
          effectiveDate: _selectedDate,
        );
        context.appState.updateTransaction(updatedTx);
      } else {
        context.appState.addExpense(
          amount: amount,
          note: _noteController.text.isEmpty ? null : _noteController.text,
          category: _selectedCategory!.label,
          outletId: _selectedOutletId,
          effectiveDate: _selectedDate,
        );
      }

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
          style: TextStyle(
            letterSpacing: 2,
            fontWeight: FontWeight.w700,
            color: AppColors.textSecondary,
          ),
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
                            ? const Icon(Icons.check,
                                color: AppColors.brandBlue)
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
              border: Border.all(
                color: AppColors.negative.withValues(alpha: 0.5),
                width: 2,
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.storefront_outlined,
                  color: AppColors.negative,
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
