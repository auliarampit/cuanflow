import 'package:flutter/material.dart';
import '../../core/formatters/idr_formatter.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dynamic_colors.dart';
import '../../core/ui/app_gradient_scaffold.dart';

class RawMaterialScreen extends StatefulWidget {
  const RawMaterialScreen({super.key});

  @override
  State<RawMaterialScreen> createState() => _RawMaterialScreenState();
}

class _RawMaterialScreenState extends State<RawMaterialScreen> {
  String _searchQuery = '';
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final all = context.appState.rawMaterials;
    final items = _searchQuery.isEmpty
        ? all
        : all
            .where((m) =>
                m.name.toLowerCase().contains(_searchQuery.toLowerCase()))
            .toList();

    return AppGradientScaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Bahan Baku',
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _searchQuery = v),
              decoration: InputDecoration(
                hintText: 'Cari bahan baku...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: context.appColors.cardSoft,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: items.isEmpty
                ? _EmptyState(onAdd: () => _openForm(context))
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: items.length,
                    separatorBuilder: (context, i) =>
                        const SizedBox(height: 10),
                    itemBuilder: (context, i) => _MaterialCard(
                      item: items[i],
                      onAdjust: (delta) => context.appState
                          .adjustRawMaterialStock(items[i].id, delta),
                      onEdit: () => _openForm(context, item: items[i]),
                      onDelete: () =>
                          context.appState.deleteRawMaterial(items[i].id),
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openForm(context),
        backgroundColor: AppColors.brandBlue,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  void _openForm(BuildContext context, {RawMaterial? item}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _RawMaterialForm(
        item: item,
        onSave: (result) async {
          if (item == null) {
            await context.appState.addRawMaterial(result);
          } else {
            await context.appState.updateRawMaterial(result);
          }
        },
      ),
    );
  }
}

// ─── Card ─────────────────────────────────────────────────────────────────────

class _MaterialCard extends StatelessWidget {
  const _MaterialCard({
    required this.item,
    required this.onAdjust,
    required this.onEdit,
    required this.onDelete,
  });

  final RawMaterial item;
  final void Function(double delta) onAdjust;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  Color _borderColor() {
    if (item.isOutOfStock) return AppColors.negative;
    if (item.isLowStock) return const Color(0xFFF59E0B);
    return AppColors.brandGreen;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.appColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _borderColor(), width: 1.5),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.name,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 2),
                    Text(
                      '${IdrFormatter.format(item.costPerUnit.round())} / ${item.unit}',
                      style: TextStyle(
                          color: context.appColors.textSecondary, fontSize: 13),
                    ),
                    if (item.supplierName != null &&
                        item.supplierName!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Supplier: ${item.supplierName}',
                        style: TextStyle(
                            color: context.appColors.textSecondary,
                            fontSize: 12),
                      ),
                    ],
                  ],
                ),
              ),
              // Stock adjust
              Row(
                children: [
                  _AdjustBtn('-1', () => onAdjust(-1)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Text(
                      '${item.currentStock % 1 == 0 ? item.currentStock.toInt() : item.currentStock} ${item.unit}',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ),
                  _AdjustBtn('+1', () => onAdjust(1)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _stockBadge(context),
              const Spacer(),
              _AdjustBtn('+10', () => onAdjust(10)),
              const SizedBox(width: 8),
              InkWell(
                onTap: onEdit,
                borderRadius: BorderRadius.circular(8),
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(Icons.edit_outlined, size: 18),
                ),
              ),
              const SizedBox(width: 4),
              InkWell(
                onTap: onDelete,
                borderRadius: BorderRadius.circular(8),
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child:
                      Icon(Icons.delete_outline, size: 18, color: AppColors.negative),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _stockBadge(BuildContext context) {
    String label;
    Color color;
    if (item.isOutOfStock) {
      label = 'HABIS';
      color = AppColors.negative;
    } else if (item.isLowStock) {
      label = 'MENIPIS';
      color = const Color(0xFFF59E0B);
    } else {
      label = 'AMAN';
      color = AppColors.brandGreen;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label,
          style: TextStyle(
              color: color, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }
}

class _AdjustBtn extends StatelessWidget {
  const _AdjustBtn(this.label, this.onTap);
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: context.appColors.cardSoft,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: context.appColors.outline),
        ),
        child: Text(label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
      ),
    );
  }
}

// ─── Form ─────────────────────────────────────────────────────────────────────

class _RawMaterialForm extends StatefulWidget {
  const _RawMaterialForm({this.item, required this.onSave});
  final RawMaterial? item;
  final Future<void> Function(RawMaterial) onSave;

  @override
  State<_RawMaterialForm> createState() => _RawMaterialFormState();
}

class _RawMaterialFormState extends State<_RawMaterialForm> {
  final _name = TextEditingController();
  final _unit = TextEditingController();
  final _cost = TextEditingController();
  final _stock = TextEditingController();
  final _minStock = TextEditingController();
  final _supplier = TextEditingController();

  @override
  void initState() {
    super.initState();
    final m = widget.item;
    if (m != null) {
      _name.text = m.name;
      _unit.text = m.unit;
      _cost.text = m.costPerUnit.toStringAsFixed(0);
      _stock.text = m.currentStock.toStringAsFixed(0);
      _minStock.text = m.minStock.toStringAsFixed(0);
      _supplier.text = m.supplierName ?? '';
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _unit.dispose();
    _cost.dispose();
    _stock.dispose();
    _minStock.dispose();
    _supplier.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_name.text.trim().isEmpty || _unit.text.trim().isEmpty) return;
    final result = widget.item == null
        ? RawMaterial.create(
            name: _name.text.trim(),
            unit: _unit.text.trim(),
            costPerUnit: double.tryParse(_cost.text) ?? 0,
            currentStock: double.tryParse(_stock.text) ?? 0,
            minStock: double.tryParse(_minStock.text) ?? 0,
            supplierName:
                _supplier.text.trim().isEmpty ? null : _supplier.text.trim(),
          )
        : widget.item!.copyWith(
            name: _name.text.trim(),
            unit: _unit.text.trim(),
            costPerUnit: double.tryParse(_cost.text) ?? 0,
            currentStock: double.tryParse(_stock.text) ?? 0,
            minStock: double.tryParse(_minStock.text) ?? 0,
            supplierName:
                _supplier.text.trim().isEmpty ? null : _supplier.text.trim(),
          );
    await widget.onSave(result);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(20, 20, 20, bottom + 24),
      decoration: const BoxDecoration(
        color: Color(0xFF0D1F16),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.item == null ? 'Tambah Bahan Baku' : 'Edit Bahan Baku',
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
                IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context)),
              ],
            ),
            const SizedBox(height: 16),
            _field('Nama Bahan', _name, hint: 'Tepung Terigu'),
            _field('Satuan', _unit, hint: 'Kg / Liter / Pcs'),
            _field('Harga per Satuan (Rp)', _cost,
                hint: '8000', isNumber: true),
            _field('Stok Saat Ini', _stock, hint: '50', isNumber: true),
            _field('Stok Minimum (alert)', _minStock,
                hint: '10', isNumber: true),
            _field('Nama Supplier (opsional)', _supplier,
                hint: 'Toko Bahan Kue'),
            const SizedBox(height: 8),
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
                child: Text(
                  widget.item == null ? 'Simpan Bahan Baku' : 'Update',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(String label, TextEditingController ctrl,
      {String hint = '', bool isNumber = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  color: Colors.white70, fontSize: 12, letterSpacing: 0.5)),
          const SizedBox(height: 6),
          TextField(
            controller: ctrl,
            keyboardType:
                isNumber ? TextInputType.number : TextInputType.text,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: Colors.white38),
              filled: true,
              fillColor: const Color(0xFF1A2C22),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Colors.white12),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Colors.white12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Empty ─────────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAdd});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.science_outlined,
              size: 64, color: context.appColors.textSecondary),
          const SizedBox(height: 16),
          const Text('Belum ada bahan baku',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 8),
          Text('Tambahkan bahan baku untuk menghitung HPP real-time',
              textAlign: TextAlign.center,
              style: TextStyle(color: context.appColors.textSecondary)),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            label: const Text('Tambah Bahan Baku'),
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
