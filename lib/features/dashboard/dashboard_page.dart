import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/theme.dart';
import '../../core/providers/providers.dart';
import '../../core/services/stock_service.dart';
import '../../core/utils/morocco_format.dart';
import '../../shared/widgets/stat_card.dart';
import '../../shared/widgets/ws_components.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats  = ref.watch(dashboardProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
      body: stats.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error:   (e, _) => Center(child: Text('Erreur: $e')),
        data:    (s) => _DashboardBody(stats: s),
      ),
    );
  }
}

class _DashboardBody extends StatelessWidget {
  const _DashboardBody({required this.stats});
  final DashboardStats stats;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now   = DateTime.now();
    const months = [
      '', 'jan.', 'fév.', 'mars', 'avr.', 'mai', 'juin',
      'juil.', 'août', 'sep.', 'oct.', 'nov.', 'déc.',
    ];
    final dateStr = '${now.day} ${months[now.month]} ${now.year}';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──────────────────────────────────────────────────────────
          Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Tableau de bord',
                    style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w700, letterSpacing: -0.5)),
                const SizedBox(height: 2),
                Text(dateStr,
                    style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant)),
              ]),
            ),
            WsButton(
              label: 'Nouvelle facture',
              icon: Icons.add_rounded,
              onPressed: () {},
            ),
          ]),
          const SizedBox(height: 28),

          // ── KPI cards ────────────────────────────────────────────────────────
          LayoutBuilder(builder: (ctx, c) {
            final cols = c.maxWidth > 1200 ? 6
                : c.maxWidth > 800  ? 3
                : 2;
            return GridView.count(
              crossAxisCount: cols,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.55,
              children: [
                StatCard(
                  title:    'Chiffre d\'affaires',
                  value:    MoroccoFormat.madInt(stats.totalRevenue),
                  icon:     Icons.account_balance_wallet_rounded,
                  color:    WsColors.blue600,
                  subtitle: 'Factures payées',
                ),
                StatCard(
                  title:    'En attente',
                  value:    '${stats.pendingCount}',
                  icon:     Icons.schedule_rounded,
                  color:    WsColors.amber500,
                  subtitle: MoroccoFormat.madInt(stats.pendingAmount),
                ),
                StatCard(
                  title:    'Clients',
                  value:    '${stats.clientCount}',
                  icon:     Icons.people_rounded,
                  color:    WsColors.green600,
                  subtitle: 'actifs',
                ),
                StatCard(
                  title:    'Commandes',
                  value:    '${stats.orderCount}',
                  icon:     Icons.shopping_bag_rounded,
                  color:    WsColors.purple500,
                  subtitle: 'total cumulé',
                ),
                StatCard(
                  title:    'Ventes POS',
                  value:    MoroccoFormat.madInt(stats.posRevenueTotal),
                  icon:     Icons.point_of_sale_rounded,
                  color:    WsColors.teal500,
                  subtitle: 'total cumulé',
                ),
                StatCard(
                  title:    'Paie du mois',
                  value:    MoroccoFormat.madInt(stats.hrMonthlyPayroll),
                  icon:     Icons.badge_rounded,
                  color:    WsColors.orange500,
                  subtitle: 'net salarié',
                ),
              ],
            );
          }),
          const SizedBox(height: 24),

          // ── Low stock alert ─────────────────────────────────────────────────
          if (stats.lowStockCount > 0) ...[
            _LowStockBanner(count: stats.lowStockCount, threshold: stats.lowStockThreshold),
            const SizedBox(height: 20),
          ],

          // ── Charts + recent invoices ────────────────────────────────────────
          LayoutBuilder(builder: (ctx, c) {
            if (c.maxWidth > 800) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 3, child: _RevenueChart(data: stats.revenueByMonth)),
                  const SizedBox(width: 16),
                  Expanded(flex: 2, child: _InvoiceStatusChart(counts: stats.invoiceStatusCounts)),
                ],
              );
            }
            return Column(children: [
              _RevenueChart(data: stats.revenueByMonth),
              const SizedBox(height: 16),
              _InvoiceStatusChart(counts: stats.invoiceStatusCounts),
            ]);
          }),
          const SizedBox(height: 20),

          // ── Recent invoices ─────────────────────────────────────────────────
          _RecentInvoicesCard(),
        ],
      ),
    );
  }
}

// ── Low stock banner ──────────────────────────────────────────────────────────

class _LowStockBanner extends StatefulWidget {
  const _LowStockBanner({required this.count, this.threshold = 5});
  final int count;
  final int threshold;

  @override
  State<_LowStockBanner> createState() => _LowStockBannerState();
}

class _LowStockBannerState extends State<_LowStockBanner> {
  List<Map<String, dynamic>> _items = [];
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    StockService.getLowStock(threshold: widget.threshold)
        .then((v) { if (mounted) setState(() { _items = v; _loaded = true; }); });
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) return const SizedBox.shrink();

    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: WsColors.amber500.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: WsColors.amber500.withValues(alpha: 0.3)),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: WsColors.amber500.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(7),
          ),
          child: const Icon(Icons.warning_amber_rounded,
              size: 16, color: WsColors.amber500),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
              '${widget.count} produit(s) en stock faible',
              style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF92400E)),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: _items.map((p) {
                final qty = (p['stock'] as num?)?.toInt() ?? 0;
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: WsColors.amber500.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: WsColors.amber500.withValues(alpha: 0.25)),
                  ),
                  child: Text(
                    '${p['name']} · $qty',
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF92400E)),
                  ),
                );
              }).toList(),
            ),
          ]),
        ),
      ]),
    );
  }
}

// ── Revenue chart ─────────────────────────────────────────────────────────────

class _RevenueChart extends StatelessWidget {
  const _RevenueChart({required this.data});
  final List<Map<String, dynamic>> data;

  @override
  Widget build(BuildContext context) {
    final theme   = Theme.of(context);
    final primary = theme.colorScheme.primary;

    List<FlSpot> spots;
    List<String> labels;
    if (data.isEmpty) {
      spots  = [const FlSpot(0, 0)];
      labels = ['—'];
    } else {
      spots = data.asMap().entries
          .map((e) => FlSpot(e.key.toDouble(), (e.value['amount'] as num).toDouble()))
          .toList();
      labels = data.map((d) {
        final parts = (d['month'] as String).split('-');
        const ml = ['','Jan','Fév','Mar','Avr','Mai','Jui','Jul','Aoû','Sep','Oct','Nov','Déc'];
        return ml[int.parse(parts[1])];
      }).toList();
    }

    return WsCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        WsSectionTitle('Chiffre d\'affaires',
            trailing: Text('6 derniers mois · TTC',
                style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant))),
        const SizedBox(height: 20),
        SizedBox(
          height: 200,
          child: LineChart(LineChartData(
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              getDrawingHorizontalLine: (_) => FlLine(
                color: theme.colorScheme.outlineVariant,
                strokeWidth: 1,
              ),
            ),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 60,
                  getTitlesWidget: (v, _) => Text(
                    '${(v / 1000).toStringAsFixed(0)}k',
                    style: TextStyle(
                        fontSize: 10,
                        color: theme.colorScheme.onSurfaceVariant),
                  ),
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (v, _) {
                    final i = v.toInt();
                    if (i < 0 || i >= labels.length) return const SizedBox.shrink();
                    return Text(labels[i],
                        style: TextStyle(
                            fontSize: 11,
                            color: theme.colorScheme.onSurfaceVariant));
                  },
                ),
              ),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles:   const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            borderData: FlBorderData(show: false),
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: true,
                curveSmoothness: 0.35,
                color: primary,
                barWidth: 2.5,
                dotData: FlDotData(
                  getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
                    radius: 4,
                    color: primary,
                    strokeWidth: 2.5,
                    strokeColor: theme.colorScheme.surface,
                  ),
                ),
                belowBarData: BarAreaData(
                  show: true,
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      primary.withValues(alpha: 0.15),
                      primary.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ],
            minY: 0,
          )),
        ),
      ]),
    );
  }
}

// ── Invoice status chart ──────────────────────────────────────────────────────

class _InvoiceStatusChart extends StatelessWidget {
  const _InvoiceStatusChart({required this.counts});
  final Map<String, int> counts;

  @override
  Widget build(BuildContext context) {
    final theme   = Theme.of(context);
    final paid    = counts['Payée'] ?? 0;
    final sent    = counts['Envoyée'] ?? 0;
    final overdue = counts['En retard'] ?? 0;
    final draft   = counts['Brouillon'] ?? 0;
    final total   = paid + sent + overdue + draft;

    final sections = total == 0
        ? [
            PieChartSectionData(
              value: 1,
              color: theme.colorScheme.surfaceContainerHigh,
              title: '',
              radius: 52,
            )
          ]
        : [
            if (paid > 0)
              PieChartSectionData(value: paid.toDouble(), color: WsColors.green600,
                  title: '$paid', radius: 52,
                  titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
            if (sent > 0)
              PieChartSectionData(value: sent.toDouble(), color: WsColors.blue600,
                  title: '$sent', radius: 52,
                  titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
            if (overdue > 0)
              PieChartSectionData(value: overdue.toDouble(), color: WsColors.red500,
                  title: '$overdue', radius: 52,
                  titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
            if (draft > 0)
              PieChartSectionData(value: draft.toDouble(), color: WsColors.slate300,
                  title: '$draft', radius: 52,
                  titleStyle: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontWeight: FontWeight.bold, fontSize: 12)),
          ];

    return WsCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        WsSectionTitle('Statut des factures',
            trailing: Text('Répartition actuelle',
                style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant))),
        const SizedBox(height: 16),
        SizedBox(
          height: 150,
          child: PieChart(PieChartData(
              sections: sections, sectionsSpace: 2, centerSpaceRadius: 28)),
        ),
        const SizedBox(height: 16),
        _LegendRow(color: WsColors.green600,  label: 'Payées',    count: paid),
        const SizedBox(height: 6),
        _LegendRow(color: WsColors.blue600,   label: 'Envoyées',  count: sent),
        const SizedBox(height: 6),
        _LegendRow(color: WsColors.red500,    label: 'En retard', count: overdue),
        const SizedBox(height: 6),
        _LegendRow(color: WsColors.slate300,  label: 'Brouillons',count: draft),
      ]),
    );
  }
}

class _LegendRow extends StatelessWidget {
  const _LegendRow({required this.color, required this.label, required this.count});
  final Color color;
  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(children: [
      Container(width: 10, height: 10,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
      const SizedBox(width: 8),
      Expanded(
        child: Text(label, style: theme.textTheme.bodySmall),
      ),
      Text('$count',
          style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600)),
    ]);
  }
}

// ── Recent invoices ───────────────────────────────────────────────────────────

class _RecentInvoicesCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme  = Theme.of(context);
    final async  = ref.watch(invoiceProvider);
    final isDark = theme.brightness == Brightness.dark;

    return WsCard(
      padding: EdgeInsets.zero,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 16, 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Dernières factures',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600)),
              TextButton(
                  style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6)),
                  onPressed: () {},
                  child: const Text('Voir tout →',
                      style: TextStyle(fontSize: 13))),
            ],
          ),
        ),
        Container(height: 1, color: theme.colorScheme.outlineVariant),
        async.maybeWhen(
          data: (invoices) {
            final recent = invoices.take(6).toList();
            if (recent.isEmpty) {
              return const Padding(
                padding: EdgeInsets.all(32),
                child: WsEmptyState(
                  icon: Icons.receipt_long_outlined,
                  title: 'Aucune facture',
                  subtitle: 'Créez votre première facture client',
                ),
              );
            }
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(
                    isDark ? WsColors.slate800 : WsColors.slate50),
                headingTextStyle: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                dataRowColor: WidgetStateProperty.resolveWith((s) {
                  if (s.contains(WidgetState.hovered)) {
                    return isDark
                        ? WsColors.slate700.withValues(alpha: 0.35)
                        : WsColors.slate50;
                  }
                  return null;
                }),
                columns: const [
                  DataColumn(label: Text('FACTURE')),
                  DataColumn(label: Text('CLIENT')),
                  DataColumn(label: Text('TOTAL TTC'), numeric: true),
                  DataColumn(label: Text('DATE')),
                  DataColumn(label: Text('STATUT')),
                ],
                rows: recent.map((inv) => DataRow(cells: [
                  DataCell(Text(inv.reference,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
                  DataCell(Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(inv.clientName ?? '—', style: const TextStyle(fontSize: 13)),
                      if (inv.companyName != null)
                        Text(inv.companyName!,
                            style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant)),
                    ],
                  )),
                  DataCell(Text(MoroccoFormat.mad(inv.totalTtc),
                      style: const TextStyle(fontWeight: FontWeight.w600))),
                  DataCell(Text(MoroccoFormat.date(inv.issuedDate),
                      style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant))),
                  DataCell(WsBadge.invoiceStatus(inv.status, size: WsBadgeSize.small)),
                ])).toList(),
              ),
            );
          },
          orElse: () => const Padding(
            padding: EdgeInsets.all(32),
            child: Center(child: CircularProgressIndicator()),
          ),
        ),
      ]),
    );
  }
}
