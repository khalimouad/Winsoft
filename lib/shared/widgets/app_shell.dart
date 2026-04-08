import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/router.dart';
import '../../app/app.dart';
import '../../app/theme.dart';
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
    final w = MediaQuery.of(context).size.width;

    if (w >= 1000) return _buildDesktop();
    if (w >= 640)  return _buildRail();
    return _buildMobile();
  }

  // ── Desktop layout ──────────────────────────────────────────────────────────

  Widget _buildDesktop() {
    return Scaffold(
      backgroundColor: WsColors.sidebarBg,
      body: Row(children: [
        _Sidebar(selectedIndex: _selectedIndex, onSelected: _onDestinationSelected),
        // Content area — has its own background
        Expanded(
          child: ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft:     Radius.circular(12),
              bottomLeft:  Radius.circular(12),
            ),
            child: widget.child,
          ),
        ),
      ]),
    );
  }

  // ── Tablet rail ──────────────────────────────────────────────────────────────

  Widget _buildRail() {
    final theme = Theme.of(context);
    return Scaffold(
      body: Row(children: [
        Container(
          color: WsColors.sidebarBg,
          child: NavigationRail(
            backgroundColor: WsColors.sidebarBg,
            selectedIndex: _selectedIndex,
            onDestinationSelected: _onDestinationSelected,
            labelType: NavigationRailLabelType.none,
            minWidth: 64,
            selectedIconTheme: const IconThemeData(color: Colors.white, size: 20),
            unselectedIconTheme:
                const IconThemeData(color: WsColors.sidebarText, size: 20),
            indicatorColor: WsColors.sidebarActive,
            leading: Padding(
              padding: const EdgeInsets.only(top: 16, bottom: 8),
              child: _LogoMark(),
            ),
            destinations: appDestinations
                .map((d) => NavigationRailDestination(
                      icon: d.icon,
                      selectedIcon: d.selectedIcon,
                      label: Text(d.label,
                          style: const TextStyle(
                              fontSize: 10, color: WsColors.sidebarText)),
                    ))
                .toList(),
          ),
        ),
        Container(width: 1, color: WsColors.sidebarBorder),
        Expanded(child: widget.child),
      ]),
    );
  }

  // ── Mobile ──────────────────────────────────────────────────────────────────

  Widget _buildMobile() {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(appDestinations[_selectedIndex].label),
        actions: [_ThemeToggleButton(), const SizedBox(width: 8)],
      ),
      drawer: _MobileDrawer(
        selectedIndex: _selectedIndex,
        onSelected: (i) {
          Navigator.of(context).pop();
          _onDestinationSelected(i);
        },
      ),
      body: widget.child,
    );
  }
}

// ── Sidebar ──────────────────────────────────────────────────────────────────

class _Sidebar extends ConsumerWidget {
  const _Sidebar({required this.selectedIndex, required this.onSelected});

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth      = ref.watch(authProvider);
    final sub       = ref.watch(subscriptionProvider);
    final themeMode = ref.watch(themeModeProvider);

    return Container(
      width: 248,
      color: WsColors.sidebarBg,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // ── Brand header ────────────────────────────────────────────────────
        _SidebarHeader(sub: sub),

        // ── Nav items ───────────────────────────────────────────────────────
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            children: _buildNavItems(context),
          ),
        ),

        // ── Trial banner ─────────────────────────────────────────────────────
        sub.maybeWhen(
          data: (s) => s.isTrial ? _TrialBanner(daysLeft: s.daysRemaining) : const SizedBox.shrink(),
          orElse: () => const SizedBox.shrink(),
        ),

        // ── User footer ──────────────────────────────────────────────────────
        Container(
          height: 1,
          color: WsColors.sidebarBorder,
        ),
        _SidebarUserFooter(
          user: auth.user,
          themeMode: themeMode,
          onToggleTheme: () {
            ref.read(themeModeProvider.notifier).state =
                themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
          },
          onLogout: () => ref.read(authProvider.notifier).logout(),
        ),
      ]),
    );
  }

  List<Widget> _buildNavItems(BuildContext context) {
    final items     = <Widget>[];
    String? lastGrp;

    for (var i = 0; i < appDestinations.length; i++) {
      final dest = appDestinations[i];

      if (dest.groupLabel != null && dest.groupLabel != lastGrp) {
        if (lastGrp != null) items.add(const SizedBox(height: 6));
        items.add(_SectionLabel(label: dest.groupLabel!));
        lastGrp = dest.groupLabel;
      }

      items.add(_SidebarNavItem(
        destination: dest,
        isSelected:  selectedIndex == i,
        onTap:       () => onSelected(i),
      ));
    }
    return items;
  }
}

// ── Sidebar header ────────────────────────────────────────────────────────────

class _SidebarHeader extends StatelessWidget {
  const _SidebarHeader({required this.sub});
  final AsyncValue<dynamic> sub;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(children: [
        _LogoMark(),
        const SizedBox(width: 10),
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('WinSoft',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    letterSpacing: -0.2)),
            sub.maybeWhen(
              data: (s) => Text(
                'Plan ${s.plan.name}${s.isTrial ? "  •  Essai" : ""}',
                style: const TextStyle(
                    color: WsColors.blue400,
                    fontSize: 11,
                    fontWeight: FontWeight.w600),
              ),
              orElse: () => const SizedBox.shrink(),
            ),
          ],
        ),
      ]),
    );
  }
}

class _LogoMark extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [WsColors.blue500, WsColors.blue700],
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(Icons.business_center_rounded,
          color: Colors.white, size: 16),
    );
  }
}

// ── Section label ─────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 12, 10, 4),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          color: WsColors.sidebarLabel,
          letterSpacing: 0.7,
        ),
      ),
    );
  }
}

// ── Nav item ──────────────────────────────────────────────────────────────────

class _SidebarNavItem extends StatefulWidget {
  const _SidebarNavItem({
    required this.destination,
    required this.isSelected,
    required this.onTap,
  });

  final NavDestination destination;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  State<_SidebarNavItem> createState() => _SidebarNavItemState();
}

class _SidebarNavItemState extends State<_SidebarNavItem> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final sel   = widget.isSelected;
    final hover = _hovering && !sel;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovering = true),
        onExit:  (_) => setState(() => _hovering = false),
        cursor:  SystemMouseCursors.click,
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            decoration: BoxDecoration(
              color: sel
                  ? WsColors.sidebarActive
                  : hover
                      ? WsColors.sidebarHover.withValues(alpha: 0.7)
                      : Colors.transparent,
              borderRadius: BorderRadius.circular(7),
              border: sel
                  ? Border(
                      left: BorderSide(
                        color: WsColors.sidebarActiveBorder,
                        width: 2.5,
                      ),
                    )
                  : null,
            ),
            padding: EdgeInsets.only(
              left: sel ? 10 : 12,
              right: 12,
              top: 8,
              bottom: 8,
            ),
            child: Row(children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 150),
                child: IconTheme(
                  key: ValueKey(sel),
                  data: IconThemeData(
                    color: sel
                        ? Colors.white
                        : hover
                            ? const Color(0xFFCBD5E1)
                            : WsColors.sidebarText,
                    size: 17,
                  ),
                  child: sel
                      ? widget.destination.selectedIcon
                      : widget.destination.icon,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                widget.destination.label,
                style: TextStyle(
                  color: sel
                      ? Colors.white
                      : hover
                          ? const Color(0xFFCBD5E1)
                          : WsColors.sidebarText,
                  fontSize: 13.5,
                  fontWeight: sel ? FontWeight.w600 : FontWeight.w400,
                  letterSpacing: -0.1,
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

// ── Trial banner ──────────────────────────────────────────────────────────────

class _TrialBanner extends StatelessWidget {
  const _TrialBanner({required this.daysLeft});
  final int daysLeft;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(10, 0, 10, 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: WsColors.blue900.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: WsColors.blue700.withValues(alpha: 0.5)),
      ),
      child: Row(children: [
        const Icon(Icons.auto_awesome, size: 14, color: WsColors.amber500),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'Essai gratuit — $daysLeft j. restants',
            style: const TextStyle(
                fontSize: 12, color: Colors.white, fontWeight: FontWeight.w500),
          ),
        ),
        GestureDetector(
          onTap: () => context.go('/subscription'),
          child: const Text('Passer au Pro →',
              style: TextStyle(
                  fontSize: 11,
                  color: WsColors.blue400,
                  fontWeight: FontWeight.w700)),
        ),
      ]),
    );
  }
}

// ── User footer ───────────────────────────────────────────────────────────────

class _SidebarUserFooter extends StatelessWidget {
  const _SidebarUserFooter({
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

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(children: [
        // Avatar
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [WsColors.blue600, WsColors.blue700],
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(initials.toUpperCase(),
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 12)),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(user!.name,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 13),
                  overflow: TextOverflow.ellipsis),
              Text(AppUser.roleLabel(user!.role),
                  style: const TextStyle(
                      color: WsColors.sidebarText,
                      fontSize: 11),
                  overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
        // Theme toggle
        _SidebarIconButton(
          icon: themeMode == ThemeMode.dark
              ? Icons.light_mode_outlined
              : Icons.dark_mode_outlined,
          tooltip: 'Thème',
          onTap: onToggleTheme,
        ),
        const SizedBox(width: 2),
        // Logout
        _SidebarIconButton(
          icon: Icons.logout_rounded,
          tooltip: 'Déconnexion',
          color: const Color(0xFFF87171),
          onTap: onLogout,
        ),
      ]),
    );
  }
}

class _SidebarIconButton extends StatefulWidget {
  const _SidebarIconButton({
    required this.icon,
    required this.onTap,
    required this.tooltip,
    this.color,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;
  final Color? color;

  @override
  State<_SidebarIconButton> createState() => _SidebarIconButtonState();
}

class _SidebarIconButtonState extends State<_SidebarIconButton> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit:  (_) => setState(() => _hovering = false),
      cursor:  SystemMouseCursors.click,
      child: Tooltip(
        message: widget.tooltip,
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: _hovering
                  ? WsColors.sidebarHover
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(widget.icon,
                size: 16,
                color: widget.color ?? WsColors.sidebarText),
          ),
        ),
      ),
    );
  }
}

// ── Mobile drawer ─────────────────────────────────────────────────────────────

class _MobileDrawer extends StatelessWidget {
  const _MobileDrawer({required this.selectedIndex, required this.onSelected});

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: WsColors.sidebarBg,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      child: Column(children: [
        const SizedBox(height: 56),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [WsColors.blue500, WsColors.blue700],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.business_center_rounded,
                  color: Colors.white, size: 17),
            ),
            const SizedBox(width: 10),
            const Text('WinSoft',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 18)),
          ]),
        ),
        const Divider(color: WsColors.sidebarBorder, height: 1),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            itemCount: appDestinations.length,
            itemBuilder: (ctx, i) {
              final dest = appDestinations[i];
              final sel  = selectedIndex == i;
              return _SidebarNavItem(
                destination: dest,
                isSelected: sel,
                onTap: () => onSelected(i),
              );
            },
          ),
        ),
      ]),
    );
  }
}

// ── Theme toggle (mobile AppBar) ──────────────────────────────────────────────

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
