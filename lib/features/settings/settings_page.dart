import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/app.dart';
import '../../core/database/database_helper.dart';
import '../../core/models/app_lists.dart';
import '../../core/providers/providers.dart';
import '../../core/providers/language_provider.dart';
import '../../core/services/backup_service.dart';
import '../../core/utils/morocco_format.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});
  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  final _nameCtrl    = TextEditingController();
  final _emailCtrl   = TextEditingController();
  final _phoneCtrl   = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _iceCtrl     = TextEditingController();
  final _rcCtrl      = TextEditingController();
  final _ifCtrl      = TextEditingController();
  final _prefixCtrl  = TextEditingController();
  final _poPrefix    = TextEditingController();
  final _cnPrefix    = TextEditingController();
  final _termsCtrl   = TextEditingController();
  final _notesCtrl   = TextEditingController();
  String _selectedCity = MoroccoFormat.cities.first;
  double _tvaDefault = 20.0;
  bool _loaded = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _iceCtrl.dispose();
    _rcCtrl.dispose();
    _ifCtrl.dispose();
    _prefixCtrl.dispose();
    _poPrefix.dispose();
    _cnPrefix.dispose();
    _termsCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeMode = ref.watch(themeModeProvider);
    final settingsAsync = ref.watch(settingsProvider);
    final listsAsync = ref.watch(appListsProvider);
    final lists = listsAsync.valueOrNull ?? AppLists.defaults;

    return settingsAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Erreur: $e'))),
      data: (settings) {
        if (!_loaded) {
          _nameCtrl.text    = settings['company_name'] ?? '';
          _emailCtrl.text   = settings['company_email'] ?? '';
          _phoneCtrl.text   = settings['company_phone'] ?? '';
          _addressCtrl.text = settings['company_address'] ?? '';
          _iceCtrl.text     = settings['company_ice'] ?? '';
          _rcCtrl.text      = settings['company_rc'] ?? '';
          _ifCtrl.text      = settings['company_if'] ?? '';
          _prefixCtrl.text  = settings['invoice_prefix'] ?? 'FAC';
          _poPrefix.text    = settings['po_prefix'] ?? 'BA';
          _cnPrefix.text    = settings['cn_prefix'] ?? 'AV';
          _termsCtrl.text   = settings['invoice_terms'] ?? '30 jours net';
          _notesCtrl.text   = settings['invoice_notes'] ?? '';
          final city = settings['company_city'] ?? MoroccoFormat.cities.first;
          _selectedCity = MoroccoFormat.cities.contains(city)
              ? city
              : MoroccoFormat.cities.first;
          _tvaDefault = double.tryParse(settings['tva_default'] ?? '20') ?? 20;
          _loaded = true;
        }

        return Scaffold(
          backgroundColor: theme.colorScheme.surfaceContainerLowest,
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Paramètres',
                    style: theme.textTheme.headlineSmall
                        ?.copyWith(fontWeight: FontWeight.bold)),
                Text('Configurez votre application et votre profil entreprise.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant)),
                const SizedBox(height: 24),

                // ── Company Profile ──────────────────────────────────────────
                _Section(
                  title: 'Profil Entreprise',
                  icon: Icons.business_outlined,
                  children: [
                    _field(_nameCtrl, 'Raison Sociale'),
                    _field(_emailCtrl, 'Email'),
                    _field(_phoneCtrl, 'Téléphone'),
                    _field(_addressCtrl, 'Adresse'),
                    const SizedBox(height: 8),
                    StatefulBuilder(
                      builder: (ctx, ss) => DropdownButtonFormField<String>(
                        value: lists.cities.contains(_selectedCity)
                            ? _selectedCity
                            : lists.cities.first,
                        decoration: const InputDecoration(labelText: 'Ville'),
                        items: lists.cities
                            .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                            .toList(),
                        onChanged: (v) => ss(() => _selectedCity = v!),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text('Informations fiscales',
                        style: theme.textTheme.labelLarge
                            ?.copyWith(color: theme.colorScheme.primary)),
                    const SizedBox(height: 8),
                    _field(_iceCtrl, 'ICE (15 chiffres)'),
                    _field(_rcCtrl, 'RC'),
                    _field(_ifCtrl, 'IF (Identifiant Fiscal)'),
                    const SizedBox(height: 8),
                    FilledButton(
                      onPressed: _saveCompanyProfile,
                      child: const Text('Enregistrer le profil'),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // ── Invoice settings ─────────────────────────────────────────
                _Section(
                  title: 'Paramètres de facturation',
                  icon: Icons.receipt_long_outlined,
                  children: [
                    Row(children: [
                      Expanded(child: _field(_prefixCtrl, 'Préfixe facture (ex: FAC)')),
                      const SizedBox(width: 12),
                      Expanded(child: _field(_poPrefix, 'Préfixe bon de commande (ex: BA)')),
                      const SizedBox(width: 12),
                      Expanded(child: _field(_cnPrefix, 'Préfixe avoir (ex: AV)')),
                    ]),
                    _field(_termsCtrl, 'Conditions de paiement'),
                    StatefulBuilder(
                      builder: (ctx, ss) => DropdownButtonFormField<double>(
                        value: lists.tvaRates.contains(_tvaDefault)
                            ? _tvaDefault
                            : lists.tvaRates.last,
                        decoration:
                            const InputDecoration(labelText: 'TVA par défaut'),
                        items: lists.tvaRates
                            .map((r) => DropdownMenuItem(
                                value: r,
                                child: Text(MoroccoFormat.tvaLabel(r))))
                            .toList(),
                        onChanged: (v) => ss(() => _tvaDefault = v!),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _field(_notesCtrl, 'Note de bas de facture', maxLines: 3),
                    const SizedBox(height: 8),
                    FilledButton(
                      onPressed: _saveInvoiceSettings,
                      child: const Text('Enregistrer'),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // ── Configurable Lists ───────────────────────────────────────
                _Section(
                  title: 'Listes personnalisables',
                  icon: Icons.list_alt_outlined,
                  children: [
                    Text(
                      'Personnalisez les options disponibles dans tous les formulaires de l\'application.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 20),
                    _ListEditor(
                      title: 'Villes',
                      icon: Icons.location_city_outlined,
                      settingsKey: AppLists.kCities,
                      items: lists.cities,
                    ),
                    const SizedBox(height: 16),
                    _ListEditor(
                      title: 'Taux de TVA (%)',
                      icon: Icons.percent_outlined,
                      settingsKey: AppLists.kTvaRates,
                      items: lists.tvaRates.map((r) => r.toInt() == r ? r.toInt().toString() : r.toString()).toList(),
                      isNumeric: true,
                    ),
                    const SizedBox(height: 16),
                    _ListEditor(
                      title: 'Formes juridiques',
                      icon: Icons.gavel_outlined,
                      settingsKey: AppLists.kFormesJuridiques,
                      items: lists.formesJuridiques,
                    ),
                    const SizedBox(height: 16),
                    _ListEditor(
                      title: 'Modes de paiement',
                      icon: Icons.payment_outlined,
                      settingsKey: AppLists.kPaymentMethods,
                      items: lists.paymentMethods,
                    ),
                    const SizedBox(height: 16),
                    _ListEditor(
                      title: 'Types de congés',
                      icon: Icons.beach_access_outlined,
                      settingsKey: AppLists.kLeaveTypes,
                      items: lists.leaveTypes,
                    ),
                    const SizedBox(height: 16),
                    _ListEditor(
                      title: 'Catégories de produits',
                      icon: Icons.category_outlined,
                      settingsKey: AppLists.kProductCategories,
                      items: lists.productCategories,
                    ),
                    const SizedBox(height: 16),
                    _ListEditor(
                      title: 'Unités de mesure',
                      icon: Icons.straighten_outlined,
                      settingsKey: AppLists.kProductUnits,
                      items: lists.productUnits,
                    ),
                    const SizedBox(height: 16),
                    _ListEditor(
                      title: 'Statuts entreprises',
                      icon: Icons.business_center_outlined,
                      settingsKey: AppLists.kCompanyStatuses,
                      items: lists.companyStatuses,
                    ),
                    const SizedBox(height: 16),
                    _ListEditor(
                      title: 'Départements employés',
                      icon: Icons.people_outlined,
                      settingsKey: AppLists.kEmployeeDepartments,
                      items: lists.employeeDepartments,
                    ),
                    const SizedBox(height: 16),
                    _JournalEditor(journals: lists.journals),
                  ],
                ),
                const SizedBox(height: 20),

                // ── Appearance & Language ────────────────────────────────────
                _Section(
                  title: 'Apparence & Langue',
                  icon: Icons.palette_outlined,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          Text('Mode sombre',
                              style: theme.textTheme.bodyLarge
                                  ?.copyWith(fontWeight: FontWeight.w500)),
                          Text('Changer le thème de l\'interface',
                              style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant)),
                        ]),
                        Switch(
                          value: themeMode == ThemeMode.dark,
                          onChanged: (val) => ref
                              .read(themeModeProvider.notifier)
                              .state = val ? ThemeMode.dark : ThemeMode.light,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Consumer(
                      builder: (ctx, ref, _) {
                        final langAsync = ref.watch(languageProvider);
                        final currentLang =
                            langAsync.maybeWhen(data: (l) => l, orElse: () => 'fr');
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                              Text('Langue / اللغة / Language',
                                  style: theme.textTheme.bodyLarge
                                      ?.copyWith(fontWeight: FontWeight.w500)),
                              Text('Interface en Français, العربية ou English',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                      color:
                                          theme.colorScheme.onSurfaceVariant)),
                            ]),
                            SegmentedButton<String>(
                              segments: const [
                                ButtonSegment(value: 'fr', label: Text('FR')),
                                ButtonSegment(value: 'ar', label: Text('ع')),
                                ButtonSegment(value: 'en', label: Text('EN')),
                              ],
                              selected: {currentLang},
                              onSelectionChanged: (sel) => ref
                                  .read(languageProvider.notifier)
                                  .setLanguage(sel.first),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // ── Backup & Restore ─────────────────────────────────────────
                _BackupSection(),
                const SizedBox(height: 20),

                // ── About ────────────────────────────────────────────────────
                _Section(
                  title: 'À propos',
                  icon: Icons.info_outlined,
                  children: [
                    _InfoRow(label: 'Version', value: '1.0.0'),
                    _InfoRow(label: 'Framework', value: 'Flutter 3.32'),
                    _InfoRow(label: 'Plateformes', value: 'Windows · Android · iOS · Web'),
                    _InfoRow(label: 'Base de données', value: 'SQLite (local)'),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _saveCompanyProfile() async {
    final db = DatabaseHelper.instance;
    await db.setSetting('company_name', _nameCtrl.text.trim());
    await db.setSetting('company_email', _emailCtrl.text.trim());
    await db.setSetting('company_phone', _phoneCtrl.text.trim());
    await db.setSetting('company_address', _addressCtrl.text.trim());
    await db.setSetting('company_city', _selectedCity);
    await db.setSetting('company_ice', _iceCtrl.text.trim());
    await db.setSetting('company_rc', _rcCtrl.text.trim());
    await db.setSetting('company_if', _ifCtrl.text.trim());
    ref.invalidate(settingsProvider);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Profil enregistré'),
          behavior: SnackBarBehavior.floating));
    }
  }

  Future<void> _saveInvoiceSettings() async {
    final db = DatabaseHelper.instance;
    await db.setSetting('invoice_prefix', _prefixCtrl.text.trim().isEmpty ? 'FAC' : _prefixCtrl.text.trim());
    await db.setSetting('po_prefix', _poPrefix.text.trim().isEmpty ? 'BA' : _poPrefix.text.trim());
    await db.setSetting('cn_prefix', _cnPrefix.text.trim().isEmpty ? 'AV' : _cnPrefix.text.trim());
    await db.setSetting('invoice_terms', _termsCtrl.text.trim());
    await db.setSetting('invoice_notes', _notesCtrl.text.trim());
    await db.setSetting('tva_default', _tvaDefault.toString());
    ref.invalidate(settingsProvider);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Paramètres enregistrés'),
          behavior: SnackBarBehavior.floating));
    }
  }

  Widget _field(TextEditingController ctrl, String label, {int maxLines = 1}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: SizedBox(
          width: 480,
          child: TextField(
              controller: ctrl,
              maxLines: maxLines,
              decoration: InputDecoration(labelText: label)),
        ),
      );
}

// ── Reusable List Editor ──────────────────────────────────────────────────────

class _ListEditor extends ConsumerStatefulWidget {
  const _ListEditor({
    required this.title,
    required this.icon,
    required this.settingsKey,
    required this.items,
    this.isNumeric = false,
  });
  final String title;
  final IconData icon;
  final String settingsKey;
  final List<String> items;
  final bool isNumeric;

  @override
  ConsumerState<_ListEditor> createState() => _ListEditorState();
}

class _ListEditorState extends ConsumerState<_ListEditor> {
  late List<String> _items;
  final _addCtrl = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _items = List.from(widget.items);
  }

  @override
  void didUpdateWidget(_ListEditor old) {
    super.didUpdateWidget(old);
    if (old.items != widget.items) {
      _items = List.from(widget.items);
    }
  }

  @override
  void dispose() {
    _addCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final encoded = widget.isNumeric
        ? AppLists.encode(_items
            .map((s) => double.tryParse(s) ?? 0)
            .where((v) => v >= 0)
            .toList())
        : AppLists.encode(_items);
    await DatabaseHelper.instance.setSetting(widget.settingsKey, encoded);
    ref.invalidate(appListsProvider);
    ref.invalidate(settingsProvider);
    if (mounted) setState(() => _saving = false);
  }

  void _add() {
    final v = _addCtrl.text.trim();
    if (v.isEmpty) return;
    if (widget.isNumeric && double.tryParse(v) == null) return;
    if (_items.contains(v)) return;
    setState(() => _items.add(v));
    _addCtrl.clear();
    _save();
  }

  void _remove(String item) {
    setState(() => _items.remove(item));
    _save();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(children: [
          Icon(widget.icon, size: 16, color: theme.colorScheme.primary),
          const SizedBox(width: 6),
          Text(widget.title,
              style: theme.textTheme.labelLarge
                  ?.copyWith(fontWeight: FontWeight.w600)),
          if (_saving) ...[
            const SizedBox(width: 8),
            const SizedBox(
                width: 12, height: 12,
                child: CircularProgressIndicator(strokeWidth: 1.5)),
          ],
        ]),
        const SizedBox(height: 10),

        // Chips
        if (_items.isEmpty)
          Text('Aucun élément', style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant))
        else
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _items.map((item) => Chip(
              label: Text(item, style: const TextStyle(fontSize: 12)),
              deleteIcon: const Icon(Icons.close, size: 14),
              onDeleted: () => _remove(item),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 4),
            )).toList(),
          ),
        const SizedBox(height: 10),

        // Add row
        Row(children: [
          Expanded(
            child: SizedBox(
              height: 40,
              child: TextField(
                controller: _addCtrl,
                keyboardType: widget.isNumeric
                    ? const TextInputType.numberWithOptions(decimal: true)
                    : TextInputType.text,
                decoration: InputDecoration(
                  hintText: widget.isNumeric
                      ? 'Nouveau taux (ex: 5)...'
                      : 'Nouvel élément...',
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                onSubmitted: (_) => _add(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            height: 40,
            child: OutlinedButton.icon(
              onPressed: _add,
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Ajouter'),
              style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 14)),
            ),
          ),
        ]),
        const Divider(height: 24),
      ],
    );
  }
}

// ── Journal Editor ────────────────────────────────────────────────────────────

class _JournalEditor extends ConsumerStatefulWidget {
  const _JournalEditor({required this.journals});
  final List<JournalDef> journals;

  @override
  ConsumerState<_JournalEditor> createState() => _JournalEditorState();
}

class _JournalEditorState extends ConsumerState<_JournalEditor> {
  late List<JournalDef> _journals;
  final _codeCtrl  = TextEditingController();
  final _labelCtrl = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _journals = List.from(widget.journals);
  }

  @override
  void didUpdateWidget(_JournalEditor old) {
    super.didUpdateWidget(old);
    if (old.journals != widget.journals) _journals = List.from(widget.journals);
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    _labelCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    await DatabaseHelper.instance.setSetting(
        AppLists.kJournals, AppLists.encodeJournals(_journals));
    ref.invalidate(appListsProvider);
    ref.invalidate(settingsProvider);
    if (mounted) setState(() => _saving = false);
  }

  void _add() {
    final code  = _codeCtrl.text.trim().toUpperCase();
    final label = _labelCtrl.text.trim();
    if (code.isEmpty || label.isEmpty) return;
    if (_journals.any((j) => j.code == code)) return;
    setState(() => _journals.add(JournalDef(code: code, label: label)));
    _codeCtrl.clear();
    _labelCtrl.clear();
    _save();
  }

  void _editLabel(int index, String newLabel) {
    if (newLabel.trim().isEmpty) return;
    setState(() {
      _journals[index] = JournalDef(
          code: _journals[index].code, label: newLabel.trim());
    });
    _save();
  }

  void _remove(int index) {
    setState(() => _journals.removeAt(index));
    _save();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Icon(Icons.account_balance_outlined, size: 16,
              color: theme.colorScheme.primary),
          const SizedBox(width: 6),
          Text('Journaux comptables',
              style: theme.textTheme.labelLarge
                  ?.copyWith(fontWeight: FontWeight.w600)),
          if (_saving) ...[
            const SizedBox(width: 8),
            const SizedBox(width: 12, height: 12,
                child: CircularProgressIndicator(strokeWidth: 1.5)),
          ],
        ]),
        const SizedBox(height: 10),

        // List of journals
        ..._journals.asMap().entries.map((e) {
          final i = e.key;
          final j = e.value;
          final labelCtrl = TextEditingController(text: j.label);
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(children: [
              Container(
                width: 52,
                height: 36,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(6),
                ),
                alignment: Alignment.center,
                child: Text(j.code,
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                        color: theme.colorScheme.onPrimaryContainer)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SizedBox(
                  height: 36,
                  child: TextField(
                    controller: labelCtrl,
                    style: const TextStyle(fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Libellé du journal',
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 8),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6)),
                    ),
                    onSubmitted: (v) => _editLabel(i, v),
                    onEditingComplete: () => _editLabel(i, labelCtrl.text),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              IconButton(
                icon: Icon(Icons.delete_outline, size: 16,
                    color: theme.colorScheme.error),
                onPressed: () => _remove(i),
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
            ]),
          );
        }),

        const SizedBox(height: 8),
        // Add new journal row
        Row(children: [
          SizedBox(
            width: 80,
            height: 36,
            child: TextField(
              controller: _codeCtrl,
              textCapitalization: TextCapitalization.characters,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              decoration: InputDecoration(
                hintText: 'Code',
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 8),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6)),
              ),
              onSubmitted: (_) => FocusScope.of(context).nextFocus(),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: SizedBox(
              height: 36,
              child: TextField(
                controller: _labelCtrl,
                style: const TextStyle(fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Libellé (ex: Emprunts)',
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 8),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6)),
                ),
                onSubmitted: (_) => _add(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            height: 36,
            child: OutlinedButton.icon(
              onPressed: _add,
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Ajouter'),
              style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 14)),
            ),
          ),
        ]),
        const Divider(height: 24),
      ],
    );
  }
}

// ── Section wrapper ───────────────────────────────────────────────────────────

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.icon, required this.children});
  final String title;
  final IconData icon;
  final List<Widget> children;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(icon, size: 20, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text(title,
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600)),
            ]),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(children: [
        SizedBox(
          width: 140,
          child: Text(label,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        ),
        Text(value,
            style: theme.textTheme.bodyMedium
                ?.copyWith(fontWeight: FontWeight.w500)),
      ]),
    );
  }
}

// ── Backup & Restore Section ──────────────────────────────────────────────────

class _BackupSection extends StatefulWidget {
  @override
  State<_BackupSection> createState() => _BackupSectionState();
}

class _BackupSectionState extends State<_BackupSection> {
  bool _loading = false;
  String? _lastMessage;
  final _importPathCtrl = TextEditingController();

  @override
  void dispose() {
    _importPathCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _Section(
      title: 'Sauvegarde & Restauration',
      icon: Icons.backup_outlined,
      children: [
        Text(
          'Exportez toutes vos données dans un fichier JSON, ou restaurez depuis une sauvegarde existante.',
          style: theme.textTheme.bodyMedium
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 16),
        Row(children: [
          FilledButton.icon(
            onPressed: _loading ? null : _doExport,
            icon: _loading
                ? const SizedBox(width: 16, height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.download_outlined, size: 18),
            label: const Text('Exporter les données'),
          ),
          const SizedBox(width: 12),
          OutlinedButton.icon(
            onPressed: _loading ? null : _listBackups,
            icon: const Icon(Icons.folder_open_outlined, size: 18),
            label: const Text('Voir les sauvegardes'),
          ),
        ]),
        if (_lastMessage != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(children: [
              Icon(Icons.check_circle_outline, size: 16,
                  color: theme.colorScheme.onPrimaryContainer),
              const SizedBox(width: 8),
              Expanded(
                child: Text(_lastMessage!,
                    style: TextStyle(fontSize: 12,
                        color: theme.colorScheme.onPrimaryContainer)),
              ),
            ]),
          ),
        ],
        const SizedBox(height: 20),
        Divider(color: theme.colorScheme.outlineVariant),
        const SizedBox(height: 12),
        Text('Restaurer depuis une sauvegarde',
            style: theme.textTheme.titleSmall
                ?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Text(
          'Entrez le chemin complet du fichier .json à restaurer. '
          'Attention : cette opération remplace toutes les données actuelles.',
          style: theme.textTheme.bodySmall
              ?.copyWith(color: Colors.orange.shade700),
        ),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(
            child: TextField(
              controller: _importPathCtrl,
              decoration: InputDecoration(
                labelText: 'Chemin du fichier de sauvegarde',
                hintText: r'C:\Users\...\Documents\WinsoftBackup\winsoft_backup_....json',
                isDense: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
          const SizedBox(width: 12),
          OutlinedButton.icon(
            onPressed: _loading ? null : _doImport,
            style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
            icon: const Icon(Icons.restore, size: 18),
            label: const Text('Restaurer'),
          ),
        ]),
      ],
    );
  }

  Future<void> _doExport() async {
    setState(() => _loading = true);
    try {
      final path = await BackupService.export();
      if (mounted) setState(() { _lastMessage = 'Sauvegarde créée : $path'; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _lastMessage = 'Erreur : $e'; _loading = false; });
    }
  }

  Future<void> _listBackups() async {
    final backups = await BackupService.listBackups();
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sauvegardes disponibles'),
        content: SizedBox(
          width: 520, height: 300,
          child: backups.isEmpty
              ? const Center(child: Text('Aucune sauvegarde trouvée'))
              : ListView.builder(
                  itemCount: backups.length,
                  itemBuilder: (_, i) {
                    final name = backups[i].path
                        .split(backups[i].path.contains('\\') ? '\\' : '/')
                        .last;
                    return ListTile(
                      leading: const Icon(Icons.description_outlined),
                      title: Text(name, style: const TextStyle(fontSize: 13)),
                      onTap: () {
                        _importPathCtrl.text = backups[i].path;
                        Navigator.of(ctx).pop();
                      },
                    );
                  }),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Fermer')),
        ],
      ),
    );
  }

  Future<void> _doImport() async {
    final path = _importPathCtrl.text.trim();
    if (path.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Entrez le chemin du fichier de sauvegarde')));
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmer la restauration'),
        content: const Text(
            'Cette opération va EFFACER toutes les données actuelles et les remplacer par celles de la sauvegarde. Continuer ?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Annuler')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Restaurer'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => _loading = true);
    try {
      await BackupService.import(path);
      if (mounted) setState(() { _lastMessage = 'Restauration réussie depuis : $path'; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _lastMessage = 'Erreur : $e'; _loading = false; });
    }
  }
}
