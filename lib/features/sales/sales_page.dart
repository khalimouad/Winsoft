import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/app_lists.dart';
import '../../core/providers/providers.dart';
import '../../core/services/document_workflow.dart';
import '../../core/utils/morocco_format.dart';

class SalesPage extends ConsumerStatefulWidget {
  const SalesPage({super.key});
  @override
  ConsumerState<SalesPage> createState() => _SalesPageState();
}

class _SalesPageState extends ConsumerState<SalesPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
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
            child: Text(
              'Ventes',
              style: theme.textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          TabBar(
            controller: _tabs,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            tabs: const [
              Tab(text: 'Bons de Commande'),
              Tab(text: 'Livraisons'),
              Tab(text: 'Bons de Retour'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: const [
                _OrdersTab(),
                _DeliveriesTab(),
                _ReturnNotesTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Orders tab ───────────────────────────────────────────────────────────────

class _OrdersTab extends ConsumerStatefulWidget {
  const _OrdersTab();
  @override
  ConsumerState<_OrdersTab> createState() => _OrdersTabState();
}

class _OrdersTabState extends ConsumerState<_OrdersTab> {
  String _selectedStatus = 'Tous';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final async = ref.watch(saleOrderProvider);
    final lists = ref.watch(appListsProvider).valueOrNull ?? AppLists.defaults;
    final statuses = ['Tous', ...lists.orderStatuses];

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              async.whenOrNull(
                      data: (list) => Text(
                          '${list.length} commandes',
                          style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant))) ??
                  const SizedBox.shrink(),
              FilledButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.add_shopping_cart, size: 18),
                label: const Text('Nouveau BC'),
              ),
            ],
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
                    onSelected: (_) =>
                        setState(() => _selectedStatus = s),
                    showCheckmark: false,
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 12),
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
                        DataColumn(label: Text('DATE')),
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
                                DataCell(Text(
                                    MoroccoFormat.date(o.date))),
                                DataCell(Text(
                                  MoroccoFormat.mad(o.totalTtc),
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600),
                                )),
                                DataCell(_StatusBadge(
                                    status: o.status,
                                    colorMap: _orderColors)),
                                DataCell(Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // Create BL from order
                                    Tooltip(
                                      message: 'Créer un bon de livraison',
                                      child: IconButton(
                                        icon: const Icon(
                                            Icons.local_shipping_outlined,
                                            size: 18),
                                        onPressed: () =>
                                            _createDelivery(context, o.id!),
                                        visualDensity: VisualDensity.compact,
                                      ),
                                    ),
                                    // Create invoice directly from order
                                    Tooltip(
                                      message: 'Facturer directement',
                                      child: IconButton(
                                        icon: const Icon(
                                            Icons.receipt_outlined,
                                            size: 18),
                                        onPressed: () =>
                                            _createInvoice(context, o.id!),
                                        visualDensity: VisualDensity.compact,
                                      ),
                                    ),
                                    PopupMenuButton<String>(
                                      icon: const Icon(Icons.more_vert,
                                          size: 18),
                                      itemBuilder: (ctx) =>
                                          lists.orderStatuses
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
    );
  }

  Future<void> _createDelivery(BuildContext context, int orderId) async {
    try {
      await DocumentWorkflowService.instance
          .createDeliveryFromOrder(orderId);
      ref.invalidate(deliveryProvider);
      ref.invalidate(saleOrderProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bon de livraison créé'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  Future<void> _createInvoice(BuildContext context, int orderId) async {
    try {
      await DocumentWorkflowService.instance
          .createInvoiceFromOrder(orderId);
      ref.invalidate(invoiceProvider);
      ref.invalidate(saleOrderProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Facture créée'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }
}

// ── Deliveries tab ───────────────────────────────────────────────────────────

class _DeliveriesTab extends ConsumerStatefulWidget {
  const _DeliveriesTab();
  @override
  ConsumerState<_DeliveriesTab> createState() => _DeliveriesTabState();
}

class _DeliveriesTabState extends ConsumerState<_DeliveriesTab> {
  String _selectedStatus = 'Tous';

  static const _statuses = ['Tous', 'Brouillon', 'Confirmé', 'Livré', 'Annulé'];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final async = ref.watch(deliveryProvider);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              async.whenOrNull(
                      data: (list) => Text(
                          '${list.length} livraisons',
                          style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant))) ??
                  const SizedBox.shrink(),
              FilledButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Nouveau BL'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _statuses.map((s) {
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
          const SizedBox(height: 12),
          Expanded(
            child: async.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Erreur: $e')),
              data: (deliveries) {
                final filtered = _selectedStatus == 'Tous'
                    ? deliveries
                    : deliveries
                        .where((d) => d.status == _selectedStatus)
                        .toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.local_shipping_outlined,
                            size: 48,
                            color: theme.colorScheme.onSurfaceVariant),
                        const SizedBox(height: 12),
                        Text('Aucune livraison',
                            style: theme.textTheme.bodyLarge?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant)),
                        const SizedBox(height: 4),
                        Text(
                            'Créez un BL depuis un bon de commande',
                            style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant)),
                      ],
                    ),
                  );
                }

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
                        DataColumn(label: Text('DATE')),
                        DataColumn(
                            label: Text('TOTAL TTC'), numeric: true),
                        DataColumn(label: Text('STATUT')),
                        DataColumn(label: Text('ACTIONS')),
                      ],
                      rows: filtered
                          .map((d) => DataRow(cells: [
                                DataCell(Text(d.reference,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w500))),
                                DataCell(Text(d.clientName ?? '—')),
                                DataCell(Text(
                                    MoroccoFormat.date(d.date))),
                                DataCell(Text(
                                  MoroccoFormat.mad(d.totalTtc),
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600),
                                )),
                                DataCell(_StatusBadge(
                                    status: d.status,
                                    colorMap: _deliveryColors)),
                                DataCell(Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Tooltip(
                                      message: 'Facturer ce BL',
                                      child: IconButton(
                                        icon: const Icon(
                                            Icons.receipt_outlined,
                                            size: 18),
                                        onPressed: d.status == 'Livré'
                                            ? () => _createInvoiceFromBl(
                                                context, d.id!)
                                            : null,
                                        visualDensity: VisualDensity.compact,
                                      ),
                                    ),
                                    PopupMenuButton<String>(
                                      icon: const Icon(Icons.more_vert,
                                          size: 18),
                                      itemBuilder: (ctx) => [
                                        'Brouillon',
                                        'Confirmé',
                                        'Livré',
                                        'Annulé'
                                      ]
                                          .map((s) => PopupMenuItem(
                                              value: s,
                                              child: Text(s)))
                                          .toList(),
                                      onSelected: (s) => ref
                                          .read(deliveryProvider.notifier)
                                          .updateStatus(d.id!, s),
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
    );
  }

  Future<void> _createInvoiceFromBl(
      BuildContext context, int deliveryId) async {
    try {
      await DocumentWorkflowService.instance
          .createInvoiceFromDelivery(deliveryId);
      ref.invalidate(invoiceProvider);
      ref.invalidate(deliveryProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Facture créée depuis le BL'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }
}

// ── Return Notes tab ─────────────────────────────────────────────────────────

class _ReturnNotesTab extends ConsumerStatefulWidget {
  const _ReturnNotesTab();
  @override
  ConsumerState<_ReturnNotesTab> createState() => _ReturnNotesTabState();
}

class _ReturnNotesTabState extends ConsumerState<_ReturnNotesTab> {
  String _selectedStatus = 'Tous';

  static const _statuses = [
    'Tous',
    'Brouillon',
    'Confirmé',
    'Traité',
    'Annulé'
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final async = ref.watch(returnNoteProvider);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              async.whenOrNull(
                      data: (list) => Text(
                          '${list.length} bons de retour',
                          style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant))) ??
                  const SizedBox.shrink(),
              FilledButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Nouveau BR'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _statuses.map((s) {
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
          const SizedBox(height: 12),
          Expanded(
            child: async.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Erreur: $e')),
              data: (returnNotes) {
                final filtered = _selectedStatus == 'Tous'
                    ? returnNotes
                    : returnNotes
                        .where((r) => r.status == _selectedStatus)
                        .toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.assignment_return_outlined,
                            size: 48,
                            color: theme.colorScheme.onSurfaceVariant),
                        const SizedBox(height: 12),
                        Text('Aucun bon de retour',
                            style: theme.textTheme.bodyLarge?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant)),
                      ],
                    ),
                  );
                }

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
                        DataColumn(label: Text('DATE')),
                        DataColumn(label: Text('MOTIF')),
                        DataColumn(
                            label: Text('TOTAL TTC'), numeric: true),
                        DataColumn(label: Text('STATUT')),
                        DataColumn(label: Text('ACTIONS')),
                      ],
                      rows: filtered
                          .map((r) => DataRow(cells: [
                                DataCell(Text(r.reference,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w500))),
                                DataCell(Text(r.clientName ?? '—')),
                                DataCell(Text(
                                    MoroccoFormat.date(r.date))),
                                DataCell(Text(
                                  r.reason.isEmpty ? '—' : r.reason,
                                  overflow: TextOverflow.ellipsis,
                                )),
                                DataCell(Text(
                                  MoroccoFormat.mad(r.totalTtc),
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600),
                                )),
                                DataCell(_StatusBadge(
                                    status: r.status,
                                    colorMap: _returnColors)),
                                DataCell(PopupMenuButton<String>(
                                  icon: const Icon(Icons.more_vert,
                                      size: 18),
                                  itemBuilder: (ctx) => [
                                    'Brouillon',
                                    'Confirmé',
                                    'Traité',
                                    'Annulé'
                                  ]
                                      .map((s) => PopupMenuItem(
                                          value: s, child: Text(s)))
                                      .toList(),
                                  onSelected: (s) => ref
                                      .read(returnNoteProvider.notifier)
                                      .updateStatus(r.id!, s),
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
    );
  }
}

// ── Shared helpers ────────────────────────────────────────────────────────────

const _orderColors = {
  'Terminée': (Colors.green, 0.1),
  'En cours': (Color(0xFF1565C0), 0.1),
  'En attente': (Colors.orange, 0.1),
};

const _deliveryColors = {
  'Livré': (Colors.green, 0.1),
  'Confirmé': (Color(0xFF1565C0), 0.1),
  'Brouillon': (Colors.grey, 0.1),
};

const _returnColors = {
  'Traité': (Colors.green, 0.1),
  'Confirmé': (Color(0xFF1565C0), 0.1),
  'Brouillon': (Colors.grey, 0.1),
};

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status, required this.colorMap});
  final String status;
  final Map<String, (Color, double)> colorMap;

  @override
  Widget build(BuildContext context) {
    final (color, alpha) =
        colorMap[status] ?? (Colors.red, 0.1);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
          color: color.withValues(alpha: alpha),
          borderRadius: BorderRadius.circular(20)),
      child: Text(status,
          style: TextStyle(
              color: color, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}
