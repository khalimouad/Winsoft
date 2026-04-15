import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/database/database_helper.dart';
import '../../core/models/subscription.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/utils/morocco_format.dart';

class SubscriptionPage extends ConsumerStatefulWidget {
  const SubscriptionPage({super.key});

  @override
  ConsumerState<SubscriptionPage> createState() => _SubscriptionPageState();
}

class _SubscriptionPageState extends ConsumerState<SubscriptionPage> {
  bool _yearly = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subAsync = ref.watch(subscriptionProvider);

    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerLowest,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Abonnement',
                        style: theme.textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    Text('Gérez votre plan et votre facturation.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Current plan banner
            subAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
              data: (sub) => _CurrentPlanBanner(sub: sub),
            ),
            const SizedBox(height: 32),

            // Billing toggle
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Mensuel',
                    style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: _yearly
                            ? FontWeight.normal
                            : FontWeight.bold)),
                const SizedBox(width: 12),
                Switch(
                  value: _yearly,
                  onChanged: (v) => setState(() => _yearly = v),
                ),
                const SizedBox(width: 12),
                Text('Annuel',
                    style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: _yearly
                            ? FontWeight.bold
                            : FontWeight.normal)),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Économisez 17%',
                    style: TextStyle(
                        color: Colors.green,
                        fontSize: 12,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Plan cards
            subAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Erreur: $e')),
              data: (sub) => LayoutBuilder(
                builder: (ctx, constraints) {
                  final crossAxis = constraints.maxWidth > 900
                      ? 3
                      : constraints.maxWidth > 600
                          ? 2
                          : 1;
                  return GridView.builder(
                    shrinkWrap: true,
                    physics:
                        const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxis,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: crossAxis == 1 ? 1.4 : 0.85,
                    ),
                    itemCount: kSubscriptionPlans.length,
                    itemBuilder: (ctx, i) => _PlanCard(
                      plan: kSubscriptionPlans[i],
                      yearly: _yearly,
                      isCurrent:
                          sub.planId == kSubscriptionPlans[i].id,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 32),

            // Invoice history
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Historique de facturation',
                            style: theme.textTheme.titleMedium
                                ?.copyWith(
                                    fontWeight: FontWeight.w600)),
                        TextButton.icon(
                          onPressed: () {},
                          icon: const Icon(
                              Icons.download_outlined,
                              size: 16),
                          label: const Text('Exporter'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _BillingRow(
                      date: '01/04/2026',
                      description: 'Plan Pro — Mensuel',
                      amount: '299,00 DH',
                      status: 'Payée',
                    ),
                    const Divider(height: 1),
                    _BillingRow(
                      date: '01/03/2026',
                      description: 'Plan Pro — Mensuel',
                      amount: '299,00 DH',
                      status: 'Payée',
                    ),
                    const Divider(height: 1),
                    _BillingRow(
                      date: '01/02/2026',
                      description: 'Plan Pro — Mensuel',
                      amount: '299,00 DH',
                      status: 'Payée',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Plan selection helper ────────────────────────────────────────────────────

Future<void> _selectPlan(
    BuildContext context, WidgetRef ref, SubscriptionPlan plan) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text('Passer au plan ${plan.name}'),
      content: Text(
          'Activer le plan ${plan.name} à ${MoroccoFormat.mad(plan.priceMonthly)}/mois ?'),
      actions: [
        TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Annuler')),
        FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Confirmer')),
      ],
    ),
  );
  if (confirmed != true || !context.mounted) return;

  final endMs = DateTime.now()
      .add(const Duration(days: 30))
      .millisecondsSinceEpoch;

  await DatabaseHelper.instance.setSetting('subscription_plan', plan.id);
  await DatabaseHelper.instance.setSetting('subscription_status', 'active');
  await DatabaseHelper.instance.setSetting('subscription_end', endMs.toString());

  ref.invalidate(subscriptionProvider);

  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Plan ${plan.name} activé avec succès !')),
    );
  }
}

class _CurrentPlanBanner extends StatelessWidget {
  const _CurrentPlanBanner({required this.sub});
  final ActiveSubscription sub;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final plan = sub.plan;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.primary.withValues(alpha: 0.75),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Plan ${plan.name}',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 10),
                    if (sub.isTrial)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text('ESSAI GRATUIT',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w700)),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  sub.isTrial
                      ? 'Essai gratuit — ${sub.daysRemaining} jours restants'
                      : 'Actif jusqu\'au ${MoroccoFormat.date(sub.endDate)}',
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 14),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _Pill('${plan.maxUsers == -1 ? "∞" : plan.maxUsers} utilisateurs'),
                    const SizedBox(width: 8),
                    _Pill(plan.maxInvoices == -1
                        ? 'Factures illimitées'
                        : '${plan.maxInvoices} factures/mois'),
                  ],
                ),
              ],
            ),
          ),
          if (sub.isTrial || sub.planId == 'starter')
            Consumer(builder: (_, ref, __) => FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: theme.colorScheme.primary,
              ),
              onPressed: () => _selectPlan(
                  context, ref, kSubscriptionPlans.firstWhere((p) => p.id == 'pro')),
              child: const Text('Passer au Pro',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            )),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill(this.label);
  final String label;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500)),
      );
}

class _PlanCard extends ConsumerWidget {
  const _PlanCard({
    required this.plan,
    required this.yearly,
    required this.isCurrent,
  });

  final SubscriptionPlan plan;
  final bool yearly;
  final bool isCurrent;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final price = yearly ? plan.priceYearly / 12 : plan.priceMonthly;
    final isFree = price == 0;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: plan.isPopular
              ? theme.colorScheme.primary
              : theme.colorScheme.outlineVariant,
          width: plan.isPopular ? 2 : 1,
        ),
        boxShadow: plan.isPopular
            ? [
                BoxShadow(
                  color: theme.colorScheme.primary.withValues(alpha: 0.15),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Popular badge
            if (plan.isPopular)
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('Le plus populaire',
                    style: TextStyle(
                        color: theme.colorScheme.onPrimaryContainer,
                        fontSize: 11,
                        fontWeight: FontWeight.w700)),
              ),

            Text(plan.name,
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),

            // Price
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  isFree ? 'Gratuit' : MoroccoFormat.mad(price),
                  style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary),
                ),
                if (!isFree) ...[
                  const SizedBox(width: 4),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text('/ mois',
                        style: theme.textTheme.bodySmall?.copyWith(
                            color:
                                theme.colorScheme.onSurfaceVariant)),
                  ),
                ],
              ],
            ),
            if (yearly && !isFree)
              Text(
                'Facturé ${MoroccoFormat.mad(plan.priceYearly)} / an',
                style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant),
              ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),

            // Features
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: plan.features
                    .map((f) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              Icon(Icons.check_circle,
                                  size: 16,
                                  color: theme.colorScheme.primary),
                              const SizedBox(width: 8),
                              Expanded(
                                  child: Text(f,
                                      style: theme.textTheme
                                          .bodySmall)),
                            ],
                          ),
                        ))
                    .toList(),
              ),
            ),
            const SizedBox(height: 12),

            // CTA
            SizedBox(
              width: double.infinity,
              child: isCurrent
                  ? OutlinedButton(
                      onPressed: null,
                      child: const Text('Plan actuel'),
                    )
                  : FilledButton(
                      onPressed: () => _selectPlan(context, ref, plan),
                      child: Text(isFree
                          ? 'Démarrer gratuitement'
                          : 'Choisir ${plan.name}'),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BillingRow extends StatelessWidget {
  const _BillingRow({
    required this.date,
    required this.description,
    required this.amount,
    required this.status,
  });
  final String date, description, amount, status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          SizedBox(
              width: 100,
              child: Text(date,
                  style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant))),
          Expanded(child: Text(description)),
          Text(amount,
              style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(width: 16),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(status,
                style: const TextStyle(
                    color: Colors.green,
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.download_outlined, size: 16),
            onPressed: () {},
            tooltip: 'Télécharger',
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}
