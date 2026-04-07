import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/router.dart';
import '../../app/app.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/models/app_user.dart';

class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key, required this.child});
  final Widget child;

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  int _selectedIndex = 0;

  void _onDestinationSelected(int index) {
    setState(() => _selectedIndex = index);
    context.go(appDestinations[index].route);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final location = GoRouterState.of(context).uri.toString();
    final idx = appDestinations.indexWhere((d) => d.route == location);
    if (idx != -1 && idx != _selectedIndex) {
      setState(() => _selectedIndex = idx);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 900;
    final isTablet = screenWidth >= 600 && screenWidth < 900;
    final theme = Theme.of(context);

    if (isDesktop) return _buildDesktop(theme);
    if (isTablet) return _buildRail(theme);
    return _buildMobile(theme);
  }

  Widget _buildDesktop(ThemeData theme) {
    return Scaffold(
      body: Row(
        children: [
          _DesktopSidebar(
            selectedIndex: _selectedIndex,
            onSelected: _onDestinationSelected,
          ),
          VerticalDivider(
              width: 1,
              thickness: 1,
              color: theme.colorScheme.outlineVariant),
          Expanded(child: widget.child),
        ],
      ),
    );
  }

  Widget _buildRail(ThemeData theme) {
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: _selectedIndex,
            onDestinationSelected: _onDestinationSelected,
            labelType: NavigationRailLabelType.all,
            destinations: appDestinations
                .map((d) => NavigationRailDestination(
                      icon: d.icon,
                      selectedIcon: d.selectedIcon,
                      label: Text(d.label,
                          style: const TextStyle(fontSize: 10)),
                    ))
                .toList(),
          ),
          VerticalDivider(
              width: 1,
              thickness: 1,
              color: theme.colorScheme.outlineVariant),
          Expanded(child: widget.child),
        ],
      ),
    );
  }

  Widget _buildMobile(ThemeData theme) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          appDestinations[_selectedIndex].label,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        actions: [_ThemeToggleButton(), const SizedBox(width: 8)],
      ),
      drawer: NavigationDrawer(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          Navigator.of(context).pop();
          _onDestinationSelected(index);
        },
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(28, 20, 16, 10),
            child: Text('WinSoft',
                style: TextStyle(
                    fontSize: 22, fontWeight: FontWeight.bold)),
          ),
          ...appDestinations.map((d) => NavigationDrawerDestination(
                icon: d.icon,
                selectedIcon: d.selectedIcon,
                label: Text(d.label),
              )),
        ],
      ),
      body: widget.child,
    );
  }
}

// ── Desktop Sidebar ──────────────────────────────────────────────────────

class _DesktopSidebar extends ConsumerWidget {
  const _DesktopSidebar({
    required this.selectedIndex,
    required this.onSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final auth = ref.watch(authProvider);
    final sub = ref.watch(subscriptionProvider);
    final themeMode = ref.watch(themeModeProvider);

    return Container(
      width: 240,
      color: theme.colorScheme.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Logo header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.business_center,
                      color: theme.colorScheme.onPrimary, size: 18),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('WinSoft',
                        style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold)),
                    sub.maybeWhen(
                      data: (s) => Text(
                        'Plan ${s.plan.name}${s.isTrial ? " — Essai" : ""}',
                        style: TextStyle(
                            fontSize: 10,
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w600),
                      ),
                      orElse: () => const SizedBox.shrink(),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Trial banner
          sub.maybeWhen(
            data: (s) => s.isTrial
                ? _TrialBanner(daysLeft: s.daysRemaining)
                : const SizedBox.shrink(),
            orElse: () => const SizedBox.shrink(),
          ),

          // Nav items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(
                  horizontal: 8, vertical: 4),
              children: _buildNavItems(context, theme),
            ),
          ),

          const Divider(height: 1),

          // User profile footer
          _UserFooter(
            user: auth.user,
            themeMode: themeMode,
            onToggleTheme: () {
              ref.read(themeModeProvider.notifier).state =
                  themeMode == ThemeMode.dark
                      ? ThemeMode.light
                      : ThemeMode.dark;
            },
            onLogout: () {
              ref.read(authProvider.notifier).logout();
            },
          ),
        ],
      ),
    );
  }

  List<Widget> _buildNavItems(BuildContext context, ThemeData theme) {
    final items = <Widget>[];
    String? lastGroup;

    for (var i = 0; i < appDestinations.length; i++) {
      final dest = appDestinations[i];
      if (dest.groupLabel != null && dest.groupLabel != lastGroup) {
        if (lastGroup != null) items.add(const SizedBox(height: 8));
        items.add(Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
          child: Text(
            dest.groupLabel!,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurfaceVariant
                  .withValues(alpha: 0.6),
              letterSpacing: 0.8,
            ),
          ),
        ));
        lastGroup = dest.groupLabel;
      }

      items.add(_NavItem(
        destination: dest,
        isSelected: selectedIndex == i,
        onTap: () => onSelected(i),
      ));
    }
    return items;
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.destination,
    required this.isSelected,
    required this.onTap,
  });

  final NavDestination destination;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = isSelected
        ? theme.colorScheme.onSecondaryContainer
        : theme.colorScheme.onSurfaceVariant;
    final bg =
        isSelected ? theme.colorScheme.secondaryContainer : Colors.transparent;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            child: Row(
              children: [
                IconTheme(
                  data: IconThemeData(color: color, size: 20),
                  child: isSelected
                      ? destination.selectedIcon
                      : destination.icon,
                ),
                const SizedBox(width: 12),
                Text(
                  destination.label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: color,
                    fontWeight: isSelected
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TrialBanner extends StatelessWidget {
  const _TrialBanner({required this.daysLeft});
  final int daysLeft;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(Icons.workspace_premium,
              size: 16, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Essai gratuit — $daysLeft j.',
              style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: () => context.go('/subscription'),
            style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: const Size(0, 0),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap),
            child: Text('Passer au Pro',
                style: TextStyle(
                    fontSize: 11,
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

class _UserFooter extends StatelessWidget {
  const _UserFooter({
    required this.user,
    required this.themeMode,
    required this.onToggleTheme,
    required this.onLogout,
  });

  final AppUser? user;
  final ThemeMode themeMode;
  final VoidCallback onToggleTheme;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (user == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: theme.colorScheme.primaryContainer,
            child: Text(
              user!.name.isNotEmpty ? user!.name[0].toUpperCase() : '?',
              style: TextStyle(
                color: theme.colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(user!.name,
                    style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis),
                Text(AppUser.roleLabel(user!.role),
                    style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 10,
                        color: theme.colorScheme.onSurfaceVariant),
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          IconButton(
            icon: Icon(
              themeMode == ThemeMode.dark
                  ? Icons.light_mode_outlined
                  : Icons.dark_mode_outlined,
              size: 18,
            ),
            tooltip: 'Changer le thème',
            onPressed: onToggleTheme,
            visualDensity: VisualDensity.compact,
          ),
          IconButton(
            icon: Icon(Icons.logout,
                size: 18, color: theme.colorScheme.error),
            tooltip: 'Se déconnecter',
            onPressed: onLogout,
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}

class _ThemeToggleButton extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    return IconButton(
      icon: Icon(themeMode == ThemeMode.dark
          ? Icons.light_mode_outlined
          : Icons.dark_mode_outlined),
      onPressed: () {
        ref.read(themeModeProvider.notifier).state =
            themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
      },
    );
  }
}
