import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/formatters/currency_input_formatter.dart';
import '../../../core/formatters/idr_formatter.dart';
import '../../../core/localization/transalation_extansions.dart';
import '../../../core/models/product_model.dart';
import '../../../core/models/raw_material_model.dart';
import '../../../core/theme/app_colors.dart';

class AddItemSheet extends StatefulWidget {
  const AddItemSheet({
    super.key,
    required this.title,
    required this.nameLabel,
    required this.nameHint,
    this.amountLabel,
    this.amountHint,
    this.unitLabel,
    this.unitHint,
    this.noteLabel,
    this.noteHint,
    required this.priceLabel,
    required this.submitLabel,
    required this.onSave,
    this.isCost = false,
    this.existingProducts,
    this.rawMaterials,
    this.onSaveRawMaterial,
  });

  final String title;
  final String nameLabel;
  final String nameHint;
  final String? amountLabel;
  final String? amountHint;
  final String? unitLabel;
  final String? unitHint;
  final String? noteLabel;
  final String? noteHint;
  final String priceLabel;
  final String submitLabel;
  final Function(String name, double qty, String unit, double price, String note)
      onSave;
  final bool isCost;
  final List<ProductModel>? existingProducts;
  final List<RawMaterial>? rawMaterials;
  /// Called instead of [onSave] when user picks a raw material as ingredient.
  final void Function(String name, double qty, String unit, double price,
      String note, String rawMaterialId)? onSaveRawMaterial;

  @override
  State<AddItemSheet> createState() => _AddItemSheetState();
}

class _AddItemSheetState extends State<AddItemSheet> {
  final _nameController = TextEditingController();
  final _qtyController = TextEditingController();
  final _noteController = TextEditingController();
  final _priceController = TextEditingController();
  String _unit = 'Gram (gr)';

  // 0 = manual, 1 = from product, 2 = from raw material
  int _mode = 0;
  ProductModel? _selectedProduct;
  RawMaterial? _selectedRawMaterial;

  final List<String> _units = [
    'Gram (gr)',
    'Kg',
    'Liter (l)',
    'ml',
    'Pcs',
    'Ikat',
    'Butir',
    'Sendok',
    'Buah'
  ];

  bool get _hasProducts =>
      widget.existingProducts != null && widget.existingProducts!.isNotEmpty;
  bool get _hasRawMaterials =>
      widget.rawMaterials != null && widget.rawMaterials!.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final bgColor = const Color(0xFF0D1F16);
    final inputColor = const Color(0xFF1A2C22);
    final textColor = Colors.white;
    final hintColor = Colors.white54;
    final accentColor = AppColors.brandGreen;

    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final showTabs = !widget.isCost && (_hasProducts || _hasRawMaterials);

    return Container(
      padding: EdgeInsets.fromLTRB(20, 20, 20, bottomInset + 20),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.title,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              IconButton(
                icon: Icon(Icons.close, color: textColor),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Toggle Tabs
          if (showTabs) ...[
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: inputColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildToggleOption(
                      title: context.t('addItem.modeManual'),
                      isSelected: _mode == 0,
                      onTap: () => setState(() => _mode = 0),
                    ),
                  ),
                  if (_hasProducts)
                    Expanded(
                      child: _buildToggleOption(
                        title: context.t('addItem.modeProduct'),
                        isSelected: _mode == 1,
                        onTap: () => setState(() => _mode = 1),
                      ),
                    ),
                  if (_hasRawMaterials)
                    Expanded(
                      child: _buildToggleOption(
                        title: 'Bahan Baku',
                        isSelected: _mode == 2,
                        onTap: () => setState(() => _mode = 2),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],

          // ── Raw Material Mode ─────────────────────────────────────────────
          if (_mode == 2 && !widget.isCost) ...[
            _buildLabel('Bahan Baku', hintColor),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: inputColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white12),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<RawMaterial>(
                  value: _selectedRawMaterial,
                  hint: Text('Pilih bahan baku…',
                      style: TextStyle(color: hintColor)),
                  dropdownColor: inputColor,
                  isExpanded: true,
                  icon: Icon(Icons.keyboard_arrow_down, color: hintColor),
                  style: TextStyle(color: textColor),
                  items: widget.rawMaterials!.map((m) {
                    return DropdownMenuItem<RawMaterial>(
                      value: m,
                      child: Text(
                        '${m.name} — ${IdrFormatter.format(m.costPerUnit.round())}/${m.unit}',
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (v) {
                    setState(() {
                      _selectedRawMaterial = v;
                      _updateRawMaterialCalculation();
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel(
                          context.t('addItem.usedAmount'), hintColor),
                      const SizedBox(height: 8),
                      _buildInput(
                        controller: _qtyController,
                        hint: '0',
                        bgColor: inputColor,
                        textColor: textColor,
                        hintColor: hintColor,
                        isNumber: true,
                        onChanged: (_) => _updateRawMaterialCalculation(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel(context.t('addItem.unit'), hintColor),
                      const SizedBox(height: 8),
                      Container(
                        height: 50,
                        alignment: Alignment.centerLeft,
                        padding:
                            const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: inputColor.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: Text(
                          _selectedRawMaterial?.unit ??
                              context.t('addItem.unitPlaceholder'),
                          style: TextStyle(
                              color: textColor.withValues(alpha: 0.7)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildLabel(context.t('addItem.autoTotal'), hintColor),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                _priceController.text.isEmpty
                    ? 'Rp 0'
                    : 'Rp ${_priceController.text}',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: accentColor,
                ),
              ),
            ),
          ]

          // ── Product Mode ──────────────────────────────────────────────────
          else if (_mode == 1 && !widget.isCost) ...[
            _buildLabel(context.t('addItem.modeVariant'), hintColor),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: inputColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white12),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<ProductModel>(
                  value: _selectedProduct,
                  hint: Text(context.t('addItem.productHint'),
                      style: TextStyle(color: hintColor)),
                  dropdownColor: inputColor,
                  isExpanded: true,
                  icon: Icon(Icons.keyboard_arrow_down, color: hintColor),
                  style: TextStyle(color: textColor),
                  items: widget.existingProducts!.map((p) {
                    return DropdownMenuItem<ProductModel>(
                      value: p,
                      child: Text(
                        '${p.name} (HPP: ${IdrFormatter.format(p.hppPerUnit.round())})',
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (v) {
                    setState(() {
                      _selectedProduct = v;
                      _updateProductCalculation();
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel(
                          context.t('addItem.usedAmount'), hintColor),
                      const SizedBox(height: 8),
                      _buildInput(
                        controller: _qtyController,
                        hint: '0',
                        bgColor: inputColor,
                        textColor: textColor,
                        hintColor: hintColor,
                        isNumber: true,
                        onChanged: (_) => _updateProductCalculation(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel(context.t('addItem.unit'), hintColor),
                      const SizedBox(height: 8),
                      Container(
                        height: 50,
                        alignment: Alignment.centerLeft,
                        padding:
                            const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: inputColor.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: Text(
                          _selectedProduct?.yieldUnit ??
                              context.t('addItem.unitPlaceholder'),
                          style: TextStyle(
                              color: textColor.withValues(alpha: 0.7)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildLabel(context.t('addItem.autoTotal'), hintColor),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                _priceController.text.isEmpty
                    ? 'Rp 0'
                    : 'Rp ${_priceController.text}',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: accentColor,
                ),
              ),
            ),
          ]

          // ── Manual Mode ───────────────────────────────────────────────────
          else ...[
            Text(
              widget.priceLabel,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: hintColor,
                letterSpacing: 1,
              ),
            ),
            TextField(
              controller: _priceController,
              keyboardType: TextInputType.number,
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                CurrencyInputFormatter(),
              ],
              decoration: InputDecoration(
                prefixText: 'Rp ',
                prefixStyle: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: accentColor,
                ),
                hintText: '0',
                hintStyle: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: textColor.withValues(alpha: 0.3),
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const SizedBox(height: 24),
            _buildLabel(widget.nameLabel, hintColor),
            const SizedBox(height: 8),
            _buildInput(
              controller: _nameController,
              hint: widget.nameHint,
              bgColor: inputColor,
              textColor: textColor,
              hintColor: hintColor,
            ),
            const SizedBox(height: 16),
            if (!widget.isCost) ...[
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel(widget.amountLabel!, hintColor),
                        const SizedBox(height: 8),
                        _buildInput(
                          controller: _qtyController,
                          hint: widget.amountHint!,
                          bgColor: inputColor,
                          textColor: textColor,
                          hintColor: hintColor,
                          isNumber: true,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel(widget.unitLabel!, hintColor),
                        const SizedBox(height: 8),
                        Container(
                          height: 50,
                          padding:
                              const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: inputColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white12),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _units.contains(_unit)
                                  ? _unit
                                  : _units.first,
                              dropdownColor: inputColor,
                              icon: Icon(Icons.keyboard_arrow_down,
                                  color: hintColor),
                              style: TextStyle(color: textColor),
                              items: _units.map((v) {
                                return DropdownMenuItem<String>(
                                  value: v,
                                  child: Text(v),
                                );
                              }).toList(),
                              onChanged: (v) =>
                                  setState(() => _unit = v!),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ],

          // Note — shared across all modes (not for cost)
          if (!widget.isCost) ...[
            _buildLabel(widget.noteLabel!, hintColor),
            const SizedBox(height: 8),
            _buildInput(
              controller: _noteController,
              hint: widget.noteHint!,
              bgColor: inputColor,
              textColor: textColor,
              hintColor: hintColor,
              maxLines: 3,
            ),
            const SizedBox(height: 24),
          ],

          // Submit
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: accentColor,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.add_circle_outline, color: Colors.black),
                  const SizedBox(width: 8),
                  Text(
                    widget.submitLabel,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
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

  void _updateProductCalculation() {
    if (_selectedProduct == null) return;
    final qty = double.tryParse(_qtyController.text) ?? 0;
    final total = qty * _selectedProduct!.hppPerUnit;
    _priceController.text = CurrencyInputFormatter.formatVal(total.round());
    setState(() {});
  }

  void _updateRawMaterialCalculation() {
    if (_selectedRawMaterial == null) return;
    final qty = double.tryParse(_qtyController.text) ?? 0;
    final total = qty * _selectedRawMaterial!.costPerUnit;
    _priceController.text = CurrencyInputFormatter.formatVal(total.round());
    setState(() {});
  }

  Widget _buildToggleOption({
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF0D1F16)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isSelected
              ? [BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 4)]
              : null,
        ),
        child: Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white54,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  void _submit() {
    if (_mode == 2) {
      // Raw Material mode
      if (_selectedRawMaterial == null) return;
      if (_qtyController.text.isEmpty) return;
      final priceText =
          _priceController.text.replaceAll(RegExp(r'[^0-9]'), '');
      final price = double.tryParse(priceText) ?? 0;
      final qty = double.tryParse(_qtyController.text) ?? 1;
      widget.onSaveRawMaterial?.call(
        _selectedRawMaterial!.name,
        qty,
        _selectedRawMaterial!.unit,
        price,
        _noteController.text,
        _selectedRawMaterial!.id,
      );
      // Fallback if no raw material callback provided
      if (widget.onSaveRawMaterial == null) {
        widget.onSave(
          _selectedRawMaterial!.name,
          qty,
          _selectedRawMaterial!.unit,
          price,
          _noteController.text,
        );
      }
      Navigator.pop(context);
    } else if (_mode == 1) {
      // Product mode
      if (_selectedProduct == null) return;
      if (_qtyController.text.isEmpty) return;
      final priceText =
          _priceController.text.replaceAll(RegExp(r'[^0-9]'), '');
      final price = double.tryParse(priceText) ?? 0;
      final qty = double.tryParse(_qtyController.text) ?? 1;
      widget.onSave(
        _selectedProduct!.name,
        qty,
        _selectedProduct!.yieldUnit,
        price,
        _noteController.text,
      );
      Navigator.pop(context);
    } else {
      // Manual mode
      if (_nameController.text.isEmpty || _priceController.text.isEmpty) {
        return;
      }
      final priceText =
          _priceController.text.replaceAll(RegExp(r'[^0-9]'), '');
      final price = double.tryParse(priceText) ?? 0;
      final qty = double.tryParse(_qtyController.text) ?? 1;
      widget.onSave(
        _nameController.text,
        qty,
        _unit,
        price,
        _noteController.text,
      );
      Navigator.pop(context);
    }
  }

  Widget _buildLabel(String text, Color color) {
    return Text(
      text,
      style: TextStyle(
        color: color,
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _buildInput({
    required TextEditingController controller,
    required String hint,
    required Color bgColor,
    required Color textColor,
    required Color hintColor,
    bool isNumber = false,
    int maxLines = 1,
    Function(String)? onChanged,
  }) {
    return TextField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      maxLines: maxLines,
      style: TextStyle(color: textColor),
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: hintColor.withValues(alpha: 0.5)),
        filled: true,
        fillColor: bgColor,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
              color: AppColors.brandGreen.withValues(alpha: 0.5)),
        ),
      ),
    );
  }
}
