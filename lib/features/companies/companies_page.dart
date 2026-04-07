import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/company.dart';
import '../../core/providers/providers.dart';
import '../../core/utils/morocco_format.dart';

class CompaniesPage extends ConsumerStatefulWidget {
  const CompaniesPage({super.key});
  @override
  ConsumerState<CompaniesPage> createState() => _CompaniesPageState();
}

class _CompaniesPageState extends ConsumerState<CompaniesPage> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final async = ref.watch(companyProvider);

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
                    Text('Entreprises',
                        style: theme.textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    async.whenOrNull(
                            data: (list) => Text('${list.length} entreprises',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                    color:
                                        theme.colorScheme.onSurfaceVariant))) ??
                        const SizedBox.shrink(),
                  ],
                ),
                FilledButton.icon(
                  onPressed: () => _showDialog(context),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Nouvelle entreprise'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: 360,
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Rechercher...',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  isDense: true,
                  filled: true,
                  fillColor: theme.colorScheme.surface,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                          color: theme.colorScheme.outlineVariant)),
                ),
                onChanged: (v) => setState(() => _search = v),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: async.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, _) =>
                    Center(child: Text('Erreur: $e')),
                data: (companies) {
                  final filtered = companies
                      .where((c) =>
                          c.name.toLowerCase().contains(_search.toLowerCase()) ||
                          (c.industry ?? '')
                              .toLowerCase()
                              .contains(_search.toLowerCase()) ||
                          (c.city ?? '')
                              .toLowerCase()
                              .contains(_search.toLowerCase()))
                      .toList();
                  return Card(
                    child: SingleChildScrollView(
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
                          DataColumn(label: Text('ENTREPRISE')),
                          DataColumn(label: Text('SECTEUR')),
                          DataColumn(label: Text('VILLE')),
                          DataColumn(label: Text('ICE')),
                          DataColumn(label: Text('TÉLÉPHONE')),
                          DataColumn(label: Text('STATUT')),
                          DataColumn(label: Text('ACTIONS')),
                        ],
                        rows: filtered
                            .map((c) => DataRow(cells: [
                                  DataCell(Row(children: [
                                    CircleAvatar(
                                      radius: 16,
                                      backgroundColor:
                                          theme.colorScheme.primaryContainer,
                                      child: Text(c.name[0],
                                          style: TextStyle(
                                              color: theme.colorScheme
                                                  .onPrimaryContainer,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12)),
                                    ),
                                    const SizedBox(width: 10),
                                    Text(c.name,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w500)),
                                  ])),
                                  DataCell(Text(c.industry ?? '—')),
                                  DataCell(Text(c.city ?? '—')),
                                  DataCell(Text(c.ice ?? '—',
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: theme.colorScheme
                                              .onSurfaceVariant))),
                                  DataCell(Text(c.phone != null
                                      ? MoroccoFormat.phone(c.phone!)
                                      : '—')),
                                  DataCell(_StatusBadge(status: c.status)),
                                  DataCell(Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit_outlined,
                                            size: 18),
                                        onPressed: () =>
                                            _showDialog(context, company: c),
                                        visualDensity: VisualDensity.compact,
                                      ),
                                      IconButton(
                                        icon: Icon(Icons.delete_outline,
                                            size: 18,
                                            color: theme.colorScheme.error),
                                        onPressed: () =>
                                            _confirmDelete(context, c),
                                        visualDensity: VisualDensity.compact,
                                      ),
                                    ],
                                  )),
                                ]))
                            .toList(),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, Company c) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer l\'entreprise'),
        content: Text('Supprimer "${c.name}" ?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Annuler')),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error),
            onPressed: () {
              ref.read(companyProvider.notifier).remove(c.id!);
              Navigator.of(ctx).pop();
            },
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  void _showDialog(BuildContext context, {Company? company}) {
    final nameCtrl =
        TextEditingController(text: company?.name ?? '');
    final industryCtrl =
        TextEditingController(text: company?.industry ?? '');
    final emailCtrl =
        TextEditingController(text: company?.email ?? '');
    final phoneCtrl =
        TextEditingController(text: company?.phone ?? '');
    final addressCtrl =
        TextEditingController(text: company?.address ?? '');
    final iceCtrl = TextEditingController(text: company?.ice ?? '');
    final rcCtrl = TextEditingController(text: company?.rc ?? '');
    final ifCtrl =
        TextEditingController(text: company?.ifNumber ?? '');
    String selectedCity = company?.city ?? MoroccoFormat.cities.first;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title:
              Text(company == null ? 'Nouvelle entreprise' : 'Modifier'),
          content: SizedBox(
            width: 500,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _field(nameCtrl, 'Raison Sociale *'),
                  _field(industryCtrl, 'Secteur d\'activité'),
                  _field(emailCtrl, 'Email'),
                  _field(phoneCtrl, 'Téléphone (ex: 0522334455)'),
                  _field(addressCtrl, 'Adresse'),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: selectedCity,
                    decoration:
                        const InputDecoration(labelText: 'Ville'),
                    items: MoroccoFormat.cities
                        .map((c) => DropdownMenuItem(
                            value: c, child: Text(c)))
                        .toList(),
                    onChanged: (v) =>
                        setState(() => selectedCity = v!),
                  ),
                  const SizedBox(height: 16),
                  Text('Informations fiscales',
                      style: Theme.of(context)
                          .textTheme
                          .labelLarge
                          ?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .primary)),
                  const SizedBox(height: 8),
                  _field(iceCtrl, 'ICE (15 chiffres)'),
                  _field(rcCtrl, 'RC (Registre de Commerce)'),
                  _field(ifCtrl, 'IF (Identifiant Fiscal)'),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Annuler')),
            FilledButton(
              onPressed: () {
                if (nameCtrl.text.trim().isEmpty) return;
                final now =
                    DateTime.now().millisecondsSinceEpoch;
                final c = Company(
                  id: company?.id,
                  name: nameCtrl.text.trim(),
                  industry: industryCtrl.text.trim().isEmpty
                      ? null
                      : industryCtrl.text.trim(),
                  email: emailCtrl.text.trim().isEmpty
                      ? null
                      : emailCtrl.text.trim(),
                  phone: phoneCtrl.text.trim().isEmpty
                      ? null
                      : phoneCtrl.text.trim(),
                  address: addressCtrl.text.trim().isEmpty
                      ? null
                      : addressCtrl.text.trim(),
                  city: selectedCity,
                  ice: iceCtrl.text.trim().isEmpty
                      ? null
                      : iceCtrl.text.trim(),
                  rc: rcCtrl.text.trim().isEmpty
                      ? null
                      : rcCtrl.text.trim(),
                  ifNumber: ifCtrl.text.trim().isEmpty
                      ? null
                      : ifCtrl.text.trim(),
                  createdAt: company?.createdAt ?? now,
                );
                if (company == null) {
                  ref.read(companyProvider.notifier).add(c);
                } else {
                  ref.read(companyProvider.notifier).edit(c);
                }
                Navigator.of(ctx).pop();
              },
              child: Text(company == null ? 'Ajouter' : 'Enregistrer'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String label,
      {int maxLines = 1}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextField(
          controller: ctrl,
          maxLines: maxLines,
          decoration: InputDecoration(labelText: label),
        ),
      );
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});
  final String status;
  @override
  Widget build(BuildContext context) {
    final isActive = status == 'Active';
    final color =
        isActive ? Colors.green.shade700 : Colors.grey.shade600;
    final bg = isActive
        ? Colors.green.withValues(alpha: 0.1)
        : Colors.grey.withValues(alpha: 0.1);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(status,
          style: TextStyle(
              color: color, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}
