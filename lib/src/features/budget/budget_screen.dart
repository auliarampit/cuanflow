import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../core/formatters/currency_input_formatter.dart';
import '../../core/formatters/idr_formatter.dart';
import '../../core/localization/transalation_extansions.dart';
import '../../core/models/money_transaction.dart';
import '../../core/models/user_category.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dynamic_colors.dart';
import '../../core/ui/app_gradient_scaffold.dart';

class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key});

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  late DateTime _selectedMonth;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedMonth = DateTime(now.year, now.month);
  }

  void _prevMonth() =>
      setState(() => _selectedMonth =
          DateTime(_selectedMonth.year, _selectedMonth.month - 1));

  void _nextMonth() {
    final now = DateTime.now();
    final next = DateTime(_selectedMonth.year, _selectedMonth.month + 1);
    if (!next.isAfter(DateTime(now.year, now.month))) {
      setState(() => _selectedMonth = next);
    }
  }

  bool get _isCurrentMonth {
    final now = DateTime.now();
    return _selectedMonth.year == now.year &&
        _selectedMonth.month == now.month;
  }

  Future<void> _openAddSheet({BudgetModel? editing}) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddBudgetSheet(
        month: _selectedMonth,
        editing: editing,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.appState;
    final budgets = appState.budgetsFor(_selectedMonth);
    final incomeTargets = budgets
        .where((b) => b.type == MoneyTransactionType.income)
        .toList();
    final expenseLimits = budgets
        .where((b) => b.type == MoneyTransactionType.expense)
        .toList();

    final monthLabel =
        DateFormat('MMMM yyyy', context.appState.settings.localeCode)
            .format(_selectedMonth);

    return AppGradientScaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(context.t('budget.title')),
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddSheet,
        backgroundColor: AppColors.brandBlue,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 4, 18, 100),
        children: [
          // ── Month Navigator ────────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: _prevMonth,
                icon: const Icon(Icons.chevron_left),
              ),
              Text(
                monthLabel,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
              IconButton(
                onPressed: _isCurrentMonth ? null : _nextMonth,
                icon: Icon(
                  Icons.chevron_right,
                  color: _isCurrentMonth
                      ? context.appColors.outline
                      : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),

          if (budgets.isEmpty) ...[
            const SizedBox(height: 48),
            Center(
              child: Column(
                children: [
                  Icon(Icons.savings_outlined,
                      size: 56, color: context.appColors.outline),
                  const SizedBox(height: 16),
                  Text(
                    context.t('budget.emptyTitle'),
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    context.t('budget.emptySubtitle'),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: context.appColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            if (incomeTargets.isNotEmpty) ...[
              _SectionLabel(context.t('budget.sectionIncome')),
              const SizedBox(height: 8),
              ...incomeTargets.map((b) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _BudgetCard(
                      budget: b,
                      actual: appState.actualFor(b),
                      month: _selectedMonth,
                      onEdit: () => _openAddSheet(editing: b),
                      onDelete: () => appState.deleteBudget(b.id),
                    ),
                  )),
              const SizedBox(height: 8),
            ],
            if (expenseLimits.isNotEmpty) ...[
              _SectionLabel(context.t('budget.sectionExpense')),
              const SizedBox(height: 8),
              ...expenseLimits.map((b) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _BudgetCard(
                      budget: b,
                      actual: appState.actualFor(b),
                      month: _selectedMonth,
                      onEdit: () => _openAddSheet(editing: b),
                      onDelete: () => appState.deleteBudget(b.id),
                    ),
                  )),
            ],
          ],
        ],
      ),
    );
  }
}

// ── Budget Card ────────────────────────────────────────────────────────────────

class _BudgetCard extends StatelessWidget {
  const _BudgetCard({
    required this.budget,
    required this.actual,
    required this.month,
    required this.onEdit,
    required this.onDelete,
  });

  final BudgetModel budget;
  final int actual;
  final DateTime month;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  Color _progressColor(double ratio) {
    if (budget.type == MoneyTransactionType.income) {
      return ratio >= 1.0 ? AppColors.positive : AppColors.brandBlue;
    }
    if (ratio >= 1.0) return AppColors.negative;
    if (ratio >= 0.8) return Colors.orange;
    return AppColors.brandBlue;
  }

  @override
  Widget build(BuildContext context) {
    final ratio = budget.targetAmount > 0
        ? (actual / budget.targetAmount).clamp(0.0, 1.0)
        : 0.0;
    final percent = (ratio * 100).round();
    final isIncome = budget.type == MoneyTransactionType.income;
    final isOverBudget =
        !isIncome && actual > budget.targetAmount;

    final categoryName = budget.categoryId == null
        ? context.t(isIncome
            ? 'budget.allIncome'
            : 'budget.allExpense')
        : _resolveCategoryName(context, budget.categoryId!);

    return GestureDetector(
      onLongPress: () => _showOptions(context),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.appColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isOverBudget
                ? AppColors.negative.withValues(alpha: 0.4)
                : context.appColors.outline,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: _progressColor(ratio).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    isIncome
                        ? Icons.trending_up_rounded
                        : Icons.trending_down_rounded,
                    size: 20,
                    color: _progressColor(ratio),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        categoryName,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      Text(
                        context.t(isIncome
                            ? 'budget.labelTarget'
                            : 'budget.labelLimit'),
                        style: TextStyle(
                          fontSize: 12,
                          color: context.appColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '$percent%',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                    color: _progressColor(ratio),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: ratio,
                minHeight: 6,
                backgroundColor: context.appColors.outline,
                valueColor:
                    AlwaysStoppedAnimation<Color>(_progressColor(ratio)),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  IdrFormatter.format(actual),
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: _progressColor(ratio),
                  ),
                ),
                Text(
                  IdrFormatter.format(budget.targetAmount),
                  style: TextStyle(
                    fontSize: 13,
                    color: context.appColors.textSecondary,
                  ),
                ),
              ],
            ),
            if (isOverBudget) ...[
              const SizedBox(height: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.negative.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  context.t('budget.overBudget', {
                    'amount': IdrFormatter.format(actual - budget.targetAmount),
                  }),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.negative,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _resolveCategoryName(BuildContext context, String categoryId) {
    final all = context.appState.categoriesFor(budget.type);
    return all
        .firstWhere((c) => c.id == categoryId,
            orElse: () => UserCategory(
                id: categoryId,
                name: categoryId,
                type: budget.type,
                isDefault: false))
        .name;
  }

  void _showOptions(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: context.appColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.edit_outlined,
                  color: AppColors.brandBlue),
              title: Text(context.t('budget.edit')),
              onTap: () {
                Navigator.pop(ctx);
                onEdit();
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline,
                  color: AppColors.negative),
              title: Text(context.t('budget.delete'),
                  style: const TextStyle(color: AppColors.negative)),
              onTap: () {
                Navigator.pop(ctx);
                onDelete();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

// ── Section Label ──────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        fontWeight: FontWeight.w700,
        fontSize: 11,
        letterSpacing: 1.4,
        color: context.appColors.textSecondary,
      ),
    );
  }
}

// ── Add / Edit Sheet ───────────────────────────────────────────────────────────

class _AddBudgetSheet extends StatefulWidget {
  const _AddBudgetSheet({required this.month, this.editing});

  final DateTime month;
  final BudgetModel? editing;

  @override
  State<_AddBudgetSheet> createState() => _AddBudgetSheetState();
}

class _AddBudgetSheetState extends State<_AddBudgetSheet> {
  late MoneyTransactionType _type;
  String? _categoryId;
  final _amountCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    final e = widget.editing;
    _type = e?.type ?? MoneyTransactionType.expense;
    _categoryId = e?.categoryId;
    if (e != null) {
      _amountCtrl.text = CurrencyInputFormatter.formatVal(e.targetAmount);
    }
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  int get _parsedAmount {
    final clean = _amountCtrl.text.replaceAll('.', '');
    return int.tryParse(clean) ?? 0;
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_parsedAmount <= 0) return;

    final appState = context.appState;
    final monthYear = BudgetModel.monthYearOf(widget.month);

    if (widget.editing != null) {
      await appState.updateBudget(
        widget.editing!.copyWith(
          type: _type,
          categoryId: _categoryId,
          clearCategory: _categoryId == null,
          targetAmount: _parsedAmount,
        ),
      );
    } else {
      await appState.addBudget(BudgetModel(
        id: 'budget_${DateTime.now().microsecondsSinceEpoch}',
        type: _type,
        categoryId: _categoryId,
        targetAmount: _parsedAmount,
        monthYear: monthYear,
        createdAt: DateTime.now(),
      ));
    }

    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final categories = context.appState.categoriesFor(_type);
    final isEditing = widget.editing != null;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: context.appColors.card,
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: Form(
            key: _formKey,
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              children: [
                // Handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: context.appColors.outline,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  context.t(isEditing ? 'budget.editTitle' : 'budget.addTitle'),
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 20),

                // Type toggle
                Container(
                  decoration: BoxDecoration(
                    color: context.appColors.cardSoft,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      _TypeTab(
                        label: context.t('budget.typeIncome'),
                        selected: _type == MoneyTransactionType.income,
                        onTap: () => setState(() {
                          _type = MoneyTransactionType.income;
                          _categoryId = null;
                        }),
                      ),
                      _TypeTab(
                        label: context.t('budget.typeExpense'),
                        selected: _type == MoneyTransactionType.expense,
                        onTap: () => setState(() {
                          _type = MoneyTransactionType.expense;
                          _categoryId = null;
                        }),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Category picker — key forces rebuild when type changes
                DropdownButtonFormField<String?>(
                  key: ValueKey(_type),
                  initialValue: _categoryId,
                  decoration: InputDecoration(
                    labelText: context.t('budget.category'),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: [
                    DropdownMenuItem<String?>(
                      value: null,
                      child: Text(context.t(
                        _type == MoneyTransactionType.income
                            ? 'budget.allIncome'
                            : 'budget.allExpense',
                      )),
                    ),
                    ...categories.map((c) => DropdownMenuItem<String?>(
                          value: c.id,
                          child: Text(c.name),
                        )),
                  ],
                  onChanged: (v) => setState(() => _categoryId = v),
                ),
                const SizedBox(height: 16),

                // Amount input
                TextFormField(
                  controller: _amountCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    CurrencyInputFormatter(),
                  ],
                  decoration: InputDecoration(
                    labelText: context.t('budget.amountLabel'),
                    prefixText: 'Rp ',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) {
                      return context.t('budget.amountRequired');
                    }
                    if (_parsedAmount <= 0) {
                      return context.t('budget.amountRequired');
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.brandBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      context.t(isEditing ? 'budget.saveEdit' : 'budget.save'),
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TypeTab extends StatelessWidget {
  const _TypeTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          margin: const EdgeInsets.all(4),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? AppColors.brandBlue : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13,
              color: selected ? Colors.white : context.appColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
