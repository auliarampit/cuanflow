import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';

import '../../core/formatters/currency_input_formatter.dart';
import '../../core/formatters/idr_formatter.dart';
import '../../core/localization/transalation_extansions.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dynamic_colors.dart';

class ManageWalletsScreen extends StatelessWidget {
  const ManageWalletsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final wallets = context.appState.wallets;

    return Scaffold(
      appBar: AppBar(
        title: Text(context.t('wallet.manage.title')),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: context.t('wallet.add.button'),
            onPressed: () => _showForm(context, null),
          ),
        ],
      ),
      body: wallets.isEmpty
          ? _EmptyState(onAdd: () => _showForm(context, null))
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
              children: [
                _TotalBalanceCard(),
                const SizedBox(height: 12),
                for (final wallet in wallets) ...[
                  _WalletCard(
                    wallet: wallet,
                    balance: context.appState.balanceFor(wallet.id),
                    onEdit: () => _showForm(context, wallet),
                    onDelete: () => _confirmDelete(context, wallet),
                  ),
                  const SizedBox(height: 10),
                ],
              ],
            ),
      floatingActionButton: wallets.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: () => _showForm(context, null),
              icon: const Icon(Icons.add),
              label: Text(context.t('wallet.add.button')),
              backgroundColor: AppColors.brandBlue,
              foregroundColor: Colors.white,
            )
          : null,
    );
  }

  void _showForm(BuildContext context, WalletModel? existing) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.appColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _WalletForm(existing: existing),
    );
  }

  void _confirmDelete(BuildContext context, WalletModel wallet) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.t('wallet.delete.title')),
        content: Text(context.t('wallet.delete.content')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(context.t('common.cancel')),
          ),
          TextButton(
            onPressed: () {
              context.appState.deleteWallet(wallet.id);
              Navigator.pop(ctx);
            },
            child: Text(
              context.t('wallet.delete.title'),
              style: const TextStyle(color: AppColors.negative),
            ),
          ),
        ],
      ),
    );
  }
}

class _TotalBalanceCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final total = context.appState.totalBalance;
    final isNeg = total < 0;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isNeg
              ? [AppColors.negative.withValues(alpha: 0.8), AppColors.negative.withValues(alpha: 0.5)]
              : [AppColors.brandBlue.withValues(alpha: 0.8), AppColors.brandBlue.withValues(alpha: 0.5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.t('wallet.totalBalance'),
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 6),
          Text(
            IdrFormatter.format(total),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

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
            Icon(Icons.account_balance_wallet_outlined,
                size: 64, color: context.appColors.textSecondary),
            const SizedBox(height: 16),
            Text(
              context.t('wallet.empty'),
              textAlign: TextAlign.center,
              style: TextStyle(color: context.appColors.textSecondary),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: Text(context.t('wallet.add.button')),
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

class _WalletCard extends StatelessWidget {
  const _WalletCard({
    required this.wallet,
    required this.balance,
    required this.onEdit,
    required this.onDelete,
  });

  final WalletModel wallet;
  final int balance;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  IconData get _typeIcon {
    switch (wallet.type) {
      case WalletType.bank:
        return Icons.account_balance_outlined;
      case WalletType.ewallet:
        return Icons.phone_android_outlined;
      case WalletType.cash:
        return Icons.payments_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isNeg = balance < 0;
    final balColor = isNeg ? AppColors.negative : AppColors.positive;

    return Container(
      decoration: BoxDecoration(
        color: context.appColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.appColors.outline),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.brandBlue.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(_typeIcon, color: AppColors.brandBlue),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        wallet.name,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      if (wallet.isDefault) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.brandBlue.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Default',
                            style: TextStyle(
                              fontSize: 10,
                              color: AppColors.brandBlue,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  Text(
                    wallet.type.displayName,
                    style: TextStyle(
                        fontSize: 12, color: context.appColors.textSecondary),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  IdrFormatter.format(balance),
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    color: balColor,
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      onPressed: onEdit,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      color: context.appColors.textSecondary,
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 18),
                      onPressed: onDelete,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      color: AppColors.negative,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _WalletForm extends StatefulWidget {
  const _WalletForm({this.existing});
  final WalletModel? existing;

  @override
  State<_WalletForm> createState() => _WalletFormState();
}

class _WalletFormState extends State<_WalletForm> {
  final _nameController = TextEditingController();
  final _balanceController = TextEditingController();
  WalletType _type = WalletType.cash;
  bool _isDefault = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      final w = widget.existing!;
      _nameController.text = w.name;
      _balanceController.text = CurrencyInputFormatter.formatVal(w.initialBalance);
      _type = w.type;
      _isDefault = w.isDefault;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _balanceController.dispose();
    super.dispose();
  }

  void _save() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    final balance = int.tryParse(_balanceController.text.replaceAll('.', '')) ?? 0;
    final appState = context.appState;

    if (_isEdit) {
      appState.updateWallet(widget.existing!.copyWith(
        name: name,
        type: _type,
        initialBalance: balance,
        isDefault: _isDefault,
      ));
    } else {
      appState.addWallet(WalletModel(
        id: const Uuid().v4(),
        name: name,
        type: _type,
        initialBalance: balance,
        isDefault: _isDefault || appState.wallets.isEmpty,
        createdAt: DateTime.now(),
      ));
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _isEdit ? context.t('wallet.edit.title') : context.t('wallet.add.title'),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: context.t('wallet.nameLabel'),
              hintText: context.t('wallet.nameHint'),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _balanceController,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              CurrencyInputFormatter(),
            ],
            decoration: InputDecoration(
              labelText: context.t('wallet.initialBalanceLabel'),
              hintText: context.t('wallet.initialBalanceHint'),
              prefixText: 'Rp ',
            ),
          ),
          const SizedBox(height: 14),
          Text(context.t('wallet.typeLabel'),
              style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: WalletType.values.map((t) {
              final selected = _type == t;
              return ChoiceChip(
                label: Text(t.displayName),
                selected: selected,
                onSelected: (_) => setState(() => _type = t),
                selectedColor: AppColors.brandBlue.withValues(alpha: 0.2),
                labelStyle: TextStyle(
                  color: selected ? AppColors.brandBlue : null,
                  fontWeight: selected ? FontWeight.w700 : null,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 10),
          SwitchListTile(
            value: _isDefault,
            onChanged: (v) => setState(() => _isDefault = v),
            title: Text(context.t('wallet.isDefaultLabel')),
            contentPadding: EdgeInsets.zero,
            activeThumbColor: AppColors.brandBlue,
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brandBlue,
                foregroundColor: Colors.white,
              ),
              child: Text(context.t('wallet.save')),
            ),
          ),
        ],
      ),
    );
  }
}
