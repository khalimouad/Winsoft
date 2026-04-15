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
    if (w >= 640) return _buildDesktop();
    return _buildMobile();
  }

  // ── Desktop / tablet layout — icon ribbon ────────────────────────────────────

  Widget _buildDesktop() {
    return Scaffold(
      backgroundColor: WsColors.sidebarBg,
      body: Row(children: [
        _Ribbon(
          selectedIndex: _selectedIndex,
          onSelected: _onDestinationSelected,
        ),
        // Rounded content area floating on black sidebar
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

  // ── Mobile ──────────────────────────────────────────────────────────────────

  Widget _buildMobile() {
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

// ── Ribbon sidebar (desktop/tablet) ───────────────────────────────────────────

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
        // Nav items — scrollable
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 4),
            physics: const BouncingScrollPhysics(),
            children: _buildNavItems(context),
          ),
        ),
        // Trial banner (ribbon pill form)
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

      // Thin divider between groups
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

// ── Logo ──────────────────────────────────────────────────────────────────────

class _LogoMark extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [WsColors.blue500, WsColors.blue700],
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: WsColors.blue600.withValues(alpha: 0.35),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const Icon(Icons.business_center_rounded,
          color: Colors.white, size: 20),
    );
  }
}

// ── Ribbon nav item — icon circle + label ────────────────────────────────────

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

    // Icon bubble color
    final Color bubbleColor = sel
        ? WsColors.sidebarIconActive
        : hover
            ? WsColors.sidebarIconHover
            : Colors.transparent;

    // Label color
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
              // Circle with icon
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
              // Label
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
      // Avatar
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
      // Theme toggle
      _CircleIconButton(
        icon: themeMode == ThemeMode.dark
            ? Icons.light_mode_outlined
            : Icons.dark_mode_outlined,
        tooltip: 'Thème',
        onTap: onToggleTheme,
      ),
      const SizedBox(height: 4),
      // Logout
      _CircleIconButton(
        icon: Icons.logout_rounded,
        tooltip: 'Déconnexion',
        hoverColor: WsColors.red500.withValues(alpha: 0.2),
        onTap: onLogout,
      ),
    ]);
  }
}

// ── Circle icon button (hover = blue circle) ─────────────────────────────────

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

class _MobileDrawer extends StatelessWidget {
  const _MobileDrawer({required this.selectedIndex, required this.onSelected});

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: WsColors.sidebarBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Column(children: [
        const SizedBox(height: 56),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          child: Row(children: [
            _LogoMark(),
            const SizedBox(width: 14),
            const Text('WinSoft',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 20,
                  letterSpacing: -0.3,
                )),
          ]),
        ),
        const Divider(color: WsColors.sidebarBorder, height: 1),
        const SizedBox(height: 8),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            itemCount: appDestinations.length,
            itemBuilder: (ctx, i) {
              final dest = appDestinations[i];
              final sel  = selectedIndex == i;
              return _MobileDrawerItem(
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

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovering = true),
        onExit:  (_) => setState(() => _hovering = false),
        cursor:  SystemMouseCursors.click,
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
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
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: sel
                      ? WsColors.sidebarIconActive
                      : Colors.transparent,
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
            ]),
          ),
        ),
      ),
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
