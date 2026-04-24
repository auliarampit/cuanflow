import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';

import '../../core/formatters/currency_input_formatter.dart';
import '../../core/formatters/idr_formatter.dart';
import '../../core/localization/transalation_extansions.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dynamic_colors.dart';

class DebtScreen extends StatefulWidget {
  const DebtScreen({super.key});

  @override
  State<DebtScreen> createState() => _DebtScreenState();
}

class _DebtScreenState extends State<DebtScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final debts = context.appState.debts;
    final iOweDebts = debts.where((d) => d.type == DebtType.iOwe).toList();
    final theyOweDebts =
        debts.where((d) => d.type == DebtType.theyOwe).toList();
    final totalIOwe = context.appState.totalDebt(DebtType.iOwe);
    final totalTheyOwe = context.appState.totalDebt(DebtType.theyOwe);

    return Scaffold(
      appBar: AppBar(
        title: Text(context.t('debt.manage.title')),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showForm(context, null),
          ),
        ],
        bottom: TabBar(
          controller: _tab,
          tabs: [
            Tab(text: context.t('debt.tab.iOwe')),
            Tab(text: context.t('debt.tab.theyOwe')),
          ],
          labelColor: AppColors.negative,
          indicatorColor: AppColors.negative,
        ),
      ),
      body: Column(
        children: [
          _SummaryRow(totalIOwe: totalIOwe, totalTheyOwe: totalTheyOwe),
          Expanded(
            child: TabBarView(
              controller: _tab,
              children: [
                _DebtList(
                  debts: iOweDebts,
                  emptyKey: 'debt.empty.iOwe',
                  onAdd: () => _showForm(context, null),
                ),
                _DebtList(
                  debts: theyOweDebts,
                  emptyKey: 'debt.empty.theyOwe',
                  onAdd: () => _showForm(context, null),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showForm(context, null),
        backgroundColor: AppColors.brandBlue,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showForm(BuildContext context, DebtModel? existing) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.appColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _DebtForm(existing: existing),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.totalIOwe, required this.totalTheyOwe});
  final int totalIOwe;
  final int totalTheyOwe;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: context.appColors.cardSoft,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: _SummaryChip(
              label: context.t('debt.totalIOwe'),
              amount: totalIOwe,
              color: AppColors.negative,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _SummaryChip(
              label: context.t('debt.totalTheyOwe'),
              amount: totalTheyOwe,
              color: AppColors.positive,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({
    required this.label,
    required this.amount,
    required this.color,
  });
  final String label;
  final int amount;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 11,
                  color: context.appColors.textSecondary,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(
            IdrFormatter.format(amount),
            style: TextStyle(
                fontWeight: FontWeight.w800, color: color, fontSize: 15),
          ),
        ],
      ),
    );
  }
}

class _DebtList extends StatelessWidget {
  const _DebtList({
    required this.debts,
    required this.emptyKey,
    required this.onAdd,
  });
  final List<DebtModel> debts;
  final String emptyKey;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    if (debts.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.handshake_outlined,
                  size: 56, color: context.appColors.textSecondary),
              const SizedBox(height: 12),
              Text(
                context.t(emptyKey),
                textAlign: TextAlign.center,
                style: TextStyle(color: context.appColors.textSecondary),
              ),
            ],
          ),
        ),
      );
    }

    final unpaid = debts.where((d) => !d.isPaid).toList();
    final paid = debts.where((d) => d.isPaid).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
      children: [
        for (final d in unpaid) ...[
          _DebtCard(debt: d),
          const SizedBox(height: 8),
        ],
        if (paid.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              context.t('debt.paid'),
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 12,
                letterSpacing: 1.5,
                color: context.appColors.textSecondary,
              ),
            ),
          ),
          for (final d in paid) ...[
            _DebtCard(debt: d),
            const SizedBox(height: 8),
          ],
        ],
      ],
    );
  }
}

class _DebtCard extends StatelessWidget {
  const _DebtCard({required this.debt});
  final DebtModel debt;

  String _formatDate(DateTime d) =>
      '${d.day}/${d.month}/${d.year}';

  @override
  Widget build(BuildContext context) {
    final isIOwe = debt.type == DebtType.iOwe;
    final accentColor = isIOwe ? AppColors.negative : AppColors.positive;

    return Container(
      decoration: BoxDecoration(
        color: context.appColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: debt.isOverdue
              ? AppColors.negative.withValues(alpha: 0.6)
              : context.appColors.outline,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isIOwe ? Icons.arrow_upward : Icons.arrow_downward,
                color: accentColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    debt.personName,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      decoration: debt.isPaid
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                  ),
                  if (debt.notes != null && debt.notes!.isNotEmpty)
                    Text(
                      debt.notes!,
                      style: TextStyle(
                          fontSize: 12,
                          color: context.appColors.textSecondary),
                    ),
                  if (debt.dueDate != null)
                    Row(
                      children: [
                        Icon(
                          Icons.schedule_outlined,
                          size: 12,
                          color: debt.isOverdue
                              ? AppColors.negative
                              : context.appColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatDate(debt.dueDate!),
                          style: TextStyle(
                            fontSize: 12,
                            color: debt.isOverdue
                                ? AppColors.negative
                                : context.appColors.textSecondary,
                            fontWeight: debt.isOverdue
                                ? FontWeight.w700
                                : null,
                          ),
                        ),
                        if (debt.isOverdue) ...[
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: AppColors.negative.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              context.t('debt.overdue'),
                              style: const TextStyle(
                                  fontSize: 10,
                                  color: AppColors.negative,
                                  fontWeight: FontWeight.w700),
                            ),
                          ),
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
                  IdrFormatter.format(debt.amount),
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: debt.isPaid
                        ? context.appColors.textSecondary
                        : accentColor,
                    decoration:
                        debt.isPaid ? TextDecoration.lineThrough : null,
                  ),
                ),
                const SizedBox(height: 4),
                _DebtActions(debt: debt),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DebtActions extends StatelessWidget {
  const _DebtActions({required this.debt});
  final DebtModel debt;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: Icon(Icons.more_horiz, size: 18, color: context.appColors.textSecondary),
      padding: EdgeInsets.zero,
      itemBuilder: (_) => [
        PopupMenuItem(
          value: 'toggle',
          child: Text(
            debt.isPaid
                ? context.t('debt.markUnpaid')
                : context.t('debt.markPaid'),
          ),
        ),
        PopupMenuItem(
          value: 'edit',
          child: Text(context.t('history.menu.edit')),
        ),
        PopupMenuItem(
          value: 'delete',
          child: Text(
            context.t('history.menu.delete'),
            style: const TextStyle(color: AppColors.negative),
          ),
        ),
      ],
      onSelected: (action) {
        final appState = context.appState;
        switch (action) {
          case 'toggle':
            appState.updateDebt(debt.copyWith(isPaid: !debt.isPaid));
          case 'edit':
            showModalBottomSheet<void>(
              context: context,
              isScrollControlled: true,
              backgroundColor: context.appColors.card,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              builder: (ctx) => _DebtForm(existing: debt),
            );
          case 'delete':
            showDialog<void>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: Text(context.t('debt.delete.title')),
                content: Text(context.t('debt.delete.content')),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: Text(context.t('common.cancel')),
                  ),
                  TextButton(
                    onPressed: () {
                      appState.deleteDebt(debt.id);
                      Navigator.pop(ctx);
                    },
                    child: Text(
                      context.t('history.menu.delete'),
                      style: const TextStyle(color: AppColors.negative),
                    ),
                  ),
                ],
              ),
            );
        }
      },
    );
  }
}

class _DebtForm extends StatefulWidget {
  const _DebtForm({this.existing});
  final DebtModel? existing;

  @override
  State<_DebtForm> createState() => _DebtFormState();
}

class _DebtFormState extends State<_DebtForm> {
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  DebtType _type = DebtType.iOwe;
  DateTime? _dueDate;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      final d = widget.existing!;
      _nameController.text = d.personName;
      _amountController.text = CurrencyInputFormatter.formatVal(d.amount);
      _notesController.text = d.notes ?? '';
      _type = d.type;
      _dueDate = d.dueDate;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _save() {
    final name = _nameController.text.trim();
    final amount =
        int.tryParse(_amountController.text.replaceAll('.', '')) ?? 0;
    if (name.isEmpty || amount <= 0) return;

    final appState = context.appState;
    final notes = _notesController.text.trim().isEmpty
        ? null
        : _notesController.text.trim();

    if (_isEdit) {
      appState.updateDebt(widget.existing!.copyWith(
        personName: name,
        amount: amount,
        type: _type,
        notes: notes,
        dueDate: _dueDate,
        clearDueDate: _dueDate == null,
      ));
    } else {
      appState.addDebt(DebtModel(
        id: const Uuid().v4(),
        personName: name,
        amount: amount,
        type: _type,
        isPaid: false,
        createdAt: DateTime.now(),
        notes: notes,
        dueDate: _dueDate,
      ));
    }
    Navigator.pop(context);
  }

  String _formatDate(DateTime d) => '${d.day}/${d.month}/${d.year}';

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _isEdit
                  ? context.t('debt.edit.title')
                  : context.t('debt.add.title'),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 16),
            Text(context.t('debt.typeLabel'),
                style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _TypeChip(
                    label: context.t('debt.type.iOwe'),
                    selected: _type == DebtType.iOwe,
                    color: AppColors.negative,
                    onTap: () => setState(() => _type = DebtType.iOwe),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _TypeChip(
                    label: context.t('debt.type.theyOwe'),
                    selected: _type == DebtType.theyOwe,
                    color: AppColors.positive,
                    onTap: () => setState(() => _type = DebtType.theyOwe),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: context.t('debt.personNameLabel'),
                hintText: context.t('debt.personNameHint'),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                CurrencyInputFormatter(),
              ],
              decoration: InputDecoration(
                labelText: context.t('debt.amountLabel'),
                prefixText: 'Rp ',
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _notesController,
              decoration: InputDecoration(
                labelText: context.t('debt.notesLabel'),
                hintText: context.t('debt.notesHint'),
              ),
            ),
            const SizedBox(height: 14),
            InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _dueDate ?? DateTime.now(),
                  firstDate: DateTime.now(),
                  lastDate: DateTime(2100),
                );
                if (picked != null) setState(() => _dueDate = picked);
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                decoration: BoxDecoration(
                  color: context.appColors.cardSoft,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: context.appColors.outline),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today_outlined,
                        color: context.appColors.textSecondary, size: 18),
                    const SizedBox(width: 10),
                    Text(
                      _dueDate != null
                          ? _formatDate(_dueDate!)
                          : context.t('debt.dueDateLabel'),
                      style: TextStyle(
                        color: _dueDate != null
                            ? null
                            : context.appColors.textSecondary,
                      ),
                    ),
                    const Spacer(),
                    if (_dueDate != null)
                      GestureDetector(
                        onTap: () => setState(() => _dueDate = null),
                        child: Icon(Icons.close,
                            size: 16,
                            color: context.appColors.textSecondary),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brandBlue,
                  foregroundColor: Colors.white,
                ),
                child: Text(context.t('debt.save')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  const _TypeChip({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.15) : context.appColors.cardSoft,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? color : context.appColors.outline,
            width: selected ? 1.5 : 1,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: selected ? color : context.appColors.textSecondary,
            fontWeight: selected ? FontWeight.w700 : null,
            fontSize: 13,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
