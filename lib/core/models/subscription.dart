class SubscriptionPlan {
  final String id;
  final String name;
  final String nameAr;
  final double priceMonthly;  // MAD / mois
  final double priceYearly;   // MAD / an
  final int maxUsers;
  final int maxInvoices;      // -1 = illimité
  final List<String> features;
  final bool isPopular;

  const SubscriptionPlan({
    required this.id,
    required this.name,
    required this.nameAr,
    required this.priceMonthly,
    required this.priceYearly,
    required this.maxUsers,
    required this.maxInvoices,
    required this.features,
    this.isPopular = false,
  });

  double get discount =>
      ((1 - (priceYearly / 12) / priceMonthly) * 100).roundToDouble();
}

const kSubscriptionPlans = [
  SubscriptionPlan(
    id: 'starter',
    name: 'Starter',
    nameAr: 'مبتدئ',
    priceMonthly: 0,
    priceYearly: 0,
    maxUsers: 1,
    maxInvoices: 10,
    features: [
      '1 utilisateur',
      '10 factures / mois',
      'Devis & bons de commande',
      'Clients & produits',
      'Support par email',
    ],
  ),
  SubscriptionPlan(
    id: 'pro',
    name: 'Pro',
    nameAr: 'احترافي',
    priceMonthly: 299,
    priceYearly: 2990,
    maxUsers: 5,
    maxInvoices: -1,
    isPopular: true,
    features: [
      '5 utilisateurs',
      'Factures illimitées',
      'Export PDF',
      'Tableau de bord avancé',
      'Gestion des stocks',
      'Support prioritaire',
    ],
  ),
  SubscriptionPlan(
    id: 'enterprise',
    name: 'Entreprise',
    nameAr: 'مؤسسة',
    priceMonthly: 699,
    priceYearly: 6990,
    maxUsers: -1,
    maxInvoices: -1,
    features: [
      'Utilisateurs illimités',
      'Toutes les fonctionnalités Pro',
      'Multi-entreprises',
      'API & intégrations',
      'Manager dédié',
      'SLA 99.9%',
    ],
  ),
];

class ActiveSubscription {
  final String planId;
  final bool isYearly;
  final DateTime startDate;
  final DateTime endDate;
  final String status; // 'active' | 'trial' | 'expired' | 'cancelled'

  const ActiveSubscription({
    required this.planId,
    required this.isYearly,
    required this.startDate,
    required this.endDate,
    required this.status,
  });

  bool get isActive => status == 'active' || status == 'trial';
  bool get isTrial => status == 'trial';

  int get daysRemaining =>
      endDate.difference(DateTime.now()).inDays.clamp(0, 999);

  SubscriptionPlan get plan =>
      kSubscriptionPlans.firstWhere((p) => p.id == planId);
}
