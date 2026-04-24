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
import '../../../core/ui/app_gradient_scaffold.dart';
import '../../../shared/widgets/category_dropdown.dart';

// ─── Bulk item model ────────────────────────────────────────────────────────
class _BulkItem {
  _BulkItem({
    required this.amount,
    required this.category,
    this.note,
    this.outletId,
    this.walletId,
    this.isStockPurchase = false,
  });
  final int amount;
  final String category;
  final String? note;
  final String? outletId;
  final String? walletId;
  final bool isStockPurchase;
}

// ─── Screen ────────────────────────────────────────────────────────────────
class AddExpenseScreen extends StatefulWidget {
  const AddExpenseScreen({super.key, this.transaction});
  final MoneyTransaction? transaction;

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  final _amountFocus = FocusNode();

  UserCategory? _selectedCategory;
  String? _selectedOutletId;
  String? _selectedWalletId;
  DateTime _selectedDate = DateTime.now();
  bool _didInit = false;

  // Bulk state
  final List<_BulkItem> _items = [];

  bool get _isEditMode => widget.transaction != null;

  @override
  void initState() {
    super.initState();
    if (_isEditMode) {
      final tx = widget.transaction!;
      _amountController.text = CurrencyInputFormatter.formatVal(tx.amount);
      _noteController.text = tx.note ?? '';
      _selectedOutletId = tx.outletId;
      _selectedWalletId = tx.walletId;
      _selectedDate = tx.effectiveDate;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didInit) return;
    _didInit = true;

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
      context.appState.categoriesFor(MoneyTransactionType.expense);

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
        content: Text(context.t('common.validation.mandatory')),
        backgroundColor: AppColors.negative,
      ));
      return;
    }
    if (_noteController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(context.t('common.validation.mandatory')),
        backgroundColor: AppColors.negative,
      ));
      return;
    }

    setState(() {
      _items.add(_BulkItem(
        amount: amount,
        category: _selectedCategory!.label,
        note: _noteController.text.trim(),
        outletId: _selectedOutletId,
        walletId: _selectedWalletId,
        isStockPurchase: _selectedCategory!.isStockPurchase,
      ));
      _amountController.clear();
      _noteController.clear();
      _selectedCategory = null;
      // outlet stays selected for convenience
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
      context.appState.addExpense(
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

  void _saveEdit(BuildContext context) {
    final rawAmount = _amountController.text.replaceAll('.', '');
    final amount = int.tryParse(rawAmount) ?? 0;
    if (amount <= 0) return;

    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(context.t('common.validation.mandatory')),
        backgroundColor: AppColors.negative,
      ));
      return;
    }
    if (_noteController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(context.t('common.validation.mandatory')),
        backgroundColor: AppColors.negative,
      ));
      return;
    }

    context.appState.updateTransaction(widget.transaction!.copyWith(
      amount: amount,
      note: _noteController.text.trim(),
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
    final isBusinessMode = context.appState.profile.isBusinessMode;

    return AppGradientScaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          _isEditMode
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
                  borderRadius: BorderRadius.circular(999),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 10),
                    decoration: BoxDecoration(
                      color: context.appColors.cardSoft,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: context.appColors.outline),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.calendar_today_outlined,
                            size: 18, color: context.appColors.textSecondary),
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
                style: TextStyle(
                  letterSpacing: 2,
                  fontWeight: FontWeight.w700,
                  color: context.appColors.textSecondary,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: context.appColors.cardSoft,
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
                      child: const Icon(Icons.remove,
                          color: AppColors.negative),
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
                                color: context.appColors.textPrimary
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
                    Icon(Icons.unfold_more,
                        color: context.appColors.textSecondary),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Text(
                context.t('common.note'),
                style: TextStyle(
                  letterSpacing: 2,
                  fontWeight: FontWeight.w700,
                  color: context.appColors.textSecondary,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _noteController,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.edit_outlined),
                  hintText: context.t('expense.add.noteHint'),
                  labelText: context.t('common.note'),
                ),
              ),
              if (featureOutlets) ...[
                const SizedBox(height: 18),
                _OutletSelectorBlock(
                  selectedOutletId: _selectedOutletId,
                  onChanged: (id) => setState(() => _selectedOutletId = id),
                ),
              ],
              if (!context.appState.profile.isBusinessMode &&
                  context.appState.wallets.isNotEmpty) ...[
                const SizedBox(height: 18),
                _WalletSelectorBlock(
                  selectedWalletId: _selectedWalletId,
                  onChanged: (id) => setState(() => _selectedWalletId = id),
                ),
              ],
              const SizedBox(height: 18),
              CategoryDropdown(
                categories: categories,
                selected: _selectedCategory,
                accentColor: AppColors.negative,
                onChanged: (cat) => setState(() => _selectedCategory = cat),
              ),
              if (isBusinessMode && _selectedCategory?.isStockPurchase == true) ...[
                const SizedBox(height: 8),
                _StockInfoBanner(),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _saveEdit(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.negative,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: const Icon(Icons.save_outlined),
                  label: Text(context.t('expense.add.save')),
                ),
              ),
              const SizedBox(height: 18),
            ],

            // ── Bulk mode ────────────────────────────────────────────────
            if (!_isEditMode) ...[
              // Date row (global for all items in this session)
              _DateRowPicker(
                selectedDate: _selectedDate,
                accentColor: AppColors.negative,
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
                          color: AppColors.negative.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color:
                                AppColors.negative.withValues(alpha: 0.4),
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: AppColors.negative
                                    .withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              alignment: Alignment.center,
                              child: const Icon(Icons.remove,
                                  color: AppColors.negative, size: 20),
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

                      // Note (required)
                      TextField(
                        controller: _noteController,
                        decoration: InputDecoration(
                          prefixIcon: Icon(
                            Icons.edit_outlined,
                            size: 18,
                            color: context.appColors.textSecondary,
                          ),
                          hintText: context.t('expense.add.noteHint'),
                          labelText: context.t('common.note'),
                          isDense: true,
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Categories
                      CategoryDropdown(
                        categories: categories,
                        selected: _selectedCategory,
                        accentColor: AppColors.negative,
                        onChanged: (cat) =>
                            setState(() => _selectedCategory = cat),
                      ),
                      if (_selectedCategory?.isStockPurchase == true) ...[
                        const SizedBox(height: 8),
                        _StockInfoBanner(),
                      ],

                      // Outlet (per-item, only when feature is on)
                      if (featureOutlets) ...[
                        const SizedBox(height: 14),
                        _OutletPill(
                          selectedOutletId: _selectedOutletId,
                          accentColor: AppColors.negative,
                          onChanged: (id) =>
                              setState(() => _selectedOutletId = id),
                        ),
                      ],
                      // Wallet selector (when user has wallets set up)
                      if (context.appState.wallets.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        _WalletPill(
                          selectedWalletId: _selectedWalletId,
                          accentColor: AppColors.negative,
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
                        color: AppColors.negative, width: 1.5),
                    foregroundColor: AppColors.negative,
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
                  accentColor: AppColors.negative,
                  onDelete: (i) => setState(() => _items.removeAt(i)),
                ),
              ],

              const SizedBox(height: 80),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Stock info banner ───────────────────────────────────────────────────────
class _StockInfoBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFF9F00).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFFF9F00).withValues(alpha: 0.3)),
      ),
      child: const Row(
        children: [
          Icon(Icons.inventory_2_outlined, size: 14, color: Color(0xFFFF9F00)),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Pengeluaran ini akan tercatat sebagai Pembelian Stok di laporan',
              style: TextStyle(
                fontSize: 11,
                color: Color(0xFFFF9F00),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
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
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: context.appColors.textPrimary,
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
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: context.appColors.textPrimary,
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
              border:
                  Border.all(color: accentColor.withValues(alpha: 0.4)),
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

// ─── Item list card ──────────────────────────────────────────────────────────
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
                Icon(Icons.list_alt_outlined,
                    size: 18, color: accentColor),
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
                if (item.note != null)
                  Text(
                    item.note!,
                    style: TextStyle(
                        fontSize: 12,
                        color: context.appColors.textPrimary),
                  ),
                Row(
                  children: [
                    Text(
                      item.category,
                      style: TextStyle(
                          fontSize: 12,
                          color: context.appColors.textSecondary),
                    ),
                    if (context.appState.profile.isBusinessMode && item.isStockPurchase) ...[
                      const SizedBox(width: 5),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF9F00).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          '📦',
                          style: TextStyle(fontSize: 9),
                        ),
                      ),
                    ],
                    if (outletName != null) ...[
                      Text(
                        '  ·  ',
                        style: TextStyle(
                            color: context.appColors.textSecondary),
                      ),
                      Icon(Icons.storefront_outlined,
                          size: 12,
                          color: context.appColors.textSecondary),
                      const SizedBox(width: 3),
                      Text(
                        outletName,
                        style: TextStyle(
                            fontSize: 12,
                            color: context.appColors.textSecondary),
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
          border: Border(
              top: BorderSide(color: context.appColors.outline)),
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
                      color: AppColors.negative,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            ElevatedButton(
              onPressed: items.isNotEmpty ? onSave : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.negative,
                foregroundColor: Colors.white,
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
        Text(
          context.t('outlet.label'),
          style: TextStyle(
            letterSpacing: 2,
            fontWeight: FontWeight.w700,
            color: context.appColors.textSecondary,
          ),
        ),
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
              border: Border.all(
                color: AppColors.negative.withValues(alpha: 0.5),
                width: 2,
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.storefront_outlined,
                    color: AppColors.negative),
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
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: context.appColors.cardSoft,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: context.appColors.outline),
            ),
            child: Row(
              children: [
                const Icon(Icons.account_balance_wallet_outlined,
                    color: AppColors.negative),
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
                leading: const Icon(Icons.account_balance_wallet_outlined),
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
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: accentColor.withValues(alpha: 0.4)),
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
                    size: 16, color: context.appColors.textSecondary),
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
                leading: const Icon(Icons.account_balance_wallet_outlined),
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

