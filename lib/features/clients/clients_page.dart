import 'package:flutter/material.dart';

class ClientsPage extends StatefulWidget {
  const ClientsPage({super.key});

  @override
  State<ClientsPage> createState() => _ClientsPageState();
}

class _ClientsPageState extends State<ClientsPage> {
  String _search = '';

  final _clients = const [
    {
      'name': 'John Mitchell',
      'company': 'Acme Corporation',
      'email': 'j.mitchell@acme.com',
      'phone': '+1 555 0101',
      'totalSpent': '\$12,400',
      'lastOrder': 'Apr 5, 2026'
    },
    {
      'name': 'Sarah Chen',
      'company': 'Globe Industries',
      'email': 's.chen@globe.io',
      'phone': '+1 555 0143',
      'totalSpent': '\$8,950',
      'lastOrder': 'Apr 3, 2026'
    },
    {
      'name': 'Robert Torres',
      'company': 'TechStart Ltd',
      'email': 'r.torres@techstart.com',
      'phone': '+1 555 0200',
      'totalSpent': '\$5,600',
      'lastOrder': 'Mar 28, 2026'
    },
    {
      'name': 'Emily Watson',
      'company': 'Sunrise Retail',
      'email': 'e.watson@sunrise.com',
      'phone': '+1 555 0189',
      'totalSpent': '\$2,100',
      'lastOrder': 'Mar 20, 2026'
    },
    {
      'name': 'James Lee',
      'company': 'Delta Services',
      'email': 'j.lee@delta.net',
      'phone': '+1 555 0156',
      'totalSpent': '\$19,800',
      'lastOrder': 'Apr 4, 2026'
    },
    {
      'name': 'Maria Gonzalez',
      'company': 'Horizon Group',
      'email': 'm.gonzalez@horizon.com',
      'phone': '+1 555 0178',
      'totalSpent': '\$31,200',
      'lastOrder': 'Apr 6, 2026'
    },
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filtered = _clients
        .where((c) =>
            c['name']!.toLowerCase().contains(_search.toLowerCase()) ||
            c['company']!.toLowerCase().contains(_search.toLowerCase()) ||
            c['email']!.toLowerCase().contains(_search.toLowerCase()))
        .toList();

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
                    Text('Clients',
                        style: theme.textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    Text('${_clients.length} clients total',
                        style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant)),
                  ],
                ),
                FilledButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.person_add_outlined, size: 18),
                  label: const Text('Add Client'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: 360,
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search clients...',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  isDense: true,
                  filled: true,
                  fillColor: theme.colorScheme.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide:
                        BorderSide(color: theme.colorScheme.outlineVariant),
                  ),
                ),
                onChanged: (val) => setState(() => _search = val),
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
                      DataColumn(label: Text('CLIENT')),
                      DataColumn(label: Text('COMPANY')),
                      DataColumn(label: Text('EMAIL')),
                      DataColumn(label: Text('PHONE')),
                      DataColumn(label: Text('TOTAL SPENT'), numeric: true),
                      DataColumn(label: Text('LAST ORDER')),
                      DataColumn(label: Text('ACTIONS')),
                    ],
                    rows: filtered
                        .map((c) => DataRow(cells: [
                              DataCell(Row(
                                children: [
                                  CircleAvatar(
                                    radius: 16,
                                    backgroundColor:
                                        theme.colorScheme.tertiaryContainer,
                                    child: Text(c['name']![0],
                                        style: TextStyle(
                                            color: theme.colorScheme
                                                .onTertiaryContainer,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12)),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(c['name']!,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w500)),
                                ],
                              )),
                              DataCell(Text(c['company']!)),
                              DataCell(Text(c['email']!)),
                              DataCell(Text(c['phone']!)),
                              DataCell(Text(c['totalSpent']!,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600))),
                              DataCell(Text(c['lastOrder']!)),
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
                                    icon: const Icon(Icons.edit_outlined,
                                        size: 18),
                                    onPressed: () {},
                                    tooltip: 'Edit',
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
