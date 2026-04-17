import 'package:flutter/material.dart';

import '../../core/models/money_transaction.dart';
import '../../core/models/user_category.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dynamic_colors.dart';
import '../../core/ui/app_gradient_scaffold.dart';
import 'widgets/add_category_sheet.dart';
import 'widgets/category_list_tile.dart';

class ManageCategoriesScreen extends StatefulWidget {
  const ManageCategoriesScreen({super.key});

  @override
  State<ManageCategoriesScreen> createState() => _ManageCategoriesScreenState();
}

class _ManageCategoriesScreenState extends State<ManageCategoriesScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showAddSheet(MoneyTransactionType type) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddCategorySheet(
        type: type,
        onAdd: (name) {
          context.appState.addCategory(
            UserCategory(
              id: 'cat_${DateTime.now().microsecondsSinceEpoch}',
              name: name,
              type: type,
            ),
          );
        },
      ),
    );
  }

  void _confirmDelete(UserCategory category) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Kategori?'),
        content: Text('Hapus kategori "${category.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.appState.deleteCategory(category.id);
            },
            child: const Text('Hapus', style: TextStyle(color: AppColors.negative)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final incomeList = context.appState
        .categoriesFor(MoneyTransactionType.income);
    final expenseList = context.appState
        .categoriesFor(MoneyTransactionType.expense);

    return AppGradientScaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Kelola Kategori',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.brandBlue,
          labelColor: AppColors.brandBlue,
          unselectedLabelColor: context.appColors.textSecondary,
          tabs: const [
            Tab(text: 'Pemasukan'),
            Tab(text: 'Pengeluaran'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _CategoryTab(
            categories: incomeList,
            accentColor: AppColors.positive,
            type: MoneyTransactionType.income,
            onAdd: () => _showAddSheet(MoneyTransactionType.income),
            onDelete: _confirmDelete,
          ),
          _CategoryTab(
            categories: expenseList,
            accentColor: AppColors.negative,
            type: MoneyTransactionType.expense,
            onAdd: () => _showAddSheet(MoneyTransactionType.expense),
            onDelete: _confirmDelete,
          ),
        ],
      ),
    );
  }
}

class _CategoryTab extends StatelessWidget {
  const _CategoryTab({
    required this.categories,
    required this.accentColor,
    required this.type,
    required this.onAdd,
    required this.onDelete,
  });

  final List<UserCategory> categories;
  final Color accentColor;
  final MoneyTransactionType type;
  final VoidCallback onAdd;
  final ValueChanged<UserCategory> onDelete;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 80),
            itemCount: categories.length,
            separatorBuilder: (_, i) => const SizedBox(height: 8),
            itemBuilder: (_, i) => CategoryListTile(
              category: categories[i],
              accentColor: accentColor,
              onDelete: categories[i].isDefault ? null : () => onDelete(categories[i]),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onAdd,
              style: ElevatedButton.styleFrom(
                backgroundColor: accentColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: const Icon(Icons.add),
              label: const Text(
                'Tambah Kategori',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
