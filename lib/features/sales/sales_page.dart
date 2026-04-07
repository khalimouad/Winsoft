import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/providers.dart';
import '../../core/utils/morocco_format.dart';

class SalesPage extends ConsumerStatefulWidget {
  const SalesPage({super.key});
  @override
  ConsumerState<SalesPage> createState() => _SalesPageState();
}

class _SalesPageState extends ConsumerState<SalesPage> {
  String _selectedStatus = 'Tous';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final async = ref.watch(saleOrderProvider);
    final statuses = [
      'Tous',
      ...MoroccoFormat.orderStatuses,
    ];

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
                    Text('Bons de Commande',
                        style: theme.textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    async.whenOrNull(
                            data: (list) => Text(
                                '${list.length} commandes ce mois',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme
                                        .onSurfaceVariant))) ??
                        const SizedBox.shrink(),
                  ],
                ),
                FilledButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.add_shopping_cart, size: 18),
                  label: const Text('Nouveau BC'),
                ),
              ],
            ),
            const SizedBox(height: 20),
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
                data: (orders) {
                  final filtered = _selectedStatus == 'Tous'
                      ? orders
                      : orders
                          .where((o) => o.status == _selectedStatus)
                          .toList();
                  return Card(
                    child: SingleChildScrollView(
                      child: DataTable(
                        headingRowColor: WidgetStateProperty.all(
                            theme.colorScheme.surfaceContainerLowest),
                        columnSpacing: 20,
                        headingTextStyle:
                            theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                        columns: const [
                          DataColumn(label: Text('RÉFÉRENCE')),
                          DataColumn(label: Text('CLIENT')),
                          DataColumn(label: Text('ENTREPRISE')),
                          DataColumn(label: Text('DATE')),
                          DataColumn(
                              label: Text('MONTANT HT'), numeric: true),
                          DataColumn(label: Text('TVA'), numeric: true),
                          DataColumn(
                              label: Text('TOTAL TTC'), numeric: true),
                          DataColumn(label: Text('STATUT')),
                          DataColumn(label: Text('ACTIONS')),
                        ],
                        rows: filtered
                            .map((o) => DataRow(cells: [
                                  DataCell(Text(o.reference,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w500))),
                                  DataCell(Text(o.clientName ?? '—')),
                                  DataCell(
                                      Text(o.companyName ?? '—')),
                                  DataCell(Text(
                                      MoroccoFormat.date(o.date))),
                                  DataCell(Text(
                                      MoroccoFormat.mad(o.totalHt))),
                                  DataCell(Text(
                                      MoroccoFormat.mad(o.totalTva))),
                                  DataCell(Text(
                                    MoroccoFormat.mad(o.totalTtc),
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600),
                                  )),
                                  DataCell(_OrderStatus(
                                      status: o.status)),
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
                                      PopupMenuButton<String>(
                                        icon: const Icon(Icons.more_vert,
                                            size: 18),
                                        itemBuilder: (ctx) =>
                                            MoroccoFormat.orderStatuses
                                                .map((s) =>
                                                    PopupMenuItem(
                                                        value: s,
                                                        child: Text(s)))
                                                .toList(),
                                        onSelected: (s) => ref
                                            .read(saleOrderProvider
                                                .notifier)
                                            .updateStatus(o.id!, s),
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

class _OrderStatus extends StatelessWidget {
  const _OrderStatus({required this.status});
  final String status;
  @override
  Widget build(BuildContext context) {
    Color color;
    Color bg;
    switch (status) {
      case 'Terminée':
        color = Colors.green.shade700;
        bg = Colors.green.withValues(alpha: 0.1);
        break;
      case 'En cours':
        color = const Color(0xFF1565C0);
        bg = const Color(0xFF1565C0).withValues(alpha: 0.1);
        break;
      case 'En attente':
        color = Colors.orange.shade700;
        bg = Colors.orange.withValues(alpha: 0.1);
        break;
      default:
        color = Colors.red.shade700;
        bg = Colors.red.withValues(alpha: 0.1);
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
