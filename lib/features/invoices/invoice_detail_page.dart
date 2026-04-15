import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/models/invoice.dart';
import '../../core/models/payment.dart';
import '../../core/providers/providers.dart';
import '../../core/services/pdf_service.dart';
import '../../core/utils/morocco_format.dart';

class InvoiceDetailPage extends ConsumerWidget {
  const InvoiceDetailPage({super.key, required this.invoiceId});
  final int invoiceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return FutureBuilder<Invoice?>(
      future: ref.read(invoiceRepoProvider).getById(invoiceId),
      builder: (ctx, snap) {
        if (!snap.hasData) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: CircularProgressIndicator()),
          );
        }
        final invoice = snap.data;
        if (invoice == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Facture introuvable')),
            body: const Center(child: Text('Facture introuvable')),
          );
        }

        return Scaffold(
          backgroundColor: theme.colorScheme.surfaceContainerLowest,
          appBar: AppBar(
            backgroundColor: theme.colorScheme.surface,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.pop(),
            ),
            title: Text(invoice.reference),
            actions: [
              IconButton(
                icon: const Icon(Icons.picture_as_pdf_outlined),
                tooltip: 'Imprimer PDF',
                onPressed: () async {
                  final settings =
                      ref.read(settingsProvider).valueOrNull ?? {};
                  final bytes = await PdfService.generateInvoice(
                      invoice, settings);
                  await PdfService.printDoc(bytes);
                },
              ),
              if (invoice.status != 'Payée' &&
                  invoice.status != 'Brouillon' &&
                  invoice.status != 'Annulée')
                FilledButton.icon(
                  onPressed: () =>
                      _showPaymentDialog(context, ref, invoice),
                  icon: const Icon(Icons.payments_outlined, size: 18),
                  label: const Text('Paiement'),
                ),
              const SizedBox(width: 8),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Header card ────────────────────────────────────────
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(invoice.reference,
                                        style: theme.textTheme.titleLarge
                                            ?.copyWith(
                                                fontWeight:
                                                    FontWeight.bold)),
                                    const SizedBox(height: 4),
                                    Text(
                                        invoice.clientName ??
                                            invoice.companyName ??
                                            '',
                                        style: theme.textTheme.bodyLarge),
                                  ],
                                ),
                              ),
                              _StatusBadge(invoice.status),
                            ]),
                            const Divider(height: 24),
                            Row(
                              children: [
                                _InfoChip(
                                    label: 'Date d\'émission',
                                    value: MoroccoFormat.date(
                                        invoice.issuedDate)),
                                const SizedBox(width: 24),
                                _InfoChip(
                                    label: 'Échéance',
                                    value: MoroccoFormat.date(
                                        invoice.dueDate),
                                    valueColor: invoice.isOverdue
                                        ? theme.colorScheme.error
                                        : null),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ── Items table ────────────────────────────────────────
                    if (invoice.items.isNotEmpty) ...[
                      Text('Articles',
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Card(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: DataTable(
                            columnSpacing: 20,
                            columns: const [
                              DataColumn(label: Text('Description')),
                              DataColumn(label: Text('Qté')),
                              DataColumn(label: Text('P.U. HT')),
                              DataColumn(label: Text('TVA %')),
                              DataColumn(label: Text('Total TTC')),
                            ],
                            rows: invoice.items.map((item) {
                              return DataRow(cells: [
                                DataCell(Text(item.description)),
                                DataCell(Text(item.quantity % 1 == 0
                                    ? item.quantity.toInt().toString()
                                    : item.quantity.toStringAsFixed(2))),
                                DataCell(Text(
                                    MoroccoFormat.mad(item.unitPriceHt))),
                                DataCell(
                                    Text('${item.tvaRate.toInt()}%')),
                                DataCell(Text(
                                    MoroccoFormat.mad(item.totalTtc),
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold))),
                              ]);
                            }).toList(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // ── Totals card ────────────────────────────────────────
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(children: [
                          _TotalRow(
                              label: 'Sous-total HT',
                              value: invoice.totalHt),
                          _TotalRow(
                              label: 'TVA',
                              value: invoice.totalTva),
                          const Divider(),
                          _TotalRow(
                              label: 'Total TTC',
                              value: invoice.totalTtc,
                              bold: true),
                          if (invoice.amountPaid > 0) ...[
                            _TotalRow(
                                label: 'Déjà payé',
                                value: -invoice.amountPaid,
                                color: Colors.green),
                            const Divider(),
                            _TotalRow(
                                label: 'Reste dû',
                                value: invoice.amountDue,
                                bold: true,
                                color: invoice.isFullyPaid
                                    ? Colors.green
                                    : theme.colorScheme.error),
                          ],
                        ]),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ── Payment history ────────────────────────────────────
                    _PaymentHistoryCard(invoiceId: invoiceId),

                    // ── Notes ──────────────────────────────────────────────
                    if (invoice.notes != null &&
                        invoice.notes!.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Notes',
                                  style: theme.textTheme.titleSmall),
                              const SizedBox(height: 8),
                              Text(invoice.notes!),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showPaymentDialog(
      BuildContext context, WidgetRef ref, Invoice invoice) {
    final amountCtrl = TextEditingController(
        text: invoice.amountDue.toStringAsFixed(2));
    String method = 'Virement';
    DateTime paymentDate = DateTime.now();
    final bankRefCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: Text('Paiement — ${invoice.reference}'),
          content: SizedBox(
            width: 380,
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  TextFormField(
                    controller: amountCtrl,
                    decoration: const InputDecoration(
                        labelText: 'Montant *', suffixText: 'MAD'),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    validator: (v) =>
                        (double.tryParse(v ?? '') ?? 0) <= 0
                            ? 'Montant invalide'
                            : null,
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: method,
                    decoration: const InputDecoration(
                        labelText: 'Mode de paiement'),
                    items: ['Espèces', 'Chèque', 'Virement', 'Carte']
                        .map((m) =>
                            DropdownMenuItem(value: m, child: Text(m)))
                        .toList(),
                    onChanged: (v) => setState(() => method = v!),
                  ),
                  const SizedBox(height: 10),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Date du paiement',
                        style: TextStyle(fontSize: 13)),
                    subtitle: Text(MoroccoFormat.date(paymentDate)),
                    trailing: const Icon(Icons.calendar_today, size: 18),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: ctx,
                        initialDate: paymentDate,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        setState(() => paymentDate = picked);
                      }
                    },
                  ),
                  TextFormField(
                    controller: bankRefCtrl,
                    decoration: const InputDecoration(
                        labelText: 'Réf. bancaire'),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: notesCtrl,
                    decoration:
                        const InputDecoration(labelText: 'Notes'),
                    maxLines: 2,
                  ),
                ]),
              ),
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Annuler')),
            FilledButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                final payment = PaymentReceived(
                  invoiceId: invoice.id!,
                  amount: double.parse(amountCtrl.text),
                  method: method,
                  paymentDate: paymentDate,
                  bankRef: bankRefCtrl.text.trim().isEmpty
                      ? null
                      : bankRefCtrl.text.trim(),
                  notes: notesCtrl.text.trim().isEmpty
                      ? null
                      : notesCtrl.text.trim(),
                );
                await ref
                    .read(paymentsReceivedProvider.notifier)
                    .record(payment, invoice.totalTtc);
                if (ctx.mounted) Navigator.of(ctx).pop();
              },
              child: const Text('Enregistrer'),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Helper Widgets ────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  const _StatusBadge(this.status);
  final String status;

  static const _colors = {
    'Brouillon': Colors.grey,
    'Envoyée':   Colors.blue,
    'Payée':     Colors.green,
    'En retard': Colors.red,
    'Annulée':   Colors.red,
  };

  @override
  Widget build(BuildContext context) {
    final color = _colors[status] ?? Colors.grey;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(status,
          style: TextStyle(
              color: color, fontWeight: FontWeight.w600, fontSize: 13)),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip(
      {required this.label, required this.value, this.valueColor});
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label,
          style: TextStyle(
              fontSize: 11, color: theme.colorScheme.onSurfaceVariant)),
      Text(value,
          style: TextStyle(
              fontWeight: FontWeight.w600, color: valueColor)),
    ]);
  }
}

class _TotalRow extends StatelessWidget {
  const _TotalRow(
      {required this.label,
      required this.value,
      this.bold = false,
      this.color});
  final String label;
  final double value;
  final bool bold;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
        fontWeight: bold ? FontWeight.bold : FontWeight.normal,
        fontSize: bold ? 16 : 14,
        color: color);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(children: [
        Expanded(child: Text(label, style: style)),
        Text(MoroccoFormat.mad(value.abs()), style: style),
      ]),
    );
  }
}

class _PaymentHistoryCard extends ConsumerWidget {
  const _PaymentHistoryCard({required this.invoiceId});
  final int invoiceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return FutureBuilder<List<PaymentReceived>>(
      future: ref
          .read(paymentsReceivedRepoProvider)
          .getByInvoiceId(invoiceId),
      builder: (ctx, snap) {
        if (!snap.hasData || snap.data!.isEmpty) {
          return const SizedBox.shrink();
        }
        final payments = snap.data!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Historique des paiements',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Card(
              child: Column(
                children: payments
                    .map((p) => ListTile(
                          leading: const Icon(Icons.payments_outlined),
                          title: Text(MoroccoFormat.mad(p.amount),
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green)),
                          subtitle: Text(
                              '${p.method} · ${MoroccoFormat.date(p.paymentDate)}'
                              '${p.bankRef != null ? ' · Réf: ${p.bankRef}' : ''}',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: theme
                                      .colorScheme.onSurfaceVariant)),
                          trailing: IconButton(
                            icon: Icon(Icons.delete_outline,
                                size: 18,
                                color: theme.colorScheme.error),
                            onPressed: () => ref
                                .read(paymentsReceivedProvider.notifier)
                                .remove(p.id!),
                          ),
                        ))
                    .toList(),
              ),
            ),
          ],
        );
      },
    );
  }
}
