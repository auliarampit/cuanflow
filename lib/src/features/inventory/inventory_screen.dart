import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';

import '../../core/formatters/currency_input_formatter.dart';
import '../../core/formatters/idr_formatter.dart';
import '../../core/localization/transalation_extansions.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dynamic_colors.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final appState = context.appState;
    final all = appState.inventoryItems;
    final lowStock = appState.lowStockItems;

    final filtered = _search.isEmpty
        ? all
        : all
            .where((i) =>
                i.name.toLowerCase().contains(_search.toLowerCase()) ||
                (i.category?.toLowerCase().contains(_search.toLowerCase()) ??
                    false))
            .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(context.t('inventory.title')),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: context.t('inventory.add.button'),
            onPressed: () => _showForm(context, null),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: TextField(
              decoration: InputDecoration(
                hintText: context.t('inventory.search'),
                prefixIcon: const Icon(Icons.search, size: 20),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: context.appColors.outline),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: context.appColors.outline),
                ),
              ),
              onChanged: (v) => setState(() => _search = v),
            ),
          ),

          // Low stock banner
          if (lowStock.isNotEmpty && _search.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: Colors.orange.withValues(alpha: 0.4)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded,
                        color: Colors.orange, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        context.t('inventory.lowStockWarning',
                            {'count': '${lowStock.length}'}),
                        style: const TextStyle(
                            color: Colors.orange,
                            fontSize: 13,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 8),

          Expanded(
            child: filtered.isEmpty
                ? _EmptyState(onAdd: () => _showForm(context, null))
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
                    itemCount: filtered.length,
                    separatorBuilder: (context, i) => const SizedBox(height: 10),
                    itemBuilder: (context, i) => _InventoryCard(
                      item: filtered[i],
                      onEdit: () => _showForm(context, filtered[i]),
                      onDelete: () => _confirmDelete(context, filtered[i]),
                      onAdjust: (delta) =>
                          appState.adjustStock(filtered[i].id, delta),
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: filtered.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: () => _showForm(context, null),
              icon: const Icon(Icons.add),
              label: Text(context.t('inventory.add.button')),
              backgroundColor: AppColors.brandBlue,
              foregroundColor: Colors.white,
            )
          : null,
    );
  }

  void _showForm(BuildContext context, InventoryItem? existing) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.appColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _InventoryForm(existing: existing),
    );
  }

  void _confirmDelete(BuildContext context, InventoryItem item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.t('inventory.delete.title')),
        content: Text(context.t('inventory.delete.content',
            {'name': item.name})),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(context.t('common.cancel')),
          ),
          TextButton(
            onPressed: () {
              context.appState.deleteInventoryItem(item.id);
              Navigator.pop(ctx);
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.negative),
            child: Text(context.t('inventory.delete.confirm')),
          ),
        ],
      ),
    );
  }
}

// ─── Inventory Card ──────────────────────────────────────────────────────────
class _InventoryCard extends StatelessWidget {
  const _InventoryCard({
    required this.item,
    required this.onEdit,
    required this.onDelete,
    required this.onAdjust,
  });

  final InventoryItem item;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final void Function(double delta) onAdjust;

  @override
  Widget build(BuildContext context) {
    final Color statusColor;
    final String statusLabel;
    if (item.isOutOfStock) {
      statusColor = AppColors.negative;
      statusLabel = context.t('inventory.status.outOfStock');
    } else if (item.isLowStock) {
      statusColor = Colors.orange;
      statusLabel = context.t('inventory.status.lowStock');
    } else {
      statusColor = AppColors.positive;
      statusLabel = context.t('inventory.status.ok');
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.appColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: item.isOutOfStock || item.isLowStock
              ? statusColor.withValues(alpha: 0.4)
              : context.appColors.outline,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 15),
                    ),
                    if (item.category != null && item.category!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        item.category!,
                        style: TextStyle(
                          fontSize: 12,
                          color: context.appColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: statusColor,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              PopupMenuButton<String>(
                onSelected: (v) {
                  if (v == 'edit') onEdit();
                  if (v == 'delete') onDelete();
                },
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: 'edit',
                    child: Text(context.t('history.menu.edit')),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Text(context.t('history.menu.delete')),
                  ),
                ],
                child: const Icon(Icons.more_vert, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              // Stock info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.t('inventory.stockLabel'),
                      style: TextStyle(
                          fontSize: 11,
                          color: context.appColors.textSecondary),
                    ),
                    Text(
                      '${item.currentStock % 1 == 0 ? item.currentStock.toInt() : item.currentStock} ${item.unit}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: statusColor,
                      ),
                    ),
                    if (item.minStock > 0)
                      Text(
                        context.t('inventory.minStockLabel',
                            {'min': '${item.minStock.toInt()}'}),
                        style: TextStyle(
                          fontSize: 11,
                          color: context.appColors.textSecondary,
                        ),
                      ),
                  ],
                ),
              ),
              // Price info
              if (item.sellPrice != null || item.costPrice != null)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (item.sellPrice != null)
                        Text(
                          IdrFormatter.format(item.sellPrice!),
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 13),
                        ),
                      if (item.costPrice != null)
                        Text(
                          'HPP: ${IdrFormatter.format(item.costPrice!)}',
                          style: TextStyle(
                            fontSize: 11,
                            color: context.appColors.textSecondary,
                          ),
                        ),
                      if (item.marginPct != null)
                        Container(
                          margin: const EdgeInsets.only(top: 3),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.positive.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Margin ${item.marginPct}%',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppColors.positive,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          // +/- buttons
          Row(
            children: [
              _AdjustButton(
                label: '-1',
                icon: Icons.remove,
                color: AppColors.negative,
                onTap: () => onAdjust(-1),
              ),
              const SizedBox(width: 8),
              _AdjustButton(
                label: '+1',
                icon: Icons.add,
                color: AppColors.positive,
                onTap: () => onAdjust(1),
              ),
              const SizedBox(width: 8),
              _AdjustButton(
                label: '+10',
                icon: Icons.add,
                color: AppColors.brandBlue,
                onTap: () => onAdjust(10),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AdjustButton extends StatelessWidget {
  const _AdjustButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 2),
            Text(
              label,
              style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w700, color: color),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Empty State ─────────────────────────────────────────────────────────────
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
            Icon(Icons.inventory_2_outlined,
                size: 56, color: context.appColors.textSecondary),
            const SizedBox(height: 16),
            Text(
              context.t('inventory.emptyTitle'),
              style: const TextStyle(
                  fontWeight: FontWeight.w700, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              context.t('inventory.emptySubtitle'),
              textAlign: TextAlign.center,
              style: TextStyle(color: context.appColors.textSecondary),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: Text(context.t('inventory.add.button')),
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

// ─── Inventory Form ───────────────────────────────────────────────────────────
class _InventoryForm extends StatefulWidget {
  const _InventoryForm({this.existing});
  final InventoryItem? existing;

  @override
  State<_InventoryForm> createState() => _InventoryFormState();
}

class _InventoryFormState extends State<_InventoryForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _unitCtrl;
  late final TextEditingController _stockCtrl;
  late final TextEditingController _minStockCtrl;
  late final TextEditingController _costCtrl;
  late final TextEditingController _sellCtrl;
  late final TextEditingController _categoryCtrl;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _nameCtrl = TextEditingController(text: e?.name ?? '');
    _unitCtrl = TextEditingController(text: e?.unit ?? 'pcs');
    _stockCtrl = TextEditingController(
        text: e == null
            ? '0'
            : (e.currentStock % 1 == 0
                ? e.currentStock.toInt().toString()
                : e.currentStock.toString()));
    _minStockCtrl = TextEditingController(
        text: e == null ? '0' : e.minStock.toInt().toString());
    _costCtrl = TextEditingController(
        text: e?.costPrice != null ? e!.costPrice.toString() : '');
    _sellCtrl = TextEditingController(
        text: e?.sellPrice != null ? e!.sellPrice.toString() : '');
    _categoryCtrl = TextEditingController(text: e?.category ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _unitCtrl.dispose();
    _stockCtrl.dispose();
    _minStockCtrl.dispose();
    _costCtrl.dispose();
    _sellCtrl.dispose();
    _categoryCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final appState = context.appState;
    final stock = double.tryParse(_stockCtrl.text) ?? 0;
    final minStock = double.tryParse(_minStockCtrl.text) ?? 0;
    final costRaw = _costCtrl.text.replaceAll(RegExp(r'[^0-9]'), '');
    final sellRaw = _sellCtrl.text.replaceAll(RegExp(r'[^0-9]'), '');
    final costPrice = costRaw.isEmpty ? null : int.tryParse(costRaw);
    final sellPrice = sellRaw.isEmpty ? null : int.tryParse(sellRaw);

    if (widget.existing == null) {
      appState.addInventoryItem(InventoryItem(
        id: const Uuid().v4(),
        name: _nameCtrl.text.trim(),
        unit: _unitCtrl.text.trim().isEmpty ? 'pcs' : _unitCtrl.text.trim(),
        currentStock: stock,
        minStock: minStock,
        costPrice: costPrice,
        sellPrice: sellPrice,
        category: _categoryCtrl.text.trim().isEmpty
            ? null
            : _categoryCtrl.text.trim(),
        createdAt: DateTime.now(),
      ));
    } else {
      appState.updateInventoryItem(widget.existing!.copyWith(
        name: _nameCtrl.text.trim(),
        unit: _unitCtrl.text.trim().isEmpty ? 'pcs' : _unitCtrl.text.trim(),
        currentStock: stock,
        minStock: minStock,
        costPrice: costPrice,
        sellPrice: sellPrice,
        category: _categoryCtrl.text.trim().isEmpty
            ? null
            : _categoryCtrl.text.trim(),
        clearCostPrice: costPrice == null,
        clearSellPrice: sellPrice == null,
      ));
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
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
                context.t(isEdit
                    ? 'inventory.edit.title'
                    : 'inventory.add.title'),
                style:
                    const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameCtrl,
                decoration: InputDecoration(
                  labelText: context.t('inventory.nameLabel'),
                  hintText: context.t('inventory.nameHint'),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? context.t('inventory.nameRequired') : null,
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _stockCtrl,
                      decoration: InputDecoration(
                          labelText: context.t('inventory.stockLabel')),
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                            RegExp(r'^\d+\.?\d{0,2}'))
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _unitCtrl,
                      decoration: InputDecoration(
                          labelText: context.t('inventory.unitLabel')),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _minStockCtrl,
                decoration: InputDecoration(
                    labelText: context.t('inventory.minStockFormLabel'),
                    hintText: '0'),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _costCtrl,
                      decoration: InputDecoration(
                          labelText: context.t('inventory.costPriceLabel'),
                          hintText: '0'),
                      keyboardType: TextInputType.number,
                      inputFormatters: [CurrencyInputFormatter()],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _sellCtrl,
                      decoration: InputDecoration(
                          labelText: context.t('inventory.sellPriceLabel'),
                          hintText: '0'),
                      keyboardType: TextInputType.number,
                      inputFormatters: [CurrencyInputFormatter()],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _categoryCtrl,
                decoration: InputDecoration(
                  labelText: context.t('inventory.categoryLabel'),
                  hintText: context.t('inventory.categoryHint'),
                ),
                textCapitalization: TextCapitalization.words,
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
                  child: Text(context.t('inventory.save')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
