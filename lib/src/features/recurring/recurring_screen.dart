import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/services.dart';

import '../../core/formatters/currency_input_formatter.dart';
import '../../core/formatters/idr_formatter.dart';
import '../../core/localization/transalation_extansions.dart';
import '../../core/models/money_transaction.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dynamic_colors.dart';
import '../../shared/widgets/category_dropdown.dart';

class RecurringScreen extends StatelessWidget {
  const RecurringScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final recurring = context.appState.recurringTransactions;

    return Scaffold(
      appBar: AppBar(
        title: Text(context.t('recurring.manage.title')),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showForm(context, null),
          ),
        ],
      ),
      body: recurring.isEmpty
          ? _EmptyState(onAdd: () => _showForm(context, null))
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
              children: [
                for (final r in recurring) ...[
                  _RecurringCard(
                    item: r,
                    onEdit: () => _showForm(context, r),
                    onDelete: () => _confirmDelete(context, r),
                  ),
                  const SizedBox(height: 10),
                ],
              ],
            ),
      floatingActionButton: recurring.isNotEmpty
          ? FloatingActionButton(
              onPressed: () => _showForm(context, null),
              backgroundColor: AppColors.brandBlue,
              foregroundColor: Colors.white,
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  void _showForm(BuildContext context, RecurringTransactionModel? existing) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.appColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _RecurringForm(existing: existing),
    );
  }

  void _confirmDelete(BuildContext context, RecurringTransactionModel r) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.t('recurring.delete.title')),
        content: Text(context.t('recurring.delete.content')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(context.t('common.cancel')),
          ),
          TextButton(
            onPressed: () {
              context.appState.deleteRecurring(r.id);
              Navigator.pop(ctx);
            },
            child: Text(
              context.t('recurring.delete.title'),
              style: const TextStyle(color: AppColors.negative),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAdd});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.repeat_outlined,
                size: 64, color: context.appColors.textSecondary),
            const SizedBox(height: 16),
            Text(
              context.t('recurring.empty'),
              style: const TextStyle(
                  fontWeight: FontWeight.w700, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              context.t('recurring.emptySubtitle'),
              textAlign: TextAlign.center,
              style: TextStyle(color: context.appColors.textSecondary),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: Text(context.t('recurring.add.button')),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brandBlue,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecurringCard extends StatelessWidget {
  const _RecurringCard({
    required this.item,
    required this.onEdit,
    required this.onDelete,
  });

  final RecurringTransactionModel item;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  String _formatDate(DateTime? d) {
    if (d == null) return '-';
    return '${d.day}/${d.month}/${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final isIncome = item.type == MoneyTransactionType.income;
    final accentColor = isIncome ? AppColors.positive : AppColors.negative;

    return Container(
      decoration: BoxDecoration(
        color: context.appColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: item.isActive
              ? context.appColors.outline
              : context.appColors.outline.withValues(alpha: 0.4),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.repeat,
                color: item.isActive ? accentColor : context.appColors.textSecondary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.name,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: item.isActive ? null : context.appColors.textSecondary,
                          ),
                        ),
                      ),
                      if (!item.isActive)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: context.appColors.cardSoft,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Nonaktif',
                            style: TextStyle(
                                fontSize: 10,
                                color: context.appColors.textSecondary),
                          ),
                        ),
                    ],
                  ),
                  Text(
                    '${item.category} · ${item.frequency.displayName}',
                    style: TextStyle(
                        fontSize: 12, color: context.appColors.textSecondary),
                  ),
                  if (item.nextExecute != null)
                    Text(
                      '${context.t('recurring.nextExecute')}: ${_formatDate(item.nextExecute)}',
                      style: TextStyle(
                          fontSize: 11,
                          color: context.appColors.textSecondary),
                    ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  IdrFormatter.format(item.amount),
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: item.isActive
                        ? accentColor
                        : context.appColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: () => context.appState
                          .updateRecurring(item.copyWith(isActive: !item.isActive)),
                      child: Icon(
                        item.isActive
                            ? Icons.pause_circle_outline
                            : Icons.play_circle_outline,
                        size: 20,
                        color: context.appColors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: onEdit,
                      child: Icon(Icons.edit_outlined,
                          size: 18, color: context.appColors.textSecondary),
                    ),
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: onDelete,
                      child: const Icon(Icons.delete_outline,
                          size: 18, color: AppColors.negative),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RecurringForm extends StatefulWidget {
  const _RecurringForm({this.existing});
  final RecurringTransactionModel? existing;

  @override
  State<_RecurringForm> createState() => _RecurringFormState();
}

class _RecurringFormState extends State<_RecurringForm> {
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  final _dayController = TextEditingController();
  MoneyTransactionType _type = MoneyTransactionType.expense;
  RecurringFrequency _frequency = RecurringFrequency.monthly;
  String? _category;
  String? _walletId;
  bool _isActive = true;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      final r = widget.existing!;
      _nameController.text = r.name;
      _amountController.text = CurrencyInputFormatter.formatVal(r.amount);
      _type = r.type;
      _frequency = r.frequency;
      _category = r.category;
      _walletId = r.walletId;
      _isActive = r.isActive;
      if (r.dayOfMonth != null) {
        _dayController.text = r.dayOfMonth.toString();
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _dayController.dispose();
    super.dispose();
  }

  void _save() {
    final name = _nameController.text.trim();
    final amount =
        int.tryParse(_amountController.text.replaceAll('.', '')) ?? 0;
    if (name.isEmpty || amount <= 0 || _category == null) return;

    final int? dayOfMonth = _frequency == RecurringFrequency.monthly
        ? int.tryParse(_dayController.text)
        : null;

    final appState = context.appState;
    final now = DateTime.now();

    if (_isEdit) {
      appState.updateRecurring(widget.existing!.copyWith(
        name: name,
        amount: amount,
        type: _type,
        frequency: _frequency,
        category: _category,
        walletId: _walletId,
        isActive: _isActive,
        dayOfMonth: dayOfMonth,
      ));
    } else {
      appState.addRecurring(RecurringTransactionModel(
        id: const Uuid().v4(),
        name: name,
        amount: amount,
        category: _category!,
        type: _type,
        frequency: _frequency,
        isActive: _isActive,
        createdAt: now,
        walletId: _walletId,
        dayOfMonth: dayOfMonth,
        nextExecute: now,
      ));
    }
    Navigator.pop(context);
  }

  List<({String id, String name})> _walletOptions(BuildContext context) {
    return context.appState.wallets
        .map((w) => (id: w.id, name: w.name))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final categories = context.appState.categoriesFor(_type);
    final selectedCat = categories.firstWhereOrNull((c) => c.label == _category);
    final wallets = _walletOptions(context);

    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _isEdit
                  ? context.t('recurring.edit.title')
                  : context.t('recurring.add.title'),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 16),
            // Type toggle
            Row(
              children: [
                Expanded(
                  child: _TypeChip(
                    label: 'Pemasukan',
                    selected: _type == MoneyTransactionType.income,
                    color: AppColors.positive,
                    onTap: () => setState(() {
                      _type = MoneyTransactionType.income;
                      _category = null;
                    }),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _TypeChip(
                    label: 'Pengeluaran',
                    selected: _type == MoneyTransactionType.expense,
                    color: AppColors.negative,
                    onTap: () => setState(() {
                      _type = MoneyTransactionType.expense;
                      _category = null;
                    }),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: context.t('recurring.nameLabel'),
                hintText: context.t('recurring.nameHint'),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                CurrencyInputFormatter(),
              ],
              decoration: InputDecoration(
                labelText: context.t('recurring.amountLabel'),
                prefixText: 'Rp ',
              ),
            ),
            const SizedBox(height: 14),
            CategoryDropdown(
              categories: categories,
              selected: selectedCat,
              accentColor: _type == MoneyTransactionType.income
                  ? AppColors.positive
                  : AppColors.negative,
              onChanged: (cat) => setState(() => _category = cat?.label),
            ),
            const SizedBox(height: 14),
            Text(context.t('recurring.frequencyLabel'),
                style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: RecurringFrequency.values.map((f) {
                final sel = _frequency == f;
                return ChoiceChip(
                  label: Text(f.displayName),
                  selected: sel,
                  onSelected: (_) => setState(() => _frequency = f),
                  selectedColor: AppColors.brandBlue.withValues(alpha: 0.2),
                  labelStyle: TextStyle(
                    color: sel ? AppColors.brandBlue : null,
                    fontWeight: sel ? FontWeight.w700 : null,
                  ),
                );
              }).toList(),
            ),
            if (_frequency == RecurringFrequency.monthly) ...[
              const SizedBox(height: 14),
              TextField(
                controller: _dayController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  labelText: context.t('recurring.dayOfMonthLabel'),
                  hintText: '1',
                ),
              ),
            ],
            if (wallets.isNotEmpty) ...[
              const SizedBox(height: 14),
              Text(context.t('recurring.walletLabel'),
                  style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _walletId,
                decoration: const InputDecoration(isDense: true),
                hint: Text(context.t('wallet.noWallet')),
                items: [
                  DropdownMenuItem(
                    value: null,
                    child: Text(context.t('wallet.noWallet')),
                  ),
                  ...wallets.map((w) => DropdownMenuItem(
                        value: w.id,
                        child: Text(w.name),
                      )),
                ],
                onChanged: (v) => setState(() => _walletId = v),
              ),
            ],
            const SizedBox(height: 10),
            SwitchListTile(
              value: _isActive,
              onChanged: (v) => setState(() => _isActive = v),
              title: Text(context.t('recurring.isActiveLabel')),
              contentPadding: EdgeInsets.zero,
              activeThumbColor: AppColors.brandBlue,
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brandBlue,
                  foregroundColor: Colors.white,
                ),
                child: Text(context.t('recurring.save')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  const _TypeChip({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected
              ? color.withValues(alpha: 0.15)
              : context.appColors.cardSoft,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? color : context.appColors.outline,
            width: selected ? 1.5 : 1,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: selected ? color : context.appColors.textSecondary,
            fontWeight: selected ? FontWeight.w700 : null,
          ),
        ),
      ),
    );
  }
}
