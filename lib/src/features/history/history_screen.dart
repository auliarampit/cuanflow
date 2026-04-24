import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/localization/transalation_extansions.dart';
import '../../core/models/money_transaction.dart';
import '../../core/models/outlet_model.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dynamic_colors.dart';
import '../../core/ui/app_gradient_scaffold.dart';
import '../../core/utils/pdf_exporter.dart';
import '../../shared/widgets/loading_dialog.dart';
import '../../shared/widgets/native_ad_card.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart' show TemplateType;
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
  HistoryFilter _selectedFilter = HistoryFilter.today;
  DateTimeRange? _customRange;
  String? _selectedOutletFilter; // null = semua outlet

  void _showFilterSheet() {
    // Simpan screen context sebelum masuk builder — hindari shadowing
    final screenCtx = context;

    showModalBottomSheet(
      context: screenCtx,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetCtx) => HistoryFilterSheet(
        selectedFilter: _selectedFilter,
        onSelect: (filter) async {
          if (filter == HistoryFilter.custom) {
            // Tutup sheet DULU, baru buka date picker dengan screen context.
            // Memanggil showDateRangePicker dari overlay sheet menyebabkan
            // layar putih di release APK karena conflict overlay stack.
            Navigator.pop(sheetCtx);
            final picked = await showDateRangePicker(
              context: screenCtx,
              firstDate: DateTime(2020),
              lastDate: DateTime.now(),
              builder: (ctx, child) => Theme(
                data: Theme.of(ctx).copyWith(
                  colorScheme: const ColorScheme.dark(
                    primary: AppColors.brandBlue,
                    onPrimary: Colors.white,
                    surface: AppColors.card,
                    onSurface: Colors.white,
                  ),
                ),
                child: child!,
              ),
            );
            if (picked != null && mounted) {
              setState(() {
                _customRange = picked;
                _selectedFilter = filter;
              });
            }
          } else {
            if (mounted) setState(() => _selectedFilter = filter);
            Navigator.pop(sheetCtx);
          }
        },
      ),
    );
  }

  List<MoneyTransaction> _getFilteredTransactions() {
    // Gunakan allTransactions agar filter outlet di history bersifat lokal
    // (tidak tergantung pada outlet yang dipilih di home)
    final base = context.appState.allTransactions;
    final allTxs = _selectedOutletFilter == null
        ? base
        : base.where((t) => t.outletId == _selectedOutletFilter).toList();
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
        end = _customRange!.end.add(
          const Duration(days: 1),
        ); // Include end date
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
    // Simpan context screen sebelum di-shadow oleh builder-builder di bawah
    final screenContext = context;
    showModalBottomSheet(
      context: screenContext,
      backgroundColor: screenContext.appColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.edit, color: AppColors.brandBlue),
                title: Text(sheetContext.t('history.menu.edit')),
                onTap: () {
                  Navigator.pop(sheetContext);
                  Navigator.push(
                    screenContext,
                    MaterialPageRoute(
                      builder: (_) => isIncome
                          ? AddIncomeScreen(transaction: item)
                          : AddExpenseScreen(transaction: item),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: AppColors.negative),
                title: Text(sheetContext.t('history.menu.delete')),
                onTap: () {
                  Navigator.pop(sheetContext);
                  showDialog(
                    context: screenContext,
                    builder: (dialogContext) => AlertDialog(
                      title: Text(dialogContext.t('history.delete.title')),
                      content: Text(
                        dialogContext.t('history.delete.confirmation'),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(dialogContext),
                          child: Text(dialogContext.t('common.cancel')),
                        ),
                        TextButton(
                          onPressed: () async {
                            Navigator.pop(dialogContext);
                            if (!screenContext.mounted) return;
                            LoadingDialog.show(screenContext);
                            await screenContext.appState.deleteTransaction(
                              item.id,
                            );
                            if (screenContext.mounted) {
                              LoadingDialog.hide(screenContext);
                            }
                          },
                          child: Text(
                            dialogContext.t('history.menu.delete'),
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

  Future<void> _exportPdf() async {
    final txs = _getFilteredTransactions();
    if (txs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.t('history.exportPdfEmpty')),
          backgroundColor: AppColors.negative,
        ),
      );
      return;
    }
    LoadingDialog.show(context);
    try {
      await PdfExporter.exportHistory(
        transactions: txs,
        profile: context.appState.profile,
        periodLabel: _getFilterLabel(),
        outlets: context.appState.outlets,
        selectedOutletId: _selectedOutletFilter,
      );
    } finally {
      if (mounted) LoadingDialog.hide(context);
    }
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
    final sortedDates = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    return AppGradientScaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Column(
          children: [
            Text(
              context.t('history.title'),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            if (context.appState.selectedOutlet != null)
              Text(
                context.appState.selectedOutlet!.name,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.brandBlue,
                  fontWeight: FontWeight.w500,
                ),
              ),
          ],
        ),
        centerTitle: true,
        leading: Navigator.of(context).canPop()
            ? IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back_ios_new, size: 20),
              )
            : null,
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_outlined),
            tooltip: context.t('history.exportPdf'),
            onPressed: _exportPdf,
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter: tanggal (baris 1) + outlet (baris 2, jika relevan)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: Column(
              children: [
                // Baris 1 — filter tanggal (full width)
                InkWell(
                  onTap: _showFilterSheet,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    height: 46,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: context.appColors.cardSoft,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: context.appColors.outline),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 16,
                          color: context.appColors.textSecondary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _getFilterLabel(),
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              color: context.appColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Icon(
                          Icons.keyboard_arrow_down,
                          size: 18,
                          color: context.appColors.textSecondary,
                        ),
                      ],
                    ),
                  ),
                ),

                // Baris 2 — filter outlet (hanya jika fitur outlet aktif & ada ≥2 outlet)
                if (context.appState.profile.featureOutlets &&
                    context.appState.outlets.length >= 2) ...[
                  const SizedBox(height: 8),
                  _OutletDropdown(
                    outlets: context.appState.outlets,
                    selectedOutletId: _selectedOutletFilter,
                    allLabel: context.t('history.allOutlets'),
                    onSelect: (id) =>
                        setState(() => _selectedOutletFilter = id),
                  ),
                ],
              ],
            ),
          ),

          // List
          Expanded(
            child: filteredTxs.isEmpty
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: _HistoryAdCard(),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        context.t('history.empty'),
                        style: TextStyle(
                          color: context.appColors.textSecondary.withValues(
                            alpha: 0.5,
                          ),
                        ),
                      ),
                    ],
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: sortedDates.length > 2
                        ? sortedDates.length + 1
                        : sortedDates.length,
                    separatorBuilder: (_, i) => const SizedBox(height: 24),
                    itemBuilder: (context, index) {
                      if (sortedDates.length > 2 && index == 3) {
                        return _HistoryAdCard();
                      }
                      final dataIndex = sortedDates.length > 2 && index > 3
                          ? index - 1
                          : index;
                      final date = sortedDates[dataIndex];
                      final txs = grouped[date]!;
                      return HistoryTransactionGroup(
                        date: date,
                        transactions: txs,
                        onItemTap: _showActionModal,
                      );
                    },
                  ),
          ),

          // Bottom summary
          Container(
            decoration: BoxDecoration(
              color: context.appColors.backgroundBottom,
              border: Border(top: BorderSide(color: context.appColors.outline)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: SafeArea(
                    child: HistorySummaryCard(
                      totalIncome: totalIncome,
                      totalExpense: totalExpense,
                      totalProfit: totalProfit,
                      isBusinessMode: context.appState.profile.isBusinessMode,
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
}

// ── Outlet dropdown button ────────────────────────────────────────────────────

class _OutletDropdown extends StatelessWidget {
  const _OutletDropdown({
    required this.outlets,
    required this.selectedOutletId,
    required this.allLabel,
    required this.onSelect,
  });

  final List<OutletModel> outlets;
  final String? selectedOutletId;
  final String allLabel;
  final ValueChanged<String?> onSelect;

  String _currentLabel() {
    if (selectedOutletId == null) return allLabel;
    return outlets.firstWhereOrNull((o) => o.id == selectedOutletId)?.name ??
        allLabel;
  }

  @override
  Widget build(BuildContext context) {
    final label = _currentLabel();
    final isFiltered = selectedOutletId != null;

    return PopupMenuButton<String?>(
      onSelected: (value) => onSelect(value == '__all__' ? null : value),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: context.appColors.card,
      itemBuilder: (_) => [
        PopupMenuItem<String?>(
          value: '__all__',
          child: Text(
            allLabel,
            style: TextStyle(
              fontWeight: selectedOutletId == null
                  ? FontWeight.w700
                  : FontWeight.normal,
              color: selectedOutletId == null
                  ? AppColors.brandBlue
                  : context.appColors.textPrimary,
            ),
          ),
        ),
        ...outlets.map(
          (outlet) => PopupMenuItem<String?>(
            value: outlet.id,
            child: Text(
              outlet.name,
              style: TextStyle(
                fontWeight: selectedOutletId == outlet.id
                    ? FontWeight.w700
                    : FontWeight.normal,
                color: selectedOutletId == outlet.id
                    ? AppColors.brandBlue
                    : context.appColors.textPrimary,
              ),
            ),
          ),
        ),
      ],
      child: Container(
        height: 46,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: isFiltered
              ? AppColors.brandBlue.withValues(alpha: 0.1)
              : context.appColors.cardSoft,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isFiltered ? AppColors.brandBlue : context.appColors.outline,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.storefront_outlined,
              size: 16,
              color: isFiltered
                  ? AppColors.brandBlue
                  : context.appColors.textSecondary,
            ),
            const SizedBox(width: 4),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 80),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isFiltered
                      ? AppColors.brandBlue
                      : context.appColors.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 2),
            Icon(
              Icons.keyboard_arrow_down,
              size: 16,
              color: isFiltered
                  ? AppColors.brandBlue
                  : context.appColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryAdCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(14)),
      clipBehavior: Clip.hardEdge,
      child: const NativeAdCard(templateType: TemplateType.small),
    );
  }
}
