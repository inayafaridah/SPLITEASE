// lib/services/pdf_export_service.dart — Anggota 2
// Service untuk mengekspor laporan grup ke dalam dokumen PDF
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../models/group.dart';
import '../models/transaction.dart';
import '../models/contact.dart';
import '../services/split_calculator.dart';
import '../models/settlement.dart';

class PdfExportService {
  /// Menampilkan preview PDF laporan grup dan memungkinkan sharing/print.
  static Future<void> showGroupReport({
    required Group group,
    required List<Transaction> transactions,
    required List<Contact> contacts,
    required List<Settlement> settlements,
  }) async {
    final pdfDoc = await _generateGroupReport(
      group: group,
      transactions: transactions,
      contacts: contacts,
      settlements: settlements,
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdfDoc.save(),
      name: 'SplitEase_${group.name}_Report',
    );
  }

  /// Membuat dokumen PDF laporan grup lengkap
  static Future<pw.Document> _generateGroupReport({
    required Group group,
    required List<Transaction> transactions,
    required List<Contact> contacts,
    required List<Settlement> settlements,
  }) async {
    final pdf = pw.Document(
      title: 'Laporan Grup ${group.name}',
      author: 'SplitEase',
    );

    final totalExpense = SplitCalculator.totalExpense(transactions);
    final debts = SplitCalculator.calculate(
      transactions: transactions,
      contacts: contacts,
      settlements: settlements,
    );
    final summaries = SplitCalculator.balanceSummaries(
      transactions: transactions,
      contacts: contacts,
      settlements: settlements,
    );

    final dateNow = DateFormat('dd MMMM yyyy, HH:mm').format(DateTime.now());

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => _buildHeader(group, dateNow),
        footer: (context) => _buildFooter(context),
        build: (context) => [
          // Summary Card
          _buildSummarySection(group, totalExpense, transactions.length, contacts.length),
          pw.SizedBox(height: 20),

          // Transaction Table
          _buildTransactionTable(transactions, contacts, group.currency),
          pw.SizedBox(height: 20),

          // Balance Summary
          _buildBalanceSummary(summaries, group.currency),
          pw.SizedBox(height: 20),

          // Debt Resolution
          _buildDebtResolution(debts, group.currency),

          // Settlement History
          if (settlements.isNotEmpty) ...[
            pw.SizedBox(height: 20),
            _buildSettlementHistory(settlements, contacts, group.currency),
          ],
        ],
      ),
    );

    return pdf;
  }

  /// Header PDF
  static pw.Widget _buildHeader(Group group, String dateStr) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 16),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: PdfColors.indigo, width: 2),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'SplitEase',
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.indigo,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'Laporan Grup: ${group.name}',
                style: const pw.TextStyle(fontSize: 14, color: PdfColors.grey700),
              ),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                'Dicetak:',
                style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey500),
              ),
              pw.Text(
                dateStr,
                style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
              ),
              pw.Text(
                'Mata Uang: ${group.currency}',
                style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey500),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Footer PDF
  static pw.Widget _buildFooter(pw.Context context) {
    return pw.Container(
      alignment: pw.Alignment.centerRight,
      padding: const pw.EdgeInsets.only(top: 8),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          top: pw.BorderSide(color: PdfColors.grey300),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'Dibuat dengan SplitEase',
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey400),
          ),
          pw.Text(
            'Halaman ${context.pageNumber} / ${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey500),
          ),
        ],
      ),
    );
  }

  /// Ringkasan Umum
  static pw.Widget _buildSummarySection(
      Group group, double total, int txCount, int memberCount) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColors.indigo50,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: PdfColors.indigo100),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
        children: [
          _buildSummaryItem('Total Pengeluaran', _formatCurrency(total, group.currency)),
          _buildSummaryItem('Jumlah Transaksi', '$txCount'),
          _buildSummaryItem('Anggota Grup', '$memberCount'),
          _buildSummaryItem('Per Orang',
              memberCount > 0 ? _formatCurrency(total / memberCount, group.currency) : '-'),
        ],
      ),
    );
  }

  static pw.Widget _buildSummaryItem(String label, String value) {
    return pw.Column(
      children: [
        pw.Text(label,
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
        pw.SizedBox(height: 4),
        pw.Text(value,
            style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
      ],
    );
  }

  /// Tabel Transaksi
  static pw.Widget _buildTransactionTable(
      List<Transaction> transactions, List<Contact> contacts, String currency) {
    final contactMap = {for (var c in contacts) c.id!: c.name};

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('Daftar Transaksi',
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 8),
        if (transactions.isEmpty)
          pw.Text('Tidak ada transaksi.',
              style: const pw.TextStyle(color: PdfColors.grey500))
        else
          pw.TableHelper.fromTextArray(
            headerAlignment: pw.Alignment.centerLeft,
            cellAlignment: pw.Alignment.centerLeft,
            headerDecoration: const pw.BoxDecoration(color: PdfColors.indigo50),
            headerStyle: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              fontSize: 10,
              color: PdfColors.indigo900,
            ),
            cellStyle: const pw.TextStyle(fontSize: 9),
            cellHeight: 28,
            headers: ['No', 'Tanggal', 'Keterangan', 'Pembayar', 'Jumlah'],
            data: transactions.asMap().entries.map((entry) {
              final i = entry.key;
              final tx = entry.value;
              final date = DateFormat('dd/MM/yy')
                  .format(DateTime.tryParse(tx.date) ?? DateTime.now());
              return [
                '${i + 1}',
                date,
                tx.description,
                contactMap[tx.payerContactId] ?? '?',
                _formatCurrency(tx.amount, currency),
              ];
            }).toList(),
          ),
      ],
    );
  }

  /// Ringkasan Saldo
  static pw.Widget _buildBalanceSummary(
      List<BalanceSummary> summaries, String currency) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('Ringkasan Saldo',
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 8),
        pw.TableHelper.fromTextArray(
          headerDecoration: const pw.BoxDecoration(color: PdfColors.green50),
          headerStyle: pw.TextStyle(
            fontWeight: pw.FontWeight.bold,
            fontSize: 10,
            color: PdfColors.green900,
          ),
          cellStyle: const pw.TextStyle(fontSize: 9),
          cellHeight: 28,
          headers: ['Nama', 'Bayar', 'Bagian', 'Dilunasi', 'Saldo'],
          data: summaries.map((s) {
            return [
              s.contact.name,
              _formatCurrency(s.paid, currency),
              _formatCurrency(s.share, currency),
              _formatCurrency(s.settled, currency),
              _formatCurrency(s.balance, currency),
            ];
          }).toList(),
        ),
      ],
    );
  }

  /// Penyelesaian Hutang
  static pw.Widget _buildDebtResolution(List<DebtEntry> debts, String currency) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('Penyelesaian Hutang',
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 8),
        if (debts.isEmpty)
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: PdfColors.green50,
              borderRadius: pw.BorderRadius.circular(6),
            ),
            child: pw.Text('Semua lunas! Tidak ada hutang tersisa.',
                style: pw.TextStyle(
                    color: PdfColors.green700, fontWeight: pw.FontWeight.bold)),
          )
        else
          ...debts.map((d) => pw.Container(
                margin: const pw.EdgeInsets.only(bottom: 6),
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  color: PdfColors.amber50,
                  borderRadius: pw.BorderRadius.circular(6),
                  border: pw.Border.all(color: PdfColors.amber200),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      '${d.debtor.name}  →  ${d.creditor.name}',
                      style: pw.TextStyle(
                          fontSize: 11, fontWeight: pw.FontWeight.bold),
                    ),
                    pw.Text(
                      _formatCurrency(d.amount, currency),
                      style: pw.TextStyle(
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.red700,
                      ),
                    ),
                  ],
                ),
              )),
      ],
    );
  }

  /// Riwayat Pelunasan
  static pw.Widget _buildSettlementHistory(
      List<Settlement> settlements, List<Contact> contacts, String currency) {
    final contactMap = {for (var c in contacts) c.id!: c.name};

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('Riwayat Pelunasan',
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 8),
        pw.TableHelper.fromTextArray(
          headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey50),
          headerStyle: pw.TextStyle(
            fontWeight: pw.FontWeight.bold,
            fontSize: 10,
          ),
          cellStyle: const pw.TextStyle(fontSize: 9),
          cellHeight: 28,
          headers: ['Tanggal', 'Dari', 'Ke', 'Jumlah', 'Catatan'],
          data: settlements.map((s) {
            final date = DateFormat('dd/MM/yy')
                .format(DateTime.tryParse(s.date) ?? DateTime.now());
            return [
              date,
              contactMap[s.fromContactId] ?? '?',
              contactMap[s.toContactId] ?? '?',
              _formatCurrency(s.amount, currency),
              s.note.isEmpty ? '-' : s.note,
            ];
          }).toList(),
        ),
      ],
    );
  }

  static String _formatCurrency(double amount, String currency) {
    final formatter = NumberFormat.currency(
      locale: currency == 'IDR' ? 'id_ID' : 'en_US',
      symbol: currency == 'IDR'
          ? 'Rp '
          : currency == 'USD'
              ? '\$ '
              : '€ ',
      decimalDigits: currency == 'IDR' ? 0 : 2,
    );
    return formatter.format(amount);
  }
}
