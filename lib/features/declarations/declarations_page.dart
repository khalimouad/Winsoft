import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/providers.dart';
import '../../core/utils/morocco_format.dart';

class DeclarationsPage extends ConsumerStatefulWidget {
  const DeclarationsPage({super.key});

  @override
  ConsumerState<DeclarationsPage> createState() =>
      _DeclarationsPageState();
}

class _DeclarationsPageState extends ConsumerState<DeclarationsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  int _year = DateTime.now().year;
  int _month = DateTime.now().month;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
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
            child: Text('Déclarations fiscales',
                style: theme.textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold)),
          ),
          TabBar(
            controller: _tab,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: const [
              Tab(text: 'TVA mensuelle'),
              Tab(text: 'IS annuel'),
              Tab(text: 'Taxe Professionnelle'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tab,
              children: [
                _TvaDeclarationTab(
                    year: _year,
                    month: _month,
                    onPeriodChanged: (y, m) =>
                        setState(() { _year = y; _month = m; })),
                _IsDeclarationTab(
                    year: _year,
                    onYearChanged: (y) => setState(() => _year = y)),
                _TpDeclarationTab(
                    year: _year,
                    onYearChanged: (y) => setState(() => _year = y)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── TVA Monthly Declaration ───────────────────────────────────────────────────

class _TvaDeclarationTab extends ConsumerStatefulWidget {
  const _TvaDeclarationTab(
      {required this.year,
      required this.month,
      required this.onPeriodChanged});
  final int year;
  final int month;
  final void Function(int, int) onPeriodChanged;

  @override
  ConsumerState<_TvaDeclarationTab> createState() =>
      _TvaDeclarationTabState();
}

class _TvaDeclarationTabState extends ConsumerState<_TvaDeclarationTab> {
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
    final repo = ref.read(reportRepoProvider);

    const months = [
      '', 'Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin',
      'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre',
    ];

    return FutureBuilder(
      future: repo.tvaReport(_year, _month),
      builder: (ctx, snap) => ListView(
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
            _DeclarationHeader(
              title: 'Déclaration TVA — ${months[_month]} $_year',
              subtitle: 'Direction Générale des Impôts — Formulaire 11',
            ),
            const SizedBox(height: 16),

            // TVA form fields
            _EdiField('Période', '${_month.toString().padLeft(2,'0')}/$_year'),
            _EdiField('Régime', 'Débit (mensuel)'),
            _EdiField('TVA collectée (base imposable HT)',
                _calcBaseHt(snap.data!['collectee'] as List)),
            _EdiField('TVA collectée (montant)',
                MoroccoFormat.mad((snap.data!['total_collectee'] as num).toDouble())),
            _EdiField('TVA récupérable sur achats',
                MoroccoFormat.mad((snap.data!['total_recuperable'] as num).toDouble())),
            const Divider(),
            _EdiField(
              'TVA nette à payer',
              MoroccoFormat.mad((snap.data!['tva_nette'] as num).toDouble()),
              highlight: true,
            ),
            const SizedBox(height: 20),
            _EdiActions(
              onExportCsv: () => _exportTvaCsv(snap.data!),
              onExportEdi: () => _exportTvaEdi(snap.data!),
            ),
          ],
        ],
      ),
    );
  }

  String _calcBaseHt(List rows) {
    double base = 0;
    for (final r in rows) {
      final rate = (r['tva_rate'] as num?)?.toDouble() ?? 0;
      final tva = (r['tva_amount'] as num?)?.toDouble() ?? 0;
      if (rate > 0) base += tva / (rate / 100);
    }
    return MoroccoFormat.mad(base);
  }

  Future<void> _exportTvaCsv(Map<String, dynamic> data) async {
    final csv = StringBuffer();
    csv.writeln('Déclaration TVA');
    csv.writeln('Période;${_month.toString().padLeft(2,'0')}/$_year');
    csv.writeln('TVA collectée;${(data['total_collectee'] as num).toDouble()}');
    csv.writeln('TVA récupérable;${(data['total_recuperable'] as num).toDouble()}');
    csv.writeln('TVA nette;${(data['tva_nette'] as num).toDouble()}');
    await _saveFile('tva_${_year}_$_month.csv', csv.toString());
  }

  Future<void> _exportTvaEdi(Map<String, dynamic> data) async {
    final nette = (data['tva_nette'] as num).toDouble();
    final edi = StringBuffer();
    edi.writeln('EDI-TVA-DGI-MA');
    edi.writeln('PERIODE:${_year}${_month.toString().padLeft(2,'0')}');
    edi.writeln('TVA_COLLECTEE:${(data['total_collectee'] as num).toStringAsFixed(2)}');
    edi.writeln('TVA_RECUPERABLE:${(data['total_recuperable'] as num).toStringAsFixed(2)}');
    edi.writeln('TVA_NETTE:${nette.toStringAsFixed(2)}');
    edi.writeln('STATUT:${nette > 0 ? "A_PAYER" : "CREDIT"}');
    await _saveFile('tva_edi_${_year}_$_month.txt', edi.toString());
  }
}

// ── IS Annual Declaration ─────────────────────────────────────────────────────

class _IsDeclarationTab extends ConsumerWidget {
  const _IsDeclarationTab(
      {required this.year, required this.onYearChanged});
  final int year;
  final ValueChanged<int> onYearChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final repo = ref.read(reportRepoProvider);
    return FutureBuilder(
      future: repo.isReport(year),
      builder: (ctx, snap) => ListView(
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
          const SizedBox(height: 16),

          if (!snap.hasData)
            const Center(child: CircularProgressIndicator())
          else ...[
            _DeclarationHeader(
              title: 'Déclaration IS — Exercice $year',
              subtitle: 'Direction Générale des Impôts — Formulaire IS',
            ),
            const SizedBox(height: 16),

            _EdiField('Exercice fiscal', '$year'),
            _EdiField('Chiffre d\'affaires HT',
                MoroccoFormat.mad((snap.data!['chiffre_affaires'] as num).toDouble())),
            _EdiField('Total charges d\'exploitation',
                MoroccoFormat.mad(
                    ((snap.data!['achats'] as num) + (snap.data!['charges_personnel'] as num))
                        .toDouble())),
            _EdiField('Achats et charges externes',
                MoroccoFormat.mad((snap.data!['achats'] as num).toDouble())),
            _EdiField('Charges de personnel',
                MoroccoFormat.mad((snap.data!['charges_personnel'] as num).toDouble())),
            const Divider(),
            _EdiField('Résultat fiscal',
                MoroccoFormat.mad((snap.data!['resultat_fiscal'] as num).toDouble())),
            _EdiField(
                'IS dû (taux effectif ${(snap.data!['is_rate'] as num).toStringAsFixed(1)}%)',
                MoroccoFormat.mad((snap.data!['is_amount'] as num).toDouble()),
                highlight: true),
            const SizedBox(height: 20),
            _EdiActions(
              onExportCsv: () => _exportIsCsv(snap.data!),
              onExportEdi: () => _exportIsEdi(snap.data!),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _exportIsCsv(Map<String, dynamic> data) async {
    final csv = StringBuffer();
    csv.writeln('Déclaration IS');
    csv.writeln('Exercice;$year');
    csv.writeln('CA HT;${data['chiffre_affaires']}');
    csv.writeln('Achats;${data['achats']}');
    csv.writeln('Charges personnel;${data['charges_personnel']}');
    csv.writeln('Résultat fiscal;${data['resultat_fiscal']}');
    csv.writeln('IS dû;${data['is_amount']}');
    await _saveFile('is_$year.csv', csv.toString());
  }

  Future<void> _exportIsEdi(Map<String, dynamic> data) async {
    final edi = StringBuffer();
    edi.writeln('EDI-IS-DGI-MA');
    edi.writeln('EXERCICE:$year');
    edi.writeln('CA_HT:${(data['chiffre_affaires'] as num).toStringAsFixed(2)}');
    edi.writeln('CHARGES_EXPLOITATION:${((data['achats'] as num) + (data['charges_personnel'] as num)).toStringAsFixed(2)}');
    edi.writeln('RESULTAT_FISCAL:${(data['resultat_fiscal'] as num).toStringAsFixed(2)}');
    edi.writeln('IS_DU:${(data['is_amount'] as num).toStringAsFixed(2)}');
    await _saveFile('is_edi_$year.txt', edi.toString());
  }
}

// ── TP Declaration ────────────────────────────────────────────────────────────

class _TpDeclarationTab extends ConsumerWidget {
  const _TpDeclarationTab(
      {required this.year, required this.onYearChanged});
  final int year;
  final ValueChanged<int> onYearChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final repo = ref.read(reportRepoProvider);
    return FutureBuilder(
      future: repo.isReport(year),
      builder: (ctx, snap) => ListView(
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
          const SizedBox(height: 16),

          _DeclarationHeader(
            title: 'Taxe Professionnelle — $year',
            subtitle: 'Déclaration annuelle — Formulaire TP',
          ),
          const SizedBox(height: 16),

          if (!snap.hasData)
            const Center(child: CircularProgressIndicator())
          else ...[
            _EdiField('Exercice', '$year'),
            _EdiField('CA annuel HT',
                MoroccoFormat.mad(
                    (snap.data!['chiffre_affaires'] as num).toDouble())),
            // TP rates: 0-3M: 6%, 3-10M: 20%, >10M: 30% (simplified)
            Builder(builder: (ctx) {
              final ca = (snap.data!['chiffre_affaires'] as num).toDouble();
              final tp = _calcTp(ca);
              return _EdiField('Taxe Professionnelle estimée',
                  MoroccoFormat.mad(tp),
                  highlight: true);
            }),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Barème TP: 0-3M DH → 6% · 3-10M DH → 20% · >10M DH → 30%\n'
                'La déclaration doit être déposée avant le 31 janvier.',
                style: TextStyle(
                    fontSize: 11,
                    color: theme.colorScheme.onSecondaryContainer),
              ),
            ),
            const SizedBox(height: 20),
            _EdiActions(
              onExportCsv: () async {
                final ca = (snap.data!['chiffre_affaires'] as num).toDouble();
                final csv = 'Taxe Professionnelle\nExercice;$year\nCA HT;$ca\nTP;${_calcTp(ca)}\n';
                await _saveFile('tp_$year.csv', csv);
              },
              onExportEdi: () async {
                final ca = (snap.data!['chiffre_affaires'] as num).toDouble();
                final edi = 'EDI-TP-DGI-MA\nEXERCICE:$year\nCA_HT:${ca.toStringAsFixed(2)}\nTP_DUE:${_calcTp(ca).toStringAsFixed(2)}\n';
                await _saveFile('tp_edi_$year.txt', edi);
              },
            ),
          ],
        ],
      ),
    );
  }

  static double _calcTp(double ca) {
    if (ca <= 3000000) return ca * 0.06;
    if (ca <= 10000000) return 3000000 * 0.06 + (ca - 3000000) * 0.20;
    return 3000000 * 0.06 + 7000000 * 0.20 + (ca - 10000000) * 0.30;
  }
}

// ── Shared widgets ────────────────────────────────────────────────────────────

class _DeclarationHeader extends StatelessWidget {
  const _DeclarationHeader(
      {required this.title, required this.subtitle});
  final String title, subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(children: [
        Icon(Icons.description_outlined,
            color: theme.colorScheme.primary, size: 28),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            Text(title,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 15)),
            Text(subtitle,
                style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.onPrimaryContainer
                        .withValues(alpha: 0.7))),
          ]),
        ),
      ]),
    );
  }
}

class _EdiField extends StatelessWidget {
  const _EdiField(this.label, this.value, {this.highlight = false});
  final String label, value;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
        Text(label,
            style: TextStyle(
                color: theme.colorScheme.onSurfaceVariant,
                fontSize: 13)),
        Text(value,
            style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: highlight ? 15 : 13,
                color:
                    highlight ? theme.colorScheme.primary : null)),
      ]),
    );
  }
}

class _EdiActions extends StatelessWidget {
  const _EdiActions(
      {required this.onExportCsv, required this.onExportEdi});
  final VoidCallback onExportCsv;
  final VoidCallback onExportEdi;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: [
        OutlinedButton.icon(
          onPressed: onExportCsv,
          icon: const Icon(Icons.table_chart_outlined, size: 16),
          label: const Text('Exporter CSV'),
        ),
        FilledButton.icon(
          onPressed: onExportEdi,
          icon: const Icon(Icons.upload_file, size: 16),
          label: const Text('Générer EDI'),
        ),
      ],
    );
  }
}

// ── File save utility ─────────────────────────────────────────────────────────

Future<void> _saveFile(String filename, String content) async {
  try {
    if (kIsWeb) {
      // Web: trigger download via HTML (not available in this context — show snackbar)
      return;
    }
    final downloads = Platform.isWindows
        ? '${Platform.environment['USERPROFILE']}\\Downloads'
        : Platform.isLinux
            ? '${Platform.environment['HOME']}/Downloads'
            : '/tmp';
    final path = '$downloads/$filename';
    await File(path).writeAsString(content);
  } catch (_) {
    // Silent — file system may not be available in all environments
  }
}
