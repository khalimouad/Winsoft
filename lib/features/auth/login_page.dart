import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers/auth_provider.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _emailCtrl = TextEditingController(text: 'admin@winsoft.ma');
  final _passCtrl = TextEditingController(text: 'Admin123');
  final _formKey = GlobalKey<FormState>();
  bool _obscure = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    ref.read(authProvider.notifier).clearError();
    final ok = await ref
        .read(authProvider.notifier)
        .login(_emailCtrl.text.trim(), _passCtrl.text);
    if (ok && mounted) context.go('/dashboard');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = ref.watch(authProvider);
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth > 900;

    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerLowest,
      body: isWide ? _buildWideLayout(theme, auth) : _buildNarrowLayout(theme, auth),
    );
  }

  Widget _buildWideLayout(ThemeData theme, AuthState auth) {
    return Row(
      children: [
        // Left branding panel
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  theme.colorScheme.primary,
                  theme.colorScheme.primary.withValues(alpha: 0.7),
                  theme.colorScheme.tertiary,
                ],
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(48),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Logo
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.business_center,
                            color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Text('WinSoft',
                          style: theme.textTheme.headlineMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const Spacer(),
                  Text('Gérez votre\nentreprise en toute\nsimplicité.',
                      style: theme.textTheme.displaySmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          height: 1.2)),
                  const SizedBox(height: 20),
                  Text(
                    'Facturation · Ventes · Inventaire · Équipe',
                    style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.8)),
                  ),
                  const SizedBox(height: 48),
                  // Feature bullets
                  ...[
                    ('Facturation conforme à la législation marocaine',
                        Icons.receipt_long),
                    ('TVA intégrée — 0%, 7%, 10%, 14%, 20%',
                        Icons.percent),
                    ('Multi-utilisateurs avec gestion des rôles',
                        Icons.group),
                    ('Export PDF & synchronisation multi-appareils',
                        Icons.sync),
                  ].map((item) => Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(item.$2,
                                  color: Colors.white, size: 16),
                            ),
                            const SizedBox(width: 12),
                            Flexible(
                              child: Text(item.$1,
                                  style: TextStyle(
                                      color: Colors.white
                                          .withValues(alpha: 0.9),
                                      fontSize: 14)),
                            ),
                          ],
                        ),
                      )),
                  const Spacer(),
                  Text(
                    '© 2026 WinSoft · Solution SaaS Marocaine',
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ),
        // Right login form
        SizedBox(
          width: 480,
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(48),
              child: _buildForm(theme, auth),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNarrowLayout(ThemeData theme, AuthState auth) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            // Mini branding
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.business_center,
                  color: Colors.white, size: 30),
            ),
            const SizedBox(height: 12),
            Text('WinSoft',
                style: theme.textTheme.headlineMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Solution de gestion d\'entreprise',
                style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant)),
            const SizedBox(height: 40),
            _buildForm(theme, auth),
          ],
        ),
      ),
    );
  }

  Widget _buildForm(ThemeData theme, AuthState auth) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Connexion',
              style: theme.textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text('Entrez vos identifiants pour accéder à votre espace.',
              style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant)),
          const SizedBox(height: 32),

          // Email
          TextFormField(
            controller: _emailCtrl,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: 'Adresse email',
              prefixIcon: Icon(Icons.email_outlined,
                  color: theme.colorScheme.onSurfaceVariant),
            ),
            validator: (v) =>
                v == null || !v.contains('@') ? 'Email invalide' : null,
          ),
          const SizedBox(height: 16),

          // Password
          TextFormField(
            controller: _passCtrl,
            obscureText: _obscure,
            decoration: InputDecoration(
              labelText: 'Mot de passe',
              prefixIcon: Icon(Icons.lock_outline,
                  color: theme.colorScheme.onSurfaceVariant),
              suffixIcon: IconButton(
                icon: Icon(
                    _obscure
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: theme.colorScheme.onSurfaceVariant),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ),
            validator: (v) => v == null || v.length < 4
                ? 'Mot de passe trop court'
                : null,
            onFieldSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 8),

          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {},
              child: const Text('Mot de passe oublié ?'),
            ),
          ),

          // Error
          if (auth.error != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline,
                      color: theme.colorScheme.onErrorContainer, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(auth.error!,
                        style: TextStyle(
                            color: theme.colorScheme.onErrorContainer)),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 24),

          // Submit
          SizedBox(
            width: double.infinity,
            height: 50,
            child: FilledButton(
              onPressed: auth.isLoading ? null : _submit,
              child: auth.isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Se connecter',
                      style: TextStyle(fontSize: 16)),
            ),
          ),
          const SizedBox(height: 24),

          // Demo hint
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline,
                    size: 16,
                    color: theme.colorScheme.onSurfaceVariant),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Démo : admin@winsoft.ma / Admin123',
                    style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
