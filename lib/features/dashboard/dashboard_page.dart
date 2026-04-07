import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/providers.dart';
import '../../core/utils/morocco_format.dart';
import '../../shared/widgets/stat_card.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final statsAsync = ref.watch(dashboardProvider);

    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerLowest,
      body: statsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur: $e')),
        data: (stats) => SingleChildScrollView(
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
                      Text('Tableau de bord',
                          style: theme.textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.bold)),
                      Text('Bienvenue ! Voici un aperçu de votre activité.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                              color:
                                  theme.colorScheme.onSurfaceVariant)),
                    ],
                  ),
                  FilledButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Nouvelle facture'),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // KPI Cards
              LayoutBuilder(builder: (context, constraints) {
                final crossAxisCount = constraints.maxWidth > 900
                    ? 4
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
                      title: 'Chiffre d\'affaires',
                      value: MoroccoFormat.madInt(stats.totalRevenue),
                      icon: Icons.account_balance_wallet_outlined,
                      color: const Color(0xFF1565C0),
                      subtitle: 'Factures payées',
                    ),
                    StatCard(
                      title: 'Factures en attente',
                      value: '${stats.pendingCount}',
                      icon: Icons.receipt_long_outlined,
                      color: const Color(0xFFE65100),
                      subtitle: MoroccoFormat.madInt(stats.pendingAmount),
                    ),
                    StatCard(
                      title: 'Clients actifs',
                      value: '${stats.clientCount}',
                      icon: Icons.people_outlined,
                      color: const Color(0xFF2E7D32),
                    ),
                    StatCard(
                      title: 'Bons de commande',
                      value: '${stats.orderCount}',
                      icon: Icons.shopping_cart_outlined,
                      color: const Color(0xFF6A1B9A),
                      subtitle: 'Total cumulé',
                    ),
                  ],
                );
              }),
              const SizedBox(height: 24),

              // Charts
              LayoutBuilder(builder: (context, constraints) {
                if (constraints.maxWidth > 700) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                          flex: 3,
                          child: _RevenueChart(
                              data: stats.revenueByMonth)),
                      const SizedBox(width: 16),
                      Expanded(
                          flex: 2,
                          child: _InvoiceStatusChart(
                              counts: stats.invoiceStatusCounts)),
                    ],
                  );
                }
                return Column(children: [
                  _RevenueChart(data: stats.revenueByMonth),
                  const SizedBox(height: 16),
                  _InvoiceStatusChart(
                      counts: stats.invoiceStatusCounts),
                ]);
              }),
              const SizedBox(height: 24),

              // Recent invoices from real data
              _RecentInvoicesCard(),
            ],
          ),
        ),
      ),
    );
  }
}

class _RevenueChart extends StatelessWidget {
  const _RevenueChart({required this.data});
  final List<Map<String, dynamic>> data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    // Build spots from real data or dummy if empty
    List<FlSpot> spots;
    List<String> labels;
    if (data.isEmpty) {
      spots = [const FlSpot(0, 0)];
      labels = ['—'];
    } else {
      spots = data
          .asMap()
          .entries
          .map((e) => FlSpot(
              e.key.toDouble(), e.value['amount'] as double))
          .toList();
      labels = data.map((d) {
        final parts = (d['month'] as String).split('-');
        const months = [
          '', 'Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Jui',
          'Juil', 'Aoû', 'Sep', 'Oct', 'Nov', 'Déc'
        ];
        return months[int.parse(parts[1])];
      }).toList();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Chiffre d\'affaires',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w600)),
            Text('6 derniers mois (TTC)',
                style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant)),
            const SizedBox(height: 20),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: theme.colorScheme.outlineVariant,
                      strokeWidth: 1,
                    ),
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 56,
                        getTitlesWidget: (value, meta) => Text(
                          '${(value / 1000).toStringAsFixed(0)}k DH',
                          style: TextStyle(
                              fontSize: 10,
                              color:
                                  theme.colorScheme.onSurfaceVariant),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final idx = value.toInt();
                          if (idx >= 0 && idx < labels.length) {
                            return Text(labels[idx],
                                style: TextStyle(
                                    fontSize: 11,
                                    color: theme.colorScheme
                                        .onSurfaceVariant));
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
                      spots: spots,
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
  const _InvoiceStatusChart({required this.counts});
  final Map<String, int> counts;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final paid = counts['Payée'] ?? 0;
    final sent = counts['Envoyée'] ?? 0;
    final overdue = counts['En retard'] ?? 0;
    final draft = counts['Brouillon'] ?? 0;
    final total = paid + sent + overdue + draft;

    List<PieChartSectionData> sections;
    if (total == 0) {
      sections = [
        PieChartSectionData(
          value: 1,
          color: theme.colorScheme.outlineVariant,
          title: 'Aucune',
          radius: 55,
          titleStyle: TextStyle(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.bold,
              fontSize: 11),
        ),
      ];
    } else {
      sections = [
        if (paid > 0)
          PieChartSectionData(
            value: paid.toDouble(),
            color: Colors.green,
            title: '$paid',
            radius: 55,
            titleStyle: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12),
          ),
        if (sent > 0)
          PieChartSectionData(
            value: sent.toDouble(),
            color: const Color(0xFF1565C0),
            title: '$sent',
            radius: 55,
            titleStyle: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12),
          ),
        if (overdue > 0)
          PieChartSectionData(
            value: overdue.toDouble(),
            color: Colors.red,
            title: '$overdue',
            radius: 55,
            titleStyle: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12),
          ),
        if (draft > 0)
          PieChartSectionData(
            value: draft.toDouble(),
            color: Colors.grey,
            title: '$draft',
            radius: 55,
            titleStyle: TextStyle(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.bold,
                fontSize: 12),
          ),
      ];
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Statut des factures',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w600)),
            Text('Répartition actuelle',
                style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant)),
            const SizedBox(height: 20),
            SizedBox(
              height: 160,
              child: PieChart(PieChartData(
                  sections: sections,
                  sectionsSpace: 2,
                  centerSpaceRadius: 30)),
            ),
            const SizedBox(height: 16),
            _Legend(color: Colors.green, label: 'Payées ($paid)'),
            const SizedBox(height: 6),
            _Legend(
                color: const Color(0xFF1565C0),
                label: 'Envoyées ($sent)'),
            const SizedBox(height: 6),
            _Legend(
                color: Colors.red,
                label: 'En retard ($overdue)'),
            const SizedBox(height: 6),
            _Legend(
                color: Colors.grey,
                label: 'Brouillons ($draft)'),
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
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
              width: 12,
              height: 12,
              decoration:
                  BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      );
}

class _RecentInvoicesCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final async = ref.watch(invoiceProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Dernières factures',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600)),
                TextButton(
                    onPressed: () {},
                    child: const Text('Voir tout')),
              ],
            ),
            const SizedBox(height: 12),
            async.maybeWhen(
              data: (invoices) {
                final recent = invoices.take(5).toList();
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
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
                      DataColumn(label: Text('FACTURE')),
                      DataColumn(label: Text('CLIENT')),
                      DataColumn(
                          label: Text('TOTAL TTC'), numeric: true),
                      DataColumn(label: Text('DATE')),
                      DataColumn(label: Text('STATUT')),
                    ],
                    rows: recent
                        .map((inv) => DataRow(cells: [
                              DataCell(Text(inv.reference,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w500))),
                              DataCell(
                                  Text(inv.clientName ?? '—')),
                              DataCell(Text(
                                  MoroccoFormat.mad(inv.totalTtc),
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w500))),
                              DataCell(Text(MoroccoFormat.date(
                                  inv.issuedDate))),
                              DataCell(_StatusChip(
                                  status: inv.status)),
                            ]))
                        .toList(),
                  ),
                );
              },
              orElse: () => const Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(),
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
      default:
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
