import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/app.dart';
import '../../core/database/database_helper.dart';
import '../../core/providers/providers.dart';
import '../../core/providers/language_provider.dart';
import '../../core/utils/morocco_format.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});
  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _iceCtrl = TextEditingController();
  final _rcCtrl = TextEditingController();
  final _ifCtrl = TextEditingController();
  final _prefixCtrl = TextEditingController();
  final _termsCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
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
    _termsCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeMode = ref.watch(themeModeProvider);
    final settingsAsync = ref.watch(settingsProvider);

    return settingsAsync.when(
      loading: () => const Scaffold(
          body: Center(child: CircularProgressIndicator())),
      error: (e, _) =>
          Scaffold(body: Center(child: Text('Erreur: $e'))),
      data: (settings) {
        if (!_loaded) {
          _nameCtrl.text = settings['company_name'] ?? '';
          _emailCtrl.text = settings['company_email'] ?? '';
          _phoneCtrl.text = settings['company_phone'] ?? '';
          _addressCtrl.text = settings['company_address'] ?? '';
          _iceCtrl.text = settings['company_ice'] ?? '';
          _rcCtrl.text = settings['company_rc'] ?? '';
          _ifCtrl.text = settings['company_if'] ?? '';
          _prefixCtrl.text = settings['invoice_prefix'] ?? 'FAC';
          _termsCtrl.text =
              settings['invoice_terms'] ?? '30 jours net';
          _notesCtrl.text = settings['invoice_notes'] ?? '';
          final city = settings['company_city'] ?? MoroccoFormat.cities.first;
          _selectedCity = MoroccoFormat.cities.contains(city)
              ? city
              : MoroccoFormat.cities.first;
          _tvaDefault =
              double.tryParse(settings['tva_default'] ?? '20') ?? 20;
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
                Text(
                    'Configurez votre application et votre profil entreprise.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant)),
                const SizedBox(height: 24),

                // Company Profile
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
                      builder: (ctx, setState) =>
                          DropdownButtonFormField<String>(
                        value: _selectedCity,
                        decoration:
                            const InputDecoration(labelText: 'Ville'),
                        items: MoroccoFormat.cities
                            .map((c) => DropdownMenuItem(
                                value: c, child: Text(c)))
                            .toList(),
                        onChanged: (v) =>
                            setState(() => _selectedCity = v!),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text('Informations fiscales',
                        style: theme.textTheme.labelLarge?.copyWith(
                            color: theme.colorScheme.primary)),
                    const SizedBox(height: 8),
                    _field(_iceCtrl, 'ICE (15 chiffres)'),
                    _field(_rcCtrl, 'RC'),
                    _field(_ifCtrl, 'IF (Identifiant Fiscal)'),
                    const SizedBox(height: 8),
                    FilledButton(
                      onPressed: () => _saveCompanyProfile(),
                      child: const Text('Enregistrer le profil'),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Invoice settings
                _Section(
                  title: 'Paramètres de facturation',
                  icon: Icons.receipt_long_outlined,
                  children: [
                    _field(_prefixCtrl, 'Préfixe facture (ex: FAC)'),
                    _field(_termsCtrl, 'Conditions de paiement'),
                    StatefulBuilder(
                      builder: (ctx, setState) =>
                          DropdownButtonFormField<double>(
                        value: _tvaDefault,
                        decoration: const InputDecoration(
                            labelText: 'TVA par défaut'),
                        items: MoroccoFormat.tvaRates
                            .map((r) => DropdownMenuItem(
                                value: r,
                                child: Text(
                                    MoroccoFormat.tvaLabel(r))))
                            .toList(),
                        onChanged: (v) =>
                            setState(() => _tvaDefault = v!),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _field(_notesCtrl, 'Note de bas de facture',
                        maxLines: 3),
                    const SizedBox(height: 8),
                    FilledButton(
                      onPressed: () => _saveInvoiceSettings(),
                      child: const Text('Enregistrer'),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Appearance & Language
                _Section(
                  title: 'Apparence & Langue',
                  icon: Icons.palette_outlined,
                  children: [
                    Row(
                      mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text('Mode sombre',
                                style: theme.textTheme.bodyLarge
                                    ?.copyWith(
                                        fontWeight: FontWeight.w500)),
                            Text('Changer le thème de l\'interface',
                                style: theme.textTheme.bodySmall
                                    ?.copyWith(
                                        color: theme.colorScheme
                                            .onSurfaceVariant)),
                          ],
                        ),
                        Switch(
                          value: themeMode == ThemeMode.dark,
                          onChanged: (val) {
                            ref
                                .read(themeModeProvider.notifier)
                                .state = val
                                ? ThemeMode.dark
                                : ThemeMode.light;
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Consumer(
                      builder: (ctx, ref, _) {
                        final langAsync = ref.watch(languageProvider);
                        final currentLang = langAsync.maybeWhen(
                            data: (l) => l, orElse: () => 'fr');
                        return Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text('Langue / اللغة / Language',
                                    style: theme.textTheme.bodyLarge
                                        ?.copyWith(
                                            fontWeight:
                                                FontWeight.w500)),
                                Text(
                                    'Interface en Français, العربية ou English',
                                    style: theme.textTheme.bodySmall
                                        ?.copyWith(
                                            color: theme.colorScheme
                                                .onSurfaceVariant)),
                              ],
                            ),
                            SegmentedButton<String>(
                              segments: const [
                                ButtonSegment(
                                    value: 'fr', label: Text('FR')),
                                ButtonSegment(
                                    value: 'ar', label: Text('ع')),
                                ButtonSegment(
                                    value: 'en', label: Text('EN')),
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

                // About
                _Section(
                  title: 'À propos',
                  icon: Icons.info_outlined,
                  children: [
                    _InfoRow(label: 'Version', value: '1.0.0'),
                    _InfoRow(label: 'Framework', value: 'Flutter 3.32'),
                    _InfoRow(
                        label: 'Plateformes',
                        value: 'Windows · Android · iOS · Web'),
                    _InfoRow(
                        label: 'Base de données',
                        value: 'SQLite (local)'),
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
    await db.setSetting('invoice_prefix', _prefixCtrl.text.trim());
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

  Widget _field(TextEditingController ctrl, String label,
          {int maxLines = 1}) =>
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

class _Section extends StatelessWidget {
  const _Section(
      {required this.title,
      required this.icon,
      required this.children});
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
              style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant)),
        ),
        Text(value,
            style: theme.textTheme.bodyMedium
                ?.copyWith(fontWeight: FontWeight.w500)),
      ]),
    );
  }
}
