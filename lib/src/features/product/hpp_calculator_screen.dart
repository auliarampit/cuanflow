import 'package:flutter/material.dart';
import '../../core/formatters/currency_input_formatter.dart';
import '../../core/formatters/idr_formatter.dart';
import '../../core/localization/transalation_extansions.dart';
import '../../core/models/product_model.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/app_colors.dart';
import '../../core/ui/app_gradient_scaffold.dart';
import 'widgets/add_item_sheet.dart';
import 'widgets/calculation_summary_section.dart';
import 'widgets/cost_card.dart';
import 'widgets/ingredient_card.dart';
import 'widgets/profit_summary_section.dart';
import 'widgets/section_header.dart';

class HppCalculatorScreen extends StatefulWidget {
  const HppCalculatorScreen({super.key, this.product});

  final ProductModel? product;

  @override
  State<HppCalculatorScreen> createState() => _HppCalculatorScreenState();
}

class _HppCalculatorScreenState extends State<HppCalculatorScreen> {
  final _nameController = TextEditingController();
  final _yieldController = TextEditingController();
  final _sellingPriceController = TextEditingController();

  List<ProductIngredient> _ingredients = [];
  List<ProductCost> _costs = [];
  String _yieldUnit = 'Porsi';

  static const _yieldUnits = [
    'Porsi', 'Pcs', 'Loyang', 'Bungkus', 'Botol', 'Toples', 'Kg', 'Liter',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.product != null) {
      final p = widget.product!;
      _nameController.text = p.name;
      _yieldController.text = p.yieldAmount.toStringAsFixed(0);
      _sellingPriceController.text =
          CurrencyInputFormatter.formatVal(p.sellingPrice.toInt());
      _ingredients = List.from(p.ingredients);
      _costs = List.from(p.otherCosts);
      _yieldUnit = _yieldUnits.contains(p.yieldUnit) ? p.yieldUnit : 'Porsi';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _yieldController.dispose();
    _sellingPriceController.dispose();
    super.dispose();
  }

  void _addIngredient() {
    final appState = context.appState;
    final products = appState.products;
    final rawMaterials = appState.rawMaterials;
    final availableProducts = widget.product == null
        ? products
        : products.where((p) => p.id != widget.product!.id).toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddItemSheet(
        title: context.t('product.addIngredient.title'),
        nameLabel: context.t('product.addIngredient.nameLabel'),
        nameHint: context.t('product.addIngredient.nameHint'),
        amountLabel: context.t('product.addIngredient.amountLabel'),
        amountHint: context.t('product.addIngredient.amountHint'),
        unitLabel: context.t('product.addIngredient.unitLabel'),
        unitHint: context.t('product.addIngredient.unitHint'),
        noteLabel: context.t('product.addIngredient.noteLabel'),
        noteHint: context.t('product.addIngredient.noteHint'),
        priceLabel: context.t('product.addIngredient.totalPrice'),
        submitLabel: context.t('product.addIngredient.submit'),
        existingProducts: availableProducts.isEmpty ? null : availableProducts,
        rawMaterials: rawMaterials.isEmpty ? null : rawMaterials,
        onSave: (name, qty, unit, price, note) {
          setState(() {
            _ingredients.add(ProductIngredient.create(
              name: name,
              quantity: qty,
              unit: unit,
              totalPrice: price,
              note: note,
            ));
          });
        },
        onSaveRawMaterial: (name, qty, unit, price, note, rawMaterialId) {
          setState(() {
            _ingredients.add(ProductIngredient.create(
              name: name,
              quantity: qty,
              unit: unit,
              totalPrice: price,
              note: note.isEmpty ? null : note,
              rawMaterialId: rawMaterialId,
            ));
          });
        },
      ),
    );
  }

  void _addCost() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddItemSheet(
        title: context.t('product.calc.addCost'),
        nameLabel: context.t('product.calc.costName'),
        nameHint: '',
        priceLabel: context.t('product.calc.costAmount'),
        submitLabel: context.t('product.calc.addCost'),
        isCost: true,
        onSave: (name, qty, unit, price, note) {
          setState(() {
            _costs.add(ProductCost.create(
              name: name,
              cost: price,
            ));
          });
        },
      ),
    );
  }

  double get _totalIngredientCost =>
      _ingredients.fold(0, (sum, item) => sum + item.totalPrice);

  double get _totalOtherCost =>
      _costs.fold(0, (sum, item) => sum + item.cost);

  double get _yieldAmount => double.tryParse(_yieldController.text) ?? 1;

  double get _hppPerUnit {
    final total = _totalIngredientCost + _totalOtherCost;
    final yieldVal = _yieldAmount;
    if (yieldVal <= 0) return 0;
    return total / yieldVal;
  }

  double get _sellingPrice {
    final text = _sellingPriceController.text.replaceAll(RegExp(r'[^0-9]'), '');
    return double.tryParse(text) ?? 0;
  }

  double get _netProfit => _sellingPrice - _hppPerUnit;

  double get _margin {
    if (_sellingPrice <= 0) return 0;
    return (_netProfit / _sellingPrice) * 100;
  }

  Future<void> _save() async {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.t('product.nameRequired'))),
      );
      return;
    }

    final product = ProductModel.create(
      name: _nameController.text,
      yieldAmount: _yieldAmount,
      yieldUnit: _yieldUnit,
      ingredients: _ingredients,
      otherCosts: _costs,
      sellingPrice: _sellingPrice,
    );

    if (widget.product != null) {
      // Update existing (keep ID)
      final updated = ProductModel(
        id: widget.product!.id,
        name: product.name,
        yieldAmount: product.yieldAmount,
        yieldUnit: product.yieldUnit,
        ingredients: product.ingredients,
        otherCosts: product.otherCosts,
        sellingPrice: product.sellingPrice,
      );
      await context.appState.updateProduct(updated);
    } else {
      await context.appState.addProduct(product);
    }

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AppGradientScaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          context.t('product.calc.title'),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (widget.product != null)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: AppColors.negative),
              tooltip: 'Hapus produk',
              onPressed: () async {
                final appState = context.appState;
                final nav = Navigator.of(context);
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Hapus produk?'),
                    content: Text(
                      '${widget.product!.name} akan dihapus permanen.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Batal'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: Text(
                          'Hapus',
                          style: TextStyle(color: AppColors.negative),
                        ),
                      ),
                    ],
                  ),
                );
                if (confirm == true && mounted) {
                  await appState.deleteProduct(widget.product!.id);
                  if (mounted) nav.pop();
                }
              },
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product Name
                  Text(context.t('product.calc.nameLabel'), style: _labelStyle),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _nameController,
                    decoration:
                        _inputDecoration(context.t('product.calc.nameHint')),
                  ),
                  const SizedBox(height: 16),

                  // Yield
                  Text(context.t('product.calc.yieldLabel'), style: _labelStyle),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _yieldController,
                          keyboardType: TextInputType.number,
                          decoration: _inputDecoration(
                              context.t('product.calc.yieldHint')),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF16262E),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _yieldUnit,
                            isDense: true,
                            dropdownColor: const Color(0xFF16262E),
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                            items: _yieldUnits.map((u) => DropdownMenuItem(
                              value: u,
                              child: Text(u),
                            )).toList(),
                            onChanged: (v) => setState(() => _yieldUnit = v!),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Ingredients
                  SectionHeader(
                    title: context.t('product.calc.ingredients'),
                    onAdd: _addIngredient,
                    icon: Icons.inventory_2,
                  ),
                  const SizedBox(height: 12),
                  ..._ingredients.map((item) => IngredientCard(
                        item: item,
                        onDelete: () => setState(() => _ingredients.remove(item)),
                      )),
                  const SizedBox(height: 16),
                  _buildSummaryRow(
                    context.t('product.calc.subtotalIngredients'),
                    _totalIngredientCost,
                  ),
                  const SizedBox(height: 24),

                  // Other Costs
                  SectionHeader(
                    title: context.t('product.calc.otherCosts'),
                    onAdd: _addCost,
                    icon: Icons.monetization_on,
                  ),
                  const SizedBox(height: 12),
                  ..._costs.map((item) => CostCard(
                        item: item,
                        onDelete: () => setState(() => _costs.remove(item)),
                      )),

                  const SizedBox(height: 32),

                  // Calculation Summary
                  CalculationSummarySection(
                    hppPerUnit: _hppPerUnit,
                    sellingPriceController: _sellingPriceController,
                    onChanged: () => setState(() {}),
                  ),
                  if (_hppPerUnit > 0) ...[
                    const SizedBox(height: 12),
                    _PriceSuggestionRow(
                      hpp: _hppPerUnit,
                      onSelect: (price) {
                        _sellingPriceController.text =
                            CurrencyInputFormatter.formatVal(price);
                        setState(() {});
                      },
                    ),
                  ],
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),

          // Fixed Bottom Section (Profit, Margin, Save Button)
          Container(
            padding: EdgeInsets.fromLTRB(
                20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
            decoration: BoxDecoration(
              color: const Color(0xFF0D1F16), // Dark background
              border:
                  Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 10,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ProfitSummarySection(
                  profitPerUnit: _netProfit,
                  marginPercentage: _margin,
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.brandGreen,
                      foregroundColor: Colors.black, // Green button usually has black text for contrast, or check theme
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.save_outlined, color: Colors.black),
                        const SizedBox(width: 8),
                        Text(
                          context.t('product.calc.save'),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, double amount) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
          Text(
            IdrFormatter.format(amount.round()),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: const Color(0xFF16262E),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.brandBlue),
      ),
    );
  }

  TextStyle get _labelStyle => const TextStyle(
        color: AppColors.textSecondary,
        fontWeight: FontWeight.bold,
        fontSize: 12,
        letterSpacing: 0.5,
      );
}

// ─── Price suggestion row ─────────────────────────────────────────────────────

class _PriceSuggestionRow extends StatelessWidget {
  const _PriceSuggestionRow({required this.hpp, required this.onSelect});

  final double hpp;
  final ValueChanged<int> onSelect;

  static int _roundUp500(double val) => ((val / 500).ceil() * 500).toInt();

  @override
  Widget build(BuildContext context) {
    final breakEven = _roundUp500(hpp);
    final target30 = _roundUp500(hpp / 0.70);
    final premium50 = _roundUp500(hpp / 0.50);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'SARAN HARGA JUAL',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.8,
            color: Colors.white.withValues(alpha: 0.4),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _SuggestionChip(
              label: 'BEP',
              sublabel: 'Balik modal',
              price: breakEven,
              color: Colors.white54,
              onTap: () => onSelect(breakEven),
            ),
            const SizedBox(width: 8),
            _SuggestionChip(
              label: '30%',
              sublabel: 'Target wajar',
              price: target30,
              color: const Color(0xFFF59E0B),
              onTap: () => onSelect(target30),
            ),
            const SizedBox(width: 8),
            _SuggestionChip(
              label: '50%',
              sublabel: 'Premium',
              price: premium50,
              color: AppColors.brandGreen,
              onTap: () => onSelect(premium50),
            ),
          ],
        ),
      ],
    );
  }
}

class _SuggestionChip extends StatelessWidget {
  const _SuggestionChip({
    required this.label,
    required this.sublabel,
    required this.price,
    required this.color,
    required this.onTap,
  });

  final String label;
  final String sublabel;
  final int price;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.25)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: color,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                IdrFormatter.format(price),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
              Text(
                sublabel,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.white.withValues(alpha: 0.4),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
