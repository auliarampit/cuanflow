import 'package:flutter/material.dart';

import '../../core/formatters/idr_formatter.dart';
import '../../core/models/money_transaction.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/app_dynamic_colors.dart';

class RecentTransactionItem {
  const RecentTransactionItem({
    required this.category,
    required this.amount,
    required this.count,
    this.note,
    this.outletId,
    this.walletId,
  });

  final String category;
  final int amount;
  final int count;
  final String? note;
  final String? outletId;
  final String? walletId;
}

/// Hitung [limit] item paling sering diinput dari riwayat, difilter berdasarkan [type].
List<RecentTransactionItem> computeRecentItems(
  List<MoneyTransaction> transactions,
  MoneyTransactionType type, {
  int limit = 5,
}) {
  final relevant = transactions.where(
    (tx) => tx.type == type && tx.category != null && tx.category!.isNotEmpty,
  );

  // Group by (category, amount) — key pakai separator yang tidak mungkin ada di nama kategori
  final Map<
    String,
    ({
      int count,
      DateTime lastUsed,
      String? note,
      String? outletId,
      String? walletId,
    })
  > groups = {};

  for (final tx in relevant) {
    final key = '${tx.category}\x00${tx.amount}';
    final existing = groups[key];
    if (existing == null) {
      groups[key] = (
        count: 1,
        lastUsed: tx.createdAt,
        note: tx.note,
        outletId: tx.outletId,
        walletId: tx.walletId,
      );
    } else if (tx.createdAt.isAfter(existing.lastUsed)) {
      groups[key] = (
        count: existing.count + 1,
        lastUsed: tx.createdAt,
        note: tx.note,
        outletId: tx.outletId,
        walletId: tx.walletId,
      );
    } else {
      groups[key] = (
        count: existing.count + 1,
        lastUsed: existing.lastUsed,
        note: existing.note,
        outletId: existing.outletId,
        walletId: existing.walletId,
      );
    }
  }

  final sorted = groups.entries.toList()
    ..sort((a, b) {
      final byCount = b.value.count.compareTo(a.value.count);
      if (byCount != 0) return byCount;
      return b.value.lastUsed.compareTo(a.value.lastUsed);
    });

  return sorted.take(limit).map((e) {
    final sep = e.key.indexOf('\x00');
    return RecentTransactionItem(
      category: e.key.substring(0, sep),
      amount: int.parse(e.key.substring(sep + 1)),
      count: e.value.count,
      note: e.value.note,
      outletId: e.value.outletId,
      walletId: e.value.walletId,
    );
  }).toList();
}

/// Bar horizontal berisi chip item yang sering diinput.
/// Muncul di atas form, tap satu chip → form terisi otomatis.
class RecentItemsBar extends StatelessWidget {
  const RecentItemsBar({
    super.key,
    required this.type,
    required this.accentColor,
    required this.onSelect,
  });

  final MoneyTransactionType type;
  final Color accentColor;
  final void Function(RecentTransactionItem item) onSelect;

  @override
  Widget build(BuildContext context) {
    final items = computeRecentItems(context.appState.allTransactions, type);
    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'SERING DIINPUT',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.4,
            color: context.appColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (int i = 0; i < items.length; i++) ...[
                if (i > 0) const SizedBox(width: 8),
                _RecentChip(
                  item: items[i],
                  accentColor: accentColor,
                  onTap: () => onSelect(items[i]),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 4),
      ],
    );
  }
}

class _RecentChip extends StatelessWidget {
  const _RecentChip({
    required this.item,
    required this.accentColor,
    required this.onTap,
  });

  final RecentTransactionItem item;
  final Color accentColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: accentColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: accentColor.withValues(alpha: 0.28)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              IdrFormatter.format(item.amount),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: accentColor,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              item.category,
              style: TextStyle(
                fontSize: 11,
                color: context.appColors.textSecondary,
              ),
            ),
            if (item.note != null && item.note!.isNotEmpty) ...[
              const SizedBox(height: 1),
              Text(
                item.note!,
                style: TextStyle(
                  fontSize: 10,
                  color: context.appColors.textSecondary.withValues(alpha: 0.7),
                  fontStyle: FontStyle.italic,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
