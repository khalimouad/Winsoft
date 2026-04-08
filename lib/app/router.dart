import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/providers/auth_provider.dart';
import '../features/auth/login_page.dart';
import '../features/dashboard/dashboard_page.dart';
import '../features/companies/companies_page.dart';
import '../features/clients/clients_page.dart';
import '../features/products/products_page.dart';
import '../features/sales/sales_page.dart';
import '../features/invoices/invoices_page.dart';
import '../features/purchases/purchases_page.dart';
import '../features/hr/hr_page.dart';
import '../features/accounting/accounting_page.dart';
import '../features/manufacturing/manufacturing_page.dart';
import '../features/reports/reports_page.dart';
import '../features/declarations/declarations_page.dart';
import '../features/pos/pos_page.dart';
import '../features/pos/price_lists_page.dart';
import '../features/team/team_page.dart';
import '../features/subscription/subscription_page.dart';
import '../features/settings/settings_page.dart';
import '../shared/widgets/app_shell.dart';

// Auth-aware router rebuild trigger
final _routerListenableProvider = Provider<_AuthListenable>((ref) {
  return _AuthListenable(ref);
});

class _AuthListenable extends ChangeNotifier {
  _AuthListenable(this._ref) {
    _ref.listen(authProvider, (_, __) => notifyListeners());
  }
  final Ref _ref;
}

GoRouter buildRouter(WidgetRef ref) {
  final listenable = ref.read(_routerListenableProvider);

  return GoRouter(
    initialLocation: '/login',
    refreshListenable: listenable,
    redirect: (context, state) {
      final auth = ref.read(authProvider);
      final isLogin = state.matchedLocation == '/login';

      if (!auth.isAuthenticated && !isLogin) return '/login';
      if (auth.isAuthenticated && isLogin) return '/dashboard';
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        pageBuilder: (context, state) =>
            const NoTransitionPage(child: LoginPage()),
      ),
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: '/dashboard',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: DashboardPage()),
          ),
          GoRoute(
            path: '/companies',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: CompaniesPage()),
          ),
          GoRoute(
            path: '/clients',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: ClientsPage()),
          ),
          GoRoute(
            path: '/products',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: ProductsPage()),
          ),
          GoRoute(
            path: '/sales',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: SalesPage()),
          ),
          GoRoute(
            path: '/invoices',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: InvoicesPage()),
          ),
          GoRoute(
            path: '/purchases',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: PurchasesPage()),
          ),
          GoRoute(
            path: '/hr',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: HrPage()),
          ),
          GoRoute(
            path: '/accounting',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: AccountingPage()),
          ),
          GoRoute(
            path: '/manufacturing',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: ManufacturingPage()),
          ),
          GoRoute(
            path: '/pos',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: PosPage()),
          ),
          GoRoute(
            path: '/price-lists',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: PriceListsPage()),
          ),
          GoRoute(
            path: '/reports',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: ReportsPage()),
          ),
          GoRoute(
            path: '/declarations',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: DeclarationsPage()),
          ),
          GoRoute(
            path: '/team',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: TeamPage()),
          ),
          GoRoute(
            path: '/subscription',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: SubscriptionPage()),
          ),
          GoRoute(
            path: '/settings',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: SettingsPage()),
          ),
        ],
      ),
    ],
  );
}

// ── Navigation destinations ───────────────────────────────────────────────────

class NavDestination {
  const NavDestination({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.route,
    this.groupLabel,
  });

  final String label;
  final Widget icon;
  final Widget selectedIcon;
  final String route;
  final String? groupLabel;
}

const List<NavDestination> appDestinations = [
  NavDestination(
    label: 'Tableau de bord',
    icon: Icon(Icons.dashboard_outlined),
    selectedIcon: Icon(Icons.dashboard),
    route: '/dashboard',
    groupLabel: 'GÉNÉRAL',
  ),
  NavDestination(
    label: 'Entreprises',
    icon: Icon(Icons.business_outlined),
    selectedIcon: Icon(Icons.business),
    route: '/companies',
    groupLabel: 'CONTACTS',
  ),
  NavDestination(
    label: 'Clients',
    icon: Icon(Icons.people_outlined),
    selectedIcon: Icon(Icons.people),
    route: '/clients',
  ),
  NavDestination(
    label: 'Bons de Commande',
    icon: Icon(Icons.shopping_cart_outlined),
    selectedIcon: Icon(Icons.shopping_cart),
    route: '/sales',
    groupLabel: 'VENTES',
  ),
  NavDestination(
    label: 'Factures Clients',
    icon: Icon(Icons.receipt_long_outlined),
    selectedIcon: Icon(Icons.receipt_long),
    route: '/invoices',
  ),
  NavDestination(
    label: 'Achats',
    icon: Icon(Icons.shopping_bag_outlined),
    selectedIcon: Icon(Icons.shopping_bag),
    route: '/purchases',
    groupLabel: 'ACHATS',
  ),
  NavDestination(
    label: 'Produits & Services',
    icon: Icon(Icons.inventory_2_outlined),
    selectedIcon: Icon(Icons.inventory_2),
    route: '/products',
    groupLabel: 'INVENTAIRE',
  ),
  NavDestination(
    label: 'Production',
    icon: Icon(Icons.precision_manufacturing_outlined),
    selectedIcon: Icon(Icons.precision_manufacturing),
    route: '/manufacturing',
  ),
  NavDestination(
    label: 'Point de Vente (POS)',
    icon: Icon(Icons.point_of_sale_outlined),
    selectedIcon: Icon(Icons.point_of_sale),
    route: '/pos',
    groupLabel: 'POS',
  ),
  NavDestination(
    label: 'Listes de prix',
    icon: Icon(Icons.price_change_outlined),
    selectedIcon: Icon(Icons.price_change),
    route: '/price-lists',
  ),
  NavDestination(
    label: 'Ressources Humaines',
    icon: Icon(Icons.badge_outlined),
    selectedIcon: Icon(Icons.badge),
    route: '/hr',
    groupLabel: 'RH',
  ),
  NavDestination(
    label: 'Comptabilité',
    icon: Icon(Icons.account_balance_outlined),
    selectedIcon: Icon(Icons.account_balance),
    route: '/accounting',
    groupLabel: 'FINANCE',
  ),
  NavDestination(
    label: 'Rapports',
    icon: Icon(Icons.bar_chart_outlined),
    selectedIcon: Icon(Icons.bar_chart),
    route: '/reports',
  ),
  NavDestination(
    label: 'Déclarations fiscales',
    icon: Icon(Icons.description_outlined),
    selectedIcon: Icon(Icons.description),
    route: '/declarations',
  ),
  NavDestination(
    label: 'Équipe',
    icon: Icon(Icons.group_outlined),
    selectedIcon: Icon(Icons.group),
    route: '/team',
    groupLabel: 'ADMINISTRATION',
  ),
  NavDestination(
    label: 'Abonnement',
    icon: Icon(Icons.workspace_premium_outlined),
    selectedIcon: Icon(Icons.workspace_premium),
    route: '/subscription',
  ),
  NavDestination(
    label: 'Paramètres',
    icon: Icon(Icons.settings_outlined),
    selectedIcon: Icon(Icons.settings),
    route: '/settings',
  ),
];
