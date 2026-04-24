import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../core/formatters/currency_input_formatter.dart';
import '../../core/formatters/idr_formatter.dart';
import '../../core/localization/transalation_extansions.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dynamic_colors.dart';

// Set true saat sudah adopsi POS + payment gateway
const bool _kEnableWalletSelector = false;

class QuickSaleScreen extends StatefulWidget {
  const QuickSaleScreen({super.key});

  @override
  State<QuickSaleScreen> createState() => _QuickSaleScreenState();
}

class _QuickSaleScreenState extends State<QuickSaleScreen> {
  bool _manageMode = false;

  @override
  Widget build(BuildContext context) {
    final appState = context.appState;
    final presets = appState.quickSalePresets;

    return Scaffold(
      appBar: AppBar(
        title: Text(context.t('quickSale.title')),
        actions: [
          IconButton(
            icon: Icon(_manageMode ? Icons.check : Icons.edit_outlined),
            tooltip: _manageMode
                ? context.t('quickSale.doneManage')
                : context.t('quickSale.manage'),
            onPressed: () => setState(() => _manageMode = !_manageMode),
          ),
          if (_manageMode)
            IconButton(
              icon: const Icon(Icons.add),
              tooltip: context.t('quickSale.add.button'),
              onPressed: () => _showForm(context, null),
            ),
        ],
      ),
      body: presets.isEmpty
          ? _EmptyState(onAdd: () => _showForm(context, null))
          : Column(
              children: [
                if (!_manageMode)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                    child: Text(
                      context.t('quickSale.tapHint'),
                      style: TextStyle(
                        color: context.appColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ),
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.4,
                    ),
                    itemCount: presets.length,
                    itemBuilder: (context, i) => _PresetCard(
                      preset: presets[i],
                      manageMode: _manageMode,
                      onTap: _manageMode
                          ? null
                          : () => _confirmSale(context, presets[i]),
                      onEdit: () => _showForm(context, presets[i]),
                      onDelete: () => _confirmDelete(context, presets[i]),
                    ),
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

  void _confirmSale(BuildContext context, QuickSalePreset preset) {
    showDialog(
      context: context,
      builder: (ctx) => _SaleConfirmDialog(preset: preset),
    );
  }

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
        content: Text(context.t('quickSale.delete.content',
            {'name': preset.name})),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(context.t('common.cancel')),
          ),
          TextButton(
            onPressed: () {
              context.appState.deleteQuickSalePreset(preset.id);
              Navigator.pop(ctx);
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.negative),
            child: Text(context.t('quickSale.delete.confirm')),
          ),
        ],
      ),
    );
  }
}

// ─── Sale Confirm Dialog ───────────────────────────────────────────────────────
class _SaleConfirmDialog extends StatefulWidget {
  const _SaleConfirmDialog({required this.preset});
  final QuickSalePreset preset;

  @override
  State<_SaleConfirmDialog> createState() => _SaleConfirmDialogState();
}

class _SaleConfirmDialogState extends State<_SaleConfirmDialog> {
  int _qty = 1;
  String? _walletId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_walletId == null) {
      final presetWallet = widget.preset.walletId;
      if (presetWallet != null) {
        _walletId = presetWallet;
      } else {
        final wallets = context.appState.wallets;
        if (wallets.isNotEmpty) {
          final def = wallets.where((w) => w.isDefault).firstOrNull;
          _walletId = def?.id ?? wallets.first.id;
        }
      }
    }
  }

  void _record() {
    final appState = context.appState;
    final total = widget.preset.price * _qty;
    final walletId = _walletId;
    appState.addIncome(
      amount: total,
      category: widget.preset.category,
      note: widget.preset.note != null && widget.preset.note!.isNotEmpty
          ? '${widget.preset.name} x$_qty${widget.preset.note!.isNotEmpty ? ' — ${widget.preset.note}' : ''}'
          : '${widget.preset.name} x$_qty',
      effectiveDate: DateTime.now(),
      walletId: walletId,
      outletId: widget.preset.outletId,
    );
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.t('quickSale.recorded',
            {'name': widget.preset.name, 'amount': IdrFormatter.format(total)})),
        backgroundColor: AppColors.positive,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final wallets = context.appState.wallets;
    final total = widget.preset.price * _qty;

    return AlertDialog(
      title: Text(widget.preset.name),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            IdrFormatter.format(widget.preset.price),
            style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 20,
                color: AppColors.positive),
          ),
          if (widget.preset.note != null && widget.preset.note!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              widget.preset.note!,
              style: TextStyle(
                  color: context.appColors.textSecondary, fontSize: 13),
            ),
          ],
          const SizedBox(height: 16),
          // Qty selector
          Row(
            children: [
              Text(context.t('quickSale.qty'),
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              const Spacer(),
              IconButton(
                onPressed: _qty > 1 ? () => setState(() => _qty--) : null,
                icon: const Icon(Icons.remove_circle_outline),
                color: AppColors.negative,
              ),
              Text(
                '$_qty',
                style: const TextStyle(
                    fontWeight: FontWeight.w800, fontSize: 18),
              ),
              IconButton(
                onPressed: () => setState(() => _qty++),
                icon: const Icon(Icons.add_circle_outline),
                color: AppColors.positive,
              ),
            ],
          ),
          // Total
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            decoration: BoxDecoration(
              color: AppColors.positive.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              context.t('quickSale.total',
                  {'amount': IdrFormatter.format(total)}),
              style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  color: AppColors.positive),
              textAlign: TextAlign.center,
            ),
          ),
          // Wallet selector — aktifkan _kEnableWalletSelector saat adopsi POS
          if (_kEnableWalletSelector && wallets.isNotEmpty) ...[
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _walletId,
              decoration: InputDecoration(
                labelText: context.t('wallet.selector'),
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: wallets
                  .map((w) => DropdownMenuItem(
                        value: w.id,
                        child: Text(w.name),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _walletId = v),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(context.t('common.cancel')),
        ),
        ElevatedButton(
          onPressed: _record,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.positive,
            foregroundColor: Colors.white,
          ),
          child: Text(context.t('quickSale.record')),
        ),
      ],
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
    this.onTap,
  });

  final QuickSalePreset preset;
  final bool manageMode;
  final VoidCallback? onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: context.appColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: manageMode
                ? AppColors.brandBlue.withValues(alpha: 0.4)
                : context.appColors.outline,
          ),
          boxShadow: manageMode
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
            if (!manageMode)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.positive.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(Icons.point_of_sale,
                      size: 14, color: AppColors.positive),
                ),
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
            Icon(Icons.point_of_sale,
                size: 56, color: context.appColors.textSecondary),
            const SizedBox(height: 16),
            Text(
              context.t('quickSale.emptyTitle'),
              style: const TextStyle(
                  fontWeight: FontWeight.w700, fontSize: 16),
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
  String? _walletId;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _nameCtrl = TextEditingController(text: e?.name ?? '');
    _priceCtrl = TextEditingController(
        text: e?.price != null ? e!.price.toString() : '');
    _categoryCtrl =
        TextEditingController(text: e?.category ?? '');
    _noteCtrl = TextEditingController(text: e?.note ?? '');
    _walletId = e?.walletId;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_walletId == null && widget.existing == null) {
      final wallets = context.appState.wallets;
      if (wallets.isNotEmpty) {
        final def = wallets.where((w) => w.isDefault).firstOrNull;
        _walletId = def?.id ?? wallets.first.id;
      }
    }
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
        walletId: _walletId,
        sortOrder: nextOrder,
      ));
    } else {
      appState.updateQuickSalePreset(widget.existing!.copyWith(
        name: _nameCtrl.text.trim(),
        price: price,
        category: _categoryCtrl.text.trim(),
        note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
        walletId: _walletId,
      ));
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    final wallets = context.appState.wallets;

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
                    ? 'quickSale.edit.title'
                    : 'quickSale.add.title'),
                style: const TextStyle(
                    fontWeight: FontWeight.w800, fontSize: 16),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameCtrl,
                decoration: InputDecoration(
                  labelText: context.t('quickSale.nameLabel'),
                  hintText: context.t('quickSale.nameHint'),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty)
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
                  return val <= 0 ? context.t('quickSale.priceRequired') : null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _categoryCtrl,
                decoration: InputDecoration(
                  labelText: context.t('quickSale.categoryLabel'),
                  hintText: context.t('quickSale.categoryHint'),
                ),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _noteCtrl,
                decoration: InputDecoration(
                  labelText: context.t('quickSale.noteLabel'),
                  hintText: context.t('quickSale.noteHint'),
                ),
              ),
              if (_kEnableWalletSelector && wallets.isNotEmpty) ...[
                const SizedBox(height: 12),
                DropdownButtonFormField<String?>(
                  initialValue: _walletId,
                  decoration: InputDecoration(
                    labelText: context.t('wallet.selector'),
                  ),
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
