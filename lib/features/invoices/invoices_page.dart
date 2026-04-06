import 'package:flutter/material.dart';

class InvoicesPage extends StatefulWidget {
  const InvoicesPage({super.key});

  @override
  State<InvoicesPage> createState() => _InvoicesPageState();
}

class _InvoicesPageState extends State<InvoicesPage> {
  String _selectedStatus = 'All';

  final _invoices = const [
    {
      'id': 'INV-2026-001',
      'client': 'Maria Gonzalez',
      'company': 'Horizon Group',
      'amount': '\$5,640',
      'issued': 'Apr 6, 2026',
      'due': 'Apr 20, 2026',
      'status': 'Draft'
    },
    {
      'id': 'INV-2026-002',
      'client': 'John Mitchell',
      'company': 'Acme Corporation',
      'amount': '\$4,200',
      'issued': 'Apr 5, 2026',
      'due': 'Apr 19, 2026',
      'status': 'Paid'
    },
    {
      'id': 'INV-2026-003',
      'client': 'Sarah Chen',
      'company': 'Globe Industries',
      'amount': '\$1,850',
      'issued': 'Apr 4, 2026',
      'due': 'Apr 18, 2026',
      'status': 'Sent'
    },
    {
      'id': 'INV-2026-004',
      'client': 'James Lee',
      'company': 'Delta Services',
      'amount': '\$9,100',
      'issued': 'Mar 28, 2026',
      'due': 'Apr 11, 2026',
      'status': 'Overdue'
    },
    {
      'id': 'INV-2026-005',
      'client': 'Robert Torres',
      'company': 'TechStart Ltd',
      'amount': '\$3,100',
      'issued': 'Mar 25, 2026',
      'due': 'Apr 8, 2026',
      'status': 'Paid'
    },
    {
      'id': 'INV-2026-006',
      'client': 'Emily Watson',
      'company': 'Sunrise Retail',
      'amount': '\$750',
      'issued': 'Mar 20, 2026',
      'due': 'Apr 3, 2026',
      'status': 'Overdue'
    },
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statuses = ['All', 'Draft', 'Sent', 'Paid', 'Overdue'];
    final filtered = _selectedStatus == 'All'
        ? _invoices
        : _invoices.where((i) => i['status'] == _selectedStatus).toList();

    // Summary totals
    final totalPaid = _invoices.where((i) => i['status'] == 'Paid').length;
    final totalOverdue = _invoices.where((i) => i['status'] == 'Overdue').length;
    final totalSent = _invoices.where((i) => i['status'] == 'Sent').length;

    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerLowest,
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Invoices',
                        style: theme.textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    Text('${_invoices.length} invoices total',
                        style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant)),
                  ],
                ),
                Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.download_outlined, size: 18),
                      label: const Text('Export'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('New Invoice'),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Summary mini-cards
            Row(
              children: [
                _MiniStat(
                    label: 'Paid',
                    count: '$totalPaid',
                    color: Colors.green),
                const SizedBox(width: 12),
                _MiniStat(
                    label: 'Sent',
                    count: '$totalSent',
                    color: const Color(0xFF1565C0)),
                const SizedBox(width: 12),
                _MiniStat(
                    label: 'Overdue',
                    count: '$totalOverdue',
                    color: Colors.red),
              ],
            ),
            const SizedBox(height: 16),

            // Filter chips
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

            // Table
            Expanded(
              child: Card(
                child: SingleChildScrollView(
                  child: DataTable(
                    headingRowColor: WidgetStateProperty.all(
                        theme.colorScheme.surfaceContainerLowest),
                    columnSpacing: 20,
                    headingTextStyle: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                    columns: const [
                      DataColumn(label: Text('INVOICE')),
                      DataColumn(label: Text('CLIENT')),
                      DataColumn(label: Text('COMPANY')),
                      DataColumn(label: Text('AMOUNT'), numeric: true),
                      DataColumn(label: Text('ISSUED')),
                      DataColumn(label: Text('DUE DATE')),
                      DataColumn(label: Text('STATUS')),
                      DataColumn(label: Text('ACTIONS')),
                    ],
                    rows: filtered
                        .map((inv) => DataRow(cells: [
                              DataCell(Text(inv['id']!,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w500))),
                              DataCell(Text(inv['client']!)),
                              DataCell(Text(inv['company']!)),
                              DataCell(Text(inv['amount']!,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600))),
                              DataCell(Text(inv['issued']!)),
                              DataCell(Text(inv['due']!,
                                  style: TextStyle(
                                      color: inv['status'] == 'Overdue'
                                          ? Colors.red.shade700
                                          : null))),
                              DataCell(
                                  _InvoiceStatusChip(status: inv['status']!)),
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
                                    icon: const Icon(Icons.picture_as_pdf_outlined,
                                        size: 18),
                                    onPressed: () {},
                                    tooltip: 'Download PDF',
                                    visualDensity: VisualDensity.compact,
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.send_outlined,
                                        size: 18),
                                    onPressed: () {},
                                    tooltip: 'Send',
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

class _MiniStat extends StatelessWidget {
  const _MiniStat(
      {required this.label, required this.count, required this.color});
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
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
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
      case 'Paid':
        color = Colors.green.shade700;
        bg = Colors.green.withValues(alpha: 0.1);
        break;
      case 'Sent':
        color = const Color(0xFF1565C0);
        bg = const Color(0xFF1565C0).withValues(alpha: 0.1);
        break;
      case 'Overdue':
        color = Colors.red.shade700;
        bg = Colors.red.withValues(alpha: 0.1);
        break;
      default:
        color = Colors.grey.shade600;
        bg = Colors.grey.withValues(alpha: 0.1);
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
