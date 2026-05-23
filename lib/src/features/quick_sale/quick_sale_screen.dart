import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../core/formatters/currency_input_formatter.dart';
import '../../core/formatters/idr_formatter.dart';
import '../../core/localization/transalation_extansions.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dynamic_colors.dart';
import '../../shared/widgets/native_ad_card.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart' show TemplateType;

class QuickSaleScreen extends StatefulWidget {
  const QuickSaleScreen({super.key});

  @override
  State<QuickSaleScreen> createState() => _QuickSaleScreenState();
}

class _QuickSaleScreenState extends State<QuickSaleScreen> {
  bool _manageMode = false;
  String? _selectedCategory; // null = Semua
  final Map<String, int> _cart = {}; // presetId → qty

  // ── Helpers ────────────────────────────────────────────────────────────────

  List<String> _categories(List<QuickSalePreset> presets) {
    final cats = presets
        .map((p) => p.category)
        .where((c) => c.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    return cats;
  }

  List<QuickSalePreset> _filtered(List<QuickSalePreset> presets) {
    if (_selectedCategory == null) return presets;
    return presets.where((p) => p.category == _selectedCategory).toList();
  }

  QuickSalePreset? _presetById(List<QuickSalePreset> all, String id) {
    for (final p in all) {
      if (p.id == id) return p;
    }
    return null;
  }

  int _cartTotal(List<QuickSalePreset> all) {
    var total = 0;
    for (final entry in _cart.entries) {
      final preset = _presetById(all, entry.key);
      if (preset != null) total += preset.price * entry.value;
    }
    return total;
  }

  int get _cartItemCount => _cart.values.fold(0, (s, q) => s + q);

  // ── Cart actions ───────────────────────────────────────────────────────────

  void _addToCart(String presetId) {
    setState(() => _cart[presetId] = (_cart[presetId] ?? 0) + 1);
  }

  void _removeFromCart(String presetId) {
    setState(() {
      final current = _cart[presetId] ?? 0;
      if (current <= 1) {
        _cart.remove(presetId);
      } else {
        _cart[presetId] = current - 1;
      }
    });
  }

  void _clearCart() => setState(() => _cart.clear());

  void _recordCart() {
    if (_cart.isEmpty) return;
    final presets = context.appState.quickSalePresets;
    var totalAmount = 0;
    final cartSnapshot = Map<String, int>.from(_cart);

    for (final entry in cartSnapshot.entries) {
      final preset = _presetById(presets, entry.key);
      if (preset == null) continue;
      final qty = entry.value;
      final total = preset.price * qty;
      context.appState.addIncome(
        amount: total,
        category: preset.category,
        note: '${preset.name} x$qty',
        effectiveDate: DateTime.now(),
        walletId: preset.walletId,
        outletId: preset.outletId,
      );
      totalAmount += total;
    }

    setState(() => _cart.clear());

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${cartSnapshot.length} item tercatat · ${IdrFormatter.format(totalAmount)}',
        ),
        backgroundColor: AppColors.positive,
        duration: const Duration(seconds: 2),
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () =>
              ScaffoldMessenger.of(context).hideCurrentSnackBar(),
        ),
      ),
    );
  }

  // ── Form & dialogs ─────────────────────────────────────────────────────────

  void _showForm(BuildContext context, QuickSalePreset? existing) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.appColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _PresetForm(existing: existing),
    );
  }

  void _confirmDelete(BuildContext context, QuickSalePreset preset) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.t('quickSale.delete.title')),
        content: Text(
            context.t('quickSale.delete.content', {'name': preset.name})),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(context.t('common.cancel')),
          ),
          TextButton(
            onPressed: () {
              context.appState.deleteQuickSalePreset(preset.id);
              _cart.remove(preset.id);
              Navigator.pop(ctx);
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.negative),
            child: Text(context.t('quickSale.delete.confirm')),
          ),
        ],
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final appState = context.appState;
    final allPresets = appState.quickSalePresets;
    final categories = _categories(allPresets);
    final filtered = _filtered(allPresets);
    final hasCart = _cart.isNotEmpty && !_manageMode;

    return Scaffold(
      appBar: AppBar(
        title: Text(context.t('quickSale.title')),
        actions: [
          if (_cart.isNotEmpty && !_manageMode)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Kosongkan keranjang',
              onPressed: _clearCart,
            ),
          IconButton(
            icon: Icon(_manageMode ? Icons.check : Icons.edit_outlined),
            tooltip: _manageMode
                ? context.t('quickSale.doneManage')
                : context.t('quickSale.manage'),
            onPressed: () => setState(() {
              _manageMode = !_manageMode;
              if (_manageMode) _cart.clear();
            }),
          ),
          if (_manageMode)
            IconButton(
              icon: const Icon(Icons.add),
              tooltip: context.t('quickSale.add.button'),
              onPressed: () => _showForm(context, null),
            ),
        ],
      ),
      body: allPresets.isEmpty
          ? _EmptyState(onAdd: () => _showForm(context, null))
          : Stack(
              children: [
                Column(
                  children: [
                    // ── Category filter ─────────────────────────────────────
                    if (!_manageMode && categories.length > 1)
                      _CategoryFilterRow(
                        categories: categories,
                        selected: _selectedCategory,
                        onSelect: (cat) =>
                            setState(() => _selectedCategory = cat),
                      ),

                    // ── Hint text ───────────────────────────────────────────
                    if (!_manageMode)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 10, 16, 2),
                        child: Row(
                          children: [
                            Icon(
                              _cart.isEmpty
                                  ? Icons.touch_app_outlined
                                  : Icons.shopping_cart_outlined,
                              size: 13,
                              color: context.appColors.textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _cart.isEmpty
                                  ? 'Tap untuk tambah ke keranjang'
                                  : 'Tap tambah · tahan untuk kurangi',
                              style: TextStyle(
                                color: context.appColors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),

                    // ── Ad ──────────────────────────────────────────────────
                    if (!_manageMode)
                      const Padding(
                        padding: EdgeInsets.fromLTRB(16, 4, 16, 0),
                        child: NativeAdCard(templateType: TemplateType.small),
                      ),

                    // ── Grid ────────────────────────────────────────────────
                    Expanded(
                      child: GridView.builder(
                        padding: EdgeInsets.fromLTRB(
                            16, 8, 16, hasCart ? 80 : 16),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 1.4,
                        ),
                        itemCount: filtered.length,
                        itemBuilder: (context, i) {
                          final preset = filtered[i];
                          final qty = _cart[preset.id] ?? 0;
                          return _PresetCard(
                            preset: preset,
                            manageMode: _manageMode,
                            qty: qty,
                            onTap: _manageMode
                                ? null
                                : () => _addToCart(preset.id),
                            onLongPress: (!_manageMode && qty > 0)
                                ? () => _removeFromCart(preset.id)
                                : null,
                            onEdit: () => _showForm(context, preset),
                            onDelete: () => _confirmDelete(context, preset),
                          );
                        },
                      ),
                    ),
                  ],
                ),

                // ── Cart bar ────────────────────────────────────────────────
                if (hasCart)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: _CartBar(
                      itemCount: _cartItemCount,
                      total: _cartTotal(allPresets),
                      onRecord: _recordCart,
                    ),
                  ),
              ],
            ),
      floatingActionButton: _manageMode
          ? FloatingActionButton.extended(
              onPressed: () => _showForm(context, null),
              icon: const Icon(Icons.add),
              label: Text(context.t('quickSale.add.button')),
              backgroundColor: AppColors.brandBlue,
              foregroundColor: Colors.white,
            )
          : null,
    );
  }
}

// ─── Category filter row ───────────────────────────────────────────────────────

class _CategoryFilterRow extends StatelessWidget {
  const _CategoryFilterRow({
    required this.categories,
    required this.selected,
    required this.onSelect,
  });

  final List<String> categories;
  final String? selected;
  final ValueChanged<String?> onSelect;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _CategoryChip(
            label: 'Semua',
            selected: selected == null,
            onTap: () => onSelect(null),
          ),
          ...categories.map(
            (cat) => _CategoryChip(
              label: cat,
              selected: selected == cat,
              onTap: () => onSelect(cat),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8, top: 8, bottom: 8),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.brandBlue
                : context.appColors.cardSoft,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected
                  ? AppColors.brandBlue
                  : context.appColors.outline,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: selected
                  ? Colors.white
                  : context.appColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Cart bar ─────────────────────────────────────────────────────────────────

class _CartBar extends StatelessWidget {
  const _CartBar({
    required this.itemCount,
    required this.total,
    required this.onRecord,
  });

  final int itemCount;
  final int total;
  final VoidCallback onRecord;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        MediaQuery.of(context).padding.bottom > 0
            ? MediaQuery.of(context).padding.bottom
            : 16,
      ),
      decoration: BoxDecoration(
        color: context.appColors.card,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$itemCount item',
                  style: TextStyle(
                    fontSize: 12,
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
          // Tombol catat
          ElevatedButton.icon(
            onPressed: onRecord,
            icon: const Icon(Icons.check_rounded, size: 18),
            label: const Text(
              'Catat Penjualan',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.positive,
              foregroundColor: Colors.white,
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Preset Card ──────────────────────────────────────────────────────────────

class _PresetCard extends StatelessWidget {
  const _PresetCard({
    required this.preset,
    required this.manageMode,
    required this.onEdit,
    required this.onDelete,
    required this.qty,
    this.onTap,
    this.onLongPress,
  });

  final QuickSalePreset preset;
  final bool manageMode;
  final int qty;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  bool get _inCart => qty > 0;

  @override
  Widget build(BuildContext context) {
    final borderColor = manageMode
        ? AppColors.brandBlue.withValues(alpha: 0.4)
        : _inCart
            ? AppColors.positive
            : context.appColors.outline;

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _inCart && !manageMode
              ? AppColors.positive.withValues(alpha: 0.06)
              : context.appColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: borderColor,
            width: _inCart && !manageMode ? 2 : 1,
          ),
          boxShadow: (manageMode || _inCart)
              ? []
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  preset.name,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 14),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const Spacer(),
                Text(
                  IdrFormatter.format(preset.price),
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: AppColors.positive,
                  ),
                ),
                if (preset.category.isNotEmpty)
                  Text(
                    preset.category,
                    style: TextStyle(
                      fontSize: 11,
                      color: context.appColors.textSecondary,
                    ),
                  ),
              ],
            ),

            // Manage mode: edit + delete buttons
            if (manageMode)
              Positioned(
                top: 0,
                right: 0,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: onEdit,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppColors.brandBlue.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(Icons.edit_outlined,
                            size: 14, color: AppColors.brandBlue),
                      ),
                    ),
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: onDelete,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppColors.negative.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(Icons.close,
                            size: 14, color: AppColors.negative),
                      ),
                    ),
                  ],
                ),
              ),

            // Cart qty badge
            if (!manageMode)
              Positioned(
                top: 0,
                right: 0,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: _inCart
                      ? _QtyBadge(qty: qty, key: ValueKey(qty))
                      : Container(
                          key: const ValueKey('icon'),
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: AppColors.positive.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(Icons.add,
                              size: 14, color: AppColors.positive),
                        ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _QtyBadge extends StatelessWidget {
  const _QtyBadge({required this.qty, super.key});

  final int qty;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 24),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.positive,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '$qty',
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

// ─── Empty State ──────────────────────────────────────────────────────────────

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
            Icon(Icons.point_of_sale,
                size: 56, color: context.appColors.textSecondary),
            const SizedBox(height: 16),
            Text(
              context.t('quickSale.emptyTitle'),
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              context.t('quickSale.emptySubtitle'),
              textAlign: TextAlign.center,
              style: TextStyle(color: context.appColors.textSecondary),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: Text(context.t('quickSale.add.button')),
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

// ─── Preset Form ──────────────────────────────────────────────────────────────

class _PresetForm extends StatefulWidget {
  const _PresetForm({this.existing});
  final QuickSalePreset? existing;

  @override
  State<_PresetForm> createState() => _PresetFormState();
}

class _PresetFormState extends State<_PresetForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _priceCtrl;
  late final TextEditingController _categoryCtrl;
  late final TextEditingController _noteCtrl;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _nameCtrl = TextEditingController(text: e?.name ?? '');
    _priceCtrl =
        TextEditingController(text: e?.price != null ? e!.price.toString() : '');
    _categoryCtrl = TextEditingController(text: e?.category ?? '');
    _noteCtrl = TextEditingController(text: e?.note ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _priceCtrl.dispose();
    _categoryCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final appState = context.appState;
    final priceRaw = _priceCtrl.text.replaceAll(RegExp(r'[^0-9]'), '');
    final price = int.tryParse(priceRaw) ?? 0;
    final nextOrder = appState.quickSalePresets.length;

    if (widget.existing == null) {
      appState.addQuickSalePreset(QuickSalePreset(
        id: const Uuid().v4(),
        name: _nameCtrl.text.trim(),
        price: price,
        category: _categoryCtrl.text.trim(),
        note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
        sortOrder: nextOrder,
      ));
    } else {
      appState.updateQuickSalePreset(widget.existing!.copyWith(
        name: _nameCtrl.text.trim(),
        price: price,
        category: _categoryCtrl.text.trim(),
        note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
      ));
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;

    // Saran kategori dari preset yang sudah ada
    final existingCategories = context.appState.quickSalePresets
        .map((p) => p.category)
        .where((c) => c.isNotEmpty)
        .toSet()
        .toList()
      ..sort();

    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.t(
                    isEdit ? 'quickSale.edit.title' : 'quickSale.add.title'),
                style:
                    const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameCtrl,
                decoration: InputDecoration(
                  labelText: context.t('quickSale.nameLabel'),
                  hintText: context.t('quickSale.nameHint'),
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? context.t('quickSale.nameRequired')
                    : null,
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _priceCtrl,
                decoration: InputDecoration(
                  labelText: context.t('quickSale.priceLabel'),
                  hintText: '0',
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [CurrencyInputFormatter()],
                validator: (v) {
                  final raw = (v ?? '').replaceAll(RegExp(r'[^0-9]'), '');
                  final val = int.tryParse(raw) ?? 0;
                  return val <= 0
                      ? context.t('quickSale.priceRequired')
                      : null;
                },
              ),
              const SizedBox(height: 12),
              // Kategori dengan saran chip
              TextFormField(
                controller: _categoryCtrl,
                decoration: InputDecoration(
                  labelText: context.t('quickSale.categoryLabel'),
                  hintText: context.t('quickSale.categoryHint'),
                ),
                textCapitalization: TextCapitalization.words,
              ),
              if (existingCategories.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  children: existingCategories.map((cat) {
                    return GestureDetector(
                      onTap: () =>
                          setState(() => _categoryCtrl.text = cat),
                      child: Chip(
                        label: Text(cat,
                            style: const TextStyle(fontSize: 11)),
                        padding: EdgeInsets.zero,
                        materialTapTargetSize:
                            MaterialTapTargetSize.shrinkWrap,
                      ),
                    );
                  }).toList(),
                ),
              ],
              const SizedBox(height: 12),
              TextFormField(
                controller: _noteCtrl,
                decoration: InputDecoration(
                  labelText: context.t('quickSale.noteLabel'),
                  hintText: context.t('quickSale.noteHint'),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.brandBlue,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(context.t('quickSale.save')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
