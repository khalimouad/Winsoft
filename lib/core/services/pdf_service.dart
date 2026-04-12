import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/invoice.dart';
import '../models/payroll_slip.dart';
import '../models/pos_sale.dart';
import '../utils/morocco_format.dart';

/// Generates PDF documents for invoices, payslips and POS receipts.
class PdfService {
  PdfService._();

  static const _primaryColor = PdfColor.fromInt(0xFF1565C0);
  static const _grey = PdfColor.fromInt(0xFF757575);
  static const _lightGrey = PdfColor.fromInt(0xFFF5F5F5);
  static const _red = PdfColor.fromInt(0xFFD32F2F);
  static const _green = PdfColor.fromInt(0xFF2E7D32);

  // ── Invoice PDF ─────────────────────────────────────────────────────────────

  static Future<Uint8List> generateInvoice(
    Invoice invoice,
    Map<String, String> companySettings,
  ) async {
    final doc = pw.Document();
    final font = await PdfGoogleFonts.nunitoRegular();
    final fontBold = await PdfGoogleFonts.nunitoBold();

    doc.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(32),
      build: (ctx) => [
        // Header
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Company info
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  companySettings['company_name'] ?? 'Ma Société',
                  style: pw.TextStyle(font: fontBold, fontSize: 20, color: _primaryColor),
                ),
                pw.SizedBox(height: 4),
                if (companySettings['company_address']?.isNotEmpty == true)
                  pw.Text(companySettings['company_address']!,
                      style: pw.TextStyle(font: font, fontSize: 9, color: _grey)),
                if (companySettings['company_city']?.isNotEmpty == true)
                  pw.Text(companySettings['company_city']!,
                      style: pw.TextStyle(font: font, fontSize: 9, color: _grey)),
                if (companySettings['company_ice']?.isNotEmpty == true)
                  pw.Text('ICE: ${companySettings['company_ice']}',
                      style: pw.TextStyle(font: font, fontSize: 9, color: _grey)),
                if (companySettings['company_if']?.isNotEmpty == true)
                  pw.Text('IF: ${companySettings['company_if']}',
                      style: pw.TextStyle(font: font, fontSize: 9, color: _grey)),
              ],
            ),
            // Invoice badge
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: pw.BoxDecoration(
                color: _primaryColor,
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text('FACTURE',
                      style: pw.TextStyle(
                          font: fontBold, fontSize: 18, color: PdfColors.white)),
                  pw.Text(invoice.reference,
                      style: pw.TextStyle(
                          font: fontBold, fontSize: 13, color: PdfColors.white)),
                ],
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 24),
        // Dates row
        pw.Row(children: [
          _labelValue('Date d\'émission',
              MoroccoFormat.date(invoice.issuedDate), font, fontBold),
          pw.SizedBox(width: 32),
          _labelValue('Date d\'échéance',
              MoroccoFormat.date(invoice.dueDate), font, fontBold),
          pw.SizedBox(width: 32),
          _labelValue('Statut', invoice.status, font, fontBold,
              color: invoice.status == 'Payée' ? _green : _red),
        ]),
        pw.SizedBox(height: 20),
        // Client box
        pw.Container(
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
            color: _lightGrey,
            borderRadius: pw.BorderRadius.circular(6),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('FACTURER À',
                  style: pw.TextStyle(font: fontBold, fontSize: 9, color: _grey)),
              pw.SizedBox(height: 4),
              pw.Text(invoice.clientName ?? '',
                  style: pw.TextStyle(font: fontBold, fontSize: 12)),
              if (invoice.companyName != null)
                pw.Text(invoice.companyName!,
                    style: pw.TextStyle(font: font, fontSize: 10, color: _grey)),
            ],
          ),
        ),
        pw.SizedBox(height: 20),
        // Items table
        pw.Table(
          border: null,
          columnWidths: {
            0: const pw.FlexColumnWidth(4),
            1: const pw.FlexColumnWidth(1),
            2: const pw.FlexColumnWidth(1.5),
            3: const pw.FlexColumnWidth(1),
            4: const pw.FlexColumnWidth(1.5),
          },
          children: [
            // Header row
            pw.TableRow(
              decoration: pw.BoxDecoration(color: _primaryColor),
              children: [
                _tableHeader('Description', fontBold),
                _tableHeader('Qté', fontBold, align: pw.TextAlign.right),
                _tableHeader('Prix HT', fontBold, align: pw.TextAlign.right),
                _tableHeader('TVA', fontBold, align: pw.TextAlign.right),
                _tableHeader('Total TTC', fontBold, align: pw.TextAlign.right),
              ],
            ),
            // Item rows
            ...invoice.items.asMap().entries.map((e) {
              final item = e.value;
              final bg = e.key % 2 == 0 ? PdfColors.white : const PdfColor.fromInt(0xFFF9F9F9);
              final lineHt = item.quantity * item.unitPriceHt;
              final lineTtc = lineHt * (1 + item.tvaRate / 100);
              return pw.TableRow(
                decoration: pw.BoxDecoration(color: bg),
                children: [
                  _tableCell(item.description, font),
                  _tableCell(item.quantity.toStringAsFixed(item.quantity % 1 == 0 ? 0 : 2),
                      font, align: pw.TextAlign.right),
                  _tableCell(MoroccoFormat.mad(item.unitPriceHt), font,
                      align: pw.TextAlign.right),
                  _tableCell('${item.tvaRate.toStringAsFixed(0)}%', font,
                      align: pw.TextAlign.right),
                  _tableCell(MoroccoFormat.mad(lineTtc), fontBold,
                      align: pw.TextAlign.right),
                ],
              );
            }),
          ],
        ),
        pw.SizedBox(height: 16),
        // Totals
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.end,
          children: [
            pw.Container(
              width: 220,
              child: pw.Column(children: [
                _totalRow('Total HT', MoroccoFormat.mad(invoice.totalHt), font),
                _totalRow('TVA', MoroccoFormat.mad(invoice.totalTva), font),
                pw.Divider(color: _grey, height: 1),
                pw.SizedBox(height: 4),
                _totalRow('Total TTC', MoroccoFormat.mad(invoice.totalTtc), fontBold,
                    large: true, color: _primaryColor),
              ]),
            ),
          ],
        ),
        if (invoice.notes != null && invoice.notes!.isNotEmpty) ...[
          pw.SizedBox(height: 24),
          pw.Text('Notes:', style: pw.TextStyle(font: fontBold, fontSize: 9)),
          pw.Text(invoice.notes!, style: pw.TextStyle(font: font, fontSize: 9, color: _grey)),
        ],
        pw.SizedBox(height: 32),
        pw.Center(
          child: pw.Text('Merci pour votre confiance.',
              style: pw.TextStyle(font: font, fontSize: 10, color: _grey,
                  fontStyle: pw.FontStyle.italic)),
        ),
      ],
    ));
    return doc.save();
  }

  // ── Payslip PDF ─────────────────────────────────────────────────────────────

  static Future<Uint8List> generatePayslip(
    PayrollSlip slip,
    Map<String, String> companySettings,
  ) async {
    final doc = pw.Document();
    final font = await PdfGoogleFonts.nunitoRegular();
    final fontBold = await PdfGoogleFonts.nunitoBold();

    doc.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(32),
      build: (ctx) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Header
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(companySettings['company_name'] ?? 'Ma Société',
                  style: pw.TextStyle(font: fontBold, fontSize: 18, color: _primaryColor)),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: pw.BoxDecoration(
                    color: _primaryColor, borderRadius: pw.BorderRadius.circular(6)),
                child: pw.Text('BULLETIN DE PAIE',
                    style: pw.TextStyle(font: fontBold, fontSize: 12, color: PdfColors.white)),
              ),
            ],
          ),
          pw.SizedBox(height: 16),
          pw.Divider(color: _primaryColor, height: 1),
          pw.SizedBox(height: 12),
          // Period + employee
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              _labelValue('Période', slip.periodLabel, font, fontBold),
              _labelValue('Employé', slip.employeeName ?? '', font, fontBold),
              if (slip.employeeCin != null)
                _labelValue('CIN', slip.employeeCin!, font, fontBold),
              if (slip.employeePosition != null)
                _labelValue('Poste', slip.employeePosition!, font, fontBold),
            ],
          ),
          pw.SizedBox(height: 20),
          // Earnings
          _payrollSection('ÉLÉMENTS DE RÉMUNÉRATION', [
            ['Salaire brut de base', MoroccoFormat.mad(slip.salaryBrut)],
          ], font, fontBold, _green),
          pw.SizedBox(height: 12),
          // Deductions
          _payrollSection('RETENUES SALARIALES', [
            ['CNSS (5.44%) — Employé',
                '- ${MoroccoFormat.mad(slip.cnssEmployee)}'],
            ['AMO — Employé', '- ${MoroccoFormat.mad(slip.amoEmployee)}'],
            ['IR (IGR)', '- ${MoroccoFormat.mad(slip.igr)}'],
            if (slip.otherDeductions > 0)
              ['Autres retenues', '- ${MoroccoFormat.mad(slip.otherDeductions)}'],
          ], font, fontBold, _red),
          pw.SizedBox(height: 12),
          // Net salary box
          pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              color: _primaryColor,
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('NET À PAYER',
                    style: pw.TextStyle(font: fontBold, fontSize: 14, color: PdfColors.white)),
                pw.Text(MoroccoFormat.mad(slip.salaryNet),
                    style: pw.TextStyle(font: fontBold, fontSize: 18, color: PdfColors.white)),
              ],
            ),
          ),
          pw.SizedBox(height: 16),
          // Employer charges info
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: _lightGrey, borderRadius: pw.BorderRadius.circular(6)),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('CHARGES PATRONALES (information)',
                    style: pw.TextStyle(font: fontBold, fontSize: 9, color: _grey)),
                pw.SizedBox(height: 6),
                pw.Row(children: [
                  pw.Text('CNSS Employeur: ', style: pw.TextStyle(font: font, fontSize: 9)),
                  pw.Text(MoroccoFormat.mad(slip.cnssEmployer),
                      style: pw.TextStyle(font: fontBold, fontSize: 9)),
                  pw.SizedBox(width: 16),
                  pw.Text('AMO Employeur: ', style: pw.TextStyle(font: font, fontSize: 9)),
                  pw.Text(MoroccoFormat.mad(slip.amoEmployer),
                      style: pw.TextStyle(font: fontBold, fontSize: 9)),
                  pw.SizedBox(width: 16),
                  pw.Text('Coût total employeur: ',
                      style: pw.TextStyle(font: font, fontSize: 9)),
                  pw.Text(MoroccoFormat.mad(slip.salaryBrut +
                      slip.cnssEmployer + slip.amoEmployer),
                      style: pw.TextStyle(font: fontBold, fontSize: 9)),
                ]),
              ],
            ),
          ),
        ],
      ),
    ));
    return doc.save();
  }

  // ── POS Receipt PDF ──────────────────────────────────────────────────────────

  static Future<Uint8List> generateReceipt(
    PosSale sale,
    Map<String, String> companySettings,
  ) async {
    final doc = pw.Document();
    final font = await PdfGoogleFonts.nunitoRegular();
    final fontBold = await PdfGoogleFonts.nunitoBold();

    doc.addPage(pw.Page(
      pageFormat: PdfPageFormat(80 * PdfPageFormat.mm, double.infinity,
          marginAll: 8 * PdfPageFormat.mm),
      build: (ctx) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Text(companySettings['company_name'] ?? 'Ma Société',
              style: pw.TextStyle(font: fontBold, fontSize: 14)),
          if (companySettings['company_address']?.isNotEmpty == true)
            pw.Text(companySettings['company_address']!,
                style: pw.TextStyle(font: font, fontSize: 8, color: _grey)),
          pw.SizedBox(height: 8),
          pw.Divider(color: _grey),
          pw.Text(sale.reference,
              style: pw.TextStyle(font: fontBold, fontSize: 11)),
          pw.Text(MoroccoFormat.dateFromMs(sale.saleDate),
              style: pw.TextStyle(font: font, fontSize: 9, color: _grey)),
          if (sale.clientName != null)
            pw.Text('Client: ${sale.clientName}',
                style: pw.TextStyle(font: font, fontSize: 9)),
          pw.Divider(color: _grey),
          ...sale.items.map((item) => pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Expanded(
                    child: pw.Text('${item.description} × ${item.quantity}',
                        style: pw.TextStyle(font: font, fontSize: 9)),
                  ),
                  pw.Text(MoroccoFormat.mad(item.lineTtc),
                      style: pw.TextStyle(font: font, fontSize: 9)),
                ],
              )),
          pw.Divider(color: _grey),
          pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
            pw.Text('HT', style: pw.TextStyle(font: font, fontSize: 9)),
            pw.Text(MoroccoFormat.mad(sale.totalHt),
                style: pw.TextStyle(font: font, fontSize: 9)),
          ]),
          pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
            pw.Text('TVA', style: pw.TextStyle(font: font, fontSize: 9)),
            pw.Text(MoroccoFormat.mad(sale.totalTva),
                style: pw.TextStyle(font: font, fontSize: 9)),
          ]),
          pw.SizedBox(height: 4),
          pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
            pw.Text('TOTAL TTC', style: pw.TextStyle(font: fontBold, fontSize: 13)),
            pw.Text(MoroccoFormat.mad(sale.totalTtc),
                style: pw.TextStyle(font: fontBold, fontSize: 13)),
          ]),
          pw.SizedBox(height: 6),
          pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
            pw.Text(sale.paymentMethod, style: pw.TextStyle(font: font, fontSize: 9)),
            if (sale.paymentMethod == 'Espèces') ...[
              pw.Text('Reçu: ${MoroccoFormat.mad(sale.amountTendered)} | '
                  'Rendu: ${MoroccoFormat.mad(sale.change)}',
                  style: pw.TextStyle(font: font, fontSize: 9)),
            ],
          ]),
          pw.Divider(color: _grey),
          pw.Text('Merci pour votre achat !',
              style: pw.TextStyle(
                  font: font, fontSize: 10,
                  fontStyle: pw.FontStyle.italic, color: _grey)),
        ],
      ),
    ));
    return doc.save();
  }

  // ── Print helper ─────────────────────────────────────────────────────────────

  static Future<void> printDoc(Uint8List pdfBytes) async {
    await Printing.layoutPdf(onLayout: (_) async => pdfBytes);
  }

  static Future<void> shareDoc(Uint8List pdfBytes, String filename) async {
    await Printing.sharePdf(bytes: pdfBytes, filename: filename);
  }

  // ── Private helpers ───────────────────────────────────────────────────────────

  static pw.Widget _labelValue(String label, String value,
      pw.Font font, pw.Font fontBold,
      {PdfColor? color}) =>
      pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        pw.Text(label,
            style: pw.TextStyle(font: font, fontSize: 8, color: _grey)),
        pw.Text(value,
            style: pw.TextStyle(
                font: fontBold, fontSize: 11, color: color ?? PdfColors.black)),
      ]);

  static pw.Widget _tableHeader(String text, pw.Font fontBold,
          {pw.TextAlign align = pw.TextAlign.left}) =>
      pw.Padding(
        padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: pw.Text(text,
            textAlign: align,
            style: pw.TextStyle(font: fontBold, fontSize: 9, color: PdfColors.white)),
      );

  static pw.Widget _tableCell(String text, pw.Font font,
          {pw.TextAlign align = pw.TextAlign.left}) =>
      pw.Padding(
        padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        child: pw.Text(text,
            textAlign: align,
            style: pw.TextStyle(font: font, fontSize: 9)),
      );

  static pw.Widget _totalRow(String label, String value, pw.Font font,
      {bool large = false, PdfColor? color}) =>
      pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 2),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(label,
                style: pw.TextStyle(
                    font: font,
                    fontSize: large ? 12 : 10,
                    color: color ?? PdfColors.black)),
            pw.Text(value,
                style: pw.TextStyle(
                    font: font,
                    fontSize: large ? 14 : 10,
                    color: color ?? PdfColors.black)),
          ],
        ),
      );

  static pw.Widget _payrollSection(String title,
      List<List<String>> rows, pw.Font font, pw.Font fontBold, PdfColor color) =>
      pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          color: color.shade(0.1),
          child: pw.Text(title,
              style: pw.TextStyle(
                  font: fontBold, fontSize: 9, color: color)),
        ),
        ...rows.map((r) => pw.Padding(
              padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                pw.Text(r[0], style: pw.TextStyle(font: font, fontSize: 10)),
                pw.Text(r[1],
                    style: pw.TextStyle(font: fontBold, fontSize: 10)),
              ]),
            )),
      ]);
}
