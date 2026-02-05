import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/localization/transalation_extansions.dart';
import '../../core/models/money_transaction.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/app_colors.dart';
import '../../core/ui/app_gradient_scaffold.dart';
import '../../shared/widgets/loading_dialog.dart';
import '../transactions/add_expense/add_expense_screen.dart';
import '../transactions/add_income/add_income_screen.dart';
import 'widgets/history_filter_sheet.dart';
import 'widgets/history_summary_card.dart';
import 'widgets/history_transaction_group.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  HistoryFilter _selectedFilter = HistoryFilter.thisWeek;
  DateTimeRange? _customRange;

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => HistoryFilterSheet(
        selectedFilter: _selectedFilter,
        onSelect: (filter) async {
          if (filter == HistoryFilter.custom) {
            final picked = await showDateRangePicker(
              context: context,
              firstDate: DateTime(2020),
              lastDate: DateTime.now(),
              builder: (context, child) {
                return Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: const ColorScheme.dark(
                      primary: AppColors.brandBlue,
                      onPrimary: Colors.white,
                      surface: AppColors.card,
                      onSurface: Colors.white,
                    ),
                  ),
                  child: child!,
                );
              },
            );
            if (picked != null) {
              setState(() {
                _customRange = picked;
                _selectedFilter = filter;
              });
              Navigator.pop(context);
            }
          } else {
            setState(() => _selectedFilter = filter);
            Navigator.pop(context);
          }
        },
      ),
    );
  }

  List<MoneyTransaction> _getFilteredTransactions() {
    final allTxs = context.appState.transactions;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    DateTime start;
    DateTime end;

    switch (_selectedFilter) {
      case HistoryFilter.today:
        start = today;
        end = today.add(const Duration(days: 1));
        break;
      case HistoryFilter.yesterday:
        start = today.subtract(const Duration(days: 1));
        end = today;
        break;
      case HistoryFilter.thisWeek:
        // Assuming Monday start
        start = today.subtract(Duration(days: today.weekday - 1));
        end = start.add(const Duration(days: 7));
        break;
      case HistoryFilter.lastWeek:
        final thisMonday = today.subtract(Duration(days: today.weekday - 1));
        start = thisMonday.subtract(const Duration(days: 7));
        end = thisMonday;
        break;
      case HistoryFilter.thisMonth:
        start = DateTime(today.year, today.month, 1);
        end = DateTime(today.year, today.month + 1, 1);
        break;
      case HistoryFilter.lastMonth:
        start = DateTime(today.year, today.month - 1, 1);
        end = DateTime(today.year, today.month, 1);
        break;
      case HistoryFilter.custom:
        if (_customRange == null) return [];
        start = _customRange!.start;
        end = _customRange!.end.add(const Duration(days: 1)); // Include end date
        break;
    }

    return allTxs.where((tx) {
      final txDate = tx.effectiveDate;
      return txDate.isAfter(start.subtract(const Duration(seconds: 1))) && 
             txDate.isBefore(end);
    }).toList();
  }

  void _showActionModal(MoneyTransaction item) {
    final isIncome = item.isIncome;
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.edit, color: AppColors.brandBlue),
                title: Text(context.t('history.menu.edit')),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => isIncome
                          ? AddIncomeScreen(transaction: item)
                          : AddExpenseScreen(transaction: item),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: AppColors.negative),
                title: Text(context.t('history.menu.delete')),
                onTap: () {
                  Navigator.pop(context);
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text(context.t('history.delete.title')),
                      content: Text(context.t('history.delete.confirmation')),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(context.t('common.cancel')),
                        ),
                        TextButton(
                          onPressed: () async {
                            Navigator.pop(context);
                            LoadingDialog.show(context);
                            await context.appState.deleteTransaction(item.id);
                            if (context.mounted) {
                              LoadingDialog.hide(context);
                            }
                          },
                          child: Text(
                            context.t('history.menu.delete'),
                            style: const TextStyle(color: AppColors.negative),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  String _getFilterLabel() {
    if (_selectedFilter == HistoryFilter.custom && _customRange != null) {
      final start = DateFormat('d MMM', 'id_ID').format(_customRange!.start);
      final end = DateFormat('d MMM', 'id_ID').format(_customRange!.end);
      return '$start - $end';
    }
    return context.t(_selectedFilter.labelKey);
  }

  @override
  Widget build(BuildContext context) {
    final filteredTxs = _getFilteredTransactions();
    
    // Calculate totals
    int totalIncome = 0;
    int totalExpense = 0;
    for (final tx in filteredTxs) {
      if (tx.isIncome) {
        totalIncome += tx.amount;
      } else {
        totalExpense += tx.amount;
      }
    }
    final totalProfit = totalIncome - totalExpense;

    // Group by date
    final grouped = groupBy(filteredTxs, (MoneyTransaction tx) {
      final date = tx.effectiveDate;
      return DateTime(date.year, date.month, date.day);
    });
    
    // Sort groups by date descending
    final sortedDates = grouped.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    return AppGradientScaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          context.t('history.title'),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
        ),
      ),
      body: Column(
        children: [
          // Filter Button
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
            child: InkWell(
              onTap: _showFilterSheet,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.cardSoft,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.outline),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 20, color: Colors.white),
                    const SizedBox(width: 12),
                    Text(
                      _getFilterLabel(),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.white,
                      ),
                    ),
                    const Spacer(),
                    const Icon(Icons.keyboard_arrow_down, color: AppColors.textSecondary),
                  ],
                ),
              ),
            ),
          ),

          // List
          Expanded(
            child: filteredTxs.isEmpty
                ? Center(
                    child: Text(
                      context.t('history.empty'),
                      style: TextStyle(color: AppColors.textSecondary.withOpacity(0.5)),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: sortedDates.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 24),
                    itemBuilder: (context, index) {
                      final date = sortedDates[index];
                      final txs = grouped[date]!;
                      return HistoryTransactionGroup(
                        date: date,
                        transactions: txs,
                        onItemTap: _showActionModal,
                      );
                    },
                  ),
          ),

          // Bottom Summary
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: AppColors.backgroundBottom,
              border: Border(top: BorderSide(color: AppColors.outline)),
            ),
            child: SafeArea(
              child: HistorySummaryCard(
                totalProfit: totalProfit,
                percentageChange: null, // To implement percentage change, we need previous period data
              ),
            ),
          ),
        ],
      ),
    );
  }
}
