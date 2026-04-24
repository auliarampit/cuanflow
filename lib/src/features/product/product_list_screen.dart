import 'package:flutter/material.dart';
import '../../core/formatters/idr_formatter.dart';
import '../../core/localization/transalation_extansions.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dynamic_colors.dart';
import '../../core/ui/app_gradient_scaffold.dart';
import 'hpp_calculator_screen.dart';
import 'product_analytics_screen.dart';

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.appState;
    final rawMaterials = appState.rawMaterials;
    final products = appState.products;
    final filteredProducts = products.where((p) {
      if (_searchQuery.isEmpty) return true;
      return p.name.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return AppGradientScaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          context.t('product.list.title'),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          if (products.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.bar_chart),
              tooltip: 'Analitik',
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (_) => const ProductAnalyticsScreen()),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: InputDecoration(
                hintText: context.t('product.list.search'),
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
          Expanded(
            child: filteredProducts.isEmpty && _searchQuery.isEmpty
                ? _buildEmptyState(context)
                : ListView.builder(
                    itemCount: filteredProducts.length,
                    padding: const EdgeInsets.all(16),
                    itemBuilder: (context, index) {
                      final product = filteredProducts[index];
                      final liveHpp =
                          product.liveHppPerUnit(rawMaterials);
                      final hpp =
                          liveHpp > 0 ? liveHpp : product.hppPerUnit;
                      final margin = product.sellingPrice > 0
                          ? (product.sellingPrice - hpp) /
                              product.sellingPrice *
                              100
                          : 0.0;
                      final isLinked = product.ingredients
                          .any((i) => i.rawMaterialId != null);

                      Color marginColor;
                      String marginLabel;
                      if (margin >= 40) {
                        marginColor = AppColors.brandGreen;
                        marginLabel = 'SEHAT';
                      } else if (margin >= 20) {
                        marginColor = const Color(0xFFF59E0B);
                        marginLabel = 'TIPIS';
                      } else {
                        marginColor = AppColors.negative;
                        marginLabel = 'RUGI';
                      }

                      return Card(
                        color: context.appColors.card,
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                              color: marginColor.withValues(alpha: 0.4),
                              width: 1),
                        ),
                        child: InkWell(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    HppCalculatorScreen(product: product),
                              ),
                            );
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        product.name,
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color:
                                              context.appColors.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Text(
                                            '${context.t('product.list.hppPrefix')}${IdrFormatter.format(hpp.round())}',
                                            style: TextStyle(
                                              color: context
                                                  .appColors.textSecondary,
                                              fontSize: 13,
                                            ),
                                          ),
                                          if (isLinked) ...[
                                            const SizedBox(width: 4),
                                            const Text('⚡',
                                                style: TextStyle(fontSize: 11)),
                                          ],
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      IdrFormatter.format(
                                          product.sellingPrice.round()),
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: context.appColors.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: marginColor.withValues(alpha: 0.15),
                                        borderRadius:
                                            BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        '$marginLabel ${margin.toStringAsFixed(0)}%',
                                        style: TextStyle(
                                          color: marginColor,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: filteredProducts.isNotEmpty || _searchQuery.isNotEmpty
          ? FloatingActionButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const HppCalculatorScreen(),
                  ),
                );
              },
              backgroundColor: AppColors.brandGreen,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: context.appColors.cardSoft,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.inventory_2_outlined,
                size: 64,
                color: context.appColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              context.t('product.list.emptyTitle'),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: context.appColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              context.t('product.list.emptySubtitle'),
              style: TextStyle(
                color: context.appColors.textSecondary,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const HppCalculatorScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.add),
                label: Text(context.t('product.list.add')),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brandGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
