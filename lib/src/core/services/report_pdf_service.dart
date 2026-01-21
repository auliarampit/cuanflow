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
    UserProfile profile,
  ) async {
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
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    final dateFormat = DateFormat('dd MMM yyyy', 'id_ID');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return [
            _buildHeader(monthName, profile),
            pw.SizedBox(height: 20),
            _buildSummarySection(summary, currencyFormat),
            pw.SizedBox(height: 20),
            pw.Text(
              'Detail Transaksi',
              style: pw.TextStyle(
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 10),
            _buildTransactionTable(transactions, dateFormat, currencyFormat),
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Laporan_Keuangan_$monthName',
    );
  }

  pw.Widget _buildHeader(String monthName, UserProfile profile) {
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
                    'Pemilik: ${profile.fullName}',
                    style: const pw.TextStyle(
                      fontSize: 10,
                      color: PdfColors.grey700,
                    ),
                  ),
                ],
                if (profile.whatsapp.isNotEmpty) ...[
                  pw.SizedBox(height: 2),
                  pw.Text(
                    'Telp/WA: ${profile.whatsapp}',
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
                  'LAPORAN KEUANGAN',
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

  pw.Widget _buildSummarySection(
      Summary summary, NumberFormat currencyFormat) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Column(
        children: [
          _buildSummaryRow(
            'Total Pemasukan',
            summary.totalIncome,
            PdfColors.green,
            currencyFormat,
          ),
          pw.SizedBox(height: 5),
          _buildSummaryRow(
            'Total Pengeluaran',
            summary.totalExpense,
            PdfColors.red,
            currencyFormat,
          ),
          pw.Divider(),
          _buildSummaryRow(
            'Keuntungan Bersih',
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
  ) {
    return pw.TableHelper.fromTextArray(
      headers: ['Tanggal', 'Kategori', 'Catatan', 'Jumlah'],
      data: transactions.map((tx) {
        final date = dateFormat.format(tx.effectiveDate);
        final amount = currencyFormat.format(tx.amount);
        final amountText = tx.isIncome ? amount : '-$amount';
        
        return [
          date,
          tx.category ?? '-',
          tx.note ?? '-',
          amountText, // Note: PdfTable doesn't support styled text easily in helper, but basic text is fine.
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