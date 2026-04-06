import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/app.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final themeMode = ref.watch(themeModeProvider);

    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerLowest,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Settings',
                style: theme.textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold)),
            Text('Manage your application preferences.',
                style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant)),
            const SizedBox(height: 24),

            // Company Profile
            _SettingsSection(
              title: 'Company Profile',
              icon: Icons.business_outlined,
              children: [
                _SettingsField(
                    label: 'Company Name', placeholder: 'WinSoft Inc.'),
                _SettingsField(
                    label: 'Email Address',
                    placeholder: 'contact@winsoft.com'),
                _SettingsField(
                    label: 'Phone Number', placeholder: '+1 555 0100'),
                _SettingsField(
                    label: 'Address', placeholder: '123 Main St, City, Country'),
                _SettingsField(
                    label: 'Tax ID / VAT Number',
                    placeholder: 'US123456789'),
                const SizedBox(height: 8),
                FilledButton(
                    onPressed: () {}, child: const Text('Save Profile')),
              ],
            ),
            const SizedBox(height: 20),

            // Invoice Settings
            _SettingsSection(
              title: 'Invoice Settings',
              icon: Icons.receipt_long_outlined,
              children: [
                _SettingsField(
                    label: 'Invoice Prefix', placeholder: 'INV-'),
                _SettingsField(
                    label: 'Default Payment Terms',
                    placeholder: 'Net 14 days'),
                _SettingsField(
                    label: 'Default Currency', placeholder: 'USD (\$)'),
                _SettingsField(
                    label: 'Default Tax Rate (%)', placeholder: '20'),
                _SettingsField(
                    label: 'Invoice Notes',
                    placeholder: 'Thank you for your business.',
                    maxLines: 3),
                const SizedBox(height: 8),
                FilledButton(
                    onPressed: () {},
                    child: const Text('Save Invoice Settings')),
              ],
            ),
            const SizedBox(height: 20),

            // Appearance
            _SettingsSection(
              title: 'Appearance',
              icon: Icons.palette_outlined,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Dark Mode',
                            style: theme.textTheme.bodyLarge
                                ?.copyWith(fontWeight: FontWeight.w500)),
                        Text('Switch between light and dark theme',
                            style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant)),
                      ],
                    ),
                    Switch(
                      value: themeMode == ThemeMode.dark,
                      onChanged: (val) {
                        ref.read(themeModeProvider.notifier).state =
                            val ? ThemeMode.dark : ThemeMode.light;
                      },
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),

            // About
            _SettingsSection(
              title: 'About',
              icon: Icons.info_outlined,
              children: [
                _InfoRow(label: 'Version', value: '1.0.0'),
                _InfoRow(label: 'Framework', value: 'Flutter 3.32'),
                _InfoRow(
                    label: 'Platforms',
                    value: 'Windows · Android · iOS · Web'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({
    required this.title,
    required this.icon,
    required this.children,
  });

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
            Row(
              children: [
                Icon(icon, size: 20, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(title,
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _SettingsField extends StatelessWidget {
  const _SettingsField({
    required this.label,
    required this.placeholder,
    this.maxLines = 1,
  });

  final String label;
  final String placeholder;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant)),
          const SizedBox(height: 6),
          SizedBox(
            width: 480,
            child: TextField(
              maxLines: maxLines,
              decoration: InputDecoration(
                hintText: placeholder,
                isDense: true,
              ),
            ),
          ),
        ],
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
      child: Row(
        children: [
          SizedBox(
            width: 140,
            child: Text(label,
                style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant)),
          ),
          Text(value,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
