import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/app_lists.dart';
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
    final lists = ref.watch(appListsProvider).valueOrNull ?? AppLists.defaults;

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
                  onPressed: () => _showDialog(context,
                      lists: ref.read(appListsProvider).valueOrNull ?? AppLists.defaults),
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
                          DataColumn(label: Text('FORME')),
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
                                  DataCell(Text(c.formeJuridique ?? '—',
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: theme.colorScheme.onSurfaceVariant))),
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
                                            _showDialog(context, company: c, lists: lists),
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

  void _showDialog(BuildContext context, {Company? company, AppLists? lists}) {
    lists ??= AppLists.defaults;
    final nameCtrl         = TextEditingController(text: company?.name ?? '');
    final industryCtrl     = TextEditingController(text: company?.industry ?? '');
    final emailCtrl        = TextEditingController(text: company?.email ?? '');
    final phoneCtrl        = TextEditingController(text: company?.phone ?? '');
    final faxCtrl          = TextEditingController(text: company?.fax ?? '');
    final websiteCtrl      = TextEditingController(text: company?.website ?? '');
    final addressCtrl      = TextEditingController(text: company?.address ?? '');
    // Fiscal
    final iceCtrl          = TextEditingController(text: company?.ice ?? '');
    final rcCtrl           = TextEditingController(text: company?.rc ?? '');
    final ifCtrl           = TextEditingController(text: company?.ifNumber ?? '');
    final patenteCtrl      = TextEditingController(text: company?.patente ?? '');
    final cnssCtrl         = TextEditingController(text: company?.cnss ?? '');
    final cnssEmpCtrl      = TextEditingController(text: company?.cnssEmployeur ?? '');
    final tvaCtrl          = TextEditingController(text: company?.numeroTVA ?? '');
    final ribCtrl          = TextEditingController(text: company?.rib ?? '');
    final capitalCtrl      = TextEditingController(
        text: company?.capitalSocial?.toString() ?? '');
    String selectedCity    = company?.city ??
        (lists!.cities.isNotEmpty ? lists.cities.first : MoroccoFormat.cities.first);
    String? selectedForme  = company?.formeJuridique;
    String selectedStatus  = company?.status ??
        (lists.companyStatuses.isNotEmpty ? lists.companyStatuses.first : 'Active');

    final formes  = ['—', ...lists.formesJuridiques];
    final statuts = lists.companyStatuses;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: Text(company == null ? 'Nouvelle entreprise' : 'Modifier entreprise'),
          content: SizedBox(
            width: 540,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Informations générales ──────────────────────────────
                  _sectionLabel(ctx, 'Informations générales'),
                  _field(nameCtrl, 'Raison Sociale *'),
                  const SizedBox(height: 12),
                  _field(industryCtrl, 'Secteur d\'activité'),
                  const SizedBox(height: 12),
                  _field(emailCtrl, 'Email'),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(child: _field(phoneCtrl, 'Téléphone')),
                    const SizedBox(width: 12),
                    Expanded(child: _field(faxCtrl, 'Fax')),
                  ]),
                  const SizedBox(height: 12),
                  _field(websiteCtrl, 'Site web'),
                  const SizedBox(height: 12),
                  _field(addressCtrl, 'Adresse'),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: selectedCity,
                        decoration: const InputDecoration(labelText: 'Ville'),
                        items: lists!.cities
                            .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                            .toList(),
                        onChanged: (v) => setS(() => selectedCity = v!),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: selectedStatus,
                        decoration: const InputDecoration(labelText: 'Statut'),
                        items: statuts
                            .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                            .toList(),
                        onChanged: (v) => setS(() => selectedStatus = v!),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 20),

                  // ── Statut juridique ────────────────────────────────────
                  _sectionLabel(ctx, 'Statut juridique'),
                  Row(children: [
                    Expanded(
                      child: DropdownButtonFormField<String?>(
                        value: selectedForme,
                        decoration: const InputDecoration(labelText: 'Forme juridique'),
                        items: formes
                            .map((f) => DropdownMenuItem(
                                value: f == '—' ? null : f,
                                child: Text(f)))
                            .toList(),
                        onChanged: (v) => setS(() => selectedForme = v),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: _field(capitalCtrl, 'Capital social (MAD)')),
                  ]),
                  const SizedBox(height: 20),

                  // ── Identifiants fiscaux ────────────────────────────────
                  _sectionLabel(ctx, 'Identifiants fiscaux'),
                  Row(children: [
                    Expanded(child: _field(iceCtrl, 'ICE (15 chiffres)')),
                    const SizedBox(width: 12),
                    Expanded(child: _field(rcCtrl, 'RC (Registre de Commerce)')),
                  ]),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(child: _field(ifCtrl, 'IF (Identifiant Fiscal)')),
                    const SizedBox(width: 12),
                    Expanded(child: _field(patenteCtrl, 'Patente')),
                  ]),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(child: _field(cnssCtrl, 'N° CNSS Salarié')),
                    const SizedBox(width: 12),
                    Expanded(child: _field(cnssEmpCtrl, 'N° CNSS Employeur')),
                  ]),
                  const SizedBox(height: 12),
                  _field(tvaCtrl, 'Numéro de TVA'),
                  const SizedBox(height: 20),

                  // ── Coordonnées bancaires ───────────────────────────────
                  _sectionLabel(ctx, 'Coordonnées bancaires'),
                  _field(ribCtrl, 'RIB / IBAN'),
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
                final now = DateTime.now().millisecondsSinceEpoch;
                final c = Company(
                  id: company?.id,
                  name: nameCtrl.text.trim(),
                  industry: _nullIfEmpty(industryCtrl.text),
                  email: _nullIfEmpty(emailCtrl.text),
                  phone: _nullIfEmpty(phoneCtrl.text),
                  fax: _nullIfEmpty(faxCtrl.text),
                  website: _nullIfEmpty(websiteCtrl.text),
                  address: _nullIfEmpty(addressCtrl.text),
                  city: selectedCity,
                  ice: _nullIfEmpty(iceCtrl.text),
                  rc: _nullIfEmpty(rcCtrl.text),
                  ifNumber: _nullIfEmpty(ifCtrl.text),
                  patente: _nullIfEmpty(patenteCtrl.text),
                  cnss: _nullIfEmpty(cnssCtrl.text),
                  cnssEmployeur: _nullIfEmpty(cnssEmpCtrl.text),
                  numeroTVA: _nullIfEmpty(tvaCtrl.text),
                  rib: _nullIfEmpty(ribCtrl.text),
                  formeJuridique: selectedForme,
                  capitalSocial: double.tryParse(capitalCtrl.text.trim()),
                  status: selectedStatus,
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

  String? _nullIfEmpty(String v) => v.trim().isEmpty ? null : v.trim();

  Widget _sectionLabel(BuildContext ctx, String label) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(label,
            style: Theme.of(ctx).textTheme.labelLarge?.copyWith(
                color: Theme.of(ctx).colorScheme.primary,
                fontWeight: FontWeight.w700)),
      );

  Widget _field(TextEditingController ctrl, String label,
          {int maxLines = 1}) =>
      TextField(
        controller: ctrl,
        maxLines: maxLines,
        decoration: InputDecoration(labelText: label),
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
