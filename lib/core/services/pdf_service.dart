import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/credit_note.dart';
import '../models/invoice.dart';
import '../models/payroll_slip.dart';
import '../models/pos_sale.dart';
import '../models/purchase_order.dart';
import '../utils/morocco_format.dart';

/// Generates PDF documents for invoices, credit notes, purchase orders,
/// payslips, and POS receipts.
class PdfService {
  PdfService._();

  static const _primaryColor = PdfColor.fromInt(0xFF1565C0);
  static const _accentColor  = PdfColor.fromInt(0xFF1976D2);
  static const _grey         = PdfColor.fromInt(0xFF757575);
  static const _lightGrey    = PdfColor.fromInt(0xFFF5F5F5);
  static const _borderGrey   = PdfColor.fromInt(0xFFE0E0E0);
  static const _red          = PdfColor.fromInt(0xFFD32F2F);
  static const _green        = PdfColor.fromInt(0xFF2E7D32);
  static const _amber        = PdfColor.fromInt(0xFFF57C00);

  // ── Invoice PDF ─────────────────────────────────────────────────────────────

  static Future<Uint8List> generateInvoice(
    Invoice invoice,
    Map<String, String> companySettings,
  ) async {
    final doc      = pw.Document();
    final font     = await PdfGoogleFonts.nunitoRegular();
    final fontBold = await PdfGoogleFonts.nunitoBold();
    final fontIta  = await PdfGoogleFonts.nunitoItalic();

    // TVA breakdown: group items by TVA rate
    final tvaMap = <double, double>{};
    for (final item in invoice.items) {
      tvaMap[item.tvaRate] =
          (tvaMap[item.tvaRate] ?? 0) + item.quantity * item.unitPriceHt * item.tvaRate / 100;
    }

    // Status display config
    final statusColor = _statusPdfColor(invoice.status);

    final terms = companySettings['invoice_terms'] ?? '30 jours net';
    final notes = companySettings['invoice_notes'] ?? '';

    doc.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.fromLTRB(32, 32, 32, 40),
      footer: (ctx) => pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            companySettings['company_name'] ?? '',
            style: pw.TextStyle(font: font, fontSize: 7, color: _grey),
          ),
          pw.Text(
            'Page ${ctx.pageNumber} / ${ctx.pagesCount}',
            style: pw.TextStyle(font: font, fontSize: 7, color: _grey),
          ),
          pw.Text(
            invoice.reference,
            style: pw.TextStyle(font: fontBold, fontSize: 7, color: _grey),
          ),
        ],
      ),
      build: (ctx) => [
        // ── Header ──────────────────────────────────────────────────────────
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            // Company block
            pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
              pw.Text(
                companySettings['company_name'] ?? 'Ma Société',
                style: pw.TextStyle(font: fontBold, fontSize: 18, color: _primaryColor),
              ),
              pw.SizedBox(height: 6),
              if (companySettings['company_address']?.isNotEmpty == true)
                _companyLine(companySettings['company_address']!, font),
              if (companySettings['company_city']?.isNotEmpty == true)
                _companyLine(companySettings['company_city']!, font),
              if (companySettings['company_phone']?.isNotEmpty == true)
                _companyLine('Tél: ${companySettings['company_phone']}', font),
              if (companySettings['company_email']?.isNotEmpty == true)
                _companyLine(companySettings['company_email']!, font),
              pw.SizedBox(height: 4),
              if (companySettings['company_ice']?.isNotEmpty == true)
                _companyLine('ICE: ${companySettings['company_ice']}', font),
              if (companySettings['company_rc']?.isNotEmpty == true)
                _companyLine('RC: ${companySettings['company_rc']}', font),
              if (companySettings['company_if']?.isNotEmpty == true)
                _companyLine('IF: ${companySettings['company_if']}', font),
            ]),
            // Invoice badge
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: pw.BoxDecoration(
                color: _primaryColor,
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text('FACTURE',
                      style: pw.TextStyle(
                          font: fontBold, fontSize: 20, color: PdfColors.white)),
                  pw.SizedBox(height: 4),
                  pw.Text(invoice.reference,
                      style: pw.TextStyle(
                          font: fontBold, fontSize: 13, color: PdfColors.white)),
                  pw.SizedBox(height: 6),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: pw.BoxDecoration(
                      color: statusColor.shade(0.6),
                      borderRadius: pw.BorderRadius.circular(4),
                    ),
                    child: pw.Text(invoice.status,
                        style: pw.TextStyle(
                            font: fontBold, fontSize: 10, color: PdfColors.white)),
                  ),
                ],
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 20),

        // ── Dates + payment terms ────────────────────────────────────────────
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: pw.BoxDecoration(
            color: _lightGrey,
            borderRadius: pw.BorderRadius.circular(6),
          ),
          child: pw.Row(children: [
            _labelValue("Date d'émission",
                MoroccoFormat.date(invoice.issuedDate), font, fontBold),
            pw.SizedBox(width: 32),
            _labelValue("Date d'échéance",
                MoroccoFormat.date(invoice.dueDate), font, fontBold,
                color: invoice.isOverdue ? _red : null),
            pw.SizedBox(width: 32),
            _labelValue('Conditions de paiement', terms, font, fontBold),
          ]),
        ),
        pw.SizedBox(height: 16),

        // ── Client block ─────────────────────────────────────────────────────
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              child: pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: _borderGrey),
                  borderRadius: pw.BorderRadius.circular(6),
                ),
                child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                  pw.Text('FACTURER À',
                      style: pw.TextStyle(font: fontBold, fontSize: 8, color: _grey)),
                  pw.SizedBox(height: 6),
                  pw.Text(invoice.clientName ?? '',
                      style: pw.TextStyle(font: fontBold, fontSize: 13)),
                  if (invoice.companyName != null)
                    pw.Text(invoice.companyName!,
                        style: pw.TextStyle(font: font, fontSize: 10, color: _grey)),
                ]),
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 20),

        // ── Items table ──────────────────────────────────────────────────────
        pw.Table(
          border: null,
          columnWidths: {
            0: const pw.FlexColumnWidth(4),
            1: const pw.FlexColumnWidth(1),
            2: const pw.FlexColumnWidth(1.5),
            3: const pw.FlexColumnWidth(0.8),
            4: const pw.FlexColumnWidth(1.5),
          },
          children: [
            pw.TableRow(
              decoration: pw.BoxDecoration(color: _primaryColor),
              children: [
                _th('DÉSIGNATION',   fontBold),
                _th('QTÉ',           fontBold, align: pw.TextAlign.right),
                _th('PRIX UNIT. HT', fontBold, align: pw.TextAlign.right),
                _th('TVA',           fontBold, align: pw.TextAlign.center),
                _th('TOTAL TTC',     fontBold, align: pw.TextAlign.right),
              ],
            ),
            ...invoice.items.asMap().entries.map((e) {
              final idx  = e.key;
              final item = e.value;
              final bg   = idx % 2 == 0 ? PdfColors.white : const PdfColor.fromInt(0xFFF8F9FC);
              return pw.TableRow(
                decoration: pw.BoxDecoration(
                  color: bg,
                  border: pw.Border(bottom: pw.BorderSide(color: _borderGrey, width: 0.5)),
                ),
                children: [
                  _td(item.description, font),
                  _td(_qty(item.quantity), font, align: pw.TextAlign.right),
                  _td(MoroccoFormat.mad(item.unitPriceHt), font, align: pw.TextAlign.right),
                  _td('${item.tvaRate.toStringAsFixed(0)}%', font, align: pw.TextAlign.center),
                  _td(MoroccoFormat.mad(item.totalTtc), fontBold, align: pw.TextAlign.right),
                ],
              );
            }),
          ],
        ),
        pw.SizedBox(height: 16),

        // ── Totals + TVA breakdown ────────────────────────────────────────────
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          mainAxisAlignment: pw.MainAxisAlignment.end,
          children: [
            // TVA breakdown (only if multiple rates or non-zero)
            if (tvaMap.isNotEmpty && !(tvaMap.length == 1 && tvaMap.keys.first == 0)) ...[
              pw.Container(
                width: 200,
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  color: _lightGrey,
                  borderRadius: pw.BorderRadius.circular(6),
                ),
                child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                  pw.Text('DÉTAIL TVA',
                      style: pw.TextStyle(font: fontBold, fontSize: 8, color: _grey)),
                  pw.SizedBox(height: 6),
                  ...tvaMap.entries.map((e) => pw.Padding(
                    padding: const pw.EdgeInsets.only(bottom: 3),
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(MoroccoFormat.tvaLabel(e.key),
                            style: pw.TextStyle(font: font, fontSize: 9)),
                        pw.Text(MoroccoFormat.mad(e.value),
                            style: pw.TextStyle(font: fontBold, fontSize: 9)),
                      ],
                    ),
                  )),
                ]),
              ),
              pw.SizedBox(width: 16),
            ],
            // Totals box
            pw.Container(
              width: 200,
              child: pw.Column(children: [
                _totalRow('Total HT', MoroccoFormat.mad(invoice.totalHt), font),
                _totalRow('TVA', MoroccoFormat.mad(invoice.totalTva), font),
                pw.Container(height: 0.5, color: _grey),
                pw.SizedBox(height: 4),
                _totalRow('Total TTC', MoroccoFormat.mad(invoice.totalTtc), fontBold,
                    large: true, color: _primaryColor),
              ]),
            ),
          ],
        ),

        // ── Notes & terms ────────────────────────────────────────────────────
        if (notes.isNotEmpty) ...[
          pw.SizedBox(height: 20),
          pw.Text('Note:', style: pw.TextStyle(font: fontBold, fontSize: 9)),
          pw.Text(notes, style: pw.TextStyle(font: fontIta, fontSize: 9, color: _grey)),
        ],

        // ── Signature zone ───────────────────────────────────────────────────
        pw.SizedBox(height: 30),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Vendor signature
            pw.Container(
              width: 180,
              child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                pw.Text('Cachet & Signature émetteur',
                    style: pw.TextStyle(font: fontBold, fontSize: 8, color: _grey)),
                pw.SizedBox(height: 40),
                pw.Container(height: 0.5, color: _grey),
              ]),
            ),
            // Client signature
            pw.Container(
              width: 180,
              child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                pw.Text('Bon pour accord client',
                    style: pw.TextStyle(font: fontBold, fontSize: 8, color: _grey)),
                pw.SizedBox(height: 40),
                pw.Container(height: 0.5, color: _grey),
              ]),
            ),
          ],
        ),
      ],
    ));
    return doc.save();
  }

  // ── Credit Note PDF ──────────────────────────────────────────────────────────

  static Future<Uint8List> generateCreditNote(
    CreditNote cn,
    Map<String, String> companySettings,
  ) async {
    final doc      = pw.Document();
    final font     = await PdfGoogleFonts.nunitoRegular();
    final fontBold = await PdfGoogleFonts.nunitoBold();
    final fontIta  = await PdfGoogleFonts.nunitoItalic();

    final statusColor = _statusPdfColor(cn.status);

    doc.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.fromLTRB(32, 32, 32, 40),
      build: (ctx) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // ── Header ────────────────────────────────────────────────────────
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                pw.Text(
                  companySettings['company_name'] ?? 'Ma Société',
                  style: pw.TextStyle(font: fontBold, fontSize: 18, color: _primaryColor),
                ),
                pw.SizedBox(height: 6),
                if (companySettings['company_address']?.isNotEmpty == true)
                  _companyLine(companySettings['company_address']!, font),
                if (companySettings['company_city']?.isNotEmpty == true)
                  _companyLine(companySettings['company_city']!, font),
                if (companySettings['company_phone']?.isNotEmpty == true)
                  _companyLine('Tél: ${companySettings['company_phone']}', font),
                if (companySettings['company_ice']?.isNotEmpty == true)
                  _companyLine('ICE: ${companySettings['company_ice']}', font),
                if (companySettings['company_if']?.isNotEmpty == true)
                  _companyLine('IF: ${companySettings['company_if']}', font),
              ]),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: pw.BoxDecoration(
                  color: _amber,
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
                  pw.Text('AVOIR',
                      style: pw.TextStyle(
                          font: fontBold, fontSize: 20, color: PdfColors.white)),
                  pw.SizedBox(height: 4),
                  pw.Text(cn.reference,
                      style: pw.TextStyle(
                          font: fontBold, fontSize: 13, color: PdfColors.white)),
                  pw.SizedBox(height: 6),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: pw.BoxDecoration(
                      color: statusColor.shade(0.6),
                      borderRadius: pw.BorderRadius.circular(4),
                    ),
                    child: pw.Text(cn.status,
                        style: pw.TextStyle(
                            font: fontBold, fontSize: 10, color: PdfColors.white)),
                  ),
                ]),
              ),
            ],
          ),
          pw.SizedBox(height: 20),

          // ── Info row ───────────────────────────────────────────────────────
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: pw.BoxDecoration(
              color: _lightGrey,
              borderRadius: pw.BorderRadius.circular(6),
            ),
            child: pw.Row(children: [
              _labelValue("Date d'émission",
                  MoroccoFormat.dateFromMs(cn.issueDate), font, fontBold),
              pw.SizedBox(width: 32),
              _labelValue('Facture d\'origine',
                  cn.invoiceReference ?? '—', font, fontBold),
              pw.SizedBox(width: 32),
              _labelValue('Client', cn.clientName ?? '—', font, fontBold),
            ]),
          ),
          pw.SizedBox(height: 20),

          // ── Reason ────────────────────────────────────────────────────────
          if (cn.reason != null && cn.reason!.isNotEmpty) ...[
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: _borderGrey),
                borderRadius: pw.BorderRadius.circular(6),
              ),
              child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                pw.Text('MOTIF',
                    style: pw.TextStyle(font: fontBold, fontSize: 8, color: _grey)),
                pw.SizedBox(height: 4),
                pw.Text(cn.reason!,
                    style: pw.TextStyle(font: fontIta, fontSize: 11)),
              ]),
            ),
            pw.SizedBox(height: 20),
          ],

          // ── Amount box ────────────────────────────────────────────────────
          pw.Row(mainAxisAlignment: pw.MainAxisAlignment.end, children: [
            pw.Container(
              width: 220,
              child: pw.Column(children: [
                _totalRow('Montant HT', MoroccoFormat.mad(cn.totalHt), font),
                _totalRow('TVA', MoroccoFormat.mad(cn.totalTva), font),
                pw.Container(height: 0.5, color: _grey),
                pw.SizedBox(height: 4),
                _totalRow('Total Avoir TTC', MoroccoFormat.mad(cn.totalTtc), fontBold,
                    large: true, color: _amber),
              ]),
            ),
          ]),
          pw.Spacer(),

          // ── Footer note ────────────────────────────────────────────────────
          pw.Divider(color: _borderGrey),
          pw.SizedBox(height: 6),
          pw.Center(
            child: pw.Text(
              'Cet avoir est valable pour déduction sur votre prochaine facture.',
              style: pw.TextStyle(font: fontIta, fontSize: 9, color: _grey),
            ),
          ),
        ],
      ),
    ));
    return doc.save();
  }

  // ── Purchase Order PDF ───────────────────────────────────────────────────────

  static Future<Uint8List> generatePurchaseOrder(
    PurchaseOrder order,
    Map<String, String> companySettings,
  ) async {
    final doc      = pw.Document();
    final font     = await PdfGoogleFonts.nunitoRegular();
    final fontBold = await PdfGoogleFonts.nunitoBold();
    final fontIta  = await PdfGoogleFonts.nunitoItalic();

    final statusColor = _statusPdfColor(order.status);

    doc.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.fromLTRB(32, 32, 32, 40),
      footer: (ctx) => pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(companySettings['company_name'] ?? '',
              style: pw.TextStyle(font: font, fontSize: 7, color: _grey)),
          pw.Text('Page ${ctx.pageNumber} / ${ctx.pagesCount}',
              style: pw.TextStyle(font: font, fontSize: 7, color: _grey)),
          pw.Text(order.reference,
              style: pw.TextStyle(font: fontBold, fontSize: 7, color: _grey)),
        ],
      ),
      build: (ctx) => [
        // ── Header ──────────────────────────────────────────────────────────
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
              pw.Text(
                companySettings['company_name'] ?? 'Ma Société',
                style: pw.TextStyle(font: fontBold, fontSize: 18, color: _primaryColor),
              ),
              pw.SizedBox(height: 6),
              if (companySettings['company_address']?.isNotEmpty == true)
                _companyLine(companySettings['company_address']!, font),
              if (companySettings['company_city']?.isNotEmpty == true)
                _companyLine(companySettings['company_city']!, font),
              if (companySettings['company_phone']?.isNotEmpty == true)
                _companyLine('Tél: ${companySettings['company_phone']}', font),
              if (companySettings['company_ice']?.isNotEmpty == true)
                _companyLine('ICE: ${companySettings['company_ice']}', font),
            ]),
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: pw.BoxDecoration(
                color: _accentColor,
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
                pw.Text('BON DE COMMANDE',
                    style: pw.TextStyle(
                        font: fontBold, fontSize: 16, color: PdfColors.white)),
                pw.SizedBox(height: 4),
                pw.Text(order.reference,
                    style: pw.TextStyle(
                        font: fontBold, fontSize: 13, color: PdfColors.white)),
                pw.SizedBox(height: 6),
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: pw.BoxDecoration(
                    color: statusColor.shade(0.6),
                    borderRadius: pw.BorderRadius.circular(4),
                  ),
                  child: pw.Text(order.status,
                      style: pw.TextStyle(
                          font: fontBold, fontSize: 10, color: PdfColors.white)),
                ),
              ]),
            ),
          ],
        ),
        pw.SizedBox(height: 20),

        // ── Info row ───────────────────────────────────────────────────────
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: pw.BoxDecoration(
            color: _lightGrey,
            borderRadius: pw.BorderRadius.circular(6),
          ),
          child: pw.Row(children: [
            _labelValue('Date',
                MoroccoFormat.dateFromMs(order.date), font, fontBold),
            pw.SizedBox(width: 32),
            _labelValue('Fournisseur', order.supplierName ?? '—', font, fontBold),
            pw.SizedBox(width: 32),
            _labelValue('Statut', order.status, font, fontBold),
          ]),
        ),
        pw.SizedBox(height: 20),

        // ── Items table ──────────────────────────────────────────────────────
        pw.Table(
          border: null,
          columnWidths: {
            0: const pw.FlexColumnWidth(4),
            1: const pw.FlexColumnWidth(1),
            2: const pw.FlexColumnWidth(1.5),
            3: const pw.FlexColumnWidth(0.8),
            4: const pw.FlexColumnWidth(1.5),
          },
          children: [
            pw.TableRow(
              decoration: pw.BoxDecoration(color: _accentColor),
              children: [
                _th('DÉSIGNATION',   fontBold),
                _th('QTÉ',           fontBold, align: pw.TextAlign.right),
                _th('PRIX UNIT. HT', fontBold, align: pw.TextAlign.right),
                _th('TVA',           fontBold, align: pw.TextAlign.center),
                _th('TOTAL TTC',     fontBold, align: pw.TextAlign.right),
              ],
            ),
            ...order.items.asMap().entries.map((e) {
              final idx  = e.key;
              final item = e.value;
              final bg   = idx % 2 == 0 ? PdfColors.white : const PdfColor.fromInt(0xFFF8F9FC);
              return pw.TableRow(
                decoration: pw.BoxDecoration(
                  color: bg,
                  border: pw.Border(bottom: pw.BorderSide(color: _borderGrey, width: 0.5)),
                ),
                children: [
                  _td(item.description, font),
                  _td(_qty(item.quantity), font, align: pw.TextAlign.right),
                  _td(MoroccoFormat.mad(item.unitPriceHt), font, align: pw.TextAlign.right),
                  _td('${item.tvaRate.toStringAsFixed(0)}%', font, align: pw.TextAlign.center),
                  _td(MoroccoFormat.mad(item.lineTtc), fontBold, align: pw.TextAlign.right),
                ],
              );
            }),
          ],
        ),
        pw.SizedBox(height: 16),

        // ── Totals ─────────────────────────────────────────────────────────
        pw.Row(mainAxisAlignment: pw.MainAxisAlignment.end, children: [
          pw.Container(
            width: 220,
            child: pw.Column(children: [
              _totalRow('Total HT', MoroccoFormat.mad(order.totalHt), font),
              _totalRow('TVA', MoroccoFormat.mad(order.totalTva), font),
              pw.Container(height: 0.5, color: _grey),
              pw.SizedBox(height: 4),
              _totalRow('Total TTC', MoroccoFormat.mad(order.totalTtc), fontBold,
                  large: true, color: _accentColor),
            ]),
          ),
        ]),

        // ── Notes ──────────────────────────────────────────────────────────
        if (order.notes != null && order.notes!.isNotEmpty) ...[
          pw.SizedBox(height: 20),
          pw.Text('Notes:', style: pw.TextStyle(font: fontBold, fontSize: 9)),
          pw.Text(order.notes!,
              style: pw.TextStyle(font: fontIta, fontSize: 9, color: _grey)),
        ],

        // ── Signature zone ──────────────────────────────────────────────────
        pw.SizedBox(height: 30),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Container(
              width: 180,
              child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                pw.Text('Cachet & Signature acheteur',
                    style: pw.TextStyle(font: fontBold, fontSize: 8, color: _grey)),
                pw.SizedBox(height: 40),
                pw.Container(height: 0.5, color: _grey),
              ]),
            ),
            pw.Container(
              width: 180,
              child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                pw.Text('Bon pour accord fournisseur',
                    style: pw.TextStyle(font: fontBold, fontSize: 8, color: _grey)),
                pw.SizedBox(height: 40),
                pw.Container(height: 0.5, color: _grey),
              ]),
            ),
          ],
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
    final doc      = pw.Document();
    final font     = await PdfGoogleFonts.nunitoRegular();
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
    final doc      = pw.Document();
    final font     = await PdfGoogleFonts.nunitoRegular();
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

  // ── Print / share helpers ─────────────────────────────────────────────────────

  static Future<void> printDoc(Uint8List pdfBytes) async {
    await Printing.layoutPdf(onLayout: (_) async => pdfBytes);
  }

  static Future<void> shareDoc(Uint8List pdfBytes, String filename) async {
    await Printing.sharePdf(bytes: pdfBytes, filename: filename);
  }

  // ── Private helpers ───────────────────────────────────────────────────────────

  static PdfColor _statusPdfColor(String status) {
    switch (status) {
      case 'Payée':
      case 'Reçu':
      case 'Validé':
      case 'Appliqué':
        return _green;
      case 'En retard':
      case 'Annulé':
      case 'Annulée':
        return _red;
      case 'Envoyée':
      case 'Envoyé':
      case 'Émis':
        return PdfColor.fromInt(0xFF1976D2);
      default:
        return _grey;
    }
  }

  static pw.Widget _companyLine(String text, pw.Font font) =>
      pw.Text(text, style: pw.TextStyle(font: font, fontSize: 9, color: _grey));

  static pw.Widget _labelValue(String label, String value,
      pw.Font font, pw.Font fontBold, {PdfColor? color}) =>
      pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
        pw.Text(label,
            style: pw.TextStyle(font: font, fontSize: 8, color: _grey)),
        pw.Text(value,
            style: pw.TextStyle(
                font: fontBold, fontSize: 11, color: color ?? PdfColors.black)),
      ]);

  static pw.Widget _th(String text, pw.Font fontBold,
      {pw.TextAlign align = pw.TextAlign.left}) =>
      pw.Padding(
        padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: pw.Text(text,
            textAlign: align,
            style: pw.TextStyle(font: fontBold, fontSize: 9, color: PdfColors.white)),
      );

  static pw.Widget _td(String text, pw.Font font,
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
              style: pw.TextStyle(font: fontBold, fontSize: 9, color: color)),
        ),
        ...rows.map((r) => pw.Padding(
              padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                pw.Text(r[0], style: pw.TextStyle(font: font, fontSize: 10)),
                pw.Text(r[1], style: pw.TextStyle(font: fontBold, fontSize: 10)),
              ]),
            )),
      ]);

  /// Format quantity: no decimals if integer.
  static String _qty(double q) =>
      q % 1 == 0 ? q.toStringAsFixed(0) : q.toStringAsFixed(2);
}
