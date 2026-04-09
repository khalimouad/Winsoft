import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/app_lists.dart';
import '../../core/models/client.dart';
import '../../core/providers/providers.dart';
import '../../core/utils/morocco_format.dart';

class ClientsPage extends ConsumerStatefulWidget {
  const ClientsPage({super.key});
  @override
  ConsumerState<ClientsPage> createState() => _ClientsPageState();
}

class _ClientsPageState extends ConsumerState<ClientsPage> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final clientsAsync = ref.watch(clientProvider);
    final companiesAsync = ref.watch(companyProvider);

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
                    Text('Clients',
                        style: theme.textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    clientsAsync.whenOrNull(
                            data: (list) => Text('${list.length} clients',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme
                                        .onSurfaceVariant))) ??
                        const SizedBox.shrink(),
                  ],
                ),
                FilledButton.icon(
                  onPressed: () => _showDialog(context, companiesAsync.value ?? [],
                      ref.read(appListsProvider).valueOrNull ?? AppLists.defaults),
                  icon: const Icon(Icons.person_add_outlined, size: 18),
                  label: const Text('Nouveau client'),
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
              child: clientsAsync.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Erreur: $e')),
                data: (clients) {
                  final filtered = clients
                      .where((c) =>
                          c.name
                              .toLowerCase()
                              .contains(_search.toLowerCase()) ||
                          (c.companyName ?? '')
                              .toLowerCase()
                              .contains(_search.toLowerCase()) ||
                          (c.email ?? '')
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
                          DataColumn(label: Text('NOM')),
                          DataColumn(label: Text('ENTREPRISE')),
                          DataColumn(label: Text('EMAIL')),
                          DataColumn(label: Text('TÉLÉPHONE')),
                          DataColumn(label: Text('VILLE')),
                          DataColumn(label: Text('CIN / ICE')),
                          DataColumn(label: Text('ACTIONS')),
                        ],
                        rows: filtered
                            .map((c) => DataRow(cells: [
                                  DataCell(Row(children: [
                                    CircleAvatar(
                                      radius: 16,
                                      backgroundColor: theme
                                          .colorScheme.tertiaryContainer,
                                      child: Text(c.name[0],
                                          style: TextStyle(
                                              color: theme.colorScheme
                                                  .onTertiaryContainer,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12)),
                                    ),
                                    const SizedBox(width: 10),
                                    Text(c.name,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w500)),
                                  ])),
                                  DataCell(Text(c.companyName ?? '—')),
                                  DataCell(Text(c.email ?? '—')),
                                  DataCell(Text(c.phone != null
                                      ? MoroccoFormat.phone(c.phone!)
                                      : '—')),
                                  DataCell(Text(c.city ?? '—')),
                                  DataCell(Text(c.cin ?? c.ice ?? '—',
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: theme.colorScheme
                                              .onSurfaceVariant))),
                                  DataCell(Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(
                                            Icons.edit_outlined,
                                            size: 18),
                                        onPressed: () => _showDialog(
                                            context,
                                            companiesAsync.value ?? [],
                                            ref.read(appListsProvider).valueOrNull ?? AppLists.defaults,
                                            client: c),
                                        visualDensity:
                                            VisualDensity.compact,
                                      ),
                                      IconButton(
                                        icon: Icon(
                                            Icons.delete_outline,
                                            size: 18,
                                            color:
                                                theme.colorScheme.error),
                                        onPressed: () =>
                                            _confirmDelete(context, c),
                                        visualDensity:
                                            VisualDensity.compact,
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

  void _confirmDelete(BuildContext context, Client c) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer le client'),
        content: Text('Supprimer "${c.name}" ?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Annuler')),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error),
            onPressed: () {
              ref.read(clientProvider.notifier).remove(c.id!);
              Navigator.of(ctx).pop();
            },
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  void _showDialog(BuildContext context, List companies, AppLists lists,
      {Client? client}) {
    final nameCtrl    = TextEditingController(text: client?.name ?? '');
    final emailCtrl   = TextEditingController(text: client?.email ?? '');
    final phoneCtrl   = TextEditingController(text: client?.phone ?? '');
    final addressCtrl = TextEditingController(text: client?.address ?? '');
    final notesCtrl   = TextEditingController(text: client?.notes ?? '');
    // Moroccan identity
    final cinCtrl     = TextEditingController(text: client?.cin ?? '');
    final iceCtrl     = TextEditingController(text: client?.ice ?? '');
    final rcCtrl      = TextEditingController(text: client?.rc ?? '');
    final ifCtrl      = TextEditingController(text: client?.ifNumber ?? '');
    final patenteCtrl = TextEditingController(text: client?.patente ?? '');
    final cnssCtrl    = TextEditingController(text: client?.cnssNum ?? '');
    final ribCtrl     = TextEditingController(text: client?.rib ?? '');
    String selectedCity = client?.city ??
        (lists.cities.isNotEmpty ? lists.cities.first : MoroccoFormat.cities.first);
    int? selectedCompanyId = client?.companyId;
    String? selectedForme = client?.formeJuridique;

    final formes = ['—', ...lists.formesJuridiques];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: Text(client == null ? 'Nouveau client' : 'Modifier client'),
          content: SizedBox(
            width: 520,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Informations générales ──────────────────────────────
                  _sectionLabel(ctx, 'Informations générales'),
                  _field(nameCtrl, 'Nom complet *'),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int?>(
                    value: selectedCompanyId,
                    decoration: const InputDecoration(labelText: 'Entreprise liée'),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('— Aucune —')),
                      ...companies.map((co) => DropdownMenuItem(
                          value: co.id, child: Text(co.name))),
                    ],
                    onChanged: (v) => setS(() => selectedCompanyId = v),
                  ),
                  const SizedBox(height: 12),
                  _field(emailCtrl, 'Email'),
                  const SizedBox(height: 12),
                  _field(phoneCtrl, 'Téléphone'),
                  const SizedBox(height: 12),
                  _field(addressCtrl, 'Adresse'),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: selectedCity,
                    decoration: const InputDecoration(labelText: 'Ville'),
                    items: lists.cities
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (v) => setS(() => selectedCity = v!),
                  ),
                  const SizedBox(height: 20),

                  // ── Identité & Statut juridique ─────────────────────────
                  _sectionLabel(ctx, 'Identité & Statut juridique'),
                  DropdownButtonFormField<String?>(
                    value: selectedForme,
                    decoration: const InputDecoration(labelText: 'Forme juridique'),
                    items: formes
                        .map((f) => DropdownMenuItem(
                            value: f == '—' ? null : f,
                            child: Text(f)))
                        .toList(),
                    onChanged: (v) => setS(() => selectedForme = v),
                  ),
                  const SizedBox(height: 12),
                  _field(cinCtrl, 'CIN (Carte d\'Identité Nationale)'),
                  const SizedBox(height: 20),

                  // ── Identifiants fiscaux marocains ──────────────────────
                  _sectionLabel(ctx, 'Identifiants fiscaux'),
                  _field(iceCtrl, 'ICE (15 chiffres)'),
                  const SizedBox(height: 12),
                  _field(rcCtrl, 'RC (Registre de Commerce)'),
                  const SizedBox(height: 12),
                  _field(ifCtrl, 'IF (Identifiant Fiscal)'),
                  const SizedBox(height: 12),
                  _field(patenteCtrl, 'Patente'),
                  const SizedBox(height: 12),
                  _field(cnssCtrl, 'N° CNSS'),
                  const SizedBox(height: 20),

                  // ── Coordonnées bancaires ───────────────────────────────
                  _sectionLabel(ctx, 'Coordonnées bancaires'),
                  _field(ribCtrl, 'RIB / IBAN'),
                  const SizedBox(height: 20),

                  // ── Notes ───────────────────────────────────────────────
                  _sectionLabel(ctx, 'Notes'),
                  _field(notesCtrl, 'Notes internes', maxLines: 3),
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
                final c = Client(
                  id: client?.id,
                  name: nameCtrl.text.trim(),
                  companyId: selectedCompanyId,
                  email: _nullIfEmpty(emailCtrl.text),
                  phone: _nullIfEmpty(phoneCtrl.text),
                  address: _nullIfEmpty(addressCtrl.text),
                  city: selectedCity,
                  cin: _nullIfEmpty(cinCtrl.text),
                  ice: _nullIfEmpty(iceCtrl.text),
                  rc: _nullIfEmpty(rcCtrl.text),
                  ifNumber: _nullIfEmpty(ifCtrl.text),
                  patente: _nullIfEmpty(patenteCtrl.text),
                  cnssNum: _nullIfEmpty(cnssCtrl.text),
                  rib: _nullIfEmpty(ribCtrl.text),
                  formeJuridique: selectedForme,
                  notes: _nullIfEmpty(notesCtrl.text),
                  createdAt: client?.createdAt ?? now,
                );
                if (client == null) {
                  ref.read(clientProvider.notifier).add(c);
                } else {
                  ref.read(clientProvider.notifier).edit(c);
                }
                Navigator.of(ctx).pop();
              },
              child: Text(client == null ? 'Ajouter' : 'Enregistrer'),
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

  Widget _field(TextEditingController ctrl, String label, {int maxLines = 1}) =>
      TextField(
        controller: ctrl,
        maxLines: maxLines,
        decoration: InputDecoration(labelText: label),
      );
}
