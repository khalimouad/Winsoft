import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/invoice.dart';
import '../../core/models/client.dart';
import '../../core/models/credit_note.dart';
import '../../core/models/recurring_template.dart';
import '../../core/models/app_lists.dart';
import '../../core/models/payment.dart';
import '../../core/providers/providers.dart';
import '../../core/services/pdf_service.dart';
import '../../core/utils/morocco_format.dart';

class InvoicesPage extends ConsumerStatefulWidget {
  const InvoicesPage({super.key});
  @override
  ConsumerState<InvoicesPage> createState() => _InvoicesPageState();
}

class _InvoicesPageState extends ConsumerState<InvoicesPage>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerLowest,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
            child: Text('Facturation',
                style: theme.textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold)),
          ),
          TabBar(
            controller: _tab,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            tabs: const [
              Tab(text: 'Factures clients'),
              Tab(text: 'Avoirs'),
              Tab(text: 'Récurrentes'),
              Tab(text: 'Paiements reçus'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tab,
              children: const [
                _InvoicesTab(),
                _CreditNotesTab(),
                _RecurringTab(),
                _PaymentsReceivedTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Invoices Tab ──────────────────────────────────────────────────────────────

class _InvoicesTab extends ConsumerStatefulWidget {
  const _InvoicesTab();
  @override
  ConsumerState<_InvoicesTab> createState() => _InvoicesTabState();
}

class _InvoicesTabState extends ConsumerState<_InvoicesTab> {
  String _selectedStatus = 'Tous';

  @override
  Widget build(BuildContext context) {
    final theme     = Theme.of(context);
    final async     = ref.watch(invoiceProvider);
    final settings  = ref.watch(settingsProvider).valueOrNull ?? {};
    final lists     = ref.watch(appListsProvider).valueOrNull ?? AppLists.defaults;
    final statuses  = ['Tous', ...lists.invoiceStatuses];

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              async.whenOrNull(
                      data: (list) => Text('${list.length} factures',
                          style: theme.textTheme.bodyMedium?.copyWith(
                              color:
                                  theme.colorScheme.onSurfaceVariant))) ??
                  const SizedBox.shrink(),
              FilledButton.icon(
                onPressed: () => _showAddDialog(context, ref),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Nouvelle facture'),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Summary badges
          async.maybeWhen(
            data: (invoices) {
              final paid    = invoices.where((i) => i.status == 'Payée').length;
              final sent    = invoices.where((i) => i.status == 'Envoyée').length;
              final overdue = invoices.where((i) => i.status == 'En retard').length;
              return Row(children: [
                _MiniStat(label: 'Payées',    count: '$paid',    color: Colors.green),
                const SizedBox(width: 12),
                _MiniStat(label: 'Envoyées',  count: '$sent',    color: const Color(0xFF1565C0)),
                const SizedBox(width: 12),
                _MiniStat(label: 'En retard', count: '$overdue', color: Colors.red),
              ]);
            },
            orElse: () => const SizedBox.shrink(),
          ),
          const SizedBox(height: 12),

          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: statuses.map((s) {
                final isSelected = _selectedStatus == s;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(s),
                    selected: isSelected,
                    onSelected: (_) => setState(() => _selectedStatus = s),
                    showCheckmark: false,
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 12),

          Expanded(
            child: async.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error:   (e, _) => Center(child: Text('Erreur: $e')),
              data: (invoices) {
                final filtered = _selectedStatus == 'Tous'
                    ? invoices
                    : invoices.where((i) => i.status == _selectedStatus).toList();
                return Card(
                  child: SingleChildScrollView(
                    child: DataTable(
                      headingRowColor: WidgetStateProperty.all(
                          theme.colorScheme.surfaceContainerLowest),
                      columnSpacing: 16,
                      headingTextStyle: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                      columns: const [
                        DataColumn(label: Text('FACTURE')),
                        DataColumn(label: Text('CLIENT')),
                        DataColumn(label: Text('ÉMISSION')),
                        DataColumn(label: Text('ÉCHÉANCE')),
                        DataColumn(label: Text('TOTAL TTC'),   numeric: true),
                        DataColumn(label: Text('PAYÉ'),        numeric: true),
                        DataColumn(label: Text('RESTE DÛ'),    numeric: true),
                        DataColumn(label: Text('STATUT')),
                        DataColumn(label: Text('ACTIONS')),
                      ],
                      rows: filtered.map((inv) => DataRow(cells: [
                        DataCell(Text(inv.reference,
                            style: const TextStyle(fontWeight: FontWeight.w500))),
                        DataCell(Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(inv.clientName ?? '—'),
                            if (inv.companyName != null)
                              Text(inv.companyName!,
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: theme.colorScheme.onSurfaceVariant)),
                          ],
                        )),
                        DataCell(Text(MoroccoFormat.date(inv.issuedDate))),
                        DataCell(Text(
                          MoroccoFormat.date(inv.dueDate),
                          style: TextStyle(
                              color: inv.isOverdue ? Colors.red.shade700 : null),
                        )),
                        DataCell(Text(
                          MoroccoFormat.mad(inv.totalTtc),
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        )),
                        DataCell(Text(
                          MoroccoFormat.mad(inv.amountPaid),
                          style: TextStyle(
                            color: inv.amountPaid > 0
                                ? Colors.green.shade700
                                : null,
                          ),
                        )),
                        DataCell(Text(
                          MoroccoFormat.mad(inv.amountDue),
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: inv.amountDue > 0.01
                                ? Colors.red.shade700
                                : Colors.green.shade700,
                          ),
                        )),
                        DataCell(_InvoiceStatusChip(status: inv.status)),
                        DataCell(Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (inv.status != 'Payée' &&
                                inv.status != 'Brouillon' &&
                                inv.status != 'Annulé')
                              Tooltip(
                                message: 'Enregistrer un paiement',
                                child: IconButton(
                                  icon: const Icon(Icons.payments_outlined,
                                      size: 18),
                                  visualDensity: VisualDensity.compact,
                                  onPressed: () => _showPaymentDialog(
                                      context, ref, inv),
                                ),
                              ),
                            IconButton(
                              icon: const Icon(
                                  Icons.picture_as_pdf_outlined, size: 18),
                              tooltip: 'Imprimer / Partager PDF',
                              visualDensity: VisualDensity.compact,
                              onPressed: () =>
                                  _printInvoice(context, inv, settings),
                            ),
                            PopupMenuButton<String>(
                              icon: const Icon(Icons.more_vert, size: 18),
                              itemBuilder: (ctx) =>
                                  lists.invoiceStatuses
                                      .map((s) => PopupMenuItem(
                                          value: s, child: Text(s)))
                                      .toList(),
                              onSelected: (s) => ref
                                  .read(invoiceProvider.notifier)
                                  .updateStatus(inv.id!, s),
                            ),
                          ],
                        )),
                      ])).toList(),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _printInvoice(BuildContext context, Invoice inv,
      Map<String, String> settings) async {
    try {
      final bytes = await PdfService.generateInvoice(inv, settings);
      await PdfService.printDoc(bytes);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur PDF: $e')));
      }
    }
  }

  void _showAddDialog(BuildContext context, WidgetRef ref) {
    final clientsAsync = ref.read(clientProvider);
    clientsAsync.whenData((clients) {
      if (clients.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Ajoutez d\'abord un client')));
        return;
      }
      int? selectedClientId = clients.first.id;
      final descCtrl  = TextEditingController();
      final qtyCtrl   = TextEditingController(text: '1');
      final priceCtrl = TextEditingController();
      final formKey   = GlobalKey<FormState>();

      showDialog(
        context: context,
        builder: (ctx) => StatefulBuilder(
          builder: (ctx, setState) => AlertDialog(
            title: const Text('Nouvelle facture'),
            content: SizedBox(
              width: 420,
              child: Form(
                key: formKey,
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  DropdownButtonFormField<int>(
                    value: selectedClientId,
                    decoration: const InputDecoration(labelText: 'Client *'),
                    items: clients
                        .map((c) => DropdownMenuItem(
                            value: c.id, child: Text(c.name)))
                        .toList(),
                    onChanged: (v) =>
                        setState(() => selectedClientId = v),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: descCtrl,
                    decoration: const InputDecoration(
                        labelText: 'Description *'),
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Requis' : null,
                  ),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(
                      child: TextFormField(
                        controller: qtyCtrl,
                        decoration:
                            const InputDecoration(labelText: 'Quantité'),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: priceCtrl,
                        decoration: const InputDecoration(
                            labelText: 'Prix HT *'),
                        keyboardType: TextInputType.number,
                        validator: (v) =>
                            v == null || v.isEmpty ? 'Requis' : null,
                      ),
                    ),
                  ]),
                ]),
              ),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Annuler')),
              FilledButton(
                onPressed: () async {
                  if (!formKey.currentState!.validate()) return;
                  final qty   = double.tryParse(qtyCtrl.text) ?? 1;
                  final price = double.tryParse(priceCtrl.text) ?? 0;
                  final ht    = qty * price;
                  final tvaRate = (double.tryParse(ref.read(settingsProvider).valueOrNull?['tva_default'] ?? '20') ?? 20) / 100;
                  final tva   = ht * tvaRate;
                  final repo  = ref.read(invoiceRepoProvider);
                  final seq   = await repo.nextSequence();
                  final now   = DateTime.now();
                  final dueDays = int.tryParse(ref.read(settingsProvider).valueOrNull?['invoice_due_days'] ?? '30') ?? 30;
                  final due   = now.add(Duration(days: dueDays));
                  final invoice = Invoice(
                    reference: '${ref.read(settingsProvider).valueOrNull?['invoice_prefix'] ?? 'FAC'}-${now.year}-${seq.toString().padLeft(3, '0')}',
                    clientId: selectedClientId!,
                    issuedDate: now,
                    dueDate: due,
                    totalHt: ht,
                    totalTva: tva,
                    totalTtc: ht + tva,
                    items: [
                      InvoiceItem(
                        invoiceId: 0,
                        description: descCtrl.text.trim(),
                        quantity: qty,
                        unitPriceHt: price,
                      ),
                    ],
                  );
                  await ref.read(invoiceProvider.notifier).add(invoice, invoice.items);
                  if (ctx.mounted) Navigator.of(ctx).pop();
                },
                child: const Text('Créer'),
              ),
            ],
          ),
        ),
      );
    });
  }
  void _showPaymentDialog(
      BuildContext context, WidgetRef ref, Invoice inv) {
    final amountCtrl =
        TextEditingController(text: inv.amountDue.toStringAsFixed(2));
    final bankRefCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    String selectedMethod = 'Virement';
    DateTime selectedDate = DateTime.now();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: Text('Paiement — ${inv.reference}'),
          content: SizedBox(
            width: 380,
            child: Form(
              key: formKey,
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text(
                  'Reste dû: ${MoroccoFormat.mad(inv.amountDue)}',
                  style: TextStyle(
                      color: Colors.red.shade700, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: amountCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration:
                      const InputDecoration(labelText: 'Montant payé (MAD) *'),
                  validator: (v) {
                    final n = double.tryParse(v ?? '');
                    if (n == null || n <= 0) return 'Montant invalide';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedMethod,
                  decoration:
                      const InputDecoration(labelText: 'Mode de paiement'),
                  items: ['Espèces', 'Chèque', 'Virement', 'Carte']
                      .map((m) =>
                          DropdownMenuItem(value: m, child: Text(m)))
                      .toList(),
                  onChanged: (v) =>
                      setState(() => selectedMethod = v ?? selectedMethod),
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: () async {
                    final d = await showDatePicker(
                      context: ctx,
                      initialDate: selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2100),
                    );
                    if (d != null) setState(() => selectedDate = d);
                  },
                  child: InputDecorator(
                    decoration:
                        const InputDecoration(labelText: 'Date du paiement'),
                    child:
                        Text(MoroccoFormat.date(selectedDate)),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: bankRefCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Réf. bancaire / N° chèque'),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: notesCtrl,
                  decoration: const InputDecoration(labelText: 'Notes'),
                ),
              ]),
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
                  invoiceId: inv.id!,
                  amount: double.parse(amountCtrl.text),
                  method: selectedMethod,
                  paymentDate: selectedDate,
                  bankRef:
                      bankRefCtrl.text.isEmpty ? null : bankRefCtrl.text,
                  notes: notesCtrl.text.isEmpty ? null : notesCtrl.text,
                );
                await ref
                    .read(paymentsReceivedProvider.notifier)
                    .record(payment, inv.totalTtc);
                if (ctx.mounted) {
                  Navigator.of(ctx).pop();
                  ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
                    content: Text('Paiement enregistré'),
                    backgroundColor: Colors.green,
                  ));
                }
              },
              child: const Text('Enregistrer'),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Payments Received Tab ─────────────────────────────────────────────────────

class _PaymentsReceivedTab extends ConsumerWidget {
  const _PaymentsReceivedTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final async = ref.watch(paymentsReceivedProvider);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          async.whenOrNull(
                  data: (list) => Text(
                      '${list.length} paiements reçus',
                      style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant))) ??
              const SizedBox.shrink(),
          const SizedBox(height: 16),
          Expanded(
            child: async.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Erreur: $e')),
              data: (payments) {
                if (payments.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.payments_outlined,
                            size: 48,
                            color: theme.colorScheme.onSurfaceVariant),
                        const SizedBox(height: 12),
                        Text('Aucun paiement enregistré',
                            style: theme.textTheme.bodyLarge?.copyWith(
                                color:
                                    theme.colorScheme.onSurfaceVariant)),
                        const SizedBox(height: 4),
                        Text(
                            'Utilisez le bouton "paiement" sur une facture envoyée',
                            style: theme.textTheme.bodySmall?.copyWith(
                                color:
                                    theme.colorScheme.onSurfaceVariant)),
                      ],
                    ),
                  );
                }

                final totalCollected = payments.fold(
                    0.0, (sum, p) => sum + p.amount);

                return Column(
                  children: [
                    // Summary banner
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                        color:
                            Colors.green.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(children: [
                        const Icon(Icons.check_circle_outline,
                            color: Colors.green, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Total encaissé: ${MoroccoFormat.mad(totalCollected)}',
                          style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.green),
                        ),
                      ]),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: Card(
                        child: SingleChildScrollView(
                          child: DataTable(
                            headingRowColor: WidgetStateProperty.all(
                                theme.colorScheme
                                    .surfaceContainerLowest),
                            columnSpacing: 16,
                            headingTextStyle:
                                theme.textTheme.labelMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                            ),
                            columns: const [
                              DataColumn(label: Text('FACTURE')),
                              DataColumn(label: Text('CLIENT')),
                              DataColumn(label: Text('DATE')),
                              DataColumn(label: Text('MODE')),
                              DataColumn(label: Text('RÉF. BANCAIRE')),
                              DataColumn(
                                  label: Text('MONTANT'), numeric: true),
                              DataColumn(label: Text('ACTIONS')),
                            ],
                            rows: payments
                                .map((p) => DataRow(cells: [
                                      DataCell(Text(
                                          p.invoiceRef ?? '—',
                                          style: const TextStyle(
                                              fontWeight:
                                                  FontWeight.w500))),
                                      DataCell(
                                          Text(p.clientName ?? '—')),
                                      DataCell(Text(
                                          MoroccoFormat.date(
                                              p.paymentDate))),
                                      DataCell(Text(p.method)),
                                      DataCell(
                                          Text(p.bankRef ?? '—')),
                                      DataCell(Text(
                                        MoroccoFormat.mad(p.amount),
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            color: Colors.green),
                                      )),
                                      DataCell(IconButton(
                                        icon: const Icon(Icons.delete_outline,
                                            size: 18, color: Colors.red),
                                        tooltip: 'Supprimer',
                                        visualDensity: VisualDensity.compact,
                                        onPressed: () => ref
                                            .read(paymentsReceivedProvider
                                                .notifier)
                                            .remove(p.id!),
                                      )),
                                    ]))
                                .toList(),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── Credit Notes Tab ──────────────────────────────────────────────────────────

class _CreditNotesTab extends ConsumerWidget {
  const _CreditNotesTab();

  static const _statusColors = {
    'Brouillon': Colors.grey,
    'Émis':      Colors.blue,
    'Appliqué':  Colors.green,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme    = Theme.of(context);
    final cnAsync  = ref.watch(creditNoteProvider);
    final invAsync = ref.watch(invoiceProvider);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        Row(children: [
          const Spacer(),
          FilledButton.icon(
            onPressed: () => invAsync.whenData(
                (invoices) => _showAddDialog(context, ref, invoices)),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Nouvel avoir'),
          ),
        ]),
        const SizedBox(height: 12),
        Expanded(
          child: cnAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error:   (e, _) => Center(child: Text('Erreur: $e')),
            data: (notes) {
              if (notes.isEmpty) {
                return const Center(
                    child: Text('Aucun avoir / note de crédit'));
              }
              return ListView.builder(
                itemCount: notes.length,
                itemBuilder: (ctx, i) {
                  final cn    = notes[i];
                  final color = _statusColors[cn.status] ?? Colors.grey;
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      title: Row(children: [
                        Text(cn.reference,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600)),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(cn.status,
                              style: TextStyle(
                                  fontSize: 11,
                                  color: color,
                                  fontWeight: FontWeight.w600)),
                        ),
                      ]),
                      subtitle: Text(
                        '${cn.clientName ?? ''}'
                        '${cn.invoiceReference != null ? ' · Facture: ${cn.invoiceReference}' : ''}'
                        '${cn.reason != null ? '\n${cn.reason}' : ''}',
                        style: TextStyle(
                            fontSize: 12,
                            color: theme.colorScheme.onSurfaceVariant),
                      ),
                      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                        Text(MoroccoFormat.mad(cn.totalTtc),
                            style: const TextStyle(
                                fontWeight: FontWeight.bold)),
                        IconButton(
                          icon: const Icon(Icons.picture_as_pdf_outlined, size: 20),
                          tooltip: 'Imprimer PDF',
                          onPressed: () async {
                            final settings = ref.read(settingsProvider).valueOrNull ?? {};
                            final bytes = await PdfService.generateCreditNote(cn, settings);
                            await PdfService.printDoc(bytes);
                          },
                        ),
                        PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert, size: 18),
                          itemBuilder: (_) => [
                            ...(ref.read(appListsProvider).valueOrNull?.creditNoteStatuses
                                ?? AppLists.defaultCreditNoteStatuses)
                                .map((s) => PopupMenuItem(value: s, child: Text(s))),
                            const PopupMenuDivider(),
                            const PopupMenuItem(
                                value: '__delete',
                                child: Text('Supprimer',
                                    style: TextStyle(color: Colors.red))),
                          ],
                          onSelected: (s) {
                            if (s == '__delete') {
                              ref.read(creditNoteProvider.notifier)
                                  .remove(cn.id!);
                            } else {
                              ref.read(creditNoteProvider.notifier)
                                  .updateStatus(cn.id!, s);
                            }
                          },
                        ),
                      ]),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ]),
    );
  }

  void _showAddDialog(
      BuildContext context, WidgetRef ref, List<Invoice> invoices) {
    if (invoices.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Aucune facture pour créer un avoir')));
      return;
    }
    Invoice selectedInvoice = invoices.first;
    final reasonCtrl = TextEditingController();
    final htCtrl     = TextEditingController();
    final tvaCtrl    = TextEditingController(text: '20');
    final formKey    = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Nouvel avoir (note de crédit)'),
          content: SizedBox(
            width: 440,
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  DropdownButtonFormField<Invoice>(
                    value: selectedInvoice,
                    decoration: const InputDecoration(
                        labelText: 'Facture d\'origine *'),
                    items: invoices
                        .map((inv) => DropdownMenuItem(
                            value: inv,
                            child: Text(
                                '${inv.reference} — ${inv.clientName ?? ''}',
                                overflow: TextOverflow.ellipsis)))
                        .toList(),
                    onChanged: (v) =>
                        setState(() => selectedInvoice = v!),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: reasonCtrl,
                    decoration:
                        const InputDecoration(labelText: 'Motif'),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 10),
                  Row(children: [
                    Expanded(
                      child: TextFormField(
                        controller: htCtrl,
                        decoration: const InputDecoration(
                            labelText: 'Montant HT *'),
                        keyboardType: TextInputType.number,
                        validator: (v) =>
                            v == null || v.isEmpty ? 'Requis' : null,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: tvaCtrl,
                        decoration:
                            const InputDecoration(labelText: 'TVA %'),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ]),
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
                final ht   = double.tryParse(htCtrl.text) ?? 0;
                final tvaR = double.tryParse(tvaCtrl.text) ?? 20;
                final tva  = ht * tvaR / 100;
                final repo = ref.read(creditNoteRepoProvider);
                final seq  = await repo.nextSequence();
                final now  = DateTime.now().millisecondsSinceEpoch;
                final cn = CreditNote(
                  reference:
                      '${ref.read(settingsProvider).valueOrNull?['cn_prefix'] ?? 'AV'}-${DateTime.now().year}-${seq.toString().padLeft(3, '0')}',
                  clientId:   selectedInvoice.clientId,
                  invoiceId:  selectedInvoice.id!,
                  issueDate:  now,
                  totalHt:    ht,
                  totalTva:   tva,
                  totalTtc:   ht + tva,
                  reason: reasonCtrl.text.trim().isEmpty
                      ? null
                      : reasonCtrl.text.trim(),
                  createdAt: now,
                );
                await ref.read(creditNoteProvider.notifier).add(cn);
                if (ctx.mounted) Navigator.of(ctx).pop();
              },
              child: const Text('Créer'),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Recurring Templates Tab ───────────────────────────────────────────────────

class _RecurringTab extends ConsumerWidget {
  const _RecurringTab();

  static const _freqLabel = {
    'monthly':   'Mensuel',
    'quarterly': 'Trimestriel',
    'yearly':    'Annuel',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme     = Theme.of(context);
    final recurring = ref.watch(recurringProvider);
    final clients   = ref.watch(clientProvider);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        Row(children: [
          const Spacer(),
          FilledButton.icon(
            onPressed: () => clients.whenData(
                (c) => _showAddDialog(context, ref, c)),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Nouveau modèle'),
          ),
        ]),
        const SizedBox(height: 12),
        Expanded(
          child: recurring.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error:   (e, _) => Center(child: Text('Erreur: $e')),
            data: (templates) {
              if (templates.isEmpty) {
                return const Center(
                    child: Text('Aucun modèle récurrent'));
              }
              return ListView.builder(
                itemCount: templates.length,
                itemBuilder: (ctx, i) {
                  final t   = templates[i];
                  final due = DateTime.fromMillisecondsSinceEpoch(
                      t.nextDueDate);
                  final overdue = due.isBefore(DateTime.now());
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: Icon(Icons.repeat,
                          color: overdue
                              ? Colors.orange.shade700
                              : theme.colorScheme.primary),
                      title: Row(children: [
                        Expanded(
                          child: Text(t.name,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600)),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                              _freqLabel[t.frequency] ?? t.frequency,
                              style: TextStyle(
                                  fontSize: 11,
                                  color: theme.colorScheme
                                      .onPrimaryContainer,
                                  fontWeight: FontWeight.w600)),
                        ),
                      ]),
                      subtitle: Text(
                        '${t.clientName ?? ''} · '
                        'Prochaine: ${MoroccoFormat.date(due)}'
                        '${overdue ? ' ⚠ EN RETARD' : ''}',
                        style: TextStyle(
                            fontSize: 12,
                            color: overdue
                                ? Colors.orange.shade700
                                : theme.colorScheme.onSurfaceVariant),
                      ),
                      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                        Text(MoroccoFormat.mad(t.totalTtc),
                            style: const TextStyle(
                                fontWeight: FontWeight.bold)),
                        PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert, size: 18),
                          itemBuilder: (_) => [
                            const PopupMenuItem(
                                value: 'generate',
                                child: ListTile(
                                    leading:
                                        Icon(Icons.add_circle_outline),
                                    title: Text('Générer facture'),
                                    dense: true,
                                    contentPadding: EdgeInsets.zero)),
                            const PopupMenuItem(
                                value: 'delete',
                                child: ListTile(
                                    leading: Icon(Icons.delete_outline,
                                        color: Colors.red),
                                    title: Text('Supprimer',
                                        style: TextStyle(
                                            color: Colors.red)),
                                    dense: true,
                                    contentPadding: EdgeInsets.zero)),
                          ],
                          onSelected: (action) async {
                            if (action == 'delete') {
                              ref
                                  .read(recurringProvider.notifier)
                                  .remove(t.id!);
                            } else if (action == 'generate') {
                              await _generateInvoice(context, ref, t);
                            }
                          },
                        ),
                      ]),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ]),
    );
  }

  Future<void> _generateInvoice(
      BuildContext context, WidgetRef ref, RecurringTemplate t) async {
    try {
      final repo  = ref.read(invoiceRepoProvider);
      final seq   = await repo.nextSequence();
      final now   = DateTime.now();
      final dueDays = int.tryParse(ref.read(settingsProvider).valueOrNull?['invoice_due_days'] ?? '30') ?? 30;
      final due   = now.add(Duration(days: dueDays));
      final items = t.items.map((ri) => InvoiceItem(
        invoiceId: 0,
        description: ri.description,
        quantity: ri.quantity,
        unitPriceHt: ri.unitPriceHt,
        tvaRate: ri.tvaRate,
      )).toList();

      final invoice = Invoice(
        reference: '${ref.read(settingsProvider).valueOrNull?['invoice_prefix'] ?? 'FAC'}-${now.year}-${seq.toString().padLeft(3, '0')}',
        clientId:  t.clientId,
        issuedDate: now,
        dueDate:    due,
        totalHt:    t.totalHt,
        totalTva:   t.totalTva,
        totalTtc:   t.totalTtc,
        notes: 'Généré depuis modèle: ${t.name}',
        items: items,
      );

      await ref.read(invoiceProvider.notifier).add(invoice, items);

      // Advance next due date
      final nextDue = t.nextAfter(t.nextDueDate);
      await ref.read(recurringProvider.notifier)
          .updateNextDue(t.id!, nextDue);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
                'Facture ${invoice.reference} générée')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur: $e')));
      }
    }
  }

  void _showAddDialog(
      BuildContext context, WidgetRef ref, List<Client> clients) {
    if (clients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Ajoutez d\'abord un client')));
      return;
    }
    int? selectedClientId = clients.first.id;
    String selectedFreq   = 'monthly';
    final nameCtrl  = TextEditingController();
    final descCtrl  = TextEditingController();
    final priceCtrl = TextEditingController();
    final tvaCtrl   = TextEditingController(text: '20');
    final formKey   = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Nouveau modèle récurrent'),
          content: SizedBox(
            width: 440,
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  TextFormField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                        labelText: 'Nom du modèle *'),
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Requis' : null,
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<int>(
                    value: selectedClientId,
                    decoration:
                        const InputDecoration(labelText: 'Client *'),
                    items: clients
                        .map((c) => DropdownMenuItem(
                            value: c.id, child: Text(c.name)))
                        .toList(),
                    onChanged: (v) =>
                        setState(() => selectedClientId = v),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: selectedFreq,
                    decoration:
                        const InputDecoration(labelText: 'Fréquence'),
                    items: const [
                      DropdownMenuItem(
                          value: 'monthly',
                          child: Text('Mensuel')),
                      DropdownMenuItem(
                          value: 'quarterly',
                          child: Text('Trimestriel')),
                      DropdownMenuItem(
                          value: 'yearly', child: Text('Annuel')),
                    ],
                    onChanged: (v) =>
                        setState(() => selectedFreq = v!),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: descCtrl,
                    decoration: const InputDecoration(
                        labelText: 'Description article *'),
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Requis' : null,
                  ),
                  const SizedBox(height: 10),
                  Row(children: [
                    Expanded(
                      child: TextFormField(
                        controller: priceCtrl,
                        decoration: const InputDecoration(
                            labelText: 'Prix HT *'),
                        keyboardType: TextInputType.number,
                        validator: (v) =>
                            v == null || v.isEmpty ? 'Requis' : null,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: tvaCtrl,
                        decoration:
                            const InputDecoration(labelText: 'TVA %'),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ]),
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
                final ht   = double.tryParse(priceCtrl.text) ?? 0;
                final tvaR = double.tryParse(tvaCtrl.text) ?? 20;
                final tva  = ht * tvaR / 100;
                final now  = DateTime.now().millisecondsSinceEpoch;
                final template = RecurringTemplate(
                  name:        nameCtrl.text.trim(),
                  clientId:    selectedClientId!,
                  frequency:   selectedFreq,
                  nextDueDate: now,
                  totalHt:     ht,
                  totalTva:    tva,
                  totalTtc:    ht + tva,
                  createdAt:   now,
                  items: [
                    RecurringItem(
                      templateId: 0,
                      description: descCtrl.text.trim(),
                      quantity: 1,
                      unitPriceHt: ht,
                      tvaRate: tvaR,
                    ),
                  ],
                );
                await ref.read(recurringProvider.notifier).add(template);
                if (ctx.mounted) Navigator.of(ctx).pop();
              },
              child: const Text('Créer'),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Shared Widgets ────────────────────────────────────────────────────────────

class _MiniStat extends StatelessWidget {
  const _MiniStat(
      {required this.label, required this.count, required this.color});
  final String label;
  final String count;
  final Color  color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(
            width: 8,
            height: 8,
            decoration:
                BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Text('$count $label',
            style: theme.textTheme.bodyMedium
                ?.copyWith(fontWeight: FontWeight.w500)),
      ]),
    );
  }
}

class _InvoiceStatusChip extends StatelessWidget {
  const _InvoiceStatusChip({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    Color color;
    Color bg;
    switch (status) {
      case 'Payée':
        color = Colors.green.shade700;
        bg    = Colors.green.withValues(alpha: 0.1);
        break;
      case 'Envoyée':
        color = const Color(0xFF1565C0);
        bg    = const Color(0xFF1565C0).withValues(alpha: 0.1);
        break;
      case 'En retard':
        color = Colors.red.shade700;
        bg    = Colors.red.withValues(alpha: 0.1);
        break;
      default:
        color = Colors.grey.shade600;
        bg    = Colors.grey.withValues(alpha: 0.1);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(status,
          style: TextStyle(
              color: color, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}
