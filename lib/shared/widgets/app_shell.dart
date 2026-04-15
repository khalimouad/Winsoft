import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/router.dart';
import '../../app/app.dart';
import '../../app/theme.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/models/app_user.dart';

/// Width of the vertical icon ribbon on desktop / tablet.
const double _kRibbonWidth = 88;

/// Bottom-nav quick-access indices (into [appDestinations]).
/// The 5th slot in the bottom nav is always "Plus" (opens the full drawer).
const List<int> _kBottomNavIndices = [
  0, // Dashboard
  3, // Bons de Commande
  4, // Factures Clients
  6, // Produits & Services
];

// ── Shell provider — lets pages inject a FAB ──────────────────────────────────

/// Pages can call [ShellFab.set] to register a FAB in the bottom-right corner.
/// The shell picks it up and renders it above the bottom navigation bar.
final _fabProvider = StateProvider<Widget?>((ref) => null);

/// Helper that pages can use to set / clear the shell FAB.
abstract final class ShellFab {
  /// Register [fab] as the current page's floating action button.
  static void set(WidgetRef ref, Widget fab) =>
      ref.read(_fabProvider.notifier).state = fab;

  /// Remove the FAB (call in [dispose] or when the page leaves).
  static void clear(WidgetRef ref) =>
      ref.read(_fabProvider.notifier).state = null;
}

// ── AppShell ──────────────────────────────────────────────────────────────────

class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key, required this.child});
  final Widget child;

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  int _selectedIndex = 0;

  /// Key for the mobile Scaffold so we can programmatically open the drawer.
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

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
    final w = MediaQuery.sizeOf(context).width;
    if (w >= 640) return _buildDesktop();
    return _buildMobile();
  }

  // ── Desktop / tablet layout — icon ribbon ─────────────────────────────────

  Widget _buildDesktop() {
    return Scaffold(
      backgroundColor: WsColors.sidebarBg,
      body: Row(children: [
        _Ribbon(
          selectedIndex: _selectedIndex,
          onSelected: _onDestinationSelected,
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft:    Radius.circular(20),
              bottomLeft: Radius.circular(20),
            ),
            child: widget.child,
          ),
        ),
      ]),
    );
  }

  // ── Mobile layout — bottom navigation bar ────────────────────────────────

  Widget _buildMobile() {
    // Map current full-nav index → bottom-nav index (4 = "Plus / More")
    final bottomIdx = _kBottomNavIndices.contains(_selectedIndex)
        ? _kBottomNavIndices.indexOf(_selectedIndex)
        : 4; // "Plus" is highlighted when on a non-quick-access page

    final fab = ref.watch(_fabProvider);

    return Scaffold(
      key: _scaffoldKey,
      // ── AppBar ──────────────────────────────────────────────────────────
      appBar: _MobileAppBar(
        title: appDestinations[_selectedIndex].label,
        onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
      ),
      // ── Full drawer (all routes) ────────────────────────────────────────
      drawer: _MobileDrawer(
        selectedIndex: _selectedIndex,
        onSelected: (i) {
          Navigator.of(context).pop();
          _onDestinationSelected(i);
        },
      ),
      // ── Content ─────────────────────────────────────────────────────────
      body: widget.child,
      // ── FAB from current page ───────────────────────────────────────────
      floatingActionButton: fab,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      // ── Bottom navigation ───────────────────────────────────────────────
      bottomNavigationBar: _BottomNav(
        selectedIndex: bottomIdx,
        onDestinationSelected: (i) {
          if (i == 4) {
            // "Plus" tapped → open full drawer
            _scaffoldKey.currentState?.openDrawer();
          } else {
            _onDestinationSelected(_kBottomNavIndices[i]);
          }
        },
      ),
    );
  }
}

// ── Mobile AppBar ─────────────────────────────────────────────────────────────

class _MobileAppBar extends ConsumerWidget implements PreferredSizeWidget {
  const _MobileAppBar({required this.title, required this.onMenuTap});

  final String title;
  final VoidCallback onMenuTap;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    return AppBar(
      backgroundColor: WsColors.sidebarBg,
      foregroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.menu_rounded),
        color: Colors.white,
        onPressed: onMenuTap,
      ),
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _LogoMark(size: 28),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: Icon(
            themeMode == ThemeMode.dark
                ? Icons.light_mode_outlined
                : Icons.dark_mode_outlined,
            color: Colors.white,
          ),
          onPressed: () {
            ref.read(themeModeProvider.notifier).state =
                themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
          },
        ),
        const SizedBox(width: 4),
      ],
    );
  }
}

// ── Bottom navigation bar ─────────────────────────────────────────────────────

class _BottomNav extends StatelessWidget {
  const _BottomNav({
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return NavigationBar(
      selectedIndex: selectedIndex,
      onDestinationSelected: onDestinationSelected,
      height: 64,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      backgroundColor: theme.colorScheme.surface,
      indicatorColor: WsColors.blue600.withValues(alpha: 0.15),
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.dashboard_outlined),
          selectedIcon: Icon(Icons.dashboard, color: WsColors.blue600),
          label: 'Accueil',
        ),
        NavigationDestination(
          icon: Icon(Icons.shopping_cart_outlined),
          selectedIcon: Icon(Icons.shopping_cart, color: WsColors.blue600),
          label: 'Ventes',
        ),
        NavigationDestination(
          icon: Icon(Icons.receipt_long_outlined),
          selectedIcon: Icon(Icons.receipt_long, color: WsColors.blue600),
          label: 'Factures',
        ),
        NavigationDestination(
          icon: Icon(Icons.inventory_2_outlined),
          selectedIcon: Icon(Icons.inventory_2, color: WsColors.blue600),
          label: 'Produits',
        ),
        NavigationDestination(
          icon: Icon(Icons.more_horiz_rounded),
          selectedIcon: Icon(Icons.more_horiz_rounded, color: WsColors.blue600),
          label: 'Plus',
        ),
      ],
    );
  }
}

// ── Ribbon sidebar (desktop/tablet) ──────────────────────────────────────────

class _Ribbon extends ConsumerWidget {
  const _Ribbon({required this.selectedIndex, required this.onSelected});

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth      = ref.watch(authProvider);
    final sub       = ref.watch(subscriptionProvider);
    final themeMode = ref.watch(themeModeProvider);

    return Container(
      width: _kRibbonWidth,
      color: WsColors.sidebarBg,
      child: Column(children: [
        const SizedBox(height: 18),
        _LogoMark(),
        const SizedBox(height: 6),
        sub.maybeWhen(
          data: (s) => Text(
            s.isTrial ? 'ESSAI' : s.plan.name.toUpperCase(),
            style: const TextStyle(
              color: WsColors.blue400,
              fontSize: 8.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
            ),
          ),
          orElse: () => const SizedBox.shrink(),
        ),
        const SizedBox(height: 18),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 4),
            physics: const BouncingScrollPhysics(),
            children: _buildNavItems(context),
          ),
        ),
        sub.maybeWhen(
          data: (s) => s.isTrial
              ? _TrialPill(daysLeft: s.daysRemaining)
              : const SizedBox.shrink(),
          orElse: () => const SizedBox.shrink(),
        ),
        Container(
          height: 1,
          margin: const EdgeInsets.symmetric(horizontal: 16),
          color: WsColors.sidebarBorder,
        ),
        const SizedBox(height: 10),
        _RibbonUserFooter(
          user: auth.user,
          themeMode: themeMode,
          onToggleTheme: () {
            ref.read(themeModeProvider.notifier).state =
                themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
          },
          onLogout: () => ref.read(authProvider.notifier).logout(),
        ),
        const SizedBox(height: 12),
      ]),
    );
  }

  List<Widget> _buildNavItems(BuildContext context) {
    final items   = <Widget>[];
    String? lastGrp;

    for (var i = 0; i < appDestinations.length; i++) {
      final dest = appDestinations[i];

      if (dest.groupLabel != null && dest.groupLabel != lastGrp) {
        if (lastGrp != null) {
          items.add(const SizedBox(height: 4));
          items.add(Container(
            height: 1,
            margin: const EdgeInsets.symmetric(horizontal: 22),
            color: WsColors.sidebarBorder,
          ));
          items.add(const SizedBox(height: 4));
        }
        lastGrp = dest.groupLabel;
      }

      items.add(_RibbonNavItem(
        destination: dest,
        isSelected:  selectedIndex == i,
        onTap:       () => onSelected(i),
      ));
    }
    return items;
  }
}

// ── Logo mark ─────────────────────────────────────────────────────────────────

class _LogoMark extends StatelessWidget {
  const _LogoMark({this.size = 42});
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [WsColors.blue500, WsColors.blue700],
        ),
        borderRadius: BorderRadius.circular(size * 0.33),
        boxShadow: [
          BoxShadow(
            color: WsColors.blue600.withValues(alpha: 0.35),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Icon(Icons.business_center_rounded,
          color: Colors.white, size: size * 0.47),
    );
  }
}

// ── Ribbon nav item — icon circle + label ─────────────────────────────────────

class _RibbonNavItem extends StatefulWidget {
  const _RibbonNavItem({
    required this.destination,
    required this.isSelected,
    required this.onTap,
  });

  final NavDestination destination;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  State<_RibbonNavItem> createState() => _RibbonNavItemState();
}

class _RibbonNavItemState extends State<_RibbonNavItem> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final sel   = widget.isSelected;
    final hover = _hovering && !sel;

    final Color bubbleColor = sel
        ? WsColors.sidebarIconActive
        : hover
            ? WsColors.sidebarIconHover
            : Colors.transparent;

    final Color labelColor = sel
        ? Colors.white
        : hover
            ? Colors.white
            : WsColors.sidebarText;

    return Tooltip(
      message: widget.destination.label,
      waitDuration: const Duration(milliseconds: 400),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovering = true),
        onExit:  (_) => setState(() => _hovering = false),
        cursor:  SystemMouseCursors.click,
        child: GestureDetector(
          onTap: widget.onTap,
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
            child: Column(children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: bubbleColor,
                  shape: BoxShape.circle,
                  boxShadow: sel
                      ? [
                          BoxShadow(
                            color: WsColors.blue600.withValues(alpha: 0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 3),
                          ),
                        ]
                      : null,
                ),
                child: IconTheme(
                  data: const IconThemeData(color: Colors.white, size: 20),
                  child: sel
                      ? widget.destination.selectedIcon
                      : widget.destination.icon,
                ),
              ),
              const SizedBox(height: 4),
              SizedBox(
                height: 14,
                child: Text(
                  widget.destination.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: labelColor,
                    fontSize: 9.5,
                    fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                    letterSpacing: 0.1,
                  ),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

// ── Trial pill ────────────────────────────────────────────────────────────────

class _TrialPill extends StatelessWidget {
  const _TrialPill({required this.daysLeft});
  final int daysLeft;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Essai gratuit — $daysLeft jours restants',
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 6, 10, 10),
        child: GestureDetector(
          onTap: () => context.go('/subscription'),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: WsColors.blue900.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: WsColors.blue700.withValues(alpha: 0.5),
              ),
            ),
            child: Column(children: [
              const Icon(Icons.auto_awesome,
                  size: 14, color: WsColors.amber500),
              const SizedBox(height: 2),
              Text('$daysLeft j',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  )),
            ]),
          ),
        ),
      ),
    );
  }
}

// ── User footer (ribbon) ──────────────────────────────────────────────────────

class _RibbonUserFooter extends StatelessWidget {
  const _RibbonUserFooter({
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
    if (user == null) return const SizedBox.shrink();
    final initials = user!.name.isNotEmpty
        ? user!.name.trim().split(' ').take(2).map((w) => w[0]).join()
        : '?';

    return Column(children: [
      Tooltip(
        message: '${user!.name}\n${AppUser.roleLabel(user!.role)}',
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [WsColors.blue500, WsColors.blue700],
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: WsColors.blue600.withValues(alpha: 0.3),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: Text(initials.toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                )),
          ),
        ),
      ),
      const SizedBox(height: 8),
      _CircleIconButton(
        icon: themeMode == ThemeMode.dark
            ? Icons.light_mode_outlined
            : Icons.dark_mode_outlined,
        tooltip: 'Thème',
        onTap: onToggleTheme,
      ),
      const SizedBox(height: 4),
      _CircleIconButton(
        icon: Icons.logout_rounded,
        tooltip: 'Déconnexion',
        hoverColor: WsColors.red500.withValues(alpha: 0.2),
        onTap: onLogout,
      ),
    ]);
  }
}

// ── Circle icon button ────────────────────────────────────────────────────────

class _CircleIconButton extends StatefulWidget {
  const _CircleIconButton({
    required this.icon,
    required this.onTap,
    required this.tooltip,
    this.hoverColor,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;
  final Color? hoverColor;

  @override
  State<_CircleIconButton> createState() => _CircleIconButtonState();
}

class _CircleIconButtonState extends State<_CircleIconButton> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.tooltip,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovering = true),
        onExit:  (_) => setState(() => _hovering = false),
        cursor:  SystemMouseCursors.click,
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _hovering
                  ? (widget.hoverColor ?? WsColors.sidebarIconHover)
                  : Colors.transparent,
              shape: BoxShape.circle,
            ),
            child: Icon(widget.icon, size: 17, color: Colors.white),
          ),
        ),
      ),
    );
  }
}

// ── Mobile drawer ─────────────────────────────────────────────────────────────

class _MobileDrawer extends ConsumerWidget {
  const _MobileDrawer({required this.selectedIndex, required this.onSelected});

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final sub  = ref.watch(subscriptionProvider);

    return Drawer(
      backgroundColor: WsColors.sidebarBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight:    Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: SafeArea(
        child: Column(children: [
          // ── Header ────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Row(children: [
              _LogoMark(size: 36),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('WinSoft',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                          letterSpacing: -0.3,
                        )),
                    sub.maybeWhen(
                      data: (s) => Text(
                        s.isTrial
                            ? '${s.daysRemaining} jours d\'essai restants'
                            : 'Plan ${s.plan.name}',
                        style: const TextStyle(
                          color: WsColors.blue400,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      orElse: () => const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
            ]),
          ),
          Container(
            height: 1,
            color: WsColors.sidebarBorder,
          ),
          // ── Nav items ─────────────────────────────────────────────────
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              itemCount: appDestinations.length,
              itemBuilder: (ctx, i) {
                final dest     = appDestinations[i];
                final prevDest = i > 0 ? appDestinations[i - 1] : null;
                final showDiv  = dest.groupLabel != null &&
                    dest.groupLabel != prevDest?.groupLabel;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (showDiv && i > 0) ...[
                      const SizedBox(height: 4),
                      Padding(
                        padding: const EdgeInsets.only(left: 4, bottom: 4),
                        child: Text(
                          dest.groupLabel!,
                          style: const TextStyle(
                            color: WsColors.sidebarText,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
                    ],
                    _MobileDrawerItem(
                      destination: dest,
                      isSelected: selectedIndex == i,
                      onTap: () => onSelected(i),
                    ),
                  ],
                );
              },
            ),
          ),
          // ── User footer ───────────────────────────────────────────────
          if (auth.user != null) ...[
            Container(height: 1, color: WsColors.sidebarBorder),
            _DrawerUserFooter(
              user: auth.user!,
              onLogout: () {
                Navigator.of(context).pop();
                ref.read(authProvider.notifier).logout();
              },
            ),
          ],
        ]),
      ),
    );
  }
}

class _DrawerUserFooter extends StatelessWidget {
  const _DrawerUserFooter({required this.user, required this.onLogout});
  final AppUser user;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final initials = user.name.isNotEmpty
        ? user.name.trim().split(' ').take(2).map((w) => w[0]).join()
        : '?';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(children: [
        Container(
          width: 38,
          height: 38,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [WsColors.blue500, WsColors.blue700],
            ),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(initials.toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                )),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(user.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  )),
              Text(AppUser.roleLabel(user.role),
                  style: const TextStyle(
                    color: WsColors.sidebarText,
                    fontSize: 11,
                  )),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.logout_rounded, color: Colors.white, size: 20),
          tooltip: 'Déconnexion',
          onPressed: onLogout,
        ),
      ]),
    );
  }
}

class _MobileDrawerItem extends StatefulWidget {
  const _MobileDrawerItem({
    required this.destination,
    required this.isSelected,
    required this.onTap,
  });

  final NavDestination destination;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  State<_MobileDrawerItem> createState() => _MobileDrawerItemState();
}

class _MobileDrawerItemState extends State<_MobileDrawerItem> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final sel   = widget.isSelected;
    final hover = _hovering && !sel;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit:  (_) => setState(() => _hovering = false),
      cursor:  SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.symmetric(vertical: 2),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          decoration: BoxDecoration(
            color: sel
                ? WsColors.sidebarIconHover
                : hover
                    ? WsColors.sidebarHover
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: sel ? WsColors.sidebarIconActive : Colors.transparent,
                shape: BoxShape.circle,
              ),
              child: IconTheme(
                data: const IconThemeData(color: Colors.white, size: 18),
                child: sel
                    ? widget.destination.selectedIcon
                    : widget.destination.icon,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                widget.destination.label,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
            if (sel)
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: WsColors.blue400,
                  shape: BoxShape.circle,
                ),
              ),
          ]),
        ),
      ),
    );
  }
}
