import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme.dart';
import '../../core/providers/auth_provider.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _emailCtrl = TextEditingController(text: 'admin@winsoft.ma');
  final _passCtrl  = TextEditingController(text: 'Admin123');
  final _formKey   = GlobalKey<FormState>();
  bool _obscure    = true;

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
    final w = MediaQuery.of(context).size.width;
    return Scaffold(
      backgroundColor: WsColors.slate50,
      body: w > 900
          ? _WideLayout(
              formKey: _formKey,
              emailCtrl: _emailCtrl,
              passCtrl: _passCtrl,
              obscure: _obscure,
              onToggleObscure: () => setState(() => _obscure = !_obscure),
              onSubmit: _submit,
            )
          : _NarrowLayout(
              formKey: _formKey,
              emailCtrl: _emailCtrl,
              passCtrl: _passCtrl,
              obscure: _obscure,
              onToggleObscure: () => setState(() => _obscure = !_obscure),
              onSubmit: _submit,
            ),
    );
  }
}

// ── Wide layout (desktop) ─────────────────────────────────────────────────────

class _WideLayout extends StatelessWidget {
  const _WideLayout({
    required this.formKey,
    required this.emailCtrl,
    required this.passCtrl,
    required this.obscure,
    required this.onToggleObscure,
    required this.onSubmit,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController emailCtrl;
  final TextEditingController passCtrl;
  final bool obscure;
  final VoidCallback onToggleObscure;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      // ── Left panel ─────────────────────────────────────────────────────────
      SizedBox(
        width: 440,
        child: Container(
          decoration: const BoxDecoration(
            color: WsColors.slate900,
          ),
          padding: const EdgeInsets.all(48),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Logo
              Row(children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [WsColors.blue500, WsColors.blue700],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.business_center_rounded,
                      color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                const Text('WinSoft',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3)),
              ]),
              const Spacer(),

              // Hero text
              const Text(
                'Gérez votre\nentreprise,\nsimplement.',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -1,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'ERP moderne pour les entreprises marocaines.\nFacturation · RH · Compta · POS',
                style: TextStyle(
                    color: WsColors.slate400,
                    fontSize: 14,
                    height: 1.6),
              ),
              const SizedBox(height: 40),

              // Feature list
              ...[
                ('Facturation conforme Maroc', Icons.receipt_long_rounded),
                ('TVA & PCM intégrés', Icons.percent_rounded),
                ('Multi-langue FR · ع · EN', Icons.language_rounded),
                ('Sauvegarde & Export PDF', Icons.cloud_done_rounded),
              ].map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Row(children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: WsColors.blue900.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(7),
                      border: Border.all(color: WsColors.blue700.withValues(alpha: 0.4)),
                    ),
                    child: Icon(item.$2, color: WsColors.blue400, size: 14),
                  ),
                  const SizedBox(width: 12),
                  Text(item.$1,
                      style: const TextStyle(
                          color: WsColors.slate300,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w400)),
                ]),
              )),

              const Spacer(),
              Text('© 2026 WinSoft · Solution SaaS Marocaine',
                  style: TextStyle(color: WsColors.slate600, fontSize: 12)),
            ],
          ),
        ),
      ),

      // ── Right panel (form) ──────────────────────────────────────────────────
      Expanded(
        child: Container(
          color: WsColors.slate50,
          child: Center(
            child: SizedBox(
              width: 420,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(48),
                child: _LoginForm(
                  formKey: formKey,
                  emailCtrl: emailCtrl,
                  passCtrl: passCtrl,
                  obscure: obscure,
                  onToggleObscure: onToggleObscure,
                  onSubmit: onSubmit,
                ),
              ),
            ),
          ),
        ),
      ),
    ]);
  }
}

// ── Narrow layout (mobile) ────────────────────────────────────────────────────

class _NarrowLayout extends StatelessWidget {
  const _NarrowLayout({
    required this.formKey,
    required this.emailCtrl,
    required this.passCtrl,
    required this.obscure,
    required this.onToggleObscure,
    required this.onSubmit,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController emailCtrl;
  final TextEditingController passCtrl;
  final bool obscure;
  final VoidCallback onToggleObscure;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [WsColors.blue500, WsColors.blue700],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.business_center_rounded,
                color: Colors.white, size: 26),
          ),
          const SizedBox(height: 12),
          const Text('WinSoft',
              style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5)),
          const SizedBox(height: 4),
          Text('Solution de gestion d\'entreprise',
              style: TextStyle(
                  color: WsColors.slate500, fontSize: 14)),
          const SizedBox(height: 36),
          _LoginForm(
            formKey: formKey,
            emailCtrl: emailCtrl,
            passCtrl: passCtrl,
            obscure: obscure,
            onToggleObscure: onToggleObscure,
            onSubmit: onSubmit,
          ),
        ]),
      ),
    );
  }
}

// ── Login form ────────────────────────────────────────────────────────────────

class _LoginForm extends ConsumerWidget {
  const _LoginForm({
    required this.formKey,
    required this.emailCtrl,
    required this.passCtrl,
    required this.obscure,
    required this.onToggleObscure,
    required this.onSubmit,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController emailCtrl;
  final TextEditingController passCtrl;
  final bool obscure;
  final VoidCallback onToggleObscure;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final auth  = ref.watch(authProvider);

    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Connexion',
              style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700, letterSpacing: -0.4)),
          const SizedBox(height: 6),
          Text('Entrez vos identifiants pour continuer.',
              style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant)),
          const SizedBox(height: 32),

          // ── Email ──────────────────────────────────────────────────────────
          Text('Email',
              style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600, fontSize: 13)),
          const SizedBox(height: 6),
          TextFormField(
            controller: emailCtrl,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              hintText: 'vous@entreprise.ma',
              prefixIcon: Icon(Icons.mail_outline_rounded,
                  size: 18, color: theme.colorScheme.onSurfaceVariant),
            ),
            validator: (v) =>
                v == null || !v.contains('@') ? 'Email invalide' : null,
          ),
          const SizedBox(height: 18),

          // ── Password ───────────────────────────────────────────────────────
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Mot de passe',
                style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w600, fontSize: 13)),
            TextButton(
              style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap),
              onPressed: () {},
              child: const Text('Mot de passe oublié ?',
                  style: TextStyle(fontSize: 12)),
            ),
          ]),
          const SizedBox(height: 6),
          TextFormField(
            controller: passCtrl,
            obscureText: obscure,
            decoration: InputDecoration(
              hintText: '••••••••',
              prefixIcon: Icon(Icons.lock_outline_rounded,
                  size: 18, color: theme.colorScheme.onSurfaceVariant),
              suffixIcon: IconButton(
                icon: Icon(
                    obscure
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    size: 18,
                    color: theme.colorScheme.onSurfaceVariant),
                onPressed: onToggleObscure,
              ),
            ),
            validator: (v) =>
                v == null || v.length < 4 ? 'Trop court' : null,
            onFieldSubmitted: (_) => onSubmit(),
          ),

          // ── Error ──────────────────────────────────────────────────────────
          if (auth.error != null) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: WsColors.red500.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: WsColors.red500.withValues(alpha: 0.25)),
              ),
              child: Row(children: [
                const Icon(Icons.error_outline_rounded,
                    size: 16, color: WsColors.red600),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(auth.error!,
                      style: const TextStyle(
                          fontSize: 13,
                          color: WsColors.red600,
                          fontWeight: FontWeight.w500)),
                ),
              ]),
            ),
          ],

          const SizedBox(height: 24),

          // ── Submit ─────────────────────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            height: 46,
            child: FilledButton(
              onPressed: auth.isLoading ? null : onSubmit,
              style: FilledButton.styleFrom(
                backgroundColor: WsColors.blue600,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(9)),
                elevation: 0,
                textStyle: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w600),
              ),
              child: auth.isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Text('Connexion'),
            ),
          ),

          const SizedBox(height: 20),

          // ── Demo hint ──────────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(
              color: WsColors.slate100,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: WsColors.slate200),
            ),
            child: Row(children: [
              const Icon(Icons.info_outline_rounded,
                  size: 15, color: WsColors.slate400),
              const SizedBox(width: 8),
              Text(
                'Démo — admin@winsoft.ma / Admin123',
                style: TextStyle(
                    fontSize: 12,
                    color: WsColors.slate500,
                    fontWeight: FontWeight.w400),
              ),
            ]),
          ),
        ],
      ),
    );
  }
}
