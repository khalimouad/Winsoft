import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/providers.dart';
import '../../core/utils/morocco_format.dart';

class ReportsPage extends ConsumerStatefulWidget {
  const ReportsPage({super.key});

  @override
  ConsumerState<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends ConsumerState<ReportsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  int _year = DateTime.now().year;
  int _month = DateTime.now().month;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
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
            child: Text('Rapports',
                style: theme.textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold)),
          ),
          TabBar(
            controller: _tab,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: const [
              Tab(text: 'Chiffre d\'affaires'),
              Tab(text: 'TVA'),
              Tab(text: 'Achats'),
              Tab(text: 'Paie & IS'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tab,
              children: [
                _RevenueTab(year: _year),
                _TvaTab(year: _year, month: _month,
                    onPeriodChanged: (y, m) =>
                        setState(() { _year = y; _month = m; })),
                _PurchasesTab(year: _year),
                _PayrollIsTab(year: _year,
                    onYearChanged: (y) => setState(() => _year = y)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Revenue Tab ───────────────────────────────────────────────────────────────

class _RevenueTab extends ConsumerWidget {
  const _RevenueTab({required this.year});
  final int year;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.read(reportRepoProvider);
    return FutureBuilder(
      future: Future.wait([
        repo.revenueByMonth(12),
        repo.revenueByClient(),
        repo.revenueByProduct(),
        repo.invoiceSummary(),
      ]),
      builder: (ctx, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final monthly = snap.data![0] as List<Map<String, dynamic>>;
        final byClient = snap.data![1] as List<Map<String, dynamic>>;
        final byProduct = snap.data![2] as List<Map<String, dynamic>>;
        final summary = snap.data![3] as Map<String, dynamic>;

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _SummaryCards(summary: summary),
            const SizedBox(height: 20),
            if (monthly.isNotEmpty) _MonthlyChart(data: monthly),
            const SizedBox(height: 20),
            _RankingTable(
              title: 'Top clients (par CA)',
              icon: Icons.people_outlined,
              rows: byClient,
              nameKey: 'client_name',
              amountKey: 'total_ttc',
              subtitleKey: 'invoice_count',
              subtitleSuffix: ' facture(s)',
            ),
            const SizedBox(height: 16),
            _RankingTable(
              title: 'Top produits/services (par CA HT)',
              icon: Icons.inventory_2_outlined,
              rows: byProduct,
              nameKey: 'description',
              amountKey: 'total_ht',
              subtitleKey: 'total_qty',
              subtitleSuffix: ' unité(s)',
            ),
          ],
        );
      },
    );
  }
}

class _SummaryCards extends StatelessWidget {
  const _SummaryCards({required this.summary});
  final Map<String, dynamic> summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statuses = ['Payée', 'Envoyée', 'En retard', 'Brouillon'];
    final colors = [Colors.green, Colors.blue, Colors.red, Colors.grey];
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: List.generate(statuses.length, (i) {
        final data = summary[statuses[i]] as Map?;
        final count = (data?['count'] as int?) ?? 0;
        final amount = (data?['amount'] as num?)?.toDouble() ?? 0;
        return SizedBox(
          width: 200,
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Container(
                    width: 10, height: 10,
                    decoration: BoxDecoration(
                        color: colors[i], shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 6),
                  Text(statuses[i],
                      style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.onSurfaceVariant)),
                ]),
                const SizedBox(height: 8),
                Text(MoroccoFormat.mad(amount),
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16)),
                Text('$count facture(s)',
                    style: TextStyle(
                        fontSize: 11,
                        color: theme.colorScheme.onSurfaceVariant)),
              ]),
            ),
          ),
        );
      }),
    );
  }
}

class _MonthlyChart extends StatelessWidget {
  const _MonthlyChart({required this.data});
  final List<Map<String, dynamic>> data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final spots = data.asMap().entries.map((e) {
      final ttc = (e.value['ttc'] as num?)?.toDouble() ?? 0;
      return FlSpot(e.key.toDouble(), ttc);
    }).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Évolution du CA (12 derniers mois)',
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),
            SizedBox(
              height: 180,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                      drawVerticalLine: false,
                      getDrawingHorizontalLine: (_) =>
                          FlLine(color: theme.colorScheme.outlineVariant,
                              strokeWidth: 0.5)),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 60,
                            getTitlesWidget: (v, _) => Text(
                                MoroccoFormat.madInt(v),
                                style: const TextStyle(fontSize: 9)))),
                    bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (v, _) {
                              final idx = v.toInt();
                              if (idx < 0 || idx >= data.length) {
                                return const Text('');
                              }
                              final month =
                                  (data[idx]['month'] as String?) ?? '';
                              return Text(
                                  month.length >= 7 ? month.substring(5) : month,
                                  style: const TextStyle(fontSize: 9));
                            })),
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
                      color: theme.colorScheme.primary,
                      barWidth: 2.5,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                          show: true,
                          color: theme.colorScheme.primary
                              .withValues(alpha: 0.08)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RankingTable extends StatelessWidget {
  const _RankingTable({
    required this.title,
    required this.icon,
    required this.rows,
    required this.nameKey,
    required this.amountKey,
    required this.subtitleKey,
    required this.subtitleSuffix,
  });

  final String title;
  final IconData icon;
  final List<Map<String, dynamic>> rows;
  final String nameKey, amountKey, subtitleKey, subtitleSuffix;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(icon, size: 18, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text(title,
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w600)),
            ]),
            const SizedBox(height: 12),
            if (rows.isEmpty)
              Text('Aucune donnée',
                  style: TextStyle(
                      color: theme.colorScheme.onSurfaceVariant))
            else
              ...rows.asMap().entries.map((e) {
                final row = e.value;
                final amount =
                    (row[amountKey] as num?)?.toDouble() ?? 0;
                final sub = row[subtitleKey];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(children: [
                    Container(
                      width: 24, height: 24,
                      decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer,
                          shape: BoxShape.circle),
                      child: Center(
                        child: Text('${e.key + 1}',
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: theme
                                    .colorScheme.onPrimaryContainer)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Text(row[nameKey] as String? ?? '—',
                            style: const TextStyle(
                                fontWeight: FontWeight.w500)),
                        if (sub != null)
                          Text('$sub$subtitleSuffix',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: theme
                                      .colorScheme.onSurfaceVariant)),
                      ]),
                    ),
                    Text(MoroccoFormat.mad(amount),
                        style: const TextStyle(
                            fontWeight: FontWeight.w600)),
                  ]),
                );
              }),
          ],
        ),
      ),
    );
  }
}

// ── TVA Tab ───────────────────────────────────────────────────────────────────

class _TvaTab extends ConsumerStatefulWidget {
  const _TvaTab(
      {required this.year,
      required this.month,
      required this.onPeriodChanged});
  final int year;
  final int month;
  final void Function(int y, int m) onPeriodChanged;

  @override
  ConsumerState<_TvaTab> createState() => _TvaTabState();
}

class _TvaTabState extends ConsumerState<_TvaTab> {
  late int _year;
  late int _month;

  @override
  void initState() {
    super.initState();
    _year = widget.year;
    _month = widget.month;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const months = [
      '', 'Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin',
      'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre',
    ];
    final repo = ref.read(reportRepoProvider);

    return FutureBuilder(
      future: repo.tvaReport(_year, _month),
      builder: (ctx, snap) {
        final data = snap.data;
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Period picker
            Row(children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: () {
                  setState(() {
                    _month--;
                    if (_month < 1) { _month = 12; _year--; }
                  });
                  widget.onPeriodChanged(_year, _month);
                },
              ),
              Text('${months[_month]} $_year',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600)),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: () {
                  setState(() {
                    _month++;
                    if (_month > 12) { _month = 1; _year++; }
                  });
                  widget.onPeriodChanged(_year, _month);
                },
              ),
            ]),
            const SizedBox(height: 16),
            if (!snap.hasData)
              const Center(child: CircularProgressIndicator())
            else ...[
              _TvaCard(
                label: 'TVA collectée (ventes)',
                amount: (data!['total_collectee'] as num).toDouble(),
                color: Colors.red.shade700,
                rows: data['collectee'] as List,
              ),
              const SizedBox(height: 12),
              _TvaCard(
                label: 'TVA récupérable (achats)',
                amount: (data['total_recuperable'] as num).toDouble(),
                color: Colors.green.shade700,
                rows: data['recuperable'] as List,
              ),
              const SizedBox(height: 16),
              Card(
                color: theme.colorScheme.primaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('TVA nette à déclarer',
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold)),
                      Text(
                        MoroccoFormat.mad(
                            (data['tva_nette'] as num).toDouble()),
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _TvaCard extends StatelessWidget {
  const _TvaCard(
      {required this.label,
      required this.amount,
      required this.color,
      required this.rows});
  final String label;
  final double amount;
  final Color color;
  final List rows;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(label,
                style: const TextStyle(fontWeight: FontWeight.w600)),
            Text(MoroccoFormat.mad(amount),
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: color)),
          ]),
          if (rows.isNotEmpty) ...[
            const SizedBox(height: 10),
            const Divider(height: 1),
            ...rows.map((r) {
              final rate = (r['tva_rate'] as num?)?.toDouble() ?? 0;
              final tvaAmt = (r['tva_amount'] as num?)?.toDouble() ?? 0;
              return Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                  Text('TVA ${rate.toStringAsFixed(0)}%',
                      style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.onSurfaceVariant)),
                  Text(MoroccoFormat.mad(tvaAmt),
                      style: const TextStyle(fontSize: 12)),
                ]),
              );
            }),
          ],
        ]),
      ),
    );
  }
}

// ── Purchases Tab ─────────────────────────────────────────────────────────────

class _PurchasesTab extends ConsumerWidget {
  const _PurchasesTab({required this.year});
  final int year;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.read(reportRepoProvider);
    return FutureBuilder(
      future: Future.wait([
        repo.purchasesBySupplier(),
        repo.purchasesByMonth(12),
      ]),
      builder: (ctx, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final bySupplier = snap.data![0] as List<Map<String, dynamic>>;
        final byMonth = snap.data![1] as List<Map<String, dynamic>>;

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _RankingTable(
              title: 'Top fournisseurs',
              icon: Icons.shopping_bag_outlined,
              rows: bySupplier,
              nameKey: 'supplier_name',
              amountKey: 'total_ttc',
              subtitleKey: 'order_count',
              subtitleSuffix: ' commande(s)',
            ),
            const SizedBox(height: 16),
            if (byMonth.isNotEmpty)
              _PurchasesMonthlyCard(data: byMonth),
          ],
        );
      },
    );
  }
}

class _PurchasesMonthlyCard extends StatelessWidget {
  const _PurchasesMonthlyCard({required this.data});
  final List<Map<String, dynamic>> data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Achats par mois',
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          ...data.map((r) {
            final month = r['month'] as String? ?? '';
            final ttc = (r['ttc'] as num?)?.toDouble() ?? 0;
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                Text(month, style: const TextStyle(fontSize: 12)),
                Text(MoroccoFormat.mad(ttc),
                    style: const TextStyle(
                        fontWeight: FontWeight.w500, fontSize: 12)),
              ]),
            );
          }),
        ]),
      ),
    );
  }
}

// ── Payroll & IS Tab ──────────────────────────────────────────────────────────

class _PayrollIsTab extends ConsumerWidget {
  const _PayrollIsTab(
      {required this.year, required this.onYearChanged});
  final int year;
  final ValueChanged<int> onYearChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final repo = ref.read(reportRepoProvider);
    return FutureBuilder(
      future: Future.wait([
        repo.payrollByMonth(year),
        repo.isReport(year),
      ]),
      builder: (ctx, snap) {
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(children: [
              IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () => onYearChanged(year - 1)),
              Text('$year',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600)),
              IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () => onYearChanged(year + 1)),
            ]),
            const SizedBox(height: 12),
            if (!snap.hasData)
              const Center(child: CircularProgressIndicator())
            else ...[
              _IsCard(data: snap.data![1] as Map<String, dynamic>),
              const SizedBox(height: 16),
              _PayrollMonthlyCard(
                  data: snap.data![0] as List<Map<String, dynamic>>),
            ],
          ],
        );
      },
    );
  }
}

class _IsCard extends StatelessWidget {
  const _IsCard({required this.data});
  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ca = (data['chiffre_affaires'] as num).toDouble();
    final achats = (data['achats'] as num).toDouble();
    final payroll = (data['charges_personnel'] as num).toDouble();
    final result = (data['resultat_fiscal'] as num).toDouble();
    final is_amount = (data['is_amount'] as num).toDouble();
    final rate = (data['is_rate'] as num).toDouble();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(Icons.calculate_outlined,
                color: theme.colorScheme.primary, size: 20),
            const SizedBox(width: 8),
            Text('Impôt sur les Sociétés (IS) — ${data['year']}',
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.bold)),
          ]),
          const SizedBox(height: 16),
          _IsRow('Chiffre d\'affaires HT', MoroccoFormat.mad(ca),
              isTotal: false),
          _IsRow('Achats (charges)', '− ${MoroccoFormat.mad(achats)}',
              isTotal: false, negative: true),
          _IsRow('Charges de personnel', '− ${MoroccoFormat.mad(payroll)}',
              isTotal: false, negative: true),
          const Divider(),
          _IsRow('Résultat fiscal',
              MoroccoFormat.mad(result > 0 ? result : 0),
              isTotal: true),
          _IsRow('IS (taux effectif ${rate.toStringAsFixed(1)}%)',
              MoroccoFormat.mad(is_amount),
              isTotal: true,
              highlight: true),
        ]),
      ),
    );
  }
}

class _IsRow extends StatelessWidget {
  const _IsRow(this.label, this.value,
      {this.isTotal = false, this.negative = false, this.highlight = false});
  final String label, value;
  final bool isTotal, negative, highlight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label,
            style: TextStyle(
                fontWeight:
                    isTotal ? FontWeight.w600 : FontWeight.normal,
                color: theme.colorScheme.onSurface)),
        Text(value,
            style: TextStyle(
                fontWeight: FontWeight.w600,
                color: highlight
                    ? theme.colorScheme.primary
                    : negative
                        ? Colors.red.shade700
                        : null)),
      ]),
    );
  }
}

class _PayrollMonthlyCard extends StatelessWidget {
  const _PayrollMonthlyCard({required this.data});
  final List<Map<String, dynamic>> data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const months = [
      '', 'Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Jun',
      'Jul', 'Aoû', 'Sep', 'Oct', 'Nov', 'Déc',
    ];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Masse salariale mensuelle',
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          if (data.isEmpty)
            Text('Aucune donnée',
                style: TextStyle(
                    color: theme.colorScheme.onSurfaceVariant))
          else
            ...data.map((r) {
              final m = (r['period_month'] as int?) ?? 0;
              final brut = (r['total_brut'] as num?)?.toDouble() ?? 0;
              final net = (r['total_net'] as num?)?.toDouble() ?? 0;
              final emp = (r['employee_count'] as int?) ?? 0;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(children: [
                  SizedBox(
                      width: 36,
                      child: Text(months[m],
                          style: TextStyle(
                              fontSize: 11,
                              color:
                                  theme.colorScheme.onSurfaceVariant))),
                  Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text('Brut: ${MoroccoFormat.mad(brut)} · Net: ${MoroccoFormat.mad(net)}',
                          style: const TextStyle(fontSize: 12)),
                    ]),
                  ),
                  Text('$emp emp.',
                      style: TextStyle(
                          fontSize: 11,
                          color: theme.colorScheme.onSurfaceVariant)),
                ]),
              );
            }),
        ]),
      ),
    );
  }
}
