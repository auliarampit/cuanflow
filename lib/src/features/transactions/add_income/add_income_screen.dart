import 'package:cari_untung/src/core/ui/app_gradient_scaffold.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/formatters/currency_input_formatter.dart';
import '../../../core/formatters/idr_formatter.dart';
import '../../../core/localization/transalation_extansions.dart';
import '../../../core/models/money_transaction.dart';
import '../../../core/models/user_category.dart';
import '../../../core/state/app_state.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dynamic_colors.dart';
import '../../../shared/widgets/category_dropdown.dart';

// ─── Bulk item model ────────────────────────────────────────────────────────
class _BulkItem {
  _BulkItem({required this.amount, required this.category, this.note, this.outletId, this.walletId});
  final int amount;
  final String category;
  final String? note;
  final String? outletId;
  final String? walletId;
}

// ─── Screen ────────────────────────────────────────────────────────────────
class AddIncomeScreen extends StatefulWidget {
  const AddIncomeScreen({super.key, this.transaction});
  final MoneyTransaction? transaction;

  @override
  State<AddIncomeScreen> createState() => _AddIncomeScreenState();
}

class _AddIncomeScreenState extends State<AddIncomeScreen> {
  final _amountController = TextEditingController();
  final _amountFocus = FocusNode();

  DateTime _selectedDate = DateTime.now();
  UserCategory? _selectedCategory;
  String? _selectedOutletId;
  String? _selectedWalletId;
  bool _didInit = false;

  // Edit mode only
  final _noteController = TextEditingController();

  // Bulk state
  final List<_BulkItem> _items = [];

  bool get _isEditMode => widget.transaction != null;

  @override
  void initState() {
    super.initState();
    if (_isEditMode) {
      final tx = widget.transaction!;
      _amountController.text = CurrencyInputFormatter.formatVal(tx.amount);
      _selectedDate = tx.effectiveDate;
      _selectedOutletId = tx.outletId;
      _selectedWalletId = tx.walletId;
      _noteController.text = tx.note ?? '';
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didInit) return;
    _didInit = true;

    _selectedOutletId ??= context.appState.selectedOutletId;

    final wallets = context.appState.wallets;
    if (_selectedWalletId == null && wallets.isNotEmpty) {
      final def = wallets.where((w) => w.isDefault).firstOrNull ?? wallets.first;
      _selectedWalletId = def.id;
    }

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
    _noteController.dispose();
    _amountFocus.dispose();
    super.dispose();
  }

  List<UserCategory> _buildCategories(BuildContext context) =>
      context.appState.categoriesFor(MoneyTransactionType.income);

  void _addToList() {
    final rawAmount = _amountController.text.replaceAll('.', '');
    final amount = int.tryParse(rawAmount) ?? 0;

    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(context.t('bulk.validation.amountRequired')),
        backgroundColor: AppColors.negative,
      ));
      return;
    }
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(context.t('income.validation.categoryRequired')),
        backgroundColor: AppColors.negative,
      ));
      return;
    }
    setState(() {
      _items.add(_BulkItem(
        amount: amount,
        category: _selectedCategory!.label,
        note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
        outletId: _selectedOutletId,
        walletId: _selectedWalletId,
      ));
      _amountController.clear();
      _noteController.clear();
      _selectedCategory = null;
    });

    _amountFocus.requestFocus();
  }

  void _saveAll() {
    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(context.t('bulk.validation.emptyList')),
        backgroundColor: AppColors.negative,
      ));
      return;
    }

    for (final item in _items) {
      context.appState.addIncome(
        amount: item.amount,
        note: item.note,
        category: item.category,
        outletId: item.outletId,
        walletId: item.walletId,
        effectiveDate: _selectedDate,
      );
    }

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(
        context.t('bulk.saveSuccess', {'count': _items.length.toString()}),
      ),
      backgroundColor: AppColors.positive,
    ));

    Navigator.of(context).pop();
  }

  void _saveEdit() {
    final rawAmount = _amountController.text.replaceAll('.', '');
    final amount = int.tryParse(rawAmount) ?? 0;
    if (amount <= 0) return;

    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(context.t('income.validation.categoryRequired')),
        backgroundColor: AppColors.negative,
      ));
      return;
    }

    context.appState.updateTransaction(widget.transaction!.copyWith(
      amount: amount,
      note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
      category: _selectedCategory!.label,
      outletId: _selectedOutletId,
      walletId: _selectedWalletId,
      effectiveDate: _selectedDate,
    ));

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(context.t('common.validation.success')),
      backgroundColor: AppColors.positive,
    ));

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final categories = _buildCategories(context);
    final featureOutlets = context.appState.profile.featureOutlets;

    return AppGradientScaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          _isEditMode
              ? context.t('income.edit.title')
              : context.t('income.add.title'),
        ),
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      bottomNavigationBar:
          _isEditMode ? null : _BottomBar(items: _items, onSave: _saveAll),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          18,
          18,
          18,
          MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Edit mode ────────────────────────────────────────────────
            if (_isEditMode) ...[
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
                    Text(
                      context.t('income.add.amountHint'),
                      style: TextStyle(color: context.appColors.textSecondary),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 26),
              CategoryDropdown(
                categories: categories,
                selected: _selectedCategory,
                accentColor: AppColors.positive,
                onChanged: (cat) => setState(() => _selectedCategory = cat),
              ),
              const SizedBox(height: 16),
              if (!featureOutlets)
                TextField(
                  controller: _noteController,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.edit_outlined),
                    hintText: context.t('income.add.noteHint'),
                    labelText: context.t('common.noteOptional'),
                  ),
                ),
              if (featureOutlets) ...[
                const SizedBox(height: 16),
                _OutletSelectorBlock(
                  selectedOutletId: _selectedOutletId,
                  onChanged: (id) => setState(() => _selectedOutletId = id),
                ),
              ],
              if (!context.appState.profile.isBusinessMode &&
                  context.appState.wallets.isNotEmpty) ...[
                const SizedBox(height: 16),
                _WalletSelectorBlock(
                  selectedWalletId: _selectedWalletId,
                  onChanged: (id) => setState(() => _selectedWalletId = id),
                ),
              ],
              const SizedBox(height: 16),
              Text(
                context.t('common.date'),
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 10),
              _DatePickerTile(
                selectedDate: _selectedDate,
                onChanged: (d) => setState(() => _selectedDate = d),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveEdit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.positive,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    context.t('common.save'),
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),
            ],

            // ── Bulk mode ────────────────────────────────────────────────
            if (!_isEditMode) ...[
              // Date row (global for all items in this session)
              _DateRowPicker(
                selectedDate: _selectedDate,
                accentColor: AppColors.positive,
                onChanged: (d) => setState(() => _selectedDate = d),
              ),
              const SizedBox(height: 18),

              // Form card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Amount
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.positive.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: AppColors.positive.withValues(alpha: 0.4),
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: AppColors.positive
                                    .withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              alignment: Alignment.center,
                              child: const Icon(Icons.add,
                                  color: AppColors.positive, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextField(
                                controller: _amountController,
                                focusNode: _amountFocus,
                                keyboardType: TextInputType.number,
                                style: const TextStyle(
                                  fontSize: 36,
                                  fontWeight: FontWeight.w900,
                                ),
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                  CurrencyInputFormatter(),
                                ],
                                decoration: InputDecoration(
                                  hintText: '0',
                                  hintStyle: TextStyle(
                                    fontSize: 36,
                                    fontWeight: FontWeight.w900,
                                    color: context.appColors.textPrimary
                                        .withValues(alpha: 0.25),
                                  ),
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Note (optional, only when outlet feature is off)
                      if (!featureOutlets) ...[
                        TextField(
                          controller: _noteController,
                          decoration: InputDecoration(
                            prefixIcon: Icon(Icons.edit_outlined,
                                size: 18,
                                color: context.appColors.textSecondary),
                            hintText: context.t('income.add.noteHint'),
                            labelText: context.t('common.noteOptional'),
                            isDense: true,
                          ),
                        ),
                        const SizedBox(height: 14),
                      ],

                      // Categories
                      CategoryDropdown(
                        categories: categories,
                        selected: _selectedCategory,
                        accentColor: AppColors.positive,
                        onChanged: (cat) =>
                            setState(() => _selectedCategory = cat),
                      ),

                      // Outlet (per-item, only when feature is on)
                      if (featureOutlets) ...[
                        const SizedBox(height: 14),
                        _OutletPill(
                          selectedOutletId: _selectedOutletId,
                          accentColor: AppColors.positive,
                          onChanged: (id) =>
                              setState(() => _selectedOutletId = id),
                        ),
                      ],
                      // Wallet selector
                      if (context.appState.wallets.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        _WalletPill(
                          selectedWalletId: _selectedWalletId,
                          accentColor: AppColors.positive,
                          onChanged: (id) =>
                              setState(() => _selectedWalletId = id),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Add to list button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _addToList,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(
                        color: AppColors.positive, width: 1.5),
                    foregroundColor: AppColors.positive,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: const Icon(Icons.add_circle_outline),
                  label: Text(
                    context.t('bulk.addToList'),
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, letterSpacing: 1),
                  ),
                ),
              ),

              // Item list (below form)
              if (_items.isNotEmpty) ...[
                const SizedBox(height: 18),
                _ItemListCard(
                  items: _items,
                  accentColor: AppColors.positive,
                  onDelete: (i) => setState(() => _items.removeAt(i)),
                ),
              ],

              const SizedBox(height: 80), // space for bottom bar
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Outlet pill (compact, for inside form card) ────────────────────────────
class _OutletPill extends StatelessWidget {
  const _OutletPill({
    required this.selectedOutletId,
    required this.accentColor,
    required this.onChanged,
  });

  final String? selectedOutletId;
  final Color accentColor;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final outlets = context.appState.outlets;
    if (outlets.isEmpty) return const SizedBox.shrink();

    final outletName = selectedOutletId == null
        ? context.t('outlet.allOutlets')
        : outlets.firstWhereOrNull((o) => o.id == selectedOutletId)?.name ??
            context.t('outlet.selectOutlet');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.t('outlet.label').toUpperCase(),
          style: TextStyle(
            fontSize: 11,
            letterSpacing: 2,
            fontWeight: FontWeight.w700,
            color: context.appColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () => _showSheet(context, outlets),
          borderRadius: BorderRadius.circular(999),
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: accentColor.withValues(alpha: 0.4)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.storefront_outlined,
                    size: 16, color: accentColor),
                const SizedBox(width: 6),
                Text(
                  outletName,
                  style: TextStyle(
                    color: accentColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(Icons.expand_more,
                    size: 16, color: context.appColors.textSecondary),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showSheet(BuildContext context, List outlets) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: context.appColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  context.t('outlet.selectOutlet'),
                  style: const TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 16),
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.store_outlined),
              title: Text(context.t('outlet.allOutlets')),
              trailing: selectedOutletId == null
                  ? const Icon(Icons.check, color: AppColors.brandBlue)
                  : null,
              onTap: () {
                onChanged(null);
                Navigator.pop(ctx);
              },
            ),
            const Divider(height: 1),
            for (final o in outlets)
              ListTile(
                leading: const Icon(Icons.storefront_outlined),
                title: Text(o.name),
                trailing: selectedOutletId == o.id
                    ? const Icon(Icons.check, color: AppColors.brandBlue)
                    : null,
                onTap: () {
                  onChanged(o.id);
                  Navigator.pop(ctx);
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

// ─── Item list card (below form) ────────────────────────────────────────────
class _ItemListCard extends StatelessWidget {
  const _ItemListCard({
    required this.items,
    required this.accentColor,
    required this.onDelete,
  });

  final List<_BulkItem> items;
  final Color accentColor;
  final ValueChanged<int> onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.list_alt_outlined, size: 18, color: accentColor),
                const SizedBox(width: 8),
                Text(
                  context.t('bulk.itemList', {'count': '${items.length}'}),
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                    color: context.appColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            for (int i = 0; i < items.length; i++) ...[
              if (i > 0)
                Divider(height: 1, color: context.appColors.outline),
              _ItemTile(
                  item: items[i],
                  index: i,
                  accentColor: accentColor,
                  onDelete: onDelete),
            ],
          ],
        ),
      ),
    );
  }
}

class _ItemTile extends StatelessWidget {
  const _ItemTile({
    required this.item,
    required this.index,
    required this.accentColor,
    required this.onDelete,
  });

  final _BulkItem item;
  final int index;
  final Color accentColor;
  final ValueChanged<int> onDelete;

  @override
  Widget build(BuildContext context) {
    final outletName = item.outletId == null
        ? null
        : context.appState.outlets
            .firstWhereOrNull((o) => o.id == item.outletId)
            ?.name;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              '${index + 1}',
              style: TextStyle(
                color: accentColor,
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  IdrFormatter.format(item.amount),
                  style: TextStyle(
                      fontWeight: FontWeight.w800, color: accentColor),
                ),
                if (item.note != null && item.note!.isNotEmpty)
                  Text(
                    item.note!,
                    style: TextStyle(
                        fontSize: 12, color: context.appColors.textPrimary),
                  ),
                Row(
                  children: [
                    Text(
                      item.category,
                      style: TextStyle(
                          fontSize: 12, color: context.appColors.textSecondary),
                    ),
                    if (outletName != null) ...[
                      Text(
                        '  ·  ',
                        style: TextStyle(color: context.appColors.textSecondary),
                      ),
                      Icon(Icons.storefront_outlined,
                          size: 12, color: context.appColors.textSecondary),
                      const SizedBox(width: 3),
                      Text(
                        outletName,
                        style: TextStyle(
                            fontSize: 12, color: context.appColors.textSecondary),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline,
                size: 18, color: AppColors.negative),
            onPressed: () => onDelete(index),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}

// ─── Bottom bar ──────────────────────────────────────────────────────────────
class _BottomBar extends StatelessWidget {
  const _BottomBar({required this.items, required this.onSave});

  final List<_BulkItem> items;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final total = items.fold<int>(0, (s, e) => s + e.amount);

    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
        decoration: BoxDecoration(
          color: context.appColors.card,
          border: Border(top: BorderSide(color: context.appColors.outline)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.t('bulk.sessionTotal'),
                    style: TextStyle(
                      fontSize: 11,
                      letterSpacing: 1.5,
                      color: context.appColors.textSecondary,
                    ),
                  ),
                  Text(
                    IdrFormatter.format(total),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.positive,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            ElevatedButton(
              onPressed: items.isNotEmpty ? onSave : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.positive,
                foregroundColor: Colors.black,
                minimumSize: const Size(64, 56),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                context.t('bulk.saveAll', {'count': '${items.length}'}),
                style: const TextStyle(
                    fontWeight: FontWeight.w800, letterSpacing: 1),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Date row picker (bulk mode, full-width) ─────────────────────────────────
class _DateRowPicker extends StatelessWidget {
  const _DateRowPicker({
    required this.selectedDate,
    required this.accentColor,
    required this.onChanged,
  });

  final DateTime selectedDate;
  final Color accentColor;
  final ValueChanged<DateTime> onChanged;

  String _formatDate(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: selectedDate,
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
        );
        if (picked != null) onChanged(picked);
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: context.appColors.cardSoft,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.appColors.outline),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: Icon(Icons.calendar_month_outlined,
                  color: accentColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                context.t('common.transactionDate'),
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: context.appColors.card,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: context.appColors.outline),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _formatDate(selectedDate),
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.keyboard_arrow_down_rounded,
                      size: 16, color: context.appColors.textSecondary),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Date picker tile (edit mode) ────────────────────────────────────────────
class _DatePickerTile extends StatelessWidget {
  const _DatePickerTile(
      {required this.selectedDate, required this.onChanged});

  final DateTime selectedDate;
  final ValueChanged<DateTime> onChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: selectedDate,
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
        );
        if (picked != null) onChanged(picked);
      },
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: context.appColors.cardSoft,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: context.appColors.outline),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_outlined,
                color: AppColors.positive),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                  '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}'),
            ),
            Icon(Icons.expand_more, color: context.appColors.textSecondary),
          ],
        ),
      ),
    );
  }
}

// ─── Outlet selector block (edit mode) ──────────────────────────────────────
class _OutletSelectorBlock extends StatelessWidget {
  const _OutletSelectorBlock(
      {required this.selectedOutletId, required this.onChanged});

  final String? selectedOutletId;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final outlets = context.appState.outlets;
    if (outlets.isEmpty) return const SizedBox.shrink();

    final selectedName = selectedOutletId == null
        ? context.t('outlet.allOutlets')
        : outlets.firstWhereOrNull((o) => o.id == selectedOutletId)?.name ??
            context.t('outlet.selectOutlet');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(context.t('outlet.label'),
            style: const TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 10),
        InkWell(
          onTap: () => showModalBottomSheet<void>(
            context: context,
            backgroundColor: context.appColors.card,
            shape: const RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.vertical(top: Radius.circular(20)),
            ),
            builder: (ctx) => SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        context.t('outlet.selectOutlet'),
                        style: const TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 16),
                      ),
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.store_outlined),
                    title: Text(context.t('outlet.allOutlets')),
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
                  for (final o in outlets)
                    ListTile(
                      leading: const Icon(Icons.storefront_outlined),
                      title: Text(o.name),
                      trailing: selectedOutletId == o.id
                          ? const Icon(Icons.check,
                              color: AppColors.brandBlue)
                          : null,
                      onTap: () {
                        onChanged(o.id);
                        Navigator.pop(ctx);
                      },
                    ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: context.appColors.cardSoft,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: context.appColors.outline),
            ),
            child: Row(
              children: [
                const Icon(Icons.storefront_outlined,
                    color: AppColors.positive),
                const SizedBox(width: 10),
                Expanded(child: Text(selectedName)),
                Icon(Icons.expand_more,
                    color: context.appColors.textSecondary),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Wallet selector block (edit mode) ──────────────────────────────────────
class _WalletSelectorBlock extends StatelessWidget {
  const _WalletSelectorBlock({
    required this.selectedWalletId,
    required this.onChanged,
  });

  final String? selectedWalletId;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final wallets = context.appState.wallets;
    final selectedName = selectedWalletId == null
        ? context.t('wallet.noWallet')
        : wallets.firstWhereOrNull((w) => w.id == selectedWalletId)?.name ??
            context.t('wallet.selector');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(context.t('wallet.selector'),
            style: const TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 10),
        InkWell(
          onTap: () => _showSheet(context, wallets),
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: context.appColors.cardSoft,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: context.appColors.outline),
            ),
            child: Row(
              children: [
                const Icon(Icons.account_balance_wallet_outlined,
                    color: AppColors.positive),
                const SizedBox(width: 10),
                Expanded(child: Text(selectedName)),
                Icon(Icons.expand_more,
                    color: context.appColors.textSecondary),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showSheet(BuildContext context, List<WalletModel> wallets) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: context.appColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  context.t('wallet.selector'),
                  style: const TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 16),
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.wallet_outlined),
              title: Text(context.t('wallet.noWallet')),
              trailing: selectedWalletId == null
                  ? const Icon(Icons.check, color: AppColors.brandBlue)
                  : null,
              onTap: () {
                onChanged(null);
                Navigator.pop(ctx);
              },
            ),
            const Divider(height: 1),
            for (final w in wallets)
              ListTile(
                leading:
                    const Icon(Icons.account_balance_wallet_outlined),
                title: Text(w.name),
                subtitle: Text(w.type.displayName),
                trailing: selectedWalletId == w.id
                    ? const Icon(Icons.check, color: AppColors.brandBlue)
                    : null,
                onTap: () {
                  onChanged(w.id);
                  Navigator.pop(ctx);
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

// ─── Wallet pill (compact, for inside form card) ─────────────────────────────
class _WalletPill extends StatelessWidget {
  const _WalletPill({
    required this.selectedWalletId,
    required this.accentColor,
    required this.onChanged,
  });

  final String? selectedWalletId;
  final Color accentColor;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final wallets = context.appState.wallets;
    final walletName = selectedWalletId == null
        ? context.t('wallet.noWallet')
        : wallets.firstWhereOrNull((w) => w.id == selectedWalletId)?.name ??
            context.t('wallet.selector');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.t('wallet.selector').toUpperCase(),
          style: TextStyle(
            fontSize: 11,
            letterSpacing: 2,
            fontWeight: FontWeight.w700,
            color: context.appColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () => _showSheet(context, wallets),
          borderRadius: BorderRadius.circular(999),
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(999),
              border:
                  Border.all(color: accentColor.withValues(alpha: 0.4)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.account_balance_wallet_outlined,
                    size: 16, color: accentColor),
                const SizedBox(width: 6),
                Text(
                  walletName,
                  style: TextStyle(
                    color: accentColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(Icons.expand_more,
                    size: 16,
                    color: context.appColors.textSecondary),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showSheet(BuildContext context, List<WalletModel> wallets) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: context.appColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  context.t('wallet.selector'),
                  style: const TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 16),
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.wallet_outlined),
              title: Text(context.t('wallet.noWallet')),
              trailing: selectedWalletId == null
                  ? const Icon(Icons.check, color: AppColors.brandBlue)
                  : null,
              onTap: () {
                onChanged(null);
                Navigator.pop(ctx);
              },
            ),
            const Divider(height: 1),
            for (final w in wallets)
              ListTile(
                leading:
                    const Icon(Icons.account_balance_wallet_outlined),
                title: Text(w.name),
                subtitle: Text(w.type.displayName),
                trailing: selectedWalletId == w.id
                    ? const Icon(Icons.check, color: AppColors.brandBlue)
                    : null,
                onTap: () {
                  onChanged(w.id);
                  Navigator.pop(ctx);
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
