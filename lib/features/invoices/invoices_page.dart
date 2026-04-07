import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/providers.dart';
import '../../core/utils/morocco_format.dart';

class InvoicesPage extends ConsumerStatefulWidget {
  const InvoicesPage({super.key});
  @override
  ConsumerState<InvoicesPage> createState() => _InvoicesPageState();
}

class _InvoicesPageState extends ConsumerState<InvoicesPage> {
  String _selectedStatus = 'Tous';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final async = ref.watch(invoiceProvider);
    final statuses = ['Tous', ...MoroccoFormat.invoiceStatuses];

    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerLowest,
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Factures Clients',
                        style: theme.textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    async.whenOrNull(
                            data: (list) =>
                                Text('${list.length} factures',
                                    style: theme.textTheme.bodyMedium
                                        ?.copyWith(
                                            color: theme.colorScheme
                                                .onSurfaceVariant))) ??
                        const SizedBox.shrink(),
                  ],
                ),
                Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.download_outlined, size: 18),
                      label: const Text('Exporter'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Nouvelle facture'),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Summary badges
            async.maybeWhen(
              data: (invoices) {
                final paid = invoices
                    .where((i) => i.status == 'Payée')
                    .length;
                final sent = invoices
                    .where((i) => i.status == 'Envoyée')
                    .length;
                final overdue = invoices
                    .where((i) => i.status == 'En retard')
                    .length;
                return Row(children: [
                  _MiniStat(
                      label: 'Payées',
                      count: '$paid',
                      color: Colors.green),
                  const SizedBox(width: 12),
                  _MiniStat(
                      label: 'Envoyées',
                      count: '$sent',
                      color: const Color(0xFF1565C0)),
                  const SizedBox(width: 12),
                  _MiniStat(
                      label: 'En retard',
                      count: '$overdue',
                      color: Colors.red),
                ]);
              },
              orElse: () => const SizedBox.shrink(),
            ),
            const SizedBox(height: 16),

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
                      onSelected: (_) =>
                          setState(() => _selectedStatus = s),
                      showCheckmark: false,
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),

            Expanded(
              child: async.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Erreur: $e')),
                data: (invoices) {
                  final filtered = _selectedStatus == 'Tous'
                      ? invoices
                      : invoices
                          .where((i) => i.status == _selectedStatus)
                          .toList();
                  return Card(
                    child: SingleChildScrollView(
                      child: DataTable(
                        headingRowColor: WidgetStateProperty.all(
                            theme.colorScheme.surfaceContainerLowest),
                        columnSpacing: 16,
                        headingTextStyle:
                            theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                        columns: const [
                          DataColumn(label: Text('FACTURE')),
                          DataColumn(label: Text('CLIENT')),
                          DataColumn(label: Text('ÉMISSION')),
                          DataColumn(label: Text('ÉCHÉANCE')),
                          DataColumn(
                              label: Text('MONTANT HT'), numeric: true),
                          DataColumn(label: Text('TVA'), numeric: true),
                          DataColumn(
                              label: Text('TOTAL TTC'), numeric: true),
                          DataColumn(label: Text('STATUT')),
                          DataColumn(label: Text('ACTIONS')),
                        ],
                        rows: filtered
                            .map((inv) => DataRow(cells: [
                                  DataCell(Text(inv.reference,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w500))),
                                  DataCell(Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(inv.clientName ?? '—'),
                                      if (inv.companyName != null)
                                        Text(inv.companyName!,
                                            style: TextStyle(
                                                fontSize: 11,
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .onSurfaceVariant)),
                                    ],
                                  )),
                                  DataCell(Text(MoroccoFormat.date(
                                      inv.issuedDate))),
                                  DataCell(Text(
                                    MoroccoFormat.date(inv.dueDate),
                                    style: TextStyle(
                                        color: inv.isOverdue
                                            ? Colors.red.shade700
                                            : null),
                                  )),
                                  DataCell(Text(
                                      MoroccoFormat.mad(inv.totalHt))),
                                  DataCell(Text(
                                      MoroccoFormat.mad(inv.totalTva))),
                                  DataCell(Text(
                                    MoroccoFormat.mad(inv.totalTtc),
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600),
                                  )),
                                  DataCell(_InvoiceStatusChip(
                                      status: inv.status)),
                                  DataCell(Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(
                                            Icons.visibility_outlined,
                                            size: 18),
                                        onPressed: () {},
                                        visualDensity:
                                            VisualDensity.compact,
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                            Icons.picture_as_pdf_outlined,
                                            size: 18),
                                        onPressed: () {},
                                        tooltip: 'Télécharger PDF',
                                        visualDensity:
                                            VisualDensity.compact,
                                      ),
                                      PopupMenuButton<String>(
                                        icon: const Icon(Icons.more_vert,
                                            size: 18),
                                        itemBuilder: (ctx) =>
                                            MoroccoFormat.invoiceStatuses
                                                .map((s) =>
                                                    PopupMenuItem(
                                                        value: s,
                                                        child: Text(s)))
                                                .toList(),
                                        onSelected: (s) => ref
                                            .read(invoiceProvider
                                                .notifier)
                                            .updateStatus(inv.id!, s),
                                      ),
                                    ],
                                  )),
                                ]))
                            .toList(),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat(
      {required this.label,
      required this.count,
      required this.color});
  final String label;
  final String count;
  final Color color;
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
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
                color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text('$count $label',
              style: theme.textTheme.bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w500)),
        ],
      ),
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
        bg = Colors.green.withValues(alpha: 0.1);
        break;
      case 'Envoyée':
        color = const Color(0xFF1565C0);
        bg = const Color(0xFF1565C0).withValues(alpha: 0.1);
        break;
      case 'En retard':
        color = Colors.red.shade700;
        bg = Colors.red.withValues(alpha: 0.1);
        break;
      default: // Brouillon
        color = Colors.grey.shade600;
        bg = Colors.grey.withValues(alpha: 0.1);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
          color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(status,
          style: TextStyle(
              color: color, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}
