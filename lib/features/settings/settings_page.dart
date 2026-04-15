import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/app.dart';
import '../../core/database/database_helper.dart';
import '../../core/models/accounting_country.dart';
import '../../core/models/app_lists.dart';
import '../../core/models/payroll_config.dart';
import '../../core/providers/auth_provider.dart';
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
  final _ecPrefix    = TextEditingController();
  final _siPrefix    = TextEditingController();
  final _termsCtrl   = TextEditingController();
  final _notesCtrl   = TextEditingController();
  // Valeurs par défaut
  final _invoiceDueDaysCtrl      = TextEditingController();
  final _lowStockCtrl            = TextEditingController();
  final _leaveDaysCtrl           = TextEditingController();
  final _mfgLeadDaysCtrl         = TextEditingController();
  String _selectedCity = AppLists.defaultCities.first;
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
    _ecPrefix.dispose();
    _siPrefix.dispose();
    _termsCtrl.dispose();
    _notesCtrl.dispose();
    _invoiceDueDaysCtrl.dispose();
    _lowStockCtrl.dispose();
    _leaveDaysCtrl.dispose();
    _mfgLeadDaysCtrl.dispose();
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
          _ecPrefix.text    = settings['ec_prefix'] ?? 'EC';
          _siPrefix.text    = settings['si_prefix'] ?? 'FF';
          _termsCtrl.text   = settings['invoice_terms'] ?? '30 jours net';
          _notesCtrl.text   = settings['invoice_notes'] ?? '';
          _invoiceDueDaysCtrl.text = settings['invoice_due_days'] ?? '30';
          _lowStockCtrl.text       = settings['low_stock_threshold'] ?? '5';
          _leaveDaysCtrl.text      = settings['default_leave_days'] ?? '5';
          _mfgLeadDaysCtrl.text    = settings['manufacturing_lead_days'] ?? '7';
          final city = settings['company_city'] ?? AppLists.defaultCities.first;
          _selectedCity = lists.cities.contains(city)
              ? city
              : AppLists.defaultCities.first;
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
                            : (lists.cities.isNotEmpty ? lists.cities.first : _selectedCity),
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
                      Expanded(child: _field(_poPrefix, 'Préfixe bon commande (ex: BA)')),
                      const SizedBox(width: 12),
                      Expanded(child: _field(_cnPrefix, 'Préfixe avoir (ex: AV)')),
                    ]),
                    Row(children: [
                      Expanded(child: _field(_ecPrefix, 'Préfixe écriture compta (ex: EC)')),
                      const SizedBox(width: 12),
                      Expanded(child: _field(_siPrefix, 'Préfixe fact. fournisseur (ex: FF)')),
                      const SizedBox(width: 12),
                      const Expanded(child: SizedBox.shrink()),
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

                // ── Document Statuses ────────────────────────────────────────
                _Section(
                  title: 'Statuts des documents',
                  icon: Icons.rule_outlined,
                  children: [
                    Text(
                      'Personnalisez les statuts disponibles pour chaque type de document.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 20),
                    _ListEditor(
                      title: 'Statuts factures',
                      icon: Icons.receipt_outlined,
                      settingsKey: AppLists.kInvoiceStatuses,
                      items: lists.invoiceStatuses,
                    ),
                    const SizedBox(height: 16),
                    _ListEditor(
                      title: 'Statuts bons de commande (ventes)',
                      icon: Icons.shopping_cart_outlined,
                      settingsKey: AppLists.kOrderStatuses,
                      items: lists.orderStatuses,
                    ),
                    const SizedBox(height: 16),
                    _ListEditor(
                      title: 'Statuts bons de commande (achats)',
                      icon: Icons.local_shipping_outlined,
                      settingsKey: AppLists.kPurchaseOrderStatuses,
                      items: lists.purchaseOrderStatuses,
                    ),
                    const SizedBox(height: 16),
                    _ListEditor(
                      title: 'Statuts factures fournisseurs',
                      icon: Icons.request_quote_outlined,
                      settingsKey: AppLists.kSupplierInvoiceStatuses,
                      items: lists.supplierInvoiceStatuses,
                    ),
                    const SizedBox(height: 16),
                    _ListEditor(
                      title: 'Statuts avoirs',
                      icon: Icons.undo_outlined,
                      settingsKey: AppLists.kCreditNoteStatuses,
                      items: lists.creditNoteStatuses,
                    ),
                    const SizedBox(height: 16),
                    _ListEditor(
                      title: 'Statuts bulletins de paie',
                      icon: Icons.description_outlined,
                      settingsKey: AppLists.kPayrollStatuses,
                      items: lists.payrollStatuses,
                    ),
                    const SizedBox(height: 16),
                    _ListEditor(
                      title: 'Statuts ordres de fabrication',
                      icon: Icons.precision_manufacturing_outlined,
                      settingsKey: AppLists.kProductionStatuses,
                      items: lists.productionStatuses,
                    ),
                    const SizedBox(height: 16),
                    _ListEditor(
                      title: 'Statuts demandes de congé',
                      icon: Icons.event_available_outlined,
                      settingsKey: AppLists.kLeaveStatuses,
                      items: lists.leaveStatuses,
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // ── Business Defaults ────────────────────────────────────────
                _Section(
                  title: 'Valeurs par défaut',
                  icon: Icons.tune_outlined,
                  children: [
                    Row(children: [
                      Expanded(child: _field(_invoiceDueDaysCtrl, 'Délai de paiement facture (jours)')),
                      const SizedBox(width: 12),
                      Expanded(child: _field(_lowStockCtrl, 'Seuil alerte stock bas (unités)')),
                    ]),
                    Row(children: [
                      Expanded(child: _field(_leaveDaysCtrl, 'Durée congé par défaut (jours)')),
                      const SizedBox(width: 12),
                      Expanded(child: _field(_mfgLeadDaysCtrl, 'Délai de fabrication (jours)')),
                    ]),
                    const SizedBox(height: 8),
                    FilledButton(
                      onPressed: _saveDocumentDefaults,
                      child: const Text('Enregistrer les valeurs'),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // ── Accounting Country ───────────────────────────────────────
                Consumer(
                  builder: (ctx, ref, _) {
                    final subAsync = ref.watch(subscriptionProvider);
                    final settings = ref.watch(settingsProvider).valueOrNull ?? {};
                    final currentCode = settings[AccountingCountry.kSettingKey] ?? 'MA';
                    final planId = subAsync.valueOrNull?.planId ?? 'starter';

                    return _Section(
                      title: 'Référentiel comptable',
                      icon: Icons.account_balance_outlined,
                      children: [
                        Text(
                          'Choisissez le plan comptable selon votre pays.'
                          ' Certains référentiels nécessitent un abonnement supérieur.',
                          style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(ctx).colorScheme.onSurfaceVariant),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: AccountingCountry.all.map((country) {
                            final isSelected = country.code == currentCode;
                            final isLocked = _isCountryLocked(country.requiredPlan, planId);
                            return _CountryChip(
                              country: country,
                              isSelected: isSelected,
                              isLocked: isLocked,
                              onTap: isLocked
                                  ? null
                                  : () async {
                                      await DatabaseHelper.instance.setSetting(
                                          AccountingCountry.kSettingKey, country.code);
                                      ref.invalidate(settingsProvider);
                                      if (ctx.mounted) {
                                        ScaffoldMessenger.of(ctx)
                                            .showSnackBar(SnackBar(
                                          content: Text(
                                              'Référentiel ${country.name} (${country.standard}) activé'),
                                        ));
                                      }
                                    },
                            );
                          }).toList(),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 20),

                // ── Payroll Configuration ────────────────────────────────────
                Consumer(
                  builder: (ctx, ref, _) {
                    final configAsync = ref.watch(payrollConfigProvider);
                    final config = configAsync.valueOrNull ?? PayrollConfig.defaults;
                    return _Section(
                      title: 'Configuration paie (CNSS / AMO / IGR)',
                      icon: Icons.account_balance_wallet_outlined,
                      children: [
                        _PayrollConfigEditor(config: config),
                      ],
                    );
                  },
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
    await db.setSetting('ec_prefix', _ecPrefix.text.trim().isEmpty ? 'EC' : _ecPrefix.text.trim());
    await db.setSetting('si_prefix', _siPrefix.text.trim().isEmpty ? 'FF' : _siPrefix.text.trim());
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

  Future<void> _saveDocumentDefaults() async {
    final db = DatabaseHelper.instance;
    await db.setSetting('invoice_due_days',
        _invoiceDueDaysCtrl.text.trim().isEmpty ? '30' : _invoiceDueDaysCtrl.text.trim());
    await db.setSetting('low_stock_threshold',
        _lowStockCtrl.text.trim().isEmpty ? '5' : _lowStockCtrl.text.trim());
    await db.setSetting('default_leave_days',
        _leaveDaysCtrl.text.trim().isEmpty ? '5' : _leaveDaysCtrl.text.trim());
    await db.setSetting('manufacturing_lead_days',
        _mfgLeadDaysCtrl.text.trim().isEmpty ? '7' : _mfgLeadDaysCtrl.text.trim());
    ref.invalidate(settingsProvider);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Valeurs enregistrées'),
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

// ── Accounting country helpers ────────────────────────────────────────────────

bool _isCountryLocked(String requiredPlan, String currentPlan) {
  const order = ['starter', 'pro', 'enterprise'];
  final required = order.indexOf(requiredPlan);
  final current  = order.indexOf(currentPlan);
  return current < required;
}

class _CountryChip extends StatelessWidget {
  const _CountryChip({
    required this.country,
    required this.isSelected,
    required this.isLocked,
    this.onTap,
  });

  final AccountingCountry country;
  final bool isSelected;
  final bool isLocked;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Opacity(
      opacity: isLocked ? 0.45 : 1.0,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? theme.colorScheme.primaryContainer
                : theme.colorScheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.outlineVariant,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(country.flag, style: const TextStyle(fontSize: 22)),
            const SizedBox(height: 4),
            Text(country.name,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected
                        ? theme.colorScheme.onPrimaryContainer
                        : theme.colorScheme.onSurface)),
            Text(country.standard,
                style: TextStyle(
                    fontSize: 10,
                    color: theme.colorScheme.onSurfaceVariant)),
            if (isLocked)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.lock_outline,
                      size: 10, color: theme.colorScheme.onSurfaceVariant),
                  const SizedBox(width: 2),
                  Text(country.requiredPlan,
                      style: TextStyle(
                          fontSize: 9,
                          color: theme.colorScheme.onSurfaceVariant)),
                ]),
              ),
          ]),
        ),
      ),
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

// ── Payroll Config Editor ─────────────────────────────────────────────────────

class _PayrollConfigEditor extends ConsumerStatefulWidget {
  const _PayrollConfigEditor({required this.config});
  final PayrollConfig config;

  @override
  ConsumerState<_PayrollConfigEditor> createState() => _PayrollConfigEditorState();
}

class _PayrollConfigEditorState extends ConsumerState<_PayrollConfigEditor> {
  late TextEditingController _cnssEmployee;
  late TextEditingController _cnssEmployer;
  late TextEditingController _cnssEmpApec;
  late TextEditingController _cnssEmrApec;
  late TextEditingController _cnssPlafond;
  late TextEditingController _amoEmployee;
  late TextEditingController _amoEmployer;
  late List<IgrBracket> _brackets;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadFrom(widget.config);
  }

  @override
  void didUpdateWidget(_PayrollConfigEditor old) {
    super.didUpdateWidget(old);
    if (old.config != widget.config) _loadFrom(widget.config);
  }

  void _loadFrom(PayrollConfig c) {
    _cnssEmployee = TextEditingController(text: _pct(c.cnssEmployeeRate));
    _cnssEmployer = TextEditingController(text: _pct(c.cnssEmployerRate));
    _cnssEmpApec  = TextEditingController(text: _pct(c.cnssEmployeeApec));
    _cnssEmrApec  = TextEditingController(text: _pct(c.cnssEmployerApec));
    _cnssPlafond  = TextEditingController(text: c.cnssPlafond.toStringAsFixed(0));
    _amoEmployee  = TextEditingController(text: _pct(c.amoEmployeeRate));
    _amoEmployer  = TextEditingController(text: _pct(c.amoEmployerRate));
    _brackets     = List.from(c.igrBrackets);
  }

  String _pct(double v) => (v * 100).toStringAsFixed(4).replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');

  @override
  void dispose() {
    _cnssEmployee.dispose();
    _cnssEmployer.dispose();
    _cnssEmpApec.dispose();
    _cnssEmrApec.dispose();
    _cnssPlafond.dispose();
    _amoEmployee.dispose();
    _amoEmployer.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final config = PayrollConfig(
      cnssEmployeeRate: (double.tryParse(_cnssEmployee.text) ?? 4.48) / 100,
      cnssEmployerRate: (double.tryParse(_cnssEmployer.text) ?? 10.64) / 100,
      cnssEmployeeApec: (double.tryParse(_cnssEmpApec.text) ?? 0.96) / 100,
      cnssEmployerApec: (double.tryParse(_cnssEmrApec.text) ?? 3.96) / 100,
      cnssPlafond:       double.tryParse(_cnssPlafond.text) ?? 6000.0,
      amoEmployeeRate:  (double.tryParse(_amoEmployee.text) ?? 2.26) / 100,
      amoEmployerRate:  (double.tryParse(_amoEmployer.text) ?? 4.11) / 100,
      igrBrackets:       _brackets,
    );
    await DatabaseHelper.instance.setSetting(PayrollConfig.kSettings, config.toJson());
    ref.invalidate(settingsProvider);
    ref.invalidate(payrollConfigProvider);
    if (mounted) {
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Configuration paie enregistrée'),
          behavior: SnackBarBehavior.floating));
    }
  }

  Widget _rateField(TextEditingController ctrl, String label) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: SizedBox(
      width: 220,
      child: TextField(
        controller: ctrl,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          labelText: label,
          suffixText: '%',
          isDense: true,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // ── CNSS ──────────────────────────────────────────────────────────────
      Text('CNSS', style: theme.textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w600, color: theme.colorScheme.primary)),
      const SizedBox(height: 8),
      Wrap(spacing: 12, runSpacing: 0, children: [
        _rateField(_cnssEmployee, 'Part salariale (%)'),
        _rateField(_cnssEmployer, 'Part patronale (%)'),
        _rateField(_cnssEmpApec,  'APEC salariale (%)'),
        _rateField(_cnssEmrApec,  'APEC patronale (%)'),
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: SizedBox(
            width: 220,
            child: TextField(
              controller: _cnssPlafond,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Plafond mensuel (DH)',
                isDense: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
        ),
      ]),
      const SizedBox(height: 12),

      // ── AMO ───────────────────────────────────────────────────────────────
      Text('AMO (Assurance maladie)', style: theme.textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w600, color: theme.colorScheme.primary)),
      const SizedBox(height: 8),
      Wrap(spacing: 12, runSpacing: 0, children: [
        _rateField(_amoEmployee, 'Part salariale (%)'),
        _rateField(_amoEmployer, 'Part patronale (%)'),
      ]),
      const SizedBox(height: 12),

      // ── IGR Brackets ──────────────────────────────────────────────────────
      Row(children: [
        Text('Tranches IGR (IR)', style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600, color: theme.colorScheme.primary)),
        const SizedBox(width: 8),
        OutlinedButton.icon(
          onPressed: _addBracket,
          icon: const Icon(Icons.add, size: 14),
          label: const Text('Ajouter tranche'),
          style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              visualDensity: VisualDensity.compact),
        ),
      ]),
      const SizedBox(height: 8),
      Table(
        columnWidths: const {
          0: FlexColumnWidth(2),
          1: FlexColumnWidth(1),
          2: FixedColumnWidth(36),
        },
        children: [
          TableRow(
            decoration: BoxDecoration(color: theme.colorScheme.surfaceContainerLowest),
            children: [
              Padding(padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                  child: Text("Jusqu'à (DH/an)", style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w600, color: theme.colorScheme.onSurfaceVariant))),
              Padding(padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                  child: Text('Taux (%)', style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w600, color: theme.colorScheme.onSurfaceVariant))),
              const SizedBox.shrink(),
            ],
          ),
          ..._brackets.asMap().entries.map((e) {
            final i = e.key;
            final b = e.value;
            final isLast = b.maxIncome.isInfinite;
            final maxCtrl = TextEditingController(
                text: isLast ? '∞' : b.maxIncome.toStringAsFixed(0));
            final rateCtrl = TextEditingController(text: _pct(b.rate));
            return TableRow(children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                child: TextField(
                  controller: maxCtrl,
                  enabled: !isLast,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(fontSize: 13),
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                  onSubmitted: (v) => _updateBracketMax(i, v),
                  onEditingComplete: () => _updateBracketMax(i, maxCtrl.text),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                child: TextField(
                  controller: rateCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(fontSize: 13),
                  decoration: InputDecoration(
                    isDense: true,
                    suffixText: '%',
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                  onSubmitted: (v) => _updateBracketRate(i, v),
                  onEditingComplete: () => _updateBracketRate(i, rateCtrl.text),
                ),
              ),
              IconButton(
                icon: Icon(Icons.delete_outline, size: 14,
                    color: isLast ? Colors.transparent : theme.colorScheme.error),
                onPressed: isLast ? null : () => _removeBracket(i),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
            ]);
          }),
        ],
      ),
      const SizedBox(height: 16),
      FilledButton(
        onPressed: _saving ? null : _save,
        child: _saving
            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
            : const Text('Enregistrer la configuration paie'),
      ),
    ]);
  }

  void _addBracket() {
    setState(() {
      final lastIdx = _brackets.indexWhere((b) => b.maxIncome.isInfinite);
      _brackets.insert(lastIdx < 0 ? _brackets.length : lastIdx,
          const IgrBracket(maxIncome: 100000, rate: 0, baseAmount: 0));
    });
  }

  void _removeBracket(int i) {
    if (_brackets[i].maxIncome.isInfinite) return;
    setState(() => _brackets.removeAt(i));
  }

  void _updateBracketMax(int i, String v) {
    final val = double.tryParse(v);
    if (val == null) return;
    setState(() {
      _brackets[i] = IgrBracket(
          maxIncome: val, rate: _brackets[i].rate, baseAmount: _brackets[i].baseAmount);
    });
  }

  void _updateBracketRate(int i, String v) {
    final val = double.tryParse(v);
    if (val == null) return;
    setState(() {
      _brackets[i] = IgrBracket(
          maxIncome: _brackets[i].maxIncome, rate: val / 100, baseAmount: _brackets[i].baseAmount);
    });
  }
}
