import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/formatters/idr_formatter.dart';
import '../../core/models/product_model.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dynamic_colors.dart';
import '../../core/ui/app_gradient_scaffold.dart';
import '../../shared/widgets/native_ad_card.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart' show TemplateType;
import 'batch_report_screen.dart';

class ProductionBatchScreen extends StatelessWidget {
  const ProductionBatchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.appState;
    final batches = appState.productionBatches;
    final products = appState.products;

    return AppGradientScaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Batch Produksi',
            style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          if (batches.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.bar_chart_rounded),
              tooltip: 'Laporan Profit',
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const BatchReportScreen()),
              ),
            ),
        ],
      ),
      body: batches.isEmpty
          ? _EmptyState(onRecord: () => _openForm(context))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: batches.length + 1,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                if (i == 0) {
                  return const NativeAdCard(templateType: TemplateType.small);
                }
                final b = batches[i - 1];
                final product = products.cast<ProductModel?>().firstWhere(
                      (p) => p?.id == b.productId,
                      orElse: () => null,
                    );
                return _BatchCard(
                  batch: b,
                  sellingPrice: product?.sellingPrice,
                  onDelete: () => appState.deleteProductionBatch(b.id),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(context),
        backgroundColor: AppColors.brandBlue,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Catat Produksi',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  void _openForm(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _BatchForm(
        onSave: (batch) => context.appState.recordProduction(batch),
      ),
    );
  }
}

// ─── Card ─────────────────────────────────────────────────────────────────────

class _BatchCard extends StatelessWidget {
  const _BatchCard({
    required this.batch,
    required this.onDelete,
    this.sellingPrice,
  });

  final ProductionBatch batch;
  final VoidCallback onDelete;
  final double? sellingPrice;

  double get _margin {
    final sp = sellingPrice ?? 0;
    if (sp <= 0) return 0;
    return ((sp - batch.costPerUnit) / sp) * 100;
  }

  Color get _marginColor {
    final m = _margin;
    if (sellingPrice == null || sellingPrice == 0) return Colors.grey;
    if (m >= 30) return AppColors.brandGreen;
    if (m >= 10) return const Color(0xFFF59E0B);
    return AppColors.negative;
  }

  @override
  Widget build(BuildContext context) {
    final hasSellingPrice = sellingPrice != null && sellingPrice! > 0;

    return Container(
      decoration: BoxDecoration(
        color: context.appColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.appColors.outline),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──────────────────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(batch.productName,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 2),
                    Text(
                      DateFormat('d MMM yyyy').format(batch.date),
                      style: TextStyle(
                          color: context.appColors.textSecondary, fontSize: 13),
                    ),
                  ],
                ),
              ),
              InkWell(
                onTap: onDelete,
                borderRadius: BorderRadius.circular(8),
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(Icons.delete_outline,
                      size: 18, color: AppColors.negative),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // ── Stats row ────────────────────────────────────────────────────
          Row(
            children: [
              _stat('Diproduksi', '${batch.qtyProduced.toInt()} unit'),
              const SizedBox(width: 16),
              _stat('Total Biaya',
                  IdrFormatter.format(batch.totalMaterialCost.round())),
              const SizedBox(width: 16),
              _stat('HPP/unit',
                  IdrFormatter.format(batch.costPerUnit.round())),
            ],
          ),

          // ── Margin row (hanya jika produk punya harga jual) ──────────────
          if (hasSellingPrice) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: _marginColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _marginColor.withValues(alpha: 0.25)),
              ),
              child: Row(
                children: [
                  Icon(
                    _margin >= 30
                        ? Icons.trending_up_rounded
                        : _margin >= 10
                            ? Icons.trending_flat_rounded
                            : Icons.trending_down_rounded,
                    size: 16,
                    color: _marginColor,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Harga jual ${IdrFormatter.format(sellingPrice!.round())}',
                    style: TextStyle(
                        fontSize: 12, color: context.appColors.textSecondary),
                  ),
                  const Spacer(),
                  Text(
                    'Margin ${_margin.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: _marginColor,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '(${IdrFormatter.format((sellingPrice! - batch.costPerUnit).round())}/unit)',
                    style: TextStyle(
                        fontSize: 11, color: context.appColors.textSecondary),
                  ),
                ],
              ),
            ),
          ],

          // ── Material breakdown ───────────────────────────────────────────
          if (batch.materialsUsed.isNotEmpty) ...[
            const SizedBox(height: 10),
            const Divider(height: 1),
            const SizedBox(height: 8),
            ...batch.materialsUsed.map((m) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      Icon(Icons.circle,
                          size: 6, color: context.appColors.textSecondary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${m.rawMaterialName}: ${m.quantity % 1 == 0 ? m.quantity.toInt() : m.quantity} ${m.unit}',
                          style: TextStyle(
                              color: context.appColors.textSecondary,
                              fontSize: 13),
                        ),
                      ),
                      Text(
                        IdrFormatter.format(m.totalCost.round()),
                        style: TextStyle(
                            color: context.appColors.textSecondary,
                            fontSize: 13),
                      ),
                    ],
                  ),
                )),
          ],
          if (batch.notes != null && batch.notes!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text('📝 ${batch.notes}',
                style: TextStyle(
                    color: context.appColors.textSecondary, fontSize: 12)),
          ],
        ],
      ),
    );
  }

  Widget _stat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
        Text(value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
      ],
    );
  }
}

// ─── Form ─────────────────────────────────────────────────────────────────────

class _BatchForm extends StatefulWidget {
  const _BatchForm({required this.onSave});
  final Future<void> Function(ProductionBatch batch) onSave;

  @override
  State<_BatchForm> createState() => _BatchFormState();
}

class _BatchFormState extends State<_BatchForm> {
  ProductModel? _selectedProduct;
  final _qtyController = TextEditingController();
  final _notesController = TextEditingController();
  DateTime _date = DateTime.now();
  final List<_MaterialEntry> _entries = [];

  @override
  void dispose() {
    _qtyController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  // ── Live HPP preview ──────────────────────────────────────────────────────

  double get _totalCost =>
      _entries.fold(0.0, (sum, e) {
        if (e.rawMaterial == null || e.qty <= 0) return sum;
        return sum + e.qty * e.rawMaterial!.costPerUnit;
      });

  double get _liveHpp {
    final qty = double.tryParse(_qtyController.text) ?? 0;
    if (qty <= 0 || _totalCost <= 0) return 0;
    return _totalCost / qty;
  }

  // ── Auto-populate materials from product recipe ───────────────────────────

  void _onProductSelected(ProductModel? product) {
    if (product == null) {
      setState(() {
        _selectedProduct = null;
        _entries.clear();
      });
      return;
    }

    final rawMaterials = context.appState.rawMaterials;
    final autoEntries = <_MaterialEntry>[];

    for (final ing in product.ingredients) {
      if (ing.rawMaterialId == null) continue;
      final mat = rawMaterials.cast<RawMaterial?>().firstWhere(
            (m) => m?.id == ing.rawMaterialId,
            orElse: () => null,
          );
      if (mat == null) continue;
      autoEntries.add(_MaterialEntry()
        ..rawMaterial = mat
        ..qty = ing.quantity);
    }

    setState(() {
      _selectedProduct = product;
      // Pre-fill dari resep, sisakan entry manual kosong jika tidak ada link
      _entries
        ..clear()
        ..addAll(autoEntries);
      if (_entries.isEmpty) _entries.add(_MaterialEntry());
    });
  }

  // ── Submit ────────────────────────────────────────────────────────────────

  Future<void> _submit() async {
    if (_selectedProduct == null) return;
    final qty = double.tryParse(_qtyController.text) ?? 0;
    if (qty <= 0) return;

    final materials = _entries
        .where((e) => e.rawMaterial != null && e.qty > 0)
        .map((e) => BatchMaterial(
              rawMaterialId: e.rawMaterial!.id,
              rawMaterialName: e.rawMaterial!.name,
              quantity: e.qty,
              unit: e.rawMaterial!.unit,
              costPerUnit: e.rawMaterial!.costPerUnit,
            ))
        .toList();

    if (materials.isEmpty) return;

    final batch = ProductionBatch.create(
      productId: _selectedProduct!.id,
      productName: _selectedProduct!.name,
      date: _date,
      qtyProduced: qty,
      materialsUsed: materials,
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
    );
    await widget.onSave(batch);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final products = context.appState.products;
    final rawMaterials = context.appState.rawMaterials;
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(20, 20, 20, bottom + 24),
      constraints:
          BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.92),
      decoration: const BoxDecoration(
        color: Color(0xFF0D1F16),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Catat Batch Produksi',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white)),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Produk ─────────────────────────────────────────────
                  _label('Produk'),
                  const SizedBox(height: 6),
                  _dropdown<ProductModel>(
                    value: _selectedProduct,
                    hint: 'Pilih produk...',
                    items: products,
                    itemLabel: (p) => p.name,
                    onChanged: _onProductSelected,
                  ),
                  const SizedBox(height: 16),

                  // ── Tanggal ────────────────────────────────────────────
                  _label('Tanggal Produksi'),
                  const SizedBox(height: 6),
                  GestureDetector(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _date,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) setState(() => _date = picked);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A2C22),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today,
                              size: 16, color: Colors.white54),
                          const SizedBox(width: 8),
                          Text(
                            DateFormat('d MMMM yyyy').format(_date),
                            style: const TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Jumlah produksi ────────────────────────────────────
                  _label('Jumlah Diproduksi (unit)'),
                  const SizedBox(height: 6),
                  _textField(
                    _qtyController,
                    hint: '0',
                    isNumber: true,
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 20),

                  // ── Bahan baku ─────────────────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _label('Bahan Baku Digunakan'),
                      TextButton.icon(
                        onPressed: () =>
                            setState(() => _entries.add(_MaterialEntry())),
                        icon: const Icon(Icons.add,
                            size: 16, color: AppColors.brandGreen),
                        label: const Text('Tambah',
                            style: TextStyle(
                                color: AppColors.brandGreen, fontSize: 13)),
                      ),
                    ],
                  ),
                  if (rawMaterials.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 8),
                      child: Text(
                          '⚠ Belum ada bahan baku. Tambah di menu Bahan Baku.',
                          style:
                              TextStyle(color: Colors.amber, fontSize: 12)),
                    ),
                  if (_selectedProduct != null &&
                      _selectedProduct!.ingredients
                          .any((i) => i.rawMaterialId != null) &&
                      _entries.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          const Icon(Icons.auto_fix_high_rounded,
                              size: 13, color: AppColors.brandGreen),
                          const SizedBox(width: 4),
                          Text(
                            'Auto-isi dari resep ${_selectedProduct!.name}',
                            style: const TextStyle(
                                color: AppColors.brandGreen, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ..._entries.asMap().entries.map((entry) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _MaterialEntryRow(
                          entry: entry.value,
                          rawMaterials: rawMaterials,
                          onChanged: () => setState(() {}),
                          onRemove: () =>
                              setState(() => _entries.removeAt(entry.key)),
                        ),
                      )),

                  // ── Live HPP preview ───────────────────────────────────
                  if (_liveHpp > 0 || _totalCost > 0) ...[
                    const SizedBox(height: 4),
                    _LiveHppPreview(
                      totalCost: _totalCost,
                      hpp: _liveHpp,
                      sellingPrice: _selectedProduct?.sellingPrice,
                    ),
                  ],

                  const SizedBox(height: 16),

                  // ── Catatan ────────────────────────────────────────────
                  _label('Catatan (opsional)'),
                  const SizedBox(height: 6),
                  _textField(_notesController,
                      hint: 'Misal: batch ke-3 bulan ini', maxLines: 2),
                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.brandGreen,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text('Catat Produksi',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _label(String text) => Text(text,
      style: const TextStyle(
          color: Colors.white70, fontSize: 12, letterSpacing: 0.5));

  Widget _textField(
    TextEditingController ctrl, {
    String hint = '',
    bool isNumber = false,
    int maxLines = 1,
    ValueChanged<String>? onChanged,
  }) {
    return TextField(
      controller: ctrl,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white),
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white38),
        filled: true,
        fillColor: const Color(0xFF1A2C22),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Colors.white12)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Colors.white12)),
      ),
    );
  }

  Widget _dropdown<T>({
    required T? value,
    required String hint,
    required List<T> items,
    required String Function(T) itemLabel,
    required void Function(T?) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2C22),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          hint: Text(hint, style: const TextStyle(color: Colors.white54)),
          dropdownColor: const Color(0xFF1A2C22),
          isExpanded: true,
          style: const TextStyle(color: Colors.white),
          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white54),
          items: items
              .map((item) => DropdownMenuItem<T>(
                    value: item,
                    child: Text(itemLabel(item),
                        overflow: TextOverflow.ellipsis),
                  ))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

// ─── Live HPP preview ─────────────────────────────────────────────────────────

class _LiveHppPreview extends StatelessWidget {
  const _LiveHppPreview({
    required this.totalCost,
    required this.hpp,
    this.sellingPrice,
  });

  final double totalCost;
  final double hpp;
  final double? sellingPrice;

  @override
  Widget build(BuildContext context) {
    final hasHpp = hpp > 0;
    final sp = sellingPrice ?? 0;
    final margin = (hasHpp && sp > 0) ? ((sp - hpp) / sp * 100) : null;
    final marginColor = margin == null
        ? Colors.white54
        : margin >= 30
            ? AppColors.brandGreen
            : margin >= 10
                ? const Color(0xFFF59E0B)
                : AppColors.negative;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.brandGreen.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.brandGreen.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total biaya bahan',
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6), fontSize: 12)),
              Text(IdrFormatter.format(totalCost.round()),
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13)),
            ],
          ),
          if (hasHpp) ...[
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('HPP/unit',
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 12)),
                Text(IdrFormatter.format(hpp.round()),
                    style: const TextStyle(
                        color: AppColors.brandGreen,
                        fontWeight: FontWeight.w800,
                        fontSize: 15)),
              ],
            ),
            if (margin != null) ...[
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Margin vs harga jual',
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontSize: 12)),
                  Text(
                    '${margin.toStringAsFixed(1)}%',
                    style: TextStyle(
                        color: marginColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 13),
                  ),
                ],
              ),
            ],
          ],
        ],
      ),
    );
  }
}

// ─── Material entry row ───────────────────────────────────────────────────────

class _MaterialEntry {
  RawMaterial? rawMaterial;
  double qty = 0;
}

class _MaterialEntryRow extends StatelessWidget {
  const _MaterialEntryRow({
    required this.entry,
    required this.rawMaterials,
    required this.onChanged,
    required this.onRemove,
  });

  final _MaterialEntry entry;
  final List<RawMaterial> rawMaterials;
  final VoidCallback onChanged;
  final VoidCallback onRemove;

  bool get _stockWarning {
    if (entry.rawMaterial == null || entry.qty <= 0) return false;
    return entry.qty > entry.rawMaterial!.currentStock;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              flex: 3,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A2C22),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: _stockWarning
                        ? AppColors.negative.withValues(alpha: 0.5)
                        : Colors.white12,
                  ),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<RawMaterial>(
                    value: entry.rawMaterial,
                    hint: const Text('Pilih bahan',
                        style:
                            TextStyle(color: Colors.white54, fontSize: 13)),
                    dropdownColor: const Color(0xFF1A2C22),
                    isExpanded: true,
                    style:
                        const TextStyle(color: Colors.white, fontSize: 13),
                    icon: const Icon(Icons.keyboard_arrow_down,
                        color: Colors.white54, size: 16),
                    items: rawMaterials
                        .map((m) => DropdownMenuItem<RawMaterial>(
                              value: m,
                              child: Text('${m.name} (${m.unit})',
                                  overflow: TextOverflow.ellipsis),
                            ))
                        .toList(),
                    onChanged: (v) {
                      entry.rawMaterial = v;
                      onChanged();
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 2,
              child: TextField(
                keyboardType: TextInputType.number,
                controller: TextEditingController(
                    text: entry.qty > 0 ? entry.qty.toString() : ''),
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Qty',
                  hintStyle: const TextStyle(color: Colors.white38),
                  filled: true,
                  fillColor: const Color(0xFF1A2C22),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 12),
                  border: OutlineInputBorder(
                      borderRadius:
                          const BorderRadius.all(Radius.circular(10)),
                      borderSide: BorderSide(
                        color: _stockWarning
                            ? AppColors.negative.withValues(alpha: 0.5)
                            : Colors.white12,
                      )),
                  enabledBorder: OutlineInputBorder(
                      borderRadius:
                          const BorderRadius.all(Radius.circular(10)),
                      borderSide: BorderSide(
                        color: _stockWarning
                            ? AppColors.negative.withValues(alpha: 0.5)
                            : Colors.white12,
                      )),
                ),
                onChanged: (v) {
                  entry.qty = double.tryParse(v) ?? 0;
                  onChanged();
                },
              ),
            ),
            const SizedBox(width: 4),
            IconButton(
              onPressed: onRemove,
              icon: const Icon(Icons.remove_circle_outline,
                  color: AppColors.negative, size: 20),
              constraints: const BoxConstraints(),
              padding: const EdgeInsets.all(4),
            ),
          ],
        ),
        // ── Stock warning ──────────────────────────────────────────────
        if (_stockWarning)
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 4),
            child: Row(
              children: [
                const Icon(Icons.warning_amber_rounded,
                    size: 12, color: AppColors.negative),
                const SizedBox(width: 4),
                Text(
                  'Stok ${entry.rawMaterial!.name}: ${entry.rawMaterial!.currentStock % 1 == 0 ? entry.rawMaterial!.currentStock.toInt() : entry.rawMaterial!.currentStock} ${entry.rawMaterial!.unit}',
                  style: const TextStyle(
                      color: AppColors.negative, fontSize: 11),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

// ─── Empty state ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onRecord});
  final VoidCallback onRecord;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.precision_manufacturing_outlined,
              size: 64, color: context.appColors.textSecondary),
          const SizedBox(height: 16),
          const Text('Belum ada batch produksi',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 8),
          Text(
            'Catat setiap kali kamu produksi untuk\ntahu HPP aktual per batch',
            textAlign: TextAlign.center,
            style: TextStyle(color: context.appColors.textSecondary),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onRecord,
            icon: const Icon(Icons.add),
            label: const Text('Catat Produksi'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.brandBlue,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
