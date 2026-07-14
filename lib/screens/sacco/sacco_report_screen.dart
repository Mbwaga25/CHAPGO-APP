import 'dart:io';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../config/theme.dart';

/// Full-page SACCO report viewer with PDF + CSV export.
class SaccoReportScreen extends StatelessWidget {
  final String title;
  final String saccoName;
  final List<List<String>> rows; // [label, value]
  const SaccoReportScreen({
    super.key,
    required this.title,
    required this.saccoName,
    required this.rows,
  });

  String get _generatedAt => DateTime.now().toString().split('.').first;
  String _safe(String s) => s.replaceAll(RegExp(r'[^A-Za-z0-9]+'), '_');

  Future<void> _exportPdf() async {
    final doc = pw.Document();
    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (ctx) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('CHAPGO SACCO', style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
            pw.SizedBox(height: 2),
            pw.Text(saccoName, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 8),
            pw.Text(title, style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
            pw.Text('Generated: $_generatedAt EAT', style: pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
            pw.SizedBox(height: 18),
            pw.TableHelper.fromTextArray(
              headers: ['Field', 'Value'],
              data: rows,
              border: pw.TableBorder.all(color: PdfColors.grey300),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
              headerDecoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFF0B1D2E)),
              cellAlignments: const {0: pw.Alignment.centerLeft, 1: pw.Alignment.centerRight},
              cellPadding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            ),
            pw.SizedBox(height: 28),
            pw.Text('Chapgo Company Limited — Chapgo Pilot · TCDC Compliant',
                style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
          ],
        ),
      ),
    );
    await Printing.sharePdf(bytes: await doc.save(), filename: '${_safe(title)}.pdf');
  }

  Future<void> _exportCsv() async {
    final sb = StringBuffer();
    sb.writeln('Report,${_csv(title)}');
    sb.writeln('SACCO,${_csv(saccoName)}');
    sb.writeln('Generated,$_generatedAt EAT');
    sb.writeln('');
    sb.writeln('Field,Value');
    for (final r in rows) {
      sb.writeln('${_csv(r[0])},${_csv(r[1])}');
    }
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/${_safe(title)}.csv');
    await file.writeAsString(sb.toString());
    await SharePlus.instance.share(ShareParams(files: [XFile(file.path)], subject: title));
  }

  String _csv(String s) => '"${s.replaceAll('"', '""')}"';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Header card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF0B1D2E), Color(0xFF1E3A5F)],
                    ),
                    borderRadius: BorderRadius.all(Radius.circular(16)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(saccoName,
                          style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 6),
                      Text(title,
                          style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 4),
                      Text('Generated: $_generatedAt EAT',
                          style: const TextStyle(color: Colors.white54, fontSize: 11)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Data rows
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Column(
                    children: List.generate(rows.length, (i) {
                      final r = rows[i];
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          border: i == rows.length - 1
                              ? null
                              : Border(bottom: BorderSide(color: AppTheme.border)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(child: Text(r[0], style: TextStyle(fontSize: 13, color: AppTheme.gray))),
                            const SizedBox(width: 12),
                            Text(r[1],
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.navy)),
                          ],
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ),
          ),
          // Export bar
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _exportCsv,
                      icon: const Icon(Icons.table_chart_outlined, size: 18),
                      label: const Text('CSV'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.green,
                        side: BorderSide(color: AppTheme.green),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _exportPdf,
                      icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
                      label: const Text('PDF'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
