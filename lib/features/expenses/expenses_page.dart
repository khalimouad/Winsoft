import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/expense.dart';
import '../../core/providers/providers.dart';
import '../../core/utils/morocco_format.dart';

class ExpensesPage extends ConsumerStatefulWidget {
  const ExpensesPage({super.key});

  @override
  ConsumerState<ExpensesPage> createState() => _ExpensesPageState();
}

class _ExpensesPageState extends ConsumerState<ExpensesPage>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
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
            child: Text('Notes de frais',
                style: theme.textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold)),
          ),
          TabBar(
            controller: _tab,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            tabs: const [
              Tab(text: 'Toutes les dépenses'),
              Tab(text: 'Par catégorie'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tab,
              children: const [
                _ExpensesListTab(),
                _ExpensesByCategoryTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Expenses List Tab ─────────────────────────────────────────────────────────

class _ExpensesListTab extends ConsumerWidget {
  const _ExpensesListTab();

  static const _statusColors = {
    'Brouillon':   Colors.grey,
    'Soumise':     Colors.blue,
    'Approuvée':   Colors.green,
    'Remboursée':  Colors.teal,
    'Rejetée':     Colors.red,
  };

  static const _categories = [
    'Déplacement',
    'Hébergement',
    'Repas',
    'Fournitures',
    'Communication',
    'Formation',
    'Représentation',
    'Autre',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final expensesAsync = ref.watch(expenseProvider);
    final employeesAsync = ref.watch(employeeProvider);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        Row(children: [
          const Spacer(),
          FilledButton.icon(
            onPressed: () => employeesAsync.whenData(
                (employees) =>
                    _showAddDialog(context, ref, employees)),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Nouvelle dépense'),
          ),
        ]),
        const SizedBox(height: 12),
        Expanded(
          child: expensesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Erreur: $e')),
            data: (expenses) {
              if (expenses.isEmpty) {
                return const Center(child: Text('Aucune note de frais'));
              }
              final totalPending = expenses
                  .where((e) => e.status == 'Soumise')
                  .fold<double>(0, (s, e) => s + e.amount);

              return Column(children: [
                if (totalPending > 0)
                  Container(
                    color: theme.colorScheme.primaryContainer,
                    padding: const EdgeInsets.all(12),
                    child: Row(children: [
                      const Icon(Icons.pending_actions, size: 18),
                      const SizedBox(width: 8),
                      Text(
                          'En attente de validation: ${MoroccoFormat.mad(totalPending)}',
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                    ]),
                  ),
                Expanded(
                  child: ListView.builder(
                    itemCount: expenses.length,
                    itemBuilder: (ctx, i) {
                      final exp = expenses[i];
                      final color =
                          _statusColors[exp.status] ?? Colors.grey;
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: _categoryIcon(exp.category),
                          title: Row(children: [
                            Text(exp.description,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600)),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(exp.status,
                                  style: TextStyle(
                                      fontSize: 10,
                                      color: color,
                                      fontWeight: FontWeight.w600)),
                            ),
                          ]),
                          subtitle: Text(
                              '${exp.category} · '
                              '${exp.employeeName ?? 'Non attribué'} · '
                              '${MoroccoFormat.dateFromMs(exp.date)}',
                              style: TextStyle(
                                  fontSize: 12,
                                  color:
                                      theme.colorScheme.onSurfaceVariant)),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(MoroccoFormat.mad(exp.amount),
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold)),
                              PopupMenuButton<String>(
                                icon: const Icon(Icons.more_vert, size: 18),
                                itemBuilder: (_) => [
                                  'Brouillon',
                                  'Soumise',
                                  'Approuvée',
                                  'Remboursée',
                                  'Rejetée',
                                ]
                                    .map((s) => PopupMenuItem(
                                        value: s, child: Text(s)))
                                    .toList()
                                  ..add(const PopupMenuItem(
                                      value: 'delete',
                                      child: ListTile(
                                          leading: Icon(
                                              Icons.delete_outline,
                                              color: Colors.red),
                                          title: Text('Supprimer',
                                              style: TextStyle(
                                                  color: Colors.red)),
                                          dense: true,
                                          contentPadding:
                                              EdgeInsets.zero))),
                                onSelected: (s) {
                                  if (s == 'delete') {
                                    ref
                                        .read(expenseProvider.notifier)
                                        .remove(exp.id!);
                                  } else {
                                    ref
                                        .read(expenseProvider.notifier)
                                        .updateStatus(exp.id!, s);
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ]);
            },
          ),
        ),
      ]),
    );
  }

  Widget _categoryIcon(String category) {
    final iconData = switch (category) {
      'Déplacement' => Icons.directions_car_outlined,
      'Hébergement' => Icons.hotel_outlined,
      'Repas' => Icons.restaurant_outlined,
      'Fournitures' => Icons.inventory_outlined,
      'Communication' => Icons.phone_outlined,
      'Formation' => Icons.school_outlined,
      'Représentation' => Icons.business_center_outlined,
      _ => Icons.receipt_outlined,
    };
    return CircleAvatar(
      backgroundColor: Colors.blueGrey.shade50,
      child: Icon(iconData, size: 20, color: Colors.blueGrey),
    );
  }

  void _showAddDialog(BuildContext context, WidgetRef ref, List employees) {
    String category = _categories.first;
    int? selectedEmployeeId =
        employees.isNotEmpty ? employees.first.id as int? : null;
    final descCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    final receiptCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    DateTime expenseDate = DateTime.now();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Nouvelle note de frais'),
          content: SizedBox(
            width: 420,
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  if (employees.isNotEmpty)
                    DropdownButtonFormField<int?>(
                      value: selectedEmployeeId,
                      decoration:
                          const InputDecoration(labelText: 'Employé'),
                      items: [
                        const DropdownMenuItem<int?>(
                            value: null, child: Text('— Non attribué —')),
                        ...employees.map((e) => DropdownMenuItem<int?>(
                            value: e.id as int?,
                            child: Text(e.name as String))),
                      ],
                      onChanged: (v) =>
                          setState(() => selectedEmployeeId = v),
                    ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: category,
                    decoration:
                        const InputDecoration(labelText: 'Catégorie'),
                    items: _categories
                        .map((c) => DropdownMenuItem(
                            value: c, child: Text(c)))
                        .toList(),
                    onChanged: (v) => setState(() => category = v!),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: descCtrl,
                    decoration:
                        const InputDecoration(labelText: 'Description *'),
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Requis' : null,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: amountCtrl,
                    decoration: const InputDecoration(
                        labelText: 'Montant (MAD) *',
                        suffixText: 'MAD'),
                    keyboardType: TextInputType.number,
                    validator: (v) =>
                        (double.tryParse(v ?? '') ?? 0) <= 0
                            ? 'Requis'
                            : null,
                  ),
                  const SizedBox(height: 10),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Date',
                        style: TextStyle(fontSize: 13)),
                    subtitle: Text(MoroccoFormat.date(expenseDate)),
                    trailing: const Icon(Icons.calendar_today, size: 18),
                    onTap: () async {
                      final d = await showDatePicker(
                          context: ctx,
                          initialDate: expenseDate,
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100));
                      if (d != null) setState(() => expenseDate = d);
                    },
                  ),
                  TextFormField(
                    controller: receiptCtrl,
                    decoration: const InputDecoration(
                        labelText: 'N° justificatif'),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: notesCtrl,
                    decoration:
                        const InputDecoration(labelText: 'Notes'),
                    maxLines: 2,
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
                final expense = Expense(
                  employeeId: selectedEmployeeId,
                  category: category,
                  description: descCtrl.text.trim(),
                  amount: double.parse(amountCtrl.text),
                  date: expenseDate.millisecondsSinceEpoch,
                  receiptRef: receiptCtrl.text.trim().isEmpty
                      ? null
                      : receiptCtrl.text.trim(),
                  notes: notesCtrl.text.trim().isEmpty
                      ? null
                      : notesCtrl.text.trim(),
                );
                await ref.read(expenseProvider.notifier).add(expense);
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

// ── Expenses By Category Tab ──────────────────────────────────────────────────

class _ExpensesByCategoryTab extends ConsumerWidget {
  const _ExpensesByCategoryTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: ref.read(expenseRepoProvider).byCategory(),
      builder: (ctx, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final rows = snap.data!;
        if (rows.isEmpty) {
          return const Center(child: Text('Aucune dépense enregistrée'));
        }
        final grandTotal = rows.fold<double>(
            0, (s, r) => s + (r['total'] as num).toDouble());

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(children: [
                const Icon(Icons.summarize_outlined, size: 20),
                const SizedBox(width: 8),
                Text('Total toutes catégories: ',
                    style: theme.textTheme.bodyMedium),
                Text(MoroccoFormat.mad(grandTotal),
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(fontWeight: FontWeight.bold)),
              ]),
            ),
            const SizedBox(height: 16),
            ...rows.map((r) {
              final total = (r['total'] as num).toDouble();
              final count = r['count'] as int;
              final pct = grandTotal > 0 ? total / grandTotal : 0.0;
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Expanded(
                          child: Text(r['category'] as String,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600)),
                        ),
                        Text(MoroccoFormat.mad(total),
                            style: const TextStyle(
                                fontWeight: FontWeight.bold)),
                        const SizedBox(width: 8),
                        Text('($count dép.)',
                            style: TextStyle(
                                fontSize: 12,
                                color:
                                    theme.colorScheme.onSurfaceVariant)),
                      ]),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: pct,
                        backgroundColor: theme.colorScheme.surfaceContainerHighest,
                        valueColor: AlwaysStoppedAnimation<Color>(
                            theme.colorScheme.primary),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        );
      },
    );
  }
}
