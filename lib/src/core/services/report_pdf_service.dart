import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/money_transaction.dart';
import '../models/outlet_model.dart';
import '../models/user_profile.dart';
import '../state/app_state.dart';

class ReportPdfService {
  Future<void> generateAndShowPdf(
    String monthName,
    Summary summary,
    List<MoneyTransaction> transactions,
    UserProfile profile, {
    String locale = 'id',
    List<OutletModel> outlets = const [],
    String? selectedOutletId,
  }) async {
    final isId = locale == 'id';
    final font = await PdfGoogleFonts.openSansRegular();
    final fontBold = await PdfGoogleFonts.openSansBold();

    final pdf = pw.Document(
      theme: pw.ThemeData.withFont(base: font, bold: fontBold),
    );

    final currencyFormat = NumberFormat.currency(
      locale: isId ? 'id_ID' : 'en_US',
      symbol: isId ? 'Rp ' : '\$ ',
      decimalDigits: 0,
    );
    final dateFormat = DateFormat('dd MMM yyyy', isId ? 'id_ID' : 'en_US');

    final labels = {
      'title': isId ? 'LAPORAN KEUANGAN' : 'FINANCIAL REPORT',
      'owner': isId ? 'Pemilik' : 'Owner',
      'contact': isId ? 'Telp/WA' : 'Phone/WA',
      'income': isId ? 'Total Pemasukan' : 'Total Income',
      'expense': isId ? 'Total Pengeluaran' : 'Total Expense',
      'net': isId ? 'Keuntungan Bersih' : 'Net Profit',
      'detail': isId ? 'Detail Transaksi' : 'Transaction Details',
      'col_date': isId ? 'Tanggal' : 'Date',
      'col_cat': isId ? 'Kategori' : 'Category',
      'col_note': isId ? 'Catatan' : 'Note',
      'col_amount': isId ? 'Jumlah' : 'Amount',
      'col_outlet': isId ? 'Outlet' : 'Outlet',
      'outlet_income': isId ? 'PENDAPATAN PER OUTLET' : 'INCOME PER OUTLET',
      'shared_expense': isId ? 'BIAYA BERSAMA' : 'SHARED EXPENSES',
      'shared_note': isId
          ? 'Biaya produksi & operasional tidak dialokasikan per outlet'
          : 'Production & operational costs are not allocated per outlet',
      'outlet_label': isId ? 'Outlet' : 'Outlet',
      'other': isId ? 'Lainnya' : 'Others',
    };

    // Build outlet name lookup
    final outletNames = {for (final o in outlets) o.id: o.name};
    final showAllOutlets = selectedOutletId == null && outlets.isNotEmpty;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return [
            _buildHeader(monthName, profile, labels,
                selectedOutletId: selectedOutletId,
                outletNames: outletNames),
            pw.SizedBox(height: 20),
            showAllOutlets
                ? _buildMultiOutletSummary(
                    transactions, outlets, currencyFormat, labels)
                : _buildSingleSummary(summary, currencyFormat, labels),
            pw.SizedBox(height: 20),
            pw.Text(
              labels['detail']!,
              style: pw.TextStyle(
                  fontSize: 18, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 10),
            _buildTransactionTable(
              transactions,
              dateFormat,
              currencyFormat,
              labels,
              isId,
              showOutletColumn: showAllOutlets,
              outletNames: outletNames,
            ),
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: isId
          ? 'Laporan_Keuangan_$monthName'
          : 'Financial_Report_$monthName',
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────

  pw.Widget _buildHeader(
    String monthName,
    UserProfile profile,
    Map<String, String> labels, {
    String? selectedOutletId,
    Map<String, String> outletNames = const {},
  }) {
    final outletLabel = selectedOutletId != null
        ? (outletNames[selectedOutletId] ?? selectedOutletId)
        : null;

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  profile.businessName.isNotEmpty
                      ? profile.businessName.toUpperCase()
                      : 'BISNIS',
                  style: pw.TextStyle(
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.grey800,
                  ),
                ),
                if (profile.fullName.isNotEmpty) ...[
                  pw.SizedBox(height: 4),
                  pw.Text(
                    '${labels['owner']}: ${profile.fullName}',
                    style: const pw.TextStyle(
                        fontSize: 10, color: PdfColors.grey700),
                  ),
                ],
                if (profile.whatsapp.isNotEmpty) ...[
                  pw.SizedBox(height: 2),
                  pw.Text(
                    '${labels['contact']}: ${profile.whatsapp}',
                    style: const pw.TextStyle(
                        fontSize: 10, color: PdfColors.grey700),
                  ),
                ],
                if (outletLabel != null) ...[
                  pw.SizedBox(height: 4),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.blue50,
                      borderRadius:
                          const pw.BorderRadius.all(pw.Radius.circular(4)),
                      border: pw.Border.all(color: PdfColors.blue200),
                    ),
                    child: pw.Text(
                      '${labels['outlet_label']}: $outletLabel',
                      style: const pw.TextStyle(
                          fontSize: 9, color: PdfColors.blue900),
                    ),
                  ),
                ],
              ],
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text(
                  labels['title']!,
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.grey800,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  monthName,
                  style: pw.TextStyle(
                    fontSize: 12,
                    color: PdfColors.blue900,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
        pw.SizedBox(height: 15),
        pw.Divider(thickness: 2, color: PdfColors.blue900),
      ],
    );
  }

  // ── Summary: Mode Semua Outlet ────────────────────────────────────────────

  pw.Widget _buildMultiOutletSummary(
    List<MoneyTransaction> transactions,
    List<OutletModel> outlets,
    NumberFormat currencyFormat,
    Map<String, String> labels,
  ) {
    // Income per outlet
    final outletIncomes = <String, int>{};
    for (final outlet in outlets) {
      outletIncomes[outlet.id] = transactions
          .where((t) => t.isIncome && t.outletId == outlet.id)
          .fold(0, (sum, t) => sum + t.amount);
    }
    // Income tanpa outlet (online/lainnya)
    final otherIncome = transactions
        .where((t) => t.isIncome && (t.outletId == null || !outlets.any((o) => o.id == t.outletId)))
        .fold(0, (sum, t) => sum + t.amount);

    final totalIncome = outletIncomes.values.fold(0, (a, b) => a + b) + otherIncome;

    // Expenses (semua sebagai biaya bersama)
    final expenseByCategory = <String, int>{};
    for (final tx in transactions.where((t) => !t.isIncome)) {
      final cat = tx.category ?? 'other';
      expenseByCategory[cat] = (expenseByCategory[cat] ?? 0) + tx.amount;
    }
    final totalExpense = expenseByCategory.values.fold(0, (a, b) => a + b);
    final netProfit = totalIncome - totalExpense;

    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Pendapatan per outlet
          pw.Container(
            padding: const pw.EdgeInsets.fromLTRB(12, 10, 12, 6),
            decoration: const pw.BoxDecoration(
              color: PdfColors.green50,
              borderRadius: pw.BorderRadius.only(
                topLeft: pw.Radius.circular(8),
                topRight: pw.Radius.circular(8),
              ),
            ),
            child: pw.Text(
              labels['outlet_income']!,
              style: pw.TextStyle(
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.green800,
              ),
            ),
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.fromLTRB(12, 6, 12, 6),
            child: pw.Column(
              children: [
                ...outlets.map((o) => _summaryRowSmall(
                      o.name,
                      outletIncomes[o.id] ?? 0,
                      PdfColors.green700,
                      currencyFormat,
                    )),
                if (otherIncome > 0)
                  _summaryRowSmall(
                    labels['other']!,
                    otherIncome,
                    PdfColors.green600,
                    currencyFormat,
                  ),
                pw.Divider(color: PdfColors.grey300),
                _summaryRowSmall(
                  labels['income']!,
                  totalIncome,
                  PdfColors.green800,
                  currencyFormat,
                  bold: true,
                ),
              ],
            ),
          ),

          // Biaya bersama
          pw.Container(
            padding: const pw.EdgeInsets.fromLTRB(12, 8, 12, 6),
            decoration:
                const pw.BoxDecoration(color: PdfColors.red50),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  labels['shared_expense']!,
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.red800,
                  ),
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  labels['shared_note']!,
                  style: const pw.TextStyle(
                      fontSize: 8, color: PdfColors.grey600),
                ),
              ],
            ),
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.fromLTRB(12, 6, 12, 6),
            child: pw.Column(
              children: [
                ..._buildExpenseCategoryRows(
                    expenseByCategory, currencyFormat),
                pw.Divider(color: PdfColors.grey300),
                _summaryRowSmall(
                  labels['expense']!,
                  totalExpense,
                  PdfColors.red800,
                  currencyFormat,
                  bold: true,
                ),
              ],
            ),
          ),

          // Net profit
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: netProfit >= 0 ? PdfColors.blue50 : PdfColors.red100,
              borderRadius: const pw.BorderRadius.only(
                bottomLeft: pw.Radius.circular(8),
                bottomRight: pw.Radius.circular(8),
              ),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  labels['net']!,
                  style: pw.TextStyle(
                    fontSize: 13,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.grey900,
                  ),
                ),
                pw.Text(
                  currencyFormat.format(netProfit.abs()) +
                      (netProfit < 0 ? ' (rugi)' : ''),
                  style: pw.TextStyle(
                    fontSize: 13,
                    fontWeight: pw.FontWeight.bold,
                    color: netProfit >= 0 ? PdfColors.blue900 : PdfColors.red800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<pw.Widget> _buildExpenseCategoryRows(
    Map<String, int> expenseByCategory,
    NumberFormat currencyFormat,
  ) {
    final categoryLabels = {
      'expense.quick.material': 'Bahan Baku',
      'expense.quick.transport': 'Transportasi',
      'expense.quick.operational': 'Operasional',
      'expense.quick.salary': 'Gaji',
      'other': 'Lainnya',
    };
    final rows = <pw.Widget>[];
    final sorted = expenseByCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    for (final entry in sorted) {
      final label = categoryLabels[entry.key] ?? entry.key;
      rows.add(_summaryRowSmall(
          label, entry.value, PdfColors.red700, currencyFormat));
    }
    return rows;
  }

  pw.Widget _summaryRowSmall(
    String label,
    int amount,
    PdfColor color,
    NumberFormat currencyFormat, {
    bool bold = false,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 3),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label,
              style: bold
                  ? pw.TextStyle(
                      fontWeight: pw.FontWeight.bold, fontSize: 11)
                  : const pw.TextStyle(fontSize: 10)),
          pw.Text(
            currencyFormat.format(amount),
            style: bold
                ? pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 11,
                    color: color)
                : pw.TextStyle(fontSize: 10, color: color),
          ),
        ],
      ),
    );
  }

  // ── Summary: Mode 1 Outlet / Tanpa Outlet ─────────────────────────────────

  pw.Widget _buildSingleSummary(
    Summary summary,
    NumberFormat currencyFormat,
    Map<String, String> labels,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Column(
        children: [
          _buildSummaryRow(
              labels['income']!, summary.totalIncome,
              PdfColors.green, currencyFormat),
          pw.SizedBox(height: 5),
          _buildSummaryRow(
              labels['expense']!, summary.totalExpense,
              PdfColors.red, currencyFormat),
          pw.Divider(),
          _buildSummaryRow(
            labels['net']!,
            summary.netProfit,
            summary.netProfit >= 0 ? PdfColors.green : PdfColors.red,
            currencyFormat,
            isBold: true,
          ),
        ],
      ),
    );
  }

  pw.Widget _buildSummaryRow(
    String label,
    num amount,
    PdfColor color,
    NumberFormat currencyFormat, {
    bool isBold = false,
  }) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(label,
            style: pw.TextStyle(
                fontWeight:
                    isBold ? pw.FontWeight.bold : pw.FontWeight.normal)),
        pw.Text(
          currencyFormat.format(amount),
          style: pw.TextStyle(
            color: color,
            fontWeight:
                isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
          ),
        ),
      ],
    );
  }

  // ── Transaction Table ─────────────────────────────────────────────────────

  pw.Widget _buildTransactionTable(
    List<MoneyTransaction> transactions,
    DateFormat dateFormat,
    NumberFormat currencyFormat,
    Map<String, String> labels,
    bool isId, {
    bool showOutletColumn = false,
    Map<String, String> outletNames = const {},
  }) {
    final categoryMap = {
      'expense.quick.material': isId ? 'Bahan Baku' : 'Raw Material',
      'expense.quick.transport': isId ? 'Transportasi' : 'Transport',
      'expense.quick.operational': isId ? 'Operasional' : 'Operational',
      'expense.quick.salary': isId ? 'Gaji' : 'Salary',
      'income.quick.sales': isId ? 'Penjualan' : 'Sales',
      'income.quick.service': isId ? 'Jasa' : 'Service',
      'income.quick.other': isId ? 'Lainnya' : 'Other',
    };

    String resolveCategory(String? cat) {
      if (cat == null) return '-';
      return categoryMap[cat] ?? cat;
    }

    String resolveOutlet(String? outletId) {
      if (outletId == null) return isId ? 'Bersama' : 'Shared';
      return outletNames[outletId] ?? outletId;
    }

    final headers = [
      labels['col_date'],
      if (showOutletColumn) labels['col_outlet'],
      labels['col_cat'],
      labels['col_note'],
      labels['col_amount'],
    ];

    final data = transactions.map((tx) {
      final date = dateFormat.format(tx.effectiveDate);
      final amount = currencyFormat.format(tx.amount);
      final amountText = tx.isIncome ? amount : '-$amount';
      return [
        date,
        if (showOutletColumn) resolveOutlet(tx.outletId),
        resolveCategory(tx.category),
        tx.note ?? '-',
        amountText,
      ];
    }).toList();

    final colCount = headers.length;
    final alignments = <int, pw.Alignment>{};
    for (int i = 0; i < colCount - 1; i++) {
      alignments[i] = pw.Alignment.centerLeft;
    }
    alignments[colCount - 1] = pw.Alignment.centerRight;

    return pw.TableHelper.fromTextArray(
      headers: headers,
      data: data,
      headerStyle: pw.TextStyle(
          fontWeight: pw.FontWeight.bold, color: PdfColors.white),
      headerDecoration:
          const pw.BoxDecoration(color: PdfColors.blue900),
      rowDecoration: const pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
        ),
      ),
      oddRowDecoration:
          const pw.BoxDecoration(color: PdfColors.grey100),
      cellAlignments: alignments,
    );
  }
}
