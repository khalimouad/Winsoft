import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../features/dashboard/dashboard_page.dart';
import '../features/companies/companies_page.dart';
import '../features/clients/clients_page.dart';
import '../features/products/products_page.dart';
import '../features/sales/sales_page.dart';
import '../features/invoices/invoices_page.dart';
import '../features/settings/settings_page.dart';
import '../shared/widgets/app_shell.dart';

final appRouter = GoRouter(
  initialLocation: '/dashboard',
  routes: [
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
          path: '/settings',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: SettingsPage()),
        ),
      ],
    ),
  ],
);

class NavDestination {
  const NavDestination({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.route,
  });

  final String label;
  final Widget icon;
  final Widget selectedIcon;
  final String route;
}

const List<NavDestination> appDestinations = [
  NavDestination(
    label: 'Dashboard',
    icon: Icon(Icons.dashboard_outlined),
    selectedIcon: Icon(Icons.dashboard),
    route: '/dashboard',
  ),
  NavDestination(
    label: 'Companies',
    icon: Icon(Icons.business_outlined),
    selectedIcon: Icon(Icons.business),
    route: '/companies',
  ),
  NavDestination(
    label: 'Clients',
    icon: Icon(Icons.people_outlined),
    selectedIcon: Icon(Icons.people),
    route: '/clients',
  ),
  NavDestination(
    label: 'Products',
    icon: Icon(Icons.inventory_2_outlined),
    selectedIcon: Icon(Icons.inventory_2),
    route: '/products',
  ),
  NavDestination(
    label: 'Sales',
    icon: Icon(Icons.shopping_cart_outlined),
    selectedIcon: Icon(Icons.shopping_cart),
    route: '/sales',
  ),
  NavDestination(
    label: 'Invoices',
    icon: Icon(Icons.receipt_long_outlined),
    selectedIcon: Icon(Icons.receipt_long),
    route: '/invoices',
  ),
  NavDestination(
    label: 'Settings',
    icon: Icon(Icons.settings_outlined),
    selectedIcon: Icon(Icons.settings),
    route: '/settings',
  ),
];
