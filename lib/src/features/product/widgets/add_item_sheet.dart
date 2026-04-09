import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/formatters/currency_input_formatter.dart';
import '../../../core/formatters/idr_formatter.dart';
import '../../../core/models/product_model.dart';
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

  @override
  State<AddItemSheet> createState() => _AddItemSheetState();
}

class _AddItemSheetState extends State<AddItemSheet> {
  final _nameController = TextEditingController();
  final _qtyController = TextEditingController();
  final _noteController = TextEditingController();
  final _priceController = TextEditingController();
  String _unit = 'Gram (gr)';
  
  // Varian Mode
  bool _isManual = true;
  ProductModel? _selectedProduct;

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

  @override
  Widget build(BuildContext context) {
    // Dark theme colors as per design
    final bgColor = const Color(0xFF0D1F16);
    final inputColor = const Color(0xFF1A2C22);
    final textColor = Colors.white;
    final hintColor = Colors.white54;
    final accentColor = AppColors.brandGreen;

    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final hasProducts = widget.existingProducts != null && widget.existingProducts!.isNotEmpty;

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

          // Toggle Mode (Only if not Cost and has products)
          if (!widget.isCost && hasProducts) ...[
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
                      title: 'Input Manual',
                      isSelected: _isManual,
                      onTap: () => setState(() => _isManual = true),
                    ),
                  ),
                  Expanded(
                    child: _buildToggleOption(
                      title: 'Pilih Produk',
                      isSelected: !_isManual,
                      onTap: () => setState(() => _isManual = false),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],

          if (!_isManual && !widget.isCost) ...[
            // PRODUCT SELECTION MODE
            _buildLabel('Pilih Produk (Varian)', hintColor),
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
                  hint: Text('Pilih produk...', style: TextStyle(color: hintColor)),
                  dropdownColor: inputColor,
                  isExpanded: true,
                  icon: Icon(Icons.keyboard_arrow_down, color: hintColor),
                  style: TextStyle(color: textColor),
                  items: widget.existingProducts!.map((ProductModel p) {
                    return DropdownMenuItem<ProductModel>(
                      value: p,
                      child: Text(
                        '${p.name} (HPP: ${IdrFormatter.format(p.hppPerUnit.round())})',
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    setState(() {
                      _selectedProduct = newValue;
                      _updateProductCalculation();
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Qty Input for Product
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel('Jumlah Dipakai', hintColor),
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
                      _buildLabel('Satuan', hintColor),
                      const SizedBox(height: 8),
                      Container(
                        height: 50,
                        alignment: Alignment.centerLeft,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: inputColor.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: Text(
                          _selectedProduct?.yieldUnit ?? 'Unit',
                          style: TextStyle(color: textColor.withOpacity(0.7)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Auto-calculated Price Display
            _buildLabel('Total Biaya (Otomatis)', hintColor),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                _priceController.text.isEmpty ? 'Rp 0' : 'Rp ${_priceController.text}',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: accentColor,
                ),
              ),
            ),
          ] else ...[
            // MANUAL INPUT MODE (Existing)
            // Price Input (Big)
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
                  color: textColor.withOpacity(0.3),
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const SizedBox(height: 24),

            // Name
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
              // Qty & Unit
              Row(
                children: [
                  Expanded(
                    flex: 1,
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
                    flex: 1,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel(widget.unitLabel!, hintColor),
                        const SizedBox(height: 8),
                        Container(
                          height: 50, // Match TextField height approx
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: inputColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white12),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value:
                                  _units.contains(_unit) ? _unit : _units.first,
                              dropdownColor: inputColor,
                              icon: Icon(Icons.keyboard_arrow_down,
                                  color: hintColor),
                              style: TextStyle(color: textColor),
                              items: _units.map((String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(value),
                                );
                              }).toList(),
                              onChanged: (newValue) {
                                setState(() {
                                  _unit = newValue!;
                                });
                              },
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

          // Note (Shared)
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

          // Submit Button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: accentColor,
                foregroundColor: Colors.black, // Black text on green button
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
    
    // Update price controller just for storage/display logic
    // We use a formatter to show it nicely
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
          color: isSelected ? const Color(0xFF0D1F16) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isSelected
              ? [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4)]
              : null,
        ),
        child: Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white54,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  void _submit() {
    // Validation
    if (!_isManual) {
       if (_selectedProduct == null) return;
       if (_qtyController.text.isEmpty) return;
    } else {
       if (_nameController.text.isEmpty || _priceController.text.isEmpty) {
         return;
       }
    }

    final priceText =
        _priceController.text.replaceAll(RegExp(r'[^0-9]'), '');
    final price = double.tryParse(priceText) ?? 0;

    final qty = double.tryParse(_qtyController.text) ?? 1;

    String finalName = _isManual ? _nameController.text : _selectedProduct!.name;
    String finalUnit = _isManual ? _unit : _selectedProduct!.yieldUnit;

    widget.onSave(
      finalName,
      qty,
      finalUnit,
      price,
      _noteController.text,
    );
    Navigator.pop(context);
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
        hintStyle: TextStyle(color: hintColor.withOpacity(0.5)),
        filled: true,
        fillColor: bgColor,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.brandGreen.withOpacity(0.5)),
        ),
      ),
    );
  }
}
