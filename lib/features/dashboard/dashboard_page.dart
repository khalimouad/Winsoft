import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../shared/widgets/stat_card.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerLowest,
      body: SingleChildScrollView(
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
                    Text(
                      'Dashboard',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Welcome back! Here\'s what\'s happening.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                FilledButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('New Invoice'),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // KPI Cards
            LayoutBuilder(
              builder: (context, constraints) {
                final crossAxisCount = constraints.maxWidth > 900
                    ? 4
                    : constraints.maxWidth > 600
                        ? 2
                        : 2;
                return GridView.count(
                  crossAxisCount: crossAxisCount,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.5,
                  children: [
                    StatCard(
                      title: 'Total Revenue',
                      value: '\$48,295',
                      icon: Icons.account_balance_wallet_outlined,
                      color: const Color(0xFF1565C0),
                      trend: '+12.5%',
                      trendUp: true,
                      subtitle: 'vs last month',
                    ),
                    StatCard(
                      title: 'Pending Invoices',
                      value: '24',
                      icon: Icons.receipt_long_outlined,
                      color: const Color(0xFFE65100),
                      trend: '-3',
                      trendUp: false,
                      subtitle: '\$18,420 outstanding',
                    ),
                    StatCard(
                      title: 'Active Clients',
                      value: '138',
                      icon: Icons.people_outlined,
                      color: const Color(0xFF2E7D32),
                      trend: '+8',
                      trendUp: true,
                      subtitle: '12 new this month',
                    ),
                    StatCard(
                      title: 'Sales Orders',
                      value: '57',
                      icon: Icons.shopping_cart_outlined,
                      color: const Color(0xFF6A1B9A),
                      trend: '+5.2%',
                      trendUp: true,
                      subtitle: 'This month',
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),

            // Charts Row
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth > 700) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 3, child: _RevenueChart()),
                      const SizedBox(width: 16),
                      Expanded(flex: 2, child: _InvoiceStatusChart()),
                    ],
                  );
                }
                return Column(
                  children: [
                    _RevenueChart(),
                    const SizedBox(height: 16),
                    _InvoiceStatusChart(),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),

            // Recent Invoices Table
            _RecentInvoicesTable(),
          ],
        ),
      ),
    );
  }
}

class _RevenueChart extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Revenue Overview',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            Text(
              'Last 6 months',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 10000,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: theme.colorScheme.outlineVariant,
                      strokeWidth: 1,
                    ),
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 10000,
                        reservedSize: 48,
                        getTitlesWidget: (value, meta) => Text(
                          '\$${(value / 1000).toStringAsFixed(0)}k',
                          style: TextStyle(
                            fontSize: 11,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          const months = [
                            'Nov',
                            'Dec',
                            'Jan',
                            'Feb',
                            'Mar',
                            'Apr'
                          ];
                          if (value.toInt() >= 0 &&
                              value.toInt() < months.length) {
                            return Text(
                              months[value.toInt()],
                              style: TextStyle(
                                fontSize: 11,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: const [
                        FlSpot(0, 28000),
                        FlSpot(1, 32000),
                        FlSpot(2, 27000),
                        FlSpot(3, 38000),
                        FlSpot(4, 42000),
                        FlSpot(5, 48295),
                      ],
                      isCurved: true,
                      color: primary,
                      barWidth: 3,
                      belowBarData: BarAreaData(
                        show: true,
                        color: primary.withValues(alpha: 0.1),
                      ),
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, bar, index) =>
                            FlDotCirclePainter(
                          radius: 4,
                          color: primary,
                          strokeWidth: 2,
                          strokeColor: theme.colorScheme.surface,
                        ),
                      ),
                    ),
                  ],
                  minY: 0,
                  maxY: 55000,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InvoiceStatusChart extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Invoice Status',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            Text(
              'Current breakdown',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 160,
              child: PieChart(
                PieChartData(
                  sections: [
                    PieChartSectionData(
                      value: 45,
                      color: Colors.green,
                      title: '45%',
                      radius: 55,
                      titleStyle: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12),
                    ),
                    PieChartSectionData(
                      value: 30,
                      color: const Color(0xFFE65100),
                      title: '30%',
                      radius: 55,
                      titleStyle: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12),
                    ),
                    PieChartSectionData(
                      value: 15,
                      color: Colors.red,
                      title: '15%',
                      radius: 55,
                      titleStyle: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12),
                    ),
                    PieChartSectionData(
                      value: 10,
                      color: theme.colorScheme.outlineVariant,
                      title: '10%',
                      radius: 55,
                      titleStyle: TextStyle(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.bold,
                          fontSize: 12),
                    ),
                  ],
                  sectionsSpace: 2,
                  centerSpaceRadius: 30,
                ),
              ),
            ),
            const SizedBox(height: 16),
            _Legend(color: Colors.green, label: 'Paid'),
            const SizedBox(height: 6),
            _Legend(color: const Color(0xFFE65100), label: 'Pending'),
            const SizedBox(height: 6),
            _Legend(color: Colors.red, label: 'Overdue'),
            const SizedBox(height: 6),
            _Legend(
                color: Theme.of(context).colorScheme.outlineVariant,
                label: 'Draft'),
          ],
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _RecentInvoicesTable extends StatelessWidget {
  final _invoices = const [
    {
      'id': 'INV-2024-001',
      'client': 'Acme Corp',
      'amount': '\$4,200',
      'date': 'Apr 5, 2026',
      'status': 'Paid'
    },
    {
      'id': 'INV-2024-002',
      'client': 'Globe Industries',
      'amount': '\$1,850',
      'date': 'Apr 4, 2026',
      'status': 'Pending'
    },
    {
      'id': 'INV-2024-003',
      'client': 'TechStart Ltd',
      'amount': '\$3,100',
      'date': 'Apr 3, 2026',
      'status': 'Overdue'
    },
    {
      'id': 'INV-2024-004',
      'client': 'Sunrise Retail',
      'amount': '\$750',
      'date': 'Apr 2, 2026',
      'status': 'Paid'
    },
    {
      'id': 'INV-2024-005',
      'client': 'Delta Services',
      'amount': '\$5,640',
      'date': 'Apr 1, 2026',
      'status': 'Draft'
    },
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Invoices',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                TextButton(onPressed: () {}, child: const Text('View All')),
              ],
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(
                    theme.colorScheme.surfaceContainerLowest),
                columnSpacing: 24,
                headingTextStyle: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
                columns: const [
                  DataColumn(label: Text('INVOICE')),
                  DataColumn(label: Text('CLIENT')),
                  DataColumn(label: Text('AMOUNT'), numeric: true),
                  DataColumn(label: Text('DATE')),
                  DataColumn(label: Text('STATUS')),
                ],
                rows: _invoices
                    .map((inv) => DataRow(
                          cells: [
                            DataCell(Text(inv['id']!,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w500))),
                            DataCell(Text(inv['client']!)),
                            DataCell(Text(inv['amount']!,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w500))),
                            DataCell(Text(inv['date']!)),
                            DataCell(_StatusChip(status: inv['status']!)),
                          ],
                        ))
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});
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
      case 'Pending':
        color = Colors.orange.shade700;
        bg = Colors.orange.withValues(alpha: 0.1);
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
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: TextStyle(
            color: color, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
}
