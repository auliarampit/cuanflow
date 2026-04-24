import 'package:collection/collection.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../formatters/idr_formatter.dart';
import '../models/money_transaction.dart';
import '../models/outlet_model.dart';
import '../models/user_profile.dart';

/// Generates a transaction history PDF and opens the OS share sheet.
class PdfExporter {
  static Future<void> exportHistory({
    required List<MoneyTransaction> transactions,
    required UserProfile profile,
    required String periodLabel,
    List<OutletModel> outlets = const [],
    String? selectedOutletId,
  }) async {
    final outletNames = {for (final o in outlets) o.id: o.name};
    int totalIncome = 0;
    int totalExpense = 0;
    for (final tx in transactions) {
      if (tx.isIncome) {
        totalIncome += tx.amount;
      } else {
        totalExpense += tx.amount;
      }
    }
    final totalProfit = totalIncome - totalExpense;

    final grouped = groupBy(transactions, (MoneyTransaction tx) {
      final d = tx.effectiveDate;
      return DateTime(d.year, d.month, d.day);
    });
    final sortedDates = grouped.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    final pdf = pw.Document();
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 40, vertical: 48),
        header: (_) => _buildHeader(profile, periodLabel),
        footer: (_) => _buildFooter(),
        build: (_) => [
          _buildSummary(totalIncome, totalExpense, totalProfit, profile),
          pw.SizedBox(height: 20),
          ..._buildGroups(grouped, sortedDates, outletNames,
              showOutletCol: selectedOutletId == null && outlets.isNotEmpty),
        ],
      ),
    );

    final bytes = await pdf.save();
    final slug = profile.businessName.isEmpty
        ? 'laporan'
        : profile.businessName.toLowerCase().replaceAll(' ', '-');
    await Printing.sharePdf(bytes: bytes, filename: '$slug.pdf');
  }

  // ── Header (repeated each page) ─────────────────────────────────────────

  static pw.Widget _buildHeader(UserProfile profile, String period) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('CUAN FLOW',
                    style: pw.TextStyle(
                        fontSize: 18, fontWeight: pw.FontWeight.bold)),
                if (profile.businessName.isNotEmpty)
                  pw.Text(profile.businessName,
                      style: const pw.TextStyle(
                          fontSize: 11, color: PdfColors.grey700)),
              ],
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text('Laporan Transaksi',
                    style: const pw.TextStyle(
                        fontSize: 11, color: PdfColors.grey600)),
                pw.Text(period,
                    style: pw.TextStyle(
                        fontSize: 11, fontWeight: pw.FontWeight.bold)),
              ],
            ),
          ],
        ),
        pw.SizedBox(height: 6),
        pw.Divider(color: PdfColors.grey400),
        pw.SizedBox(height: 10),
      ],
    );
  }

  // ── Footer ───────────────────────────────────────────────────────────────

  static pw.Widget _buildFooter() {
    final now = DateTime.now();
    final label =
        'Dicetak: ${_fmt(now)}  •  Cuan Flow © 2026';
    return pw.Column(
      children: [
        pw.Divider(color: PdfColors.grey300),
        pw.SizedBox(height: 4),
        pw.Text(label,
            style: const pw.TextStyle(
                fontSize: 9, color: PdfColors.grey500)),
      ],
    );
  }

  // ── Summary box ──────────────────────────────────────────────────────────

  static pw.Widget _buildSummary(int income, int expense, int profit, UserProfile profile) {
    final isProfit = profit >= 0;
    final String netLabel;
    if (profile.isBusinessMode) {
      netLabel = isProfit ? 'Laba Bersih' : 'Rugi Bersih';
    } else {
      netLabel = isProfit ? 'Sisa Uang' : 'Defisit';
    }
    return pw.Container(
      padding: const pw.EdgeInsets.all(14),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Column(
        children: [
          _sumRow('Total Pemasukan', income, PdfColors.green700),
          pw.SizedBox(height: 6),
          _sumRow('Total Pengeluaran', expense, PdfColors.red700),
          pw.SizedBox(height: 8),
          pw.Divider(color: PdfColors.grey400),
          pw.SizedBox(height: 8),
          _sumRow(
            netLabel,
            profit.abs(),
            isProfit ? PdfColors.green800 : PdfColors.red800,
            bold: true,
            prefix: isProfit ? '+ ' : '- ',
          ),
        ],
      ),
    );
  }

  static pw.Widget _sumRow(
    String label,
    int amount,
    PdfColor color, {
    bool bold = false,
    String prefix = '',
  }) {
    final style = bold
        ? pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)
        : const pw.TextStyle(fontSize: 11);
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(label, style: style),
        pw.Text('$prefix${IdrFormatter.format(amount)}',
            style: style.copyWith(color: color)),
      ],
    );
  }

  // ── Transaction groups ───────────────────────────────────────────────────

  static List<pw.Widget> _buildGroups(
    Map<DateTime, List<MoneyTransaction>> grouped,
    List<DateTime> sortedDates,
    Map<String, String> outletNames, {
    bool showOutletCol = false,
  }) {
    final result = <pw.Widget>[];
    for (final date in sortedDates) {
      final txs = grouped[date]!;
      result.add(pw.Container(
        color: PdfColors.grey200,
        padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        child: pw.Text(
          _fmt(date, dateOnly: true),
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
        ),
      ));
      result.add(pw.SizedBox(height: 4));
      for (final tx in txs) {
        result.add(_buildTxRow(tx, outletNames,
            showOutlet: showOutletCol));
      }
      result.add(pw.SizedBox(height: 12));
    }
    return result;
  }

  static pw.Widget _buildTxRow(
    MoneyTransaction tx,
    Map<String, String> outletNames, {
    bool showOutlet = false,
  }) {
    final isIncome = tx.isIncome;
    final color = isIncome ? PdfColors.green700 : PdfColors.red700;
    final sign = isIncome ? '+' : '-';
    final category = tx.category ?? (isIncome ? 'Pemasukan' : 'Pengeluaran');
    final outletLabel = showOutlet
        ? (tx.outletId != null
            ? (outletNames[tx.outletId] ?? tx.outletId!)
            : 'Bersama')
        : null;

    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: pw.Row(
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(children: [
                  pw.Text(category,
                      style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold, fontSize: 10)),
                  if (outletLabel != null) ...[
                    pw.SizedBox(width: 6),
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(
                          horizontal: 4, vertical: 1),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.blue50,
                        borderRadius:
                            const pw.BorderRadius.all(pw.Radius.circular(3)),
                      ),
                      child: pw.Text(outletLabel,
                          style: const pw.TextStyle(
                              fontSize: 8, color: PdfColors.blue800)),
                    ),
                  ],
                ]),
                if ((tx.note ?? '').isNotEmpty)
                  pw.Text(tx.note!,
                      style: const pw.TextStyle(
                          fontSize: 9, color: PdfColors.grey600)),
              ],
            ),
          ),
          pw.Text(
            '$sign ${IdrFormatter.format(tx.amount)}',
            style: pw.TextStyle(
                fontWeight: pw.FontWeight.bold, fontSize: 10, color: color),
          ),
        ],
      ),
    );
  }

  // ── Date helper ──────────────────────────────────────────────────────────

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
    'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
  ];

  static String _fmt(DateTime d, {bool dateOnly = false}) {
    if (dateOnly) return '${d.day} ${_months[d.month - 1]} ${d.year}';
    return '${d.day} ${_months[d.month - 1]} ${d.year}'
        ' ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }
}
