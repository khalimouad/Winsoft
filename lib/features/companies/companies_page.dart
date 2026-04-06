import 'package:flutter/material.dart';

class CompaniesPage extends StatefulWidget {
  const CompaniesPage({super.key});

  @override
  State<CompaniesPage> createState() => _CompaniesPageState();
}

class _CompaniesPageState extends State<CompaniesPage> {
  final _searchController = TextEditingController();
  String _search = '';

  final _companies = const [
    {
      'name': 'Acme Corporation',
      'industry': 'Manufacturing',
      'email': 'contact@acme.com',
      'phone': '+1 555 0100',
      'clients': '12',
      'status': 'Active'
    },
    {
      'name': 'Globe Industries',
      'industry': 'Technology',
      'email': 'info@globe.io',
      'phone': '+1 555 0142',
      'clients': '8',
      'status': 'Active'
    },
    {
      'name': 'TechStart Ltd',
      'industry': 'Software',
      'email': 'hello@techstart.com',
      'phone': '+1 555 0199',
      'clients': '5',
      'status': 'Active'
    },
    {
      'name': 'Sunrise Retail',
      'industry': 'Retail',
      'email': 'ops@sunrise.com',
      'phone': '+1 555 0188',
      'clients': '3',
      'status': 'Inactive'
    },
    {
      'name': 'Delta Services',
      'industry': 'Consulting',
      'email': 'team@delta.net',
      'phone': '+1 555 0155',
      'clients': '9',
      'status': 'Active'
    },
    {
      'name': 'Horizon Group',
      'industry': 'Finance',
      'email': 'hr@horizon.com',
      'phone': '+1 555 0177',
      'clients': '14',
      'status': 'Active'
    },
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filtered = _companies
        .where((c) =>
            c['name']!.toLowerCase().contains(_search.toLowerCase()) ||
            c['industry']!.toLowerCase().contains(_search.toLowerCase()))
        .toList();

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
                    Text('Companies',
                        style: theme.textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    Text('${_companies.length} companies registered',
                        style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant)),
                  ],
                ),
                FilledButton.icon(
                  onPressed: () => _showAddDialog(context),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add Company'),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Search
            SizedBox(
              width: 360,
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search companies...',
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

            // Table
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
                      DataColumn(label: Text('COMPANY')),
                      DataColumn(label: Text('INDUSTRY')),
                      DataColumn(label: Text('EMAIL')),
                      DataColumn(label: Text('PHONE')),
                      DataColumn(label: Text('CLIENTS'), numeric: true),
                      DataColumn(label: Text('STATUS')),
                      DataColumn(label: Text('ACTIONS')),
                    ],
                    rows: filtered
                        .map((c) => DataRow(cells: [
                              DataCell(Row(
                                children: [
                                  CircleAvatar(
                                    radius: 16,
                                    backgroundColor: theme
                                        .colorScheme.primaryContainer,
                                    child: Text(c['name']![0],
                                        style: TextStyle(
                                            color: theme
                                                .colorScheme.onPrimaryContainer,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12)),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(c['name']!,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w500)),
                                ],
                              )),
                              DataCell(Text(c['industry']!)),
                              DataCell(Text(c['email']!)),
                              DataCell(Text(c['phone']!)),
                              DataCell(Text(c['clients']!)),
                              DataCell(_StatusBadge(status: c['status']!)),
                              DataCell(Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit_outlined,
                                        size: 18),
                                    onPressed: () {},
                                    tooltip: 'Edit',
                                    visualDensity: VisualDensity.compact,
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.delete_outline,
                                        size: 18,
                                        color: theme.colorScheme.error),
                                    onPressed: () {},
                                    tooltip: 'Delete',
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

  void _showAddDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final industryCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Company'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Company Name')),
              const SizedBox(height: 12),
              TextField(
                  controller: industryCtrl,
                  decoration: const InputDecoration(labelText: 'Industry')),
              const SizedBox(height: 12),
              TextField(
                  controller: emailCtrl,
                  decoration: const InputDecoration(labelText: 'Email')),
              const SizedBox(height: 12),
              TextField(
                  controller: phoneCtrl,
                  decoration: const InputDecoration(labelText: 'Phone')),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Add')),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final isActive = status == 'Active';
    final color = isActive ? Colors.green.shade700 : Colors.grey.shade600;
    final bg =
        isActive ? Colors.green.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.1);
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
