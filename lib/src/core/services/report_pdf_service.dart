import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/money_transaction.dart';
import '../models/user_profile.dart';
import '../state/app_state.dart';

class ReportPdfService {
  Future<void> generateAndShowPdf(
    String monthName,
    Summary summary,
    List<MoneyTransaction> transactions,
    UserProfile profile, {
    String locale = 'id', // 'id' or 'en'
  }) async {
    final isId = locale == 'id';
    final font = await PdfGoogleFonts.openSansRegular();
    final fontBold = await PdfGoogleFonts.openSansBold();

    final pdf = pw.Document(
      theme: pw.ThemeData.withFont(
        base: font,
        bold: fontBold,
      ),
    );

    // Define formatters
    final currencyFormat = NumberFormat.currency(
      locale: isId ? 'id_ID' : 'en_US',
      symbol: isId ? 'Rp ' : '\$ ',
      decimalDigits: 0,
    );
    final dateFormat = DateFormat('dd MMM yyyy', isId ? 'id_ID' : 'en_US');

    // Labels
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
    };

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return [
            _buildHeader(monthName, profile, labels),
            pw.SizedBox(height: 20),
            _buildSummarySection(summary, currencyFormat, labels),
            pw.SizedBox(height: 20),
            pw.Text(
              labels['detail']!,
              style: pw.TextStyle(
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 10),
            _buildTransactionTable(
                transactions, dateFormat, currencyFormat, labels, isId),
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

  pw.Widget _buildHeader(
      String monthName, UserProfile profile, Map<String, String> labels) {
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
                      : 'GenZ Dimsum',
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
                      fontSize: 10,
                      color: PdfColors.grey700,
                    ),
                  ),
                ],
                if (profile.whatsapp.isNotEmpty) ...[
                  pw.SizedBox(height: 2),
                  pw.Text(
                    '${labels['contact']}: ${profile.whatsapp}',
                    style: const pw.TextStyle(
                      fontSize: 10,
                      color: PdfColors.grey700,
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

  pw.Widget _buildSummarySection(Summary summary, NumberFormat currencyFormat,
      Map<String, String> labels) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Column(
        children: [
          _buildSummaryRow(
            labels['income']!,
            summary.totalIncome,
            PdfColors.green,
            currencyFormat,
          ),
          pw.SizedBox(height: 5),
          _buildSummaryRow(
            labels['expense']!,
            summary.totalExpense,
            PdfColors.red,
            currencyFormat,
          ),
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
        pw.Text(
          label,
          style: pw.TextStyle(
            fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
          ),
        ),
        pw.Text(
          currencyFormat.format(amount),
          style: pw.TextStyle(
            color: color,
            fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
          ),
        ),
      ],
    );
  }

  pw.Widget _buildTransactionTable(
    List<MoneyTransaction> transactions,
    DateFormat dateFormat,
    NumberFormat currencyFormat,
    Map<String, String> labels,
    bool isId,
  ) {
    // Static translation map for categories since we don't have BuildContext
    final categoryMap = {
      // Keys
      'expense.quick.material': isId ? 'Bahan Baku' : 'Raw Material',
      'expense.quick.transport': isId ? 'Transportasi' : 'Transport',
      'expense.quick.operational': isId ? 'Operasional' : 'Operational',
      'income.quick.sales': isId ? 'Penjualan' : 'Sales',
      'income.quick.service': isId ? 'Jasa' : 'Service',
      'income.quick.other': isId ? 'Lainnya' : 'Other',
    };

    String translateCategory(String? cat) {
      if (cat == null) return '-';
      return categoryMap[cat] ?? cat;
    }

    return pw.TableHelper.fromTextArray(
      headers: [
        labels['col_date'],
        labels['col_cat'],
        labels['col_note'],
        labels['col_amount']
      ],
      data: transactions.map((tx) {
        final date = dateFormat.format(tx.effectiveDate);
        final amount = currencyFormat.format(tx.amount);
        final amountText = tx.isIncome ? amount : '-$amount';

        return [
          date,
          translateCategory(tx.category),
          tx.note ?? '-',
          amountText,
        ];
      }).toList(),
      headerStyle: pw.TextStyle(
        fontWeight: pw.FontWeight.bold,
        color: PdfColors.white,
      ),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.blue900),
      rowDecoration: const pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
        ),
      ),
      oddRowDecoration: const pw.BoxDecoration(color: PdfColors.grey100),
      cellAlignments: {
        0: pw.Alignment.centerLeft,
        1: pw.Alignment.centerLeft,
        2: pw.Alignment.centerLeft,
        3: pw.Alignment.centerRight,
      },
    );
  }
}