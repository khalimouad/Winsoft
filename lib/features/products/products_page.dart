import 'package:flutter/material.dart';

class ProductsPage extends StatefulWidget {
  const ProductsPage({super.key});

  @override
  State<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage> {
  String _search = '';

  final _products = const [
    {
      'name': 'Consulting Package — Basic',
      'sku': 'CONS-001',
      'category': 'Services',
      'price': '\$1,500',
      'stock': '—',
      'status': 'Active'
    },
    {
      'name': 'Consulting Package — Pro',
      'sku': 'CONS-002',
      'category': 'Services',
      'price': '\$3,200',
      'stock': '—',
      'status': 'Active'
    },
    {
      'name': 'Software License — Annual',
      'sku': 'SOFT-101',
      'category': 'Software',
      'price': '\$899',
      'stock': 'Unlimited',
      'status': 'Active'
    },
    {
      'name': 'Hardware Kit A',
      'sku': 'HW-201',
      'category': 'Hardware',
      'price': '\$450',
      'stock': '42',
      'status': 'Active'
    },
    {
      'name': 'Support Plan — Monthly',
      'sku': 'SUP-010',
      'category': 'Support',
      'price': '\$200',
      'stock': '—',
      'status': 'Active'
    },
    {
      'name': 'Legacy Module',
      'sku': 'LEG-999',
      'category': 'Software',
      'price': '\$150',
      'stock': '0',
      'status': 'Discontinued'
    },
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filtered = _products
        .where((p) =>
            p['name']!.toLowerCase().contains(_search.toLowerCase()) ||
            p['category']!.toLowerCase().contains(_search.toLowerCase()) ||
            p['sku']!.toLowerCase().contains(_search.toLowerCase()))
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
                    Text('Products & Services',
                        style: theme.textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    Text('${_products.length} items in catalog',
                        style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant)),
                  ],
                ),
                FilledButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add Product'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                SizedBox(
                  width: 360,
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search products...',
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
                const SizedBox(width: 12),
                DropdownButton<String>(
                  value: 'All Categories',
                  items: ['All Categories', 'Services', 'Software', 'Hardware', 'Support']
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (_) {},
                  underline: const SizedBox.shrink(),
                ),
              ],
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
                      DataColumn(label: Text('PRODUCT / SERVICE')),
                      DataColumn(label: Text('SKU')),
                      DataColumn(label: Text('CATEGORY')),
                      DataColumn(label: Text('PRICE'), numeric: true),
                      DataColumn(label: Text('STOCK')),
                      DataColumn(label: Text('STATUS')),
                      DataColumn(label: Text('ACTIONS')),
                    ],
                    rows: filtered
                        .map((p) => DataRow(cells: [
                              DataCell(Text(p['name']!,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w500))),
                              DataCell(Text(p['sku']!,
                                  style: TextStyle(
                                      color:
                                          theme.colorScheme.onSurfaceVariant,
                                      fontSize: 13))),
                              DataCell(_CategoryChip(category: p['category']!)),
                              DataCell(Text(p['price']!,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600))),
                              DataCell(Text(p['stock']!)),
                              DataCell(_ProductStatus(status: p['status']!)),
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
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({required this.category});
  final String category;

  static const _colors = {
    'Services': Color(0xFF1565C0),
    'Software': Color(0xFF6A1B9A),
    'Hardware': Color(0xFF2E7D32),
    'Support': Color(0xFFE65100),
  };

  @override
  Widget build(BuildContext context) {
    final color = _colors[category] ?? Colors.grey.shade600;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(6)),
      child: Text(category,
          style: TextStyle(
              color: color, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}

class _ProductStatus extends StatelessWidget {
  const _ProductStatus({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final isActive = status == 'Active';
    final color = isActive ? Colors.green.shade700 : Colors.grey.shade500;
    final bg = isActive
        ? Colors.green.withValues(alpha: 0.1)
        : Colors.grey.withValues(alpha: 0.1);
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
