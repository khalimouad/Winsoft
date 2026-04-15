import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/app_lists.dart';
import '../../core/models/journal_entry.dart';
import '../../core/models/fiscal_year.dart';
import '../../core/models/bank_account.dart';
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
    _tab = TabController(length: 7, vsync: this);
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
              Tab(text: 'Exercices fiscaux'),
              Tab(text: 'Comptes bancaires'),
              Tab(text: 'Déclaration TVA'),
              Tab(text: 'Balance âgée'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tab,
              children: const [
                _JournalTab(),
                _ChartOfAccountsTab(),
                _GrandLivreTab(),
                _FiscalYearsTab(),
                _BankAccountsTab(),
                _TVADeclarationTab(),
                _BalanceAgeeTab(),
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
    final journals = ref.read(appListsProvider).valueOrNull?.journals
        ?? AppLists.defaultJournals;
    final descCtrl = TextEditingController();
    String selectedJournal = journals.isNotEmpty ? journals.first.code : 'OD';
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
                  items: journals
                      .map((j) => DropdownMenuItem(
                          value: j.code,
                          child: Text(j.display)))
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
                final ecPrefix = ref.read(settingsProvider).valueOrNull?['ec_prefix'] ?? 'EC';
                final entry = JournalEntry(
                  reference:
                      '$ecPrefix-${DateTime.now().year}-${seq.toString().padLeft(4, '0')}',
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

// ── Fiscal Years Tab ──────────────────────────────────────────────────────────

class _FiscalYearsTab extends ConsumerWidget {
  const _FiscalYearsTab();

  static const _statusColors = {
    'Ouverte':     Colors.green,
    'Clôturée':    Colors.orange,
    'Verrouillée': Colors.red,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final fyAsync = ref.watch(fiscalYearProvider);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        Row(children: [
          const Spacer(),
          FilledButton.icon(
            onPressed: () => _showAddDialog(context, ref),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Nouvel exercice'),
          ),
        ]),
        const SizedBox(height: 12),
        Expanded(
          child: fyAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Erreur: $e')),
            data: (years) {
              if (years.isEmpty) {
                return const Center(child: Text('Aucun exercice fiscal'));
              }
              return ListView.builder(
                itemCount: years.length,
                itemBuilder: (ctx, i) {
                  final fy = years[i];
                  final color = _statusColors[fy.status] ?? Colors.grey;
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: Icon(Icons.calendar_today,
                          color: theme.colorScheme.primary),
                      title: Row(children: [
                        Text(fy.name,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600)),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(fy.status,
                              style: TextStyle(
                                  fontSize: 11,
                                  color: color,
                                  fontWeight: FontWeight.w600)),
                        ),
                      ]),
                      subtitle: Text(
                          '${MoroccoFormat.dateFromMs(fy.startDate)} → ${MoroccoFormat.dateFromMs(fy.endDate)}',
                          style: TextStyle(
                              fontSize: 12,
                              color: theme.colorScheme.onSurfaceVariant)),
                      trailing: PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert, size: 18),
                        itemBuilder: (_) => [
                          'Ouverte', 'Clôturée', 'Verrouillée'
                        ]
                            .map((s) => PopupMenuItem(
                                value: s, child: Text(s)))
                            .toList(),
                        onSelected: (s) => ref
                            .read(fiscalYearProvider.notifier)
                            .updateStatus(fy.id!, s),
                      ),
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

  void _showAddDialog(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final nameCtrl = TextEditingController(text: 'Exercice ${now.year}');
    DateTime startDate = DateTime(now.year, 1, 1);
    DateTime endDate = DateTime(now.year, 12, 31);
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Nouvel exercice fiscal'),
          content: SizedBox(
            width: 380,
            child: Form(
              key: formKey,
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                TextFormField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Nom *'),
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Requis' : null,
                ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Date de début',
                      style: TextStyle(fontSize: 13)),
                  subtitle: Text(MoroccoFormat.date(startDate)),
                  trailing: const Icon(Icons.calendar_today, size: 18),
                  onTap: () async {
                    final d = await showDatePicker(
                        context: ctx,
                        initialDate: startDate,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100));
                    if (d != null) setState(() => startDate = d);
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Date de fin',
                      style: TextStyle(fontSize: 13)),
                  subtitle: Text(MoroccoFormat.date(endDate)),
                  trailing: const Icon(Icons.calendar_today, size: 18),
                  onTap: () async {
                    final d = await showDatePicker(
                        context: ctx,
                        initialDate: endDate,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100));
                    if (d != null) setState(() => endDate = d);
                  },
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
                final fy = FiscalYear(
                  name: nameCtrl.text.trim(),
                  startDate: startDate.millisecondsSinceEpoch,
                  endDate: endDate.millisecondsSinceEpoch,
                );
                await ref.read(fiscalYearProvider.notifier).add(fy);
                if (ctx.mounted) Navigator.of(ctx).pop();
              },
              child: const Text('Créer'),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Bank Accounts Tab ─────────────────────────────────────────────────────────

class _BankAccountsTab extends ConsumerWidget {
  const _BankAccountsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final accountsAsync = ref.watch(bankAccountProvider);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        Row(children: [
          const Spacer(),
          FilledButton.icon(
            onPressed: () => _showDialog(context, ref, null),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Nouveau compte bancaire'),
          ),
        ]),
        const SizedBox(height: 12),
        Expanded(
          child: accountsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Erreur: $e')),
            data: (accounts) {
              if (accounts.isEmpty) {
                return const Center(child: Text('Aucun compte bancaire'));
              }
              return ListView.builder(
                itemCount: accounts.length,
                itemBuilder: (ctx, i) {
                  final acc = accounts[i];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: acc.isDefault
                            ? theme.colorScheme.primaryContainer
                            : theme.colorScheme.surfaceContainerHighest,
                        child: Icon(Icons.account_balance,
                            color: acc.isDefault
                                ? theme.colorScheme.primary
                                : theme.colorScheme.onSurfaceVariant,
                            size: 20),
                      ),
                      title: Row(children: [
                        Text(acc.name,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600)),
                        if (acc.isDefault) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text('Principal',
                                style: TextStyle(
                                    fontSize: 10,
                                    color: theme.colorScheme.primary,
                                    fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ]),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (acc.bankName != null)
                            Text(acc.bankName!,
                                style: TextStyle(
                                    fontSize: 12,
                                    color: theme
                                        .colorScheme.onSurfaceVariant)),
                          if (acc.rib != null)
                            Text('RIB: ${acc.rib}',
                                style: TextStyle(
                                    fontSize: 11,
                                    fontFamily: 'monospace',
                                    color: theme
                                        .colorScheme.onSurfaceVariant)),
                        ],
                      ),
                      isThreeLine: acc.bankName != null && acc.rib != null,
                      trailing: PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert, size: 18),
                        itemBuilder: (_) => [
                          const PopupMenuItem(
                              value: 'edit',
                              child: ListTile(
                                  leading: Icon(Icons.edit_outlined),
                                  title: Text('Modifier'),
                                  dense: true,
                                  contentPadding: EdgeInsets.zero)),
                          if (!acc.isDefault)
                            const PopupMenuItem(
                                value: 'default',
                                child: ListTile(
                                    leading: Icon(Icons.star_outline),
                                    title: Text('Compte principal'),
                                    dense: true,
                                    contentPadding: EdgeInsets.zero)),
                          const PopupMenuItem(
                              value: 'delete',
                              child: ListTile(
                                  leading: Icon(Icons.delete_outline,
                                      color: Colors.red),
                                  title: Text('Supprimer',
                                      style:
                                          TextStyle(color: Colors.red)),
                                  dense: true,
                                  contentPadding: EdgeInsets.zero)),
                        ],
                        onSelected: (v) {
                          if (v == 'edit') _showDialog(context, ref, acc);
                          if (v == 'default') {
                            ref
                                .read(bankAccountProvider.notifier)
                                .setDefault(acc.id!);
                          }
                          if (v == 'delete') {
                            ref
                                .read(bankAccountProvider.notifier)
                                .remove(acc.id!);
                          }
                        },
                      ),
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

  void _showDialog(
      BuildContext context, WidgetRef ref, BankAccount? account) {
    final nameCtrl =
        TextEditingController(text: account?.name ?? '');
    final bankCtrl =
        TextEditingController(text: account?.bankName ?? '');
    final ibanCtrl =
        TextEditingController(text: account?.iban ?? '');
    final swiftCtrl =
        TextEditingController(text: account?.swift ?? '');
    final ribCtrl =
        TextEditingController(text: account?.rib ?? '');
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(account == null
            ? 'Nouveau compte bancaire'
            : 'Modifier compte bancaire'),
        content: SizedBox(
          width: 400,
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                TextFormField(
                  controller: nameCtrl,
                  decoration:
                      const InputDecoration(labelText: 'Libellé *'),
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Requis' : null,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: bankCtrl,
                  decoration:
                      const InputDecoration(labelText: 'Banque'),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: ribCtrl,
                  decoration: const InputDecoration(labelText: 'RIB'),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: ibanCtrl,
                  decoration: const InputDecoration(labelText: 'IBAN'),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: swiftCtrl,
                  decoration: const InputDecoration(labelText: 'SWIFT/BIC'),
                ),
              ]),
            ),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Annuler')),
          FilledButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              final now = DateTime.now().millisecondsSinceEpoch;
              final acc = BankAccount(
                id: account?.id,
                name: nameCtrl.text.trim(),
                bankName: bankCtrl.text.trim().isEmpty
                    ? null
                    : bankCtrl.text.trim(),
                rib: ribCtrl.text.trim().isEmpty
                    ? null
                    : ribCtrl.text.trim(),
                iban: ibanCtrl.text.trim().isEmpty
                    ? null
                    : ibanCtrl.text.trim(),
                swift: swiftCtrl.text.trim().isEmpty
                    ? null
                    : swiftCtrl.text.trim(),
                isDefault: account?.isDefault ?? false,
                createdAt: account?.createdAt ?? now,
              );
              if (account == null) {
                await ref.read(bankAccountProvider.notifier).add(acc);
              } else {
                await ref.read(bankAccountProvider.notifier).edit(acc);
              }
              if (ctx.mounted) Navigator.of(ctx).pop();
            },
            child:
                Text(account == null ? 'Créer' : 'Enregistrer'),
          ),
        ],
      ),
    );
  }
}

// ── TVA Declaration Tab ───────────────────────────────────────────────────────

class _TVADeclarationTab extends ConsumerStatefulWidget {
  const _TVADeclarationTab();

  @override
  ConsumerState<_TVADeclarationTab> createState() =>
      _TVADeclarationTabState();
}

class _TVADeclarationTabState extends ConsumerState<_TVADeclarationTab> {
  int _selectedYear = DateTime.now().year;
  int _selectedQuarter = ((DateTime.now().month - 1) ~/ 3) + 1;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Compute period bounds
    final startMonth = (_selectedQuarter - 1) * 3 + 1;
    final start =
        DateTime(_selectedYear, startMonth, 1).millisecondsSinceEpoch;
    final endMonth = startMonth + 2;
    final end = DateTime(_selectedYear, endMonth + 1, 0, 23, 59, 59)
        .millisecondsSinceEpoch;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Text('Déclaration TVA — SIMPL',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const Spacer(),
            DropdownButton<int>(
              value: _selectedYear,
              items: List.generate(5, (i) => DateTime.now().year - i)
                  .map((y) =>
                      DropdownMenuItem(value: y, child: Text('$y')))
                  .toList(),
              onChanged: (v) => setState(() => _selectedYear = v!),
            ),
            const SizedBox(width: 16),
            DropdownButton<int>(
              value: _selectedQuarter,
              items: const [
                DropdownMenuItem(value: 1, child: Text('T1 (Jan-Mar)')),
                DropdownMenuItem(value: 2, child: Text('T2 (Avr-Jun)')),
                DropdownMenuItem(value: 3, child: Text('T3 (Jul-Sep)')),
                DropdownMenuItem(value: 4, child: Text('T4 (Oct-Déc)')),
              ],
              onChanged: (v) => setState(() => _selectedQuarter = v!),
            ),
          ]),
          const SizedBox(height: 24),
          FutureBuilder<(double, double)>(
            future: _loadTVA(ref, start, end),
            builder: (ctx, snap) {
              if (!snap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final (collected, deductible) = snap.data!;
              final net = collected - deductible;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _TVACard(
                    label: 'TVA collectée (sur ventes)',
                    amount: collected,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: 12),
                  _TVACard(
                    label: 'TVA déductible (sur achats)',
                    amount: deductible,
                    color: Colors.green,
                  ),
                  const Divider(height: 32),
                  _TVACard(
                    label: net >= 0 ? 'TVA à payer (net)' : 'Crédit TVA',
                    amount: net.abs(),
                    color: net >= 0
                        ? theme.colorScheme.error
                        : Colors.green.shade700,
                    bold: true,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Période : T$_selectedQuarter $_selectedYear — '
                    '${MoroccoFormat.dateFromMs(start)} au ${MoroccoFormat.dateFromMs(end)}',
                    style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.onSurfaceVariant),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Future<(double, double)> _loadTVA(
      WidgetRef ref, int from, int to) async {
    final repo = ref.read(bankAccountRepoProvider);
    final collected = await repo.tvaCollected(from, to);
    final deductible = await repo.tvaDeductible(from, to);
    return (collected, deductible);
  }
}

class _TVACard extends StatelessWidget {
  const _TVACard({
    required this.label,
    required this.amount,
    required this.color,
    this.bold = false,
  });

  final String label;
  final double amount;
  final Color color;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 600),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(children: [
        Expanded(
            child: Text(label,
                style: TextStyle(
                    color: color,
                    fontWeight:
                        bold ? FontWeight.bold : FontWeight.normal))),
        Text(MoroccoFormat.mad(amount),
            style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: bold ? 18 : 14)),
      ]),
    );
  }
}

// ── Balance Âgée Tab ──────────────────────────────────────────────────────────

class _BalanceAgeeTab extends ConsumerStatefulWidget {
  const _BalanceAgeeTab();

  @override
  ConsumerState<_BalanceAgeeTab> createState() => _BalanceAgeeTabState();
}

class _BalanceAgeeTabState extends ConsumerState<_BalanceAgeeTab>
    with SingleTickerProviderStateMixin {
  late TabController _innerTab;

  @override
  void initState() {
    super.initState();
    _innerTab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _innerTab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      TabBar(
        controller: _innerTab,
        tabs: const [
          Tab(text: 'Créances clients'),
          Tab(text: 'Dettes fournisseurs'),
        ],
      ),
      Expanded(
        child: TabBarView(
          controller: _innerTab,
          children: const [
            _AgedReceivablesView(),
            _AgedPayablesView(),
          ],
        ),
      ),
    ]);
  }
}

class _AgedReceivablesView extends ConsumerWidget {
  const _AgedReceivablesView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: ref.read(bankAccountRepoProvider).agedReceivables(),
      builder: (ctx, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final rows = snap.data!;
        if (rows.isEmpty) {
          return const Center(child: Text('Aucune créance impayée'));
        }
        final now = DateTime.now().millisecondsSinceEpoch;
        final total = rows.fold<double>(
            0,
            (s, r) =>
                s +
                ((r['total_ttc'] as num).toDouble() -
                    (r['amount_paid'] as num).toDouble()));
        return Column(children: [
          Container(
            color: theme.colorScheme.errorContainer,
            padding: const EdgeInsets.all(12),
            child: Row(children: [
              Icon(Icons.warning_amber,
                  color: theme.colorScheme.error, size: 18),
              const SizedBox(width: 8),
              Text('Total créances impayées: ${MoroccoFormat.mad(total)}',
                  style: TextStyle(
                      color: theme.colorScheme.error,
                      fontWeight: FontWeight.bold)),
            ]),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: DataTable(
                columnSpacing: 20,
                columns: const [
                  DataColumn(label: Text('Facture')),
                  DataColumn(label: Text('Client')),
                  DataColumn(label: Text('Échéance')),
                  DataColumn(label: Text('Retard (j)')),
                  DataColumn(label: Text('Restant dû')),
                ],
                rows: rows.map((r) {
                  final due = r['due_date'] as int;
                  final days =
                      ((now - due) / 86400000).round();
                  final amountDue = (r['total_ttc'] as num).toDouble() -
                      (r['amount_paid'] as num).toDouble();
                  final isOverdue = now > due;
                  return DataRow(cells: [
                    DataCell(Text(r['reference'] as String)),
                    DataCell(Text(r['client_name'] as String)),
                    DataCell(Text(MoroccoFormat.dateFromMs(due))),
                    DataCell(Text(
                      isOverdue ? '+$days j' : '${-days} j',
                      style: TextStyle(
                          color: isOverdue
                              ? theme.colorScheme.error
                              : Colors.green,
                          fontWeight: FontWeight.w600),
                    )),
                    DataCell(Text(MoroccoFormat.mad(amountDue),
                        style: const TextStyle(
                            fontWeight: FontWeight.bold))),
                  ]);
                }).toList(),
              ),
            ),
          ),
        ]);
      },
    );
  }
}

class _AgedPayablesView extends ConsumerWidget {
  const _AgedPayablesView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: ref.read(bankAccountRepoProvider).agedPayables(),
      builder: (ctx, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final rows = snap.data!;
        if (rows.isEmpty) {
          return const Center(child: Text('Aucune dette impayée'));
        }
        final now = DateTime.now().millisecondsSinceEpoch;
        final total = rows.fold<double>(
            0,
            (s, r) =>
                s +
                ((r['total_ttc'] as num).toDouble() -
                    (r['amount_paid'] as num).toDouble()));
        return Column(children: [
          Container(
            color: theme.colorScheme.errorContainer,
            padding: const EdgeInsets.all(12),
            child: Row(children: [
              Icon(Icons.warning_amber,
                  color: theme.colorScheme.error, size: 18),
              const SizedBox(width: 8),
              Text('Total dettes fournisseurs: ${MoroccoFormat.mad(total)}',
                  style: TextStyle(
                      color: theme.colorScheme.error,
                      fontWeight: FontWeight.bold)),
            ]),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: DataTable(
                columnSpacing: 20,
                columns: const [
                  DataColumn(label: Text('Facture')),
                  DataColumn(label: Text('Fournisseur')),
                  DataColumn(label: Text('Échéance')),
                  DataColumn(label: Text('Retard (j)')),
                  DataColumn(label: Text('Restant dû')),
                ],
                rows: rows.map((r) {
                  final due = r['due_date'] as int;
                  final days =
                      ((now - due) / 86400000).round();
                  final amountDue = (r['total_ttc'] as num).toDouble() -
                      (r['amount_paid'] as num).toDouble();
                  final isOverdue = now > due;
                  return DataRow(cells: [
                    DataCell(Text(r['reference'] as String)),
                    DataCell(Text(r['supplier_name'] as String)),
                    DataCell(Text(MoroccoFormat.dateFromMs(due))),
                    DataCell(Text(
                      isOverdue ? '+$days j' : '${-days} j',
                      style: TextStyle(
                          color: isOverdue
                              ? theme.colorScheme.error
                              : Colors.green,
                          fontWeight: FontWeight.w600),
                    )),
                    DataCell(Text(MoroccoFormat.mad(amountDue),
                        style: const TextStyle(
                            fontWeight: FontWeight.bold))),
                  ]);
                }).toList(),
              ),
            ),
          ),
        ]);
      },
    );
  }
}
