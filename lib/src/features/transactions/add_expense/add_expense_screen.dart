import 'package:cari_untung/src/core/config/space_features.dart';
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
import '../../../shared/widgets/recent_items_bar.dart';

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
  final _noteFocus = FocusNode();

  UserCategory? _selectedCategory;
  bool _categoryTouched = false;
  String? _selectedOutletId;
  String? _selectedWalletId;
  DateTime _selectedDate = DateTime.now();
  bool _didInit = false;

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
      final def =
          wallets.where((w) => w.isDefault).firstOrNull ?? wallets.first;
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
    _noteFocus.dispose();
    super.dispose();
  }

  List<UserCategory> _buildCategories(BuildContext context) =>
      context.appState.categoriesFor(MoneyTransactionType.expense);

  void _addToList() {
    final rawAmount = _amountController.text.replaceAll('.', '');
    final amount = int.tryParse(rawAmount) ?? 0;
    final note = _noteController.text.trim();

    if (note.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Isi nama barang dulu'),
          backgroundColor: AppColors.negative,
        ),
      );
      _noteFocus.requestFocus();
      return;
    }

    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.t('bulk.validation.amountRequired')),
          backgroundColor: AppColors.negative,
        ),
      );
      _amountFocus.requestFocus();
      return;
    }

    if (!_categoryTouched) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pilih kategori dulu'),
          backgroundColor: AppColors.negative,
        ),
      );
      return;
    }

    final categoryLabel = _selectedCategory?.label ?? 'Lainnya';

    setState(() {
      _items.add(
        _BulkItem(
          amount: amount,
          category: categoryLabel,
          note: note,
          outletId: _selectedOutletId,
          walletId: _selectedWalletId,
          isStockPurchase: _selectedCategory?.isStockPurchase ?? false,
        ),
      );
      _amountController.clear();
      _noteController.clear();
      _selectedCategory = null;
      _categoryTouched = false;
      // outlet dan wallet tetap terpilih untuk kenyamanan
    });

    _noteFocus.requestFocus();
  }

  void _saveAll() {
    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.t('bulk.validation.emptyList')),
          backgroundColor: AppColors.negative,
        ),
      );
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

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          context.t('bulk.saveSuccess', {'count': _items.length.toString()}),
        ),
        backgroundColor: AppColors.positive,
      ),
    );

    Navigator.of(context).pop();
  }

  void _saveEdit(BuildContext context) {
    final rawAmount = _amountController.text.replaceAll('.', '');
    final amount = int.tryParse(rawAmount) ?? 0;
    if (amount <= 0) return;

    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.t('common.validation.mandatory')),
          backgroundColor: AppColors.negative,
        ),
      );
      return;
    }
    if (_noteController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.t('common.validation.mandatory')),
          backgroundColor: AppColors.negative,
        ),
      );
      return;
    }

    context.appState.updateTransaction(
      widget.transaction!.copyWith(
        amount: amount,
        note: _noteController.text.trim(),
        category: _selectedCategory!.label,
        outletId: _selectedOutletId,
        walletId: _selectedWalletId,
        effectiveDate: _selectedDate,
      ),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.t('common.validation.success')),
        backgroundColor: AppColors.positive,
      ),
    );

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final categories = _buildCategories(context);
    final expAppState = context.appState;
    final expSpace = expAppState.activeSpace;
    final expIsPremium = expAppState.profile.isBusinessPremium;
    final featureOutlets = SpaceFeatures.canUseOutlets(expSpace, expIsPremium);
    final isBusinessMode = SpaceFeatures.canUseProductionBatch(expSpace, expIsPremium);

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
      bottomNavigationBar: _isEditMode
          ? null
          : _BottomBar(items: _items, onSave: _saveAll),
      body: _isEditMode
          ? _buildEditMode(context, categories, featureOutlets, isBusinessMode)
          : _buildBulkMode(context, categories, featureOutlets),
    );
  }

  // ── Edit mode (unchanged) ─────────────────────────────────────────────────
  Widget _buildEditMode(
    BuildContext context,
    List<UserCategory> categories,
    bool featureOutlets,
    bool isBusinessMode,
  ) {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        18,
        18,
        18,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
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
                if (picked != null) setState(() => _selectedDate = picked);
              },
              borderRadius: BorderRadius.circular(999),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: context.appColors.cardSoft,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: context.appColors.outline),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      size: 18,
                      color: context.appColors.textSecondary,
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
                  child: const Icon(Icons.remove, color: AppColors.negative),
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
                Icon(Icons.unfold_more, color: context.appColors.textSecondary),
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
          if (!isBusinessMode &&
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
      ),
    );
  }

  // ── Bulk mode — shopping list UX ──────────────────────────────────────────
  Widget _buildBulkMode(
    BuildContext context,
    List<UserCategory> categories,
    bool featureOutlets,
  ) {
    return Column(
      children: [
        // Header compact: tanggal + outlet (global untuk sesi ini)
        _SessionHeader(
          selectedDate: _selectedDate,
          accentColor: AppColors.negative,
          onDateChanged: (d) => setState(() => _selectedDate = d),
          featureOutlets: featureOutlets,
          selectedOutletId: _selectedOutletId,
          onOutletChanged: (id) => setState(() => _selectedOutletId = id),
        ),
        // Recent/frequent items
        RecentItemsBar(
          type: MoneyTransactionType.expense,
          accentColor: AppColors.negative,
          onSelect: (item) {
            setState(() {
              _selectedCategory = categories.firstWhereOrNull(
                (c) => c.label == item.category,
              );
              _categoryTouched = true;
              _amountController.text =
                  CurrencyInputFormatter.formatVal(item.amount);
              _noteController.text = item.note ?? '';
              if (item.outletId != null) _selectedOutletId = item.outletId;
              if (item.walletId != null) _selectedWalletId = item.walletId;
            });
          },
        ),
        // Daftar item yang sudah ditambahkan (tumbuh di sini)
        Expanded(
          child: _items.isEmpty
              ? const _EmptyShoppingList()
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  itemCount: _items.length,
                  separatorBuilder: (_, i) => Divider(
                    height: 1,
                    color: Theme.of(context).dividerColor,
                  ),
                  itemBuilder: (ctx, i) => _ItemTile(
                    item: _items[i],
                    index: i,
                    accentColor: AppColors.negative,
                    onDelete: (idx) => setState(() => _items.removeAt(idx)),
                  ),
                ),
        ),
        // Input cepat pinned di bawah
        _CompactInputRow(
          amountController: _amountController,
          noteController: _noteController,
          noteFocus: _noteFocus,
          amountFocus: _amountFocus,
          categories: categories,
          selectedCategory: _selectedCategory,
          categoryTouched: _categoryTouched,
          onCategoryChanged: (c) => setState(() {
            _selectedCategory = c;
            _categoryTouched = true;
          }),
          onAdd: _addToList,
          accentColor: AppColors.negative,
        ),
      ],
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
        border: Border.all(
          color: const Color(0xFFFF9F00).withValues(alpha: 0.3),
        ),
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

// ─── Session header (bulk mode) ──────────────────────────────────────────────
class _SessionHeader extends StatelessWidget {
  const _SessionHeader({
    required this.selectedDate,
    required this.accentColor,
    required this.onDateChanged,
    required this.featureOutlets,
    required this.selectedOutletId,
    required this.onOutletChanged,
  });

  final DateTime selectedDate;
  final Color accentColor;
  final ValueChanged<DateTime> onDateChanged;
  final bool featureOutlets;
  final String? selectedOutletId;
  final ValueChanged<String?> onOutletChanged;

  String _formatDate(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
    ];
    final now = DateTime.now();
    final isToday =
        d.year == now.year && d.month == now.month && d.day == now.day;
    return isToday ? 'Hari ini' : '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
      child: Row(
        children: [
          // Date pill
          InkWell(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: selectedDate,
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
              );
              if (picked != null) onDateChanged(picked);
            },
            borderRadius: BorderRadius.circular(999),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: accentColor.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 13,
                    color: accentColor,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _formatDate(selectedDate),
                    style: TextStyle(
                      color: accentColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(width: 3),
                  Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 14,
                    color: accentColor,
                  ),
                ],
              ),
            ),
          ),
          if (featureOutlets) ...[
            const SizedBox(width: 8),
            _OutletPill(
              selectedOutletId: selectedOutletId,
              accentColor: accentColor,
              onChanged: onOutletChanged,
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Compact input row (shopping list UX) ───────────────────────────────────
class _CompactInputRow extends StatelessWidget {
  const _CompactInputRow({
    required this.amountController,
    required this.noteController,
    required this.noteFocus,
    required this.amountFocus,
    required this.categories,
    required this.selectedCategory,
    required this.categoryTouched,
    required this.onCategoryChanged,
    required this.onAdd,
    required this.accentColor,
  });

  final TextEditingController amountController;
  final TextEditingController noteController;
  final FocusNode noteFocus;
  final FocusNode amountFocus;
  final List<UserCategory> categories;
  final UserCategory? selectedCategory;
  final bool categoryTouched;
  final ValueChanged<UserCategory?> onCategoryChanged;
  final VoidCallback onAdd;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.appColors.card,
        border: Border(top: BorderSide(color: context.appColors.outline)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Nama barang — field utama, fokus pertama
                  Expanded(
                    child: TextField(
                      controller: noteController,
                      focusNode: noteFocus,
                      textInputAction: TextInputAction.next,
                      onSubmitted: (_) => amountFocus.requestFocus(),
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        hintText: 'Nama barang',
                        hintStyle: TextStyle(
                          fontSize: 13,
                          color: context.appColors.textSecondary,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide:
                              BorderSide(color: context.appColors.outline),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide:
                              BorderSide(color: accentColor, width: 1.5),
                        ),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 11,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Harga
                  SizedBox(
                    width: 112,
                    child: TextField(
                      controller: amountController,
                      focusNode: amountFocus,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => onAdd(),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        CurrencyInputFormatter(),
                      ],
                      decoration: InputDecoration(
                        hintText: '0',
                        hintStyle: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: context.appColors.textPrimary
                              .withValues(alpha: 0.25),
                        ),
                        prefixText: 'Rp ',
                        prefixStyle: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: accentColor,
                        ),
                        filled: true,
                        fillColor: accentColor.withValues(alpha: 0.06),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                            color: accentColor.withValues(alpha: 0.35),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide:
                              BorderSide(color: accentColor, width: 1.5),
                        ),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 11,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Tombol tambah
                  GestureDetector(
                    onTap: onAdd,
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: accentColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.add,
                        color: Colors.white,
                        size: 26,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Chip kategori — wajib dipilih
              _CategoryChipsRow(
                categories: categories,
                selected: selectedCategory,
                categoryTouched: categoryTouched,
                onChanged: onCategoryChanged,
                accentColor: accentColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Category chips row ──────────────────────────────────────────────────────
class _CategoryChipsRow extends StatelessWidget {
  const _CategoryChipsRow({
    required this.categories,
    required this.selected,
    required this.categoryTouched,
    required this.onChanged,
    required this.accentColor,
  });

  final List<UserCategory> categories;
  final UserCategory? selected;
  final bool categoryTouched;
  final ValueChanged<UserCategory?> onChanged;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 30,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _Chip(
            label: 'Lainnya',
            isSelected: selected == null && categoryTouched,
            onTap: () => onChanged(null),
            accentColor: accentColor,
          ),
          const SizedBox(width: 6),
          ...categories.map(
            (cat) => Padding(
              padding: const EdgeInsets.only(right: 6),
              child: _Chip(
                label: cat.label,
                isSelected: selected?.key == cat.key,
                onTap: () => onChanged(cat),
                accentColor: accentColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.accentColor,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? accentColor : accentColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: isSelected
                ? accentColor
                : accentColor.withValues(alpha: 0.3),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : accentColor,
          ),
        ),
      ),
    );
  }
}

// ─── Empty state shopping list ───────────────────────────────────────────────
class _EmptyShoppingList extends StatelessWidget {
  const _EmptyShoppingList();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.shopping_basket_outlined,
            size: 52,
            color: context.appColors.textSecondary.withValues(alpha: 0.35),
          ),
          const SizedBox(height: 14),
          Text(
            'Belum ada item',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 15,
              color: context.appColors.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Ketik nama barang, harga, pilih kategori, lalu tap +',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: context.appColors.textSecondary.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Outlet pill (compact, for session header & form card) ──────────────────
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

    return InkWell(
      onTap: () => _showSheet(context, outlets),
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: accentColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: accentColor.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.storefront_outlined, size: 13, color: accentColor),
            const SizedBox(width: 6),
            Text(
              outletName,
              style: TextStyle(
                color: accentColor,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
            const SizedBox(width: 3),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 14,
              color: accentColor,
            ),
          ],
        ),
      ),
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
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
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

// ─── Item tile ───────────────────────────────────────────────────────────────
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
      padding: const EdgeInsets.symmetric(vertical: 10),
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
                    fontWeight: FontWeight.w800,
                    color: accentColor,
                  ),
                ),
                Row(
                  children: [
                    if (item.note != null)
                      Text(
                        item.note!,
                        style: TextStyle(
                          fontSize: 13,
                          color: context.appColors.textPrimary,
                        ),
                      ),
                    if (item.note != null && item.category != 'Lainnya')
                      Text(
                        '  ·  ',
                        style: TextStyle(
                          fontSize: 12,
                          color: context.appColors.textSecondary,
                        ),
                      ),
                    Text(
                      item.category,
                      style: TextStyle(
                        fontSize: 12,
                        color: context.appColors.textSecondary,
                      ),
                    ),
                    if (SpaceFeatures.canUseProductionBatch(
                          context.appState.activeSpace,
                          context.appState.profile.isBusinessPremium,
                        ) &&
                        item.isStockPurchase) ...[
                      const SizedBox(width: 5),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 1,
                        ),
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
                          color: context.appColors.textSecondary,
                        ),
                      ),
                      Icon(
                        Icons.storefront_outlined,
                        size: 12,
                        color: context.appColors.textSecondary,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        outletName,
                        style: TextStyle(
                          fontSize: 12,
                          color: context.appColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(
              Icons.delete_outline,
              size: 18,
              color: AppColors.negative,
            ),
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
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
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
  const _OutletSelectorBlock({
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
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
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
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
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
                const Icon(
                  Icons.storefront_outlined,
                  color: AppColors.negative,
                ),
                const SizedBox(width: 10),
                Expanded(child: Text(selectedName)),
                Icon(Icons.expand_more, color: context.appColors.textSecondary),
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
        Text(
          context.t('wallet.selector'),
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
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
                const Icon(
                  Icons.account_balance_wallet_outlined,
                  color: AppColors.negative,
                ),
                const SizedBox(width: 10),
                Expanded(child: Text(selectedName)),
                Icon(Icons.expand_more, color: context.appColors.textSecondary),
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
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
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
