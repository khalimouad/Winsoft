import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/app_lists.dart';
import '../../core/models/employee.dart';
import '../../core/models/payroll_slip.dart';
import '../../core/providers/providers.dart';
import '../../core/utils/morocco_format.dart';

class HrPage extends ConsumerStatefulWidget {
  const HrPage({super.key});

  @override
  ConsumerState<HrPage> createState() => _HrPageState();
}

class _HrPageState extends ConsumerState<HrPage>
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
            child: Text('Ressources Humaines',
                style: theme.textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold)),
          ),
          TabBar(
            controller: _tab,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            tabs: const [
              Tab(text: 'Employés'),
              Tab(text: 'Paie'),
              Tab(text: 'Congés'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tab,
              children: const [
                _EmployeesTab(),
                _PayrollTab(),
                _LeavesTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Employees Tab ─────────────────────────────────────────────────────────────

class _EmployeesTab extends ConsumerStatefulWidget {
  const _EmployeesTab();

  @override
  ConsumerState<_EmployeesTab> createState() => _EmployeesTabState();
}

class _EmployeesTabState extends ConsumerState<_EmployeesTab> {
  String _search = '';

  @override
  Widget build(BuildContext context) {

    final employeesAsync = ref.watch(employeeProvider);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        Row(children: [
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Rechercher…',
                prefixIcon: const Icon(Icons.search, size: 18),
                isDense: true,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              onChanged: (v) => setState(() => _search = v),
            ),
          ),
          const SizedBox(width: 12),
          FilledButton.icon(
            onPressed: () => _showDialog(context, ref, null),
            icon: const Icon(Icons.person_add_outlined, size: 18),
            label: const Text('Nouvel employé'),
          ),
        ]),
        const SizedBox(height: 12),
        Expanded(
          child: employeesAsync.when(
            loading: () =>
                const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Erreur: $e')),
            data: (employees) {
              final filtered = _search.isEmpty
                  ? employees
                  : employees
                      .where((e) =>
                          e.name.toLowerCase().contains(_search.toLowerCase()) ||
                          (e.department?.toLowerCase().contains(_search.toLowerCase()) ?? false))
                      .toList();
              if (filtered.isEmpty) {
                return const Center(child: Text('Aucun employé'));
              }
              return LayoutBuilder(
                builder: (ctx, constraints) {
                  final cols = constraints.maxWidth > 900
                      ? 3
                      : constraints.maxWidth > 600
                          ? 2
                          : 1;
                  return GridView.builder(
                    gridDelegate:
                        SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: cols,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 2.4,
                    ),
                    itemCount: filtered.length,
                    itemBuilder: (ctx, i) => _EmployeeCard(
                      employee: filtered[i],
                      onEdit: () =>
                          _showDialog(context, ref, filtered[i]),
                      onDelete: () =>
                          _confirmDelete(context, ref, filtered[i]),
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
      BuildContext context, WidgetRef ref, Employee? emp) {
    final nameCtrl = TextEditingController(text: emp?.name ?? '');
    final emailCtrl =
        TextEditingController(text: emp?.email ?? '');
    final phoneCtrl =
        TextEditingController(text: emp?.phone ?? '');
    final cinCtrl = TextEditingController(text: emp?.cin ?? '');
    final cnssCtrl =
        TextEditingController(text: emp?.cnssNum ?? '');
    final depts = ref.read(appListsProvider).valueOrNull?.employeeDepartments
        ?? AppLists.defaultEmployeeDepartments.toList();
    String? selectedDept = depts.contains(emp?.department) ? emp!.department : null;
    final posCtrl =
        TextEditingController(text: emp?.position ?? '');
    final salaryCtrl = TextEditingController(
        text: emp != null ? emp.salaryBrut.toStringAsFixed(2) : '');
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title:
            Text(emp == null ? 'Nouvel employé' : 'Modifier employé'),
        content: SizedBox(
          width: 440,
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                TextFormField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Nom complet *'),
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Requis' : null,
                ),
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(
                    child: TextFormField(
                      controller: emailCtrl,
                      decoration:
                          const InputDecoration(labelText: 'Email'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: phoneCtrl,
                      decoration:
                          const InputDecoration(labelText: 'Téléphone'),
                    ),
                  ),
                ]),
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(
                    child: TextFormField(
                      controller: cinCtrl,
                      decoration:
                          const InputDecoration(labelText: 'CIN'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: cnssCtrl,
                      decoration:
                          const InputDecoration(labelText: 'N° CNSS'),
                    ),
                  ),
                ]),
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(
                    child: DropdownButtonFormField<String?>(
                      value: selectedDept,
                      decoration: const InputDecoration(labelText: 'Département'),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('— Choisir —')),
                        ...depts.map((d) => DropdownMenuItem(value: d, child: Text(d))),
                      ],
                      onChanged: (v) => selectedDept = v,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: posCtrl,
                      decoration:
                          const InputDecoration(labelText: 'Poste'),
                    ),
                  ),
                ]),
                const SizedBox(height: 10),
                TextFormField(
                  controller: salaryCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Salaire brut (DH) *'),
                  keyboardType: TextInputType.number,
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Requis' : null,
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
              final e = Employee(
                id: emp?.id,
                name: nameCtrl.text.trim(),
                email: emailCtrl.text.trim().isEmpty
                    ? null
                    : emailCtrl.text.trim(),
                phone: phoneCtrl.text.trim().isEmpty
                    ? null
                    : phoneCtrl.text.trim(),
                cin: cinCtrl.text.trim().isEmpty
                    ? null
                    : cinCtrl.text.trim(),
                cnssNum: cnssCtrl.text.trim().isEmpty
                    ? null
                    : cnssCtrl.text.trim(),
                department: selectedDept,
                position: posCtrl.text.trim().isEmpty
                    ? null
                    : posCtrl.text.trim(),
                salaryBrut: double.tryParse(salaryCtrl.text) ?? 0,
                hireDate: emp?.hireDate ?? now,
                createdAt: emp?.createdAt ?? now,
              );
              if (emp == null) {
                await ref.read(employeeProvider.notifier).add(e);
              } else {
                await ref.read(employeeProvider.notifier).edit(e);
              }
              if (ctx.mounted) Navigator.of(ctx).pop();
            },
            child: Text(emp == null ? 'Ajouter' : 'Enregistrer'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(
      BuildContext context, WidgetRef ref, Employee emp) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer employé'),
        content: Text('Supprimer "${emp.name}" ?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Annuler')),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor:
                    Theme.of(context).colorScheme.error),
            onPressed: () {
              ref
                  .read(employeeProvider.notifier)
                  .remove(emp.id!);
              Navigator.of(ctx).pop();
            },
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }
}

class _EmployeeCard extends StatelessWidget {
  const _EmployeeCard(
      {required this.employee,
      required this.onEdit,
      required this.onDelete});

  final Employee employee;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final net = MoroccanPayroll.netSalary(employee.salaryBrut);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: employee.isActive
                ? theme.colorScheme.primaryContainer
                : Colors.grey.shade200,
            child: Text(
              employee.name.isNotEmpty
                  ? employee.name[0].toUpperCase()
                  : '?',
              style: TextStyle(
                color: employee.isActive
                    ? theme.colorScheme.onPrimaryContainer
                    : Colors.grey,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(employee.name,
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis),
                if (employee.position != null ||
                    employee.department != null)
                  Text(
                      [employee.position, employee.department]
                          .where((e) => e != null)
                          .join(' — '),
                      style: theme.textTheme.bodySmall?.copyWith(
                          color:
                              theme.colorScheme.onSurfaceVariant),
                      overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Row(children: [
                  Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Brut: ${MoroccoFormat.mad(employee.salaryBrut)}',
                            style: const TextStyle(fontSize: 11)),
                        Text('Net: ${MoroccoFormat.mad(net)}',
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.green.shade700)),
                      ]),
                ]),
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert,
                size: 18,
                color: theme.colorScheme.onSurfaceVariant),
            itemBuilder: (_) => [
              const PopupMenuItem(
                  value: 'edit',
                  child: ListTile(
                      leading: Icon(Icons.edit_outlined),
                      title: Text('Modifier'),
                      dense: true,
                      contentPadding: EdgeInsets.zero)),
              const PopupMenuItem(
                  value: 'delete',
                  child: ListTile(
                      leading: Icon(Icons.delete_outline,
                          color: Colors.red),
                      title: Text('Supprimer',
                          style: TextStyle(color: Colors.red)),
                      dense: true,
                      contentPadding: EdgeInsets.zero)),
            ],
            onSelected: (v) {
              if (v == 'edit') onEdit();
              if (v == 'delete') onDelete();
            },
          ),
        ]),
      ),
    );
  }
}

// ── Payroll Tab ───────────────────────────────────────────────────────────────

class _PayrollTab extends ConsumerStatefulWidget {
  const _PayrollTab();

  @override
  ConsumerState<_PayrollTab> createState() => _PayrollTabState();
}

class _PayrollTabState extends ConsumerState<_PayrollTab> {
  int _year = DateTime.now().year;
  int _month = DateTime.now().month;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final payrollAsync = ref.watch(payrollProvider);
    final employeesAsync = ref.watch(employeeProvider);

    const months = [
      '', 'Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Jun',
      'Jul', 'Aoû', 'Sep', 'Oct', 'Nov', 'Déc',
    ];

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        // Header with period selector and action
        Row(children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () => setState(() {
              _month--;
              if (_month < 1) {
                _month = 12;
                _year--;
              }
            }),
          ),
          Text('${months[_month]} $_year',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600)),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () => setState(() {
              _month++;
              if (_month > 12) {
                _month = 1;
                _year++;
              }
            }),
          ),
          const Spacer(),
          FilledButton.icon(
            onPressed: () => employeesAsync.whenData((employees) =>
                _generateSlips(context, ref, employees)),
            icon: const Icon(Icons.calculate_outlined, size: 18),
            label: const Text('Générer la paie'),
          ),
        ]),
        const SizedBox(height: 12),
        Expanded(
          child: payrollAsync.when(
            loading: () =>
                const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Erreur: $e')),
            data: (slips) {
              final filtered = slips
                  .where((s) =>
                      s.periodYear == _year &&
                      s.periodMonth == _month)
                  .toList();
              if (filtered.isEmpty) {
                return Center(
                    child: Text(
                        'Aucune fiche de paie pour ${months[_month]} $_year'));
              }
              return ListView.builder(
                itemCount: filtered.length,
                itemBuilder: (ctx, i) =>
                    _PayrollSlipTile(slip: filtered[i]),
              );
            },
          ),
        ),
      ]),
    );
  }

  Future<void> _generateSlips(BuildContext context, WidgetRef ref,
      List<Employee> employees) async {
    final active = employees.where((e) => e.isActive).toList();
    if (active.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Aucun employé actif')));
      return;
    }
    final now = DateTime.now().millisecondsSinceEpoch;
    int created = 0;
    for (final emp in active) {
      try {
        final slip = PayrollSlip(
          employeeId: emp.id!,
          periodYear: _year,
          periodMonth: _month,
          salaryBrut: emp.salaryBrut,
          cnssEmployee: MoroccanPayroll.cnssEmployee(emp.salaryBrut),
          amoEmployee: MoroccanPayroll.amoEmployee(emp.salaryBrut),
          igr: MoroccanPayroll.igr(emp.salaryBrut),
          salaryNet: MoroccanPayroll.netSalary(emp.salaryBrut),
          cnssEmployer: MoroccanPayroll.cnssEmployer(emp.salaryBrut),
          amoEmployer: MoroccanPayroll.amoEmployer(emp.salaryBrut),
          createdAt: now,
        );
        await ref.read(payrollProvider.notifier).add(slip);
        created++;
      } catch (_) {
        // Skip if already exists for this period
      }
    }
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content:
              Text('$created fiche(s) de paie générée(s)')));
    }
  }
}

class _PayrollSlipTile extends StatelessWidget {
  const _PayrollSlipTile({required this.slip});
  final PayrollSlip slip;

  static const _statusColor = {
    'Brouillon': Colors.grey,
    'Validé': Colors.blue,
    'Payé': Colors.green,
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _statusColor[slip.status] ?? Colors.grey;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(children: [
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              Text(slip.employeeName ?? 'Employé',
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              if (slip.employeePosition != null)
                Text(slip.employeePosition!,
                    style: TextStyle(
                        fontSize: 11,
                        color: theme.colorScheme.onSurfaceVariant)),
            ]),
          ),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('Brut: ${MoroccoFormat.mad(slip.salaryBrut)}',
                style: const TextStyle(fontSize: 12)),
            Text('CNSS: -${MoroccoFormat.mad(slip.cnssEmployee)}',
                style: TextStyle(
                    fontSize: 11,
                    color: theme.colorScheme.onSurfaceVariant)),
            Text('AMO: -${MoroccoFormat.mad(slip.amoEmployee)}',
                style: TextStyle(
                    fontSize: 11,
                    color: theme.colorScheme.onSurfaceVariant)),
            Text('IGR: -${MoroccoFormat.mad(slip.igr)}',
                style: TextStyle(
                    fontSize: 11,
                    color: theme.colorScheme.onSurfaceVariant)),
            Text('Net: ${MoroccoFormat.mad(slip.salaryNet)}',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Colors.green.shade700)),
          ]),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(slip.status,
                style: TextStyle(
                    fontSize: 11,
                    color: color,
                    fontWeight: FontWeight.w600)),
          ),
        ]),
      ),
    );
  }
}

// ── Leaves Tab ────────────────────────────────────────────────────────────────

class _LeavesTab extends ConsumerStatefulWidget {
  const _LeavesTab();

  @override
  ConsumerState<_LeavesTab> createState() => _LeavesTabState();
}

class _LeavesTabState extends ConsumerState<_LeavesTab> {
  List<String> get _types =>
      ref.read(appListsProvider).valueOrNull?.leaveTypes ??
      AppLists.defaultLeaveTypes.toList();

  List<String> get _statuses =>
      ref.read(appListsProvider).valueOrNull?.leaveStatuses ??
      AppLists.defaultLeaveStatuses.toList();

  static const _statusColors = {
    'En attente': Colors.orange,
    'Approuvé':   Colors.green,
    'Refusé':     Colors.red,
    'Annulé':     Colors.grey,
  };

  String _filterStatus = 'Tous';
  List<Map<String, dynamic>> _leaves = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadLeaves();
  }

  Future<void> _loadLeaves() async {
    setState(() => _loading = true);
    final repo = ref.read(employeeRepoProvider);
    final rows = await repo.getLeaves();
    if (mounted) setState(() { _leaves = rows; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statuses = ['Tous', ..._statuses]; // ignore: prefer_const_literals_to_create_immutables

    final filtered = _filterStatus == 'Tous'
        ? _leaves
        : _leaves.where((l) => l['status'] == _filterStatus).toList();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        Row(children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: statuses.map((s) {
              final sel = _filterStatus == s;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(s),
                  selected: sel,
                  showCheckmark: false,
                  onSelected: (_) =>
                      setState(() => _filterStatus = s),
                ),
              );
            }).toList()),
          ),
          const Spacer(),
          FilledButton.icon(
            onPressed: () => _showAddDialog(context),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Nouvelle demande'),
          ),
        ]),
        const SizedBox(height: 12),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : filtered.isEmpty
                  ? const Center(
                      child: Text('Aucune demande de congé'))
                  : ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (ctx, i) {
                        final leave = filtered[i];
                        final status = leave['status'] as String;
                        final color =
                            _statusColors[status] ?? Colors.grey;
                        final start = DateTime.fromMillisecondsSinceEpoch(
                            leave['start_date'] as int);
                        final end = DateTime.fromMillisecondsSinceEpoch(
                            leave['end_date'] as int);
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor:
                                  color.withValues(alpha: 0.12),
                              child: Icon(Icons.beach_access_outlined,
                                  size: 18, color: color),
                            ),
                            title: Text(
                              '${leave['employee_name'] ?? 'Employé'} — ${leave['type']}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600),
                            ),
                            subtitle: Text(
                              '${MoroccoFormat.date(start)} → ${MoroccoFormat.date(end)}'
                              ' · ${leave['days']} jour(s)'
                              '${leave['reason'] != null && leave['reason'].toString().isNotEmpty ? '\n${leave['reason']}' : ''}',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: theme.colorScheme
                                      .onSurfaceVariant),
                            ),
                            isThreeLine: leave['reason'] != null &&
                                leave['reason'].toString().isNotEmpty,
                            trailing: PopupMenuButton<String>(
                              icon: const Icon(Icons.more_vert,
                                  size: 18),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color:
                                      color.withValues(alpha: 0.12),
                                  borderRadius:
                                      BorderRadius.circular(12),
                                ),
                                child: Text(status,
                                    style: TextStyle(
                                        fontSize: 11,
                                        color: color,
                                        fontWeight: FontWeight.w600)),
                              ),
                              itemBuilder: (_) => _statuses
                                  .map((s) => PopupMenuItem(
                                      value: s, child: Text(s)))
                                  .toList(),
                              onSelected: (s) async {
                                await ref
                                    .read(employeeRepoProvider)
                                    .updateLeaveStatus(
                                        leave['id'] as int, s);
                                await _loadLeaves();
                              },
                            ),
                          ),
                        );
                      },
                    ),
        ),
      ]),
    );
  }

  void _showAddDialog(BuildContext context) {
    final employeesAsync = ref.read(employeeProvider);
    employeesAsync.whenData((employees) {
      if (employees.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Aucun employé enregistré')));
        return;
      }

      int? selectedEmpId = employees.first.id;
      String selectedType = _types.first;
      DateTime startDate = DateTime.now();
      final leaveDays = int.tryParse(
          ref.read(settingsProvider).valueOrNull?['default_leave_days'] ?? '5') ?? 5;
      DateTime endDate   = DateTime.now().add(Duration(days: leaveDays));
      final reasonCtrl = TextEditingController();
      final formKey = GlobalKey<FormState>();

      showDialog(
        context: context,
        builder: (ctx) => StatefulBuilder(
          builder: (ctx, setState) => AlertDialog(
            title: const Text('Demande de congé'),
            content: SizedBox(
              width: 420,
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                    DropdownButtonFormField<int>(
                      value: selectedEmpId,
                      decoration: const InputDecoration(
                          labelText: 'Employé *'),
                      items: employees
                          .map((e) => DropdownMenuItem(
                              value: e.id,
                              child: Text(e.name)))
                          .toList(),
                      onChanged: (v) =>
                          setState(() => selectedEmpId = v),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: selectedType,
                      decoration: const InputDecoration(
                          labelText: 'Type *'),
                      items: _types
                          .map((t) => DropdownMenuItem(
                              value: t, child: Text(t)))
                          .toList(),
                      onChanged: (v) =>
                          setState(() => selectedType = v!),
                    ),
                    const SizedBox(height: 10),
                    Row(children: [
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final d = await showDatePicker(
                              context: ctx,
                              initialDate: startDate,
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2030),
                            );
                            if (d != null) {
                              setState(() => startDate = d);
                            }
                          },
                          child: InputDecorator(
                            decoration: const InputDecoration(
                                labelText: 'Début',
                                suffixIcon: Icon(
                                    Icons.calendar_today_outlined,
                                    size: 16)),
                            child: Text(MoroccoFormat.date(startDate),
                                style: const TextStyle(fontSize: 14)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final d = await showDatePicker(
                              context: ctx,
                              initialDate: endDate,
                              firstDate: startDate,
                              lastDate: DateTime(2030),
                            );
                            if (d != null) {
                              setState(() => endDate = d);
                            }
                          },
                          child: InputDecorator(
                            decoration: const InputDecoration(
                                labelText: 'Fin',
                                suffixIcon: Icon(
                                    Icons.calendar_today_outlined,
                                    size: 16)),
                            child: Text(MoroccoFormat.date(endDate),
                                style: const TextStyle(fontSize: 14)),
                          ),
                        ),
                      ),
                    ]),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: reasonCtrl,
                      decoration: const InputDecoration(
                          labelText: 'Motif (optionnel)'),
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
                  final days = endDate.difference(startDate).inDays + 1;
                  await ref.read(employeeRepoProvider).insertLeave({
                    'employee_id': selectedEmpId!,
                    'type': selectedType,
                    'start_date':
                        startDate.millisecondsSinceEpoch,
                    'end_date': endDate.millisecondsSinceEpoch,
                    'days': days.toDouble(),
                    'status': 'En attente',
                    'reason': reasonCtrl.text.trim().isEmpty
                        ? null
                        : reasonCtrl.text.trim(),
                  });
                  if (ctx.mounted) Navigator.of(ctx).pop();
                  await _loadLeaves();
                },
                child: const Text('Soumettre'),
              ),
            ],
          ),
        ),
      );
    });
  }
}
