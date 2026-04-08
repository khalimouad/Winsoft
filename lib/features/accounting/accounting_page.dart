import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/journal_entry.dart';
import '../../core/providers/providers.dart';
import '../../core/utils/morocco_format.dart';

class AccountingPage extends ConsumerStatefulWidget {
  const AccountingPage({super.key});

  @override
  ConsumerState<AccountingPage> createState() => _AccountingPageState();
}

class _AccountingPageState extends ConsumerState<AccountingPage>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

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
            child: Text('Comptabilité',
                style: theme.textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold)),
          ),
          TabBar(
            controller: _tab,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: const [
              Tab(text: 'Journal'),
              Tab(text: 'Plan Comptable'),
              Tab(text: 'Grand Livre'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tab,
              children: const [
                _JournalTab(),
                _ChartOfAccountsTab(),
                _GrandLivreTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Journal Tab ───────────────────────────────────────────────────────────────

class _JournalTab extends ConsumerWidget {
  const _JournalTab();

  static const _journalColors = {
    'OD': Colors.grey,
    'VTE': Colors.blue,
    'ACH': Colors.orange,
    'TRE': Colors.green,
    'SAL': Colors.purple,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final entriesAsync = ref.watch(journalEntryProvider);
    final accountsAsync = ref.watch(accountChartProvider);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        Row(children: [
          const Spacer(),
          FilledButton.icon(
            onPressed: () => accountsAsync.whenData(
                (accounts) =>
                    _showAddDialog(context, ref, accounts)),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Nouvelle écriture'),
          ),
        ]),
        const SizedBox(height: 12),
        Expanded(
          child: entriesAsync.when(
            loading: () =>
                const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Erreur: $e')),
            data: (entries) {
              if (entries.isEmpty) {
                return const Center(
                    child: Text('Aucune écriture comptable'));
              }
              return ListView.builder(
                itemCount: entries.length,
                itemBuilder: (ctx, i) {
                  final e = entries[i];
                  final color =
                      _journalColors[e.journal] ?? Colors.grey;
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor:
                            color.withValues(alpha: 0.15),
                        radius: 20,
                        child: Text(e.journal,
                            style: TextStyle(
                                fontSize: 10,
                                color: color,
                                fontWeight: FontWeight.bold)),
                      ),
                      title: Row(children: [
                        Text(e.reference,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600)),
                        const SizedBox(width: 8),
                        if (e.isValidated)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color:
                                  Colors.green.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text('Validé',
                                style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.green,
                                    fontWeight: FontWeight.w600)),
                          ),
                      ]),
                      subtitle: Text(
                          '${e.description ?? ''} · ${MoroccoFormat.dateFromMs(e.date)}',
                          style: TextStyle(
                              fontSize: 12,
                              color: theme
                                  .colorScheme.onSurfaceVariant)),
                      trailing: !e.isValidated
                          ? TextButton(
                              onPressed: () => ref
                                  .read(journalEntryProvider
                                      .notifier)
                                  .validate(e.id!),
                              child: const Text('Valider'))
                          : null,
                    ),
                  );
                },
              );
            },
          ),
        ),
      ]),
    );
  }

  void _showAddDialog(BuildContext context, WidgetRef ref,
      List<AccountChart> accounts) {
    final descCtrl = TextEditingController();
    String selectedJournal = 'OD';
    int? debitAccountId = accounts.isNotEmpty ? accounts.first.id : null;
    int? creditAccountId = accounts.isNotEmpty ? accounts.first.id : null;
    final amountCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Nouvelle écriture'),
          content: SizedBox(
            width: 440,
            child: Form(
              key: formKey,
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                DropdownButtonFormField<String>(
                  value: selectedJournal,
                  decoration: const InputDecoration(labelText: 'Journal'),
                  items: JournalEntry.journals
                      .map((j) => DropdownMenuItem(
                          value: j,
                          child: Text(
                              '$j — ${JournalEntry.journalLabels[j]}')))
                      .toList(),
                  onChanged: (v) =>
                      setState(() => selectedJournal = v!),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: descCtrl,
                  decoration:
                      const InputDecoration(labelText: 'Libellé *'),
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Requis' : null,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  value: debitAccountId,
                  decoration:
                      const InputDecoration(labelText: 'Compte débit *'),
                  isExpanded: true,
                  items: accounts
                      .map((a) => DropdownMenuItem(
                          value: a.id,
                          child: Text('${a.code} — ${a.label}',
                              overflow: TextOverflow.ellipsis)))
                      .toList(),
                  onChanged: (v) =>
                      setState(() => debitAccountId = v),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  value: creditAccountId,
                  decoration:
                      const InputDecoration(labelText: 'Compte crédit *'),
                  isExpanded: true,
                  items: accounts
                      .map((a) => DropdownMenuItem(
                          value: a.id,
                          child: Text('${a.code} — ${a.label}',
                              overflow: TextOverflow.ellipsis)))
                      .toList(),
                  onChanged: (v) =>
                      setState(() => creditAccountId = v),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: amountCtrl,
                  decoration:
                      const InputDecoration(labelText: 'Montant (DH) *'),
                  keyboardType: TextInputType.number,
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Requis' : null,
                ),
              ]),
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Annuler')),
            FilledButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                final amount = double.tryParse(amountCtrl.text) ?? 0;
                final repo = ref.read(accountingRepoProvider);
                final seq = await repo.nextSequence();
                final entry = JournalEntry(
                  reference:
                      'EC-${DateTime.now().year}-${seq.toString().padLeft(4, '0')}',
                  date: DateTime.now().millisecondsSinceEpoch,
                  description: descCtrl.text.trim(),
                  journal: selectedJournal,
                  createdAt: DateTime.now().millisecondsSinceEpoch,
                  lines: [
                    JournalEntryLine(
                      entryId: 0,
                      accountId: debitAccountId!,
                      label: descCtrl.text.trim(),
                      debit: amount,
                    ),
                    JournalEntryLine(
                      entryId: 0,
                      accountId: creditAccountId!,
                      label: descCtrl.text.trim(),
                      credit: amount,
                    ),
                  ],
                );
                await ref
                    .read(journalEntryProvider.notifier)
                    .add(entry);
                if (ctx.mounted) Navigator.of(ctx).pop();
              },
              child: const Text('Enregistrer'),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Chart of Accounts Tab ─────────────────────────────────────────────────────

class _ChartOfAccountsTab extends ConsumerWidget {
  const _ChartOfAccountsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final accountsAsync = ref.watch(accountChartProvider);

    return accountsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Erreur: $e')),
      data: (accounts) {
        // Group by class
        final grouped = <int, List<AccountChart>>{};
        for (final a in accounts) {
          grouped.putIfAbsent(a.classNum, () => []).add(a);
        }
        final classes = grouped.keys.toList()..sort();
        return ListView(
          padding: const EdgeInsets.all(16),
          children: classes.map((cls) {
            final classAccounts = grouped[cls]!;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 12, bottom: 6),
                  child: Text(
                    'Classe $cls — ${classAccounts.first.className}',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
                ...classAccounts.map((a) => ListTile(
                      dense: true,
                      leading: Container(
                        width: 52,
                        alignment: Alignment.center,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(a.code,
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: theme
                                    .colorScheme.onPrimaryContainer)),
                      ),
                      title: Text(a.label),
                      subtitle: Text(a.type,
                          style: TextStyle(
                              fontSize: 10,
                              color: theme
                                  .colorScheme.onSurfaceVariant)),
                    )),
              ],
            );
          }).toList(),
        );
      },
    );
  }
}

// ── Grand Livre Tab ───────────────────────────────────────────────────────────

class _GrandLivreTab extends ConsumerStatefulWidget {
  const _GrandLivreTab();

  @override
  ConsumerState<_GrandLivreTab> createState() => _GrandLivreTabState();
}

class _GrandLivreTabState extends ConsumerState<_GrandLivreTab> {
  int _year = DateTime.now().year;
  List<Map<String, dynamic>>? _rows;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final repo = ref.read(accountingRepoProvider);
    final rows = await repo.grandLivre(_year);
    if (mounted) setState(() { _rows = rows; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        Row(children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () {
              setState(() => _year--);
              _load();
            },
          ),
          Text('$_year',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600)),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () {
              setState(() => _year++);
              _load();
            },
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _load,
            tooltip: 'Actualiser',
          ),
        ]),
        const SizedBox(height: 12),
        if (_loading)
          const Expanded(
              child: Center(child: CircularProgressIndicator()))
        else if (_rows == null || _rows!.isEmpty)
          const Expanded(
              child: Center(
                  child: Text(
                      'Aucune écriture pour cette période')))
        else
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(
                    theme.colorScheme.surfaceContainer),
                columns: const [
                  DataColumn(label: Text('Code')),
                  DataColumn(label: Text('Libellé')),
                  DataColumn(label: Text('Débit'), numeric: true),
                  DataColumn(label: Text('Crédit'), numeric: true),
                  DataColumn(label: Text('Solde'), numeric: true),
                ],
                rows: _rows!.map((r) {
                  final solde = (r['solde'] as num?)?.toDouble() ?? 0;
                  return DataRow(cells: [
                    DataCell(Text(r['code'] as String? ?? '')),
                    DataCell(Text(r['label'] as String? ?? '')),
                    DataCell(Text(
                        MoroccoFormat.mad((r['total_debit'] as num?)?.toDouble() ?? 0))),
                    DataCell(Text(
                        MoroccoFormat.mad((r['total_credit'] as num?)?.toDouble() ?? 0))),
                    DataCell(Text(
                      MoroccoFormat.mad(solde.abs()),
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: solde >= 0
                              ? Colors.green.shade700
                              : Colors.red),
                    )),
                  ]);
                }).toList(),
              ),
            ),
          ),
      ]),
    );
  }
}
