import 'package:flutter/material.dart';

class SalesPage extends StatefulWidget {
  const SalesPage({super.key});

  @override
  State<SalesPage> createState() => _SalesPageState();
}

class _SalesPageState extends State<SalesPage> {
  String _selectedStatus = 'All';

  final _orders = const [
    {
      'id': 'SO-2026-041',
      'client': 'Maria Gonzalez',
      'company': 'Horizon Group',
      'amount': '\$5,640',
      'date': 'Apr 6, 2026',
      'items': '3',
      'status': 'Processing'
    },
    {
      'id': 'SO-2026-040',
      'client': 'John Mitchell',
      'company': 'Acme Corporation',
      'amount': '\$4,200',
      'date': 'Apr 5, 2026',
      'items': '2',
      'status': 'Completed'
    },
    {
      'id': 'SO-2026-039',
      'client': 'Sarah Chen',
      'company': 'Globe Industries',
      'amount': '\$1,850',
      'date': 'Apr 4, 2026',
      'items': '1',
      'status': 'Completed'
    },
    {
      'id': 'SO-2026-038',
      'client': 'James Lee',
      'company': 'Delta Services',
      'amount': '\$9,100',
      'date': 'Apr 3, 2026',
      'items': '5',
      'status': 'Pending'
    },
    {
      'id': 'SO-2026-037',
      'client': 'Robert Torres',
      'company': 'TechStart Ltd',
      'amount': '\$3,100',
      'date': 'Mar 31, 2026',
      'items': '2',
      'status': 'Completed'
    },
    {
      'id': 'SO-2026-036',
      'client': 'Emily Watson',
      'company': 'Sunrise Retail',
      'amount': '\$750',
      'date': 'Mar 28, 2026',
      'items': '1',
      'status': 'Cancelled'
    },
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statuses = ['All', 'Pending', 'Processing', 'Completed', 'Cancelled'];
    final filtered = _selectedStatus == 'All'
        ? _orders
        : _orders.where((o) => o['status'] == _selectedStatus).toList();

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
                    Text('Sales Orders',
                        style: theme.textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    Text('${_orders.length} orders this month',
                        style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant)),
                  ],
                ),
                FilledButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.add_shopping_cart, size: 18),
                  label: const Text('New Order'),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Status filter chips
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
              child: Card(
                child: SingleChildScrollView(
                  child: DataTable(
                    headingRowColor: WidgetStateProperty.all(
                        theme.colorScheme.surfaceContainerLowest),
                    columnSpacing: 24,
                    headingTextStyle: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                    columns: const [
                      DataColumn(label: Text('ORDER ID')),
                      DataColumn(label: Text('CLIENT')),
                      DataColumn(label: Text('COMPANY')),
                      DataColumn(label: Text('ITEMS'), numeric: true),
                      DataColumn(label: Text('AMOUNT'), numeric: true),
                      DataColumn(label: Text('DATE')),
                      DataColumn(label: Text('STATUS')),
                      DataColumn(label: Text('ACTIONS')),
                    ],
                    rows: filtered
                        .map((o) => DataRow(cells: [
                              DataCell(Text(o['id']!,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w500))),
                              DataCell(Text(o['client']!)),
                              DataCell(Text(o['company']!)),
                              DataCell(Text(o['items']!)),
                              DataCell(Text(o['amount']!,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600))),
                              DataCell(Text(o['date']!)),
                              DataCell(_OrderStatus(status: o['status']!)),
                              DataCell(Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.visibility_outlined,
                                        size: 18),
                                    onPressed: () {},
                                    tooltip: 'View',
                                    visualDensity: VisualDensity.compact,
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                        Icons.receipt_long_outlined,
                                        size: 18),
                                    onPressed: () {},
                                    tooltip: 'Create Invoice',
                                    visualDensity: VisualDensity.compact,
                                  ),
                                ],
                              )),
                            ]))
                        .toList(),
                  ),
                ),
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
      case 'Completed':
        color = Colors.green.shade700;
        bg = Colors.green.withValues(alpha: 0.1);
        break;
      case 'Processing':
        color = const Color(0xFF1565C0);
        bg = const Color(0xFF1565C0).withValues(alpha: 0.1);
        break;
      case 'Pending':
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
