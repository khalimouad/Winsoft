import 'package:flutter/material.dart';
import '../../app/theme.dart';

// ── Page Header ───────────────────────────────────────────────────────────────
//
// Consistent top section for every page.
//
//  Title            [actions...]
//  Subtitle

class WsPageHeader extends StatelessWidget {
  const WsPageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actions = const [],
    this.bottom,
  });

  final String title;
  final String? subtitle;
  final List<Widget> actions;
  final Widget? bottom;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w700, letterSpacing: -0.3)),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(subtitle!,
                          style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant)),
                    ],
                  ],
                ),
              ),
              if (actions.isNotEmpty) ...[
                const SizedBox(width: 16),
                Row(
                    mainAxisSize: MainAxisSize.min,
                    children: actions
                        .expand((w) => [w, const SizedBox(width: 8)])
                        .toList()
                      ..removeLast()),
              ],
            ],
          ),
        ),
        if (bottom != null) bottom!,
      ],
    );
  }
}

// ── WsBadge (status chip) ─────────────────────────────────────────────────────

class WsBadge extends StatelessWidget {
  const WsBadge({
    super.key,
    required this.label,
    required this.color,
    this.dot = false,
    this.size = WsBadgeSize.medium,
  });

  final String label;
  final Color color;
  final bool dot;
  final WsBadgeSize size;

  @override
  Widget build(BuildContext context) {
    final fontSize = size == WsBadgeSize.small ? 11.0 : 12.0;
    final hPad     = size == WsBadgeSize.small ? 7.0 : 9.0;
    final vPad     = size == WsBadgeSize.small ? 2.0 : 3.0;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (dot) ...[
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
        ],
        Text(label,
            style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.w600,
                color: color)),
      ]),
    );
  }

  // ── Preset factories ──────────────────────────────────────────────────────

  factory WsBadge.invoiceStatus(String status, {WsBadgeSize size = WsBadgeSize.medium}) {
    final c = switch (status) {
      'Payée'      => WsColors.green600,
      'Envoyée'    => WsColors.blue600,
      'En retard'  => WsColors.red600,
      'Brouillon'  => WsColors.slate500,
      _            => WsColors.slate500,
    };
    return WsBadge(label: status, color: c, dot: true, size: size);
  }

  factory WsBadge.supplierStatus(String status, {WsBadgeSize size = WsBadgeSize.medium}) {
    final c = switch (status) {
      'Payée'      => WsColors.green600,
      'Validée'    => WsColors.blue600,
      'Reçue'      => WsColors.slate500,
      'Contestée'  => WsColors.orange500,
      'Annulée'    => WsColors.red600,
      _            => WsColors.slate500,
    };
    return WsBadge(label: status, color: c, dot: true, size: size);
  }

  factory WsBadge.orderStatus(String status, {WsBadgeSize size = WsBadgeSize.medium}) {
    final c = switch (status) {
      'Livré'      => WsColors.green600,
      'Confirmé'   => WsColors.blue600,
      'En attente' => WsColors.amber500,
      'Annulé'     => WsColors.red600,
      _            => WsColors.slate500,
    };
    return WsBadge(label: status, color: c, dot: true, size: size);
  }

  factory WsBadge.leaveStatus(String status) {
    final c = switch (status) {
      'Approuvé'   => WsColors.green600,
      'En attente' => WsColors.amber500,
      'Refusé'     => WsColors.red600,
      'Annulé'     => WsColors.slate500,
      _            => WsColors.slate500,
    };
    return WsBadge(label: status, color: c, dot: true);
  }
}

enum WsBadgeSize { small, medium }

// ── WsCard ────────────────────────────────────────────────────────────────────
// A styled card with consistent shadow + border + rounded corners.

class WsCard extends StatelessWidget {
  const WsCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.radius = 16.0,
    this.clip = true,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final bool clip;

  @override
  Widget build(BuildContext context) {
    final theme  = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: isDark ? WsColors.slate700 : WsColors.slate200,
        ),
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.black : WsColors.slate400)
                .withValues(alpha: isDark ? 0.2 : 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: clip ? Clip.antiAlias : Clip.none,
      child: Padding(padding: padding, child: child),
    );
  }
}

// ── WsEmptyState ──────────────────────────────────────────────────────────────

class WsEmptyState extends StatelessWidget {
  const WsEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.action,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(icon,
                size: 28, color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 16),
          Text(title,
              style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600)),
          if (subtitle != null) ...[
            const SizedBox(height: 6),
            Text(subtitle!,
                style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant),
                textAlign: TextAlign.center),
          ],
          if (action != null) ...[
            const SizedBox(height: 20),
            action!,
          ],
        ],
      ),
    );
  }
}

// ── WsSectionTitle ────────────────────────────────────────────────────────────

class WsSectionTitle extends StatelessWidget {
  const WsSectionTitle(this.title, {super.key, this.trailing});
  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title,
              style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600)),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

// ── WsDataTable ───────────────────────────────────────────────────────────────
// A styled data table wrapper with hover states.

class WsTable extends StatelessWidget {
  const WsTable({
    super.key,
    required this.columns,
    required this.rows,
  });

  final List<DataColumn> columns;
  final List<DataRow> rows;

  @override
  Widget build(BuildContext context) {
    final theme  = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return WsCard(
      padding: EdgeInsets.zero,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(
              isDark ? WsColors.slate800 : WsColors.slate50),
          headingTextStyle: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.6,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          dataRowColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.hovered)) {
              return isDark
                  ? WsColors.slate700.withValues(alpha: 0.4)
                  : WsColors.slate50;
            }
            return null;
          }),
          columns: columns,
          rows: rows,
        ),
      ),
    );
  }
}

// ── WsSearchBar ───────────────────────────────────────────────────────────────

class WsSearchBar extends StatelessWidget {
  const WsSearchBar({
    super.key,
    required this.onChanged,
    this.hint = 'Rechercher…',
    this.width,
  });

  final ValueChanged<String> onChanged;
  final String hint;
  final double? width;

  @override
  Widget build(BuildContext context) {
    final theme  = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    Widget field = TextField(
      onChanged: onChanged,
      style: theme.textTheme.bodyMedium,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
        prefixIcon: Icon(Icons.search_rounded,
            size: 18, color: theme.colorScheme.onSurfaceVariant),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        isDense: true,
        filled: true,
        fillColor: isDark ? WsColors.slate800 : WsColors.slate50,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
              color: isDark ? WsColors.slate700 : WsColors.slate200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: theme.colorScheme.primary, width: 1.5),
        ),
      ),
    );

    return width != null ? SizedBox(width: width, child: field) : field;
  }
}

// ── WsDivider ─────────────────────────────────────────────────────────────────

class WsDivider extends StatelessWidget {
  const WsDivider({super.key, this.vertical = false});
  final bool vertical;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.outlineVariant;
    return vertical
        ? Container(width: 1, color: color)
        : Container(height: 1, color: color);
  }
}

// ── WsActionButton (icon + label) ─────────────────────────────────────────────

class WsButton extends StatelessWidget {
  const WsButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.style = WsButtonStyle.filled,
    this.small = false,
    this.destructive = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final WsButtonStyle style;
  final bool small;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final vPad  = small ? 8.0 : 12.0;
    final hPad  = small ? 12.0 : 16.0;
    final fSize = small ? 13.0 : 14.0;

    Widget child = icon != null
        ? Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: small ? 15 : 17),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(fontSize: fSize, fontWeight: FontWeight.w600)),
          ])
        : Text(label, style: TextStyle(fontSize: fSize, fontWeight: FontWeight.w600));

    final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(12));
    final padding = EdgeInsets.symmetric(horizontal: hPad, vertical: vPad);

    switch (style) {
      case WsButtonStyle.filled:
        final bg = destructive ? WsColors.red600 : theme.colorScheme.primary;
        return FilledButton(
          style: FilledButton.styleFrom(
              backgroundColor: bg,
              foregroundColor: Colors.white,
              padding: padding,
              shape: shape,
              elevation: 0),
          onPressed: onPressed,
          child: child,
        );

      case WsButtonStyle.outlined:
        return OutlinedButton(
          style: OutlinedButton.styleFrom(
              foregroundColor: destructive ? WsColors.red600 : theme.colorScheme.primary,
              side: BorderSide(
                  color: destructive
                      ? WsColors.red600
                      : theme.colorScheme.outline.withValues(alpha: 0.6)),
              padding: padding,
              shape: shape),
          onPressed: onPressed,
          child: child,
        );

      case WsButtonStyle.ghost:
        return TextButton(
          style: TextButton.styleFrom(
              foregroundColor: destructive ? WsColors.red600 : theme.colorScheme.primary,
              padding: padding,
              shape: shape),
          onPressed: onPressed,
          child: child,
        );
    }
  }
}

enum WsButtonStyle { filled, outlined, ghost }
