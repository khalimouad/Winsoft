import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Design tokens — import this anywhere you need raw color values
abstract class WsColors {
  // Brand
  static const blue50  = Color(0xFFEFF6FF);
  static const blue100 = Color(0xFFDBEAFE);
  static const blue400 = Color(0xFF60A5FA);
  static const blue500 = Color(0xFF3B82F6);
  static const blue600 = Color(0xFF2563EB);
  static const blue700 = Color(0xFF1D4ED8);
  static const blue900 = Color(0xFF1E3A8A);

  // Slate scale (neutral)
  static const slate50  = Color(0xFFF8FAFC);
  static const slate100 = Color(0xFFF1F5F9);
  static const slate200 = Color(0xFFE2E8F0);
  static const slate300 = Color(0xFFCBD5E1);
  static const slate400 = Color(0xFF94A3B8);
  static const slate500 = Color(0xFF64748B);
  static const slate600 = Color(0xFF475569);
  static const slate700 = Color(0xFF334155);
  static const slate800 = Color(0xFF1E293B);
  static const slate900 = Color(0xFF0F172A);
  static const slate950 = Color(0xFF020617);

  // Semantic
  static const green400 = Color(0xFF4ADE80);
  static const green500 = Color(0xFF22C55E);
  static const green600 = Color(0xFF16A34A);
  static const orange400 = Color(0xFFFB923C);
  static const orange500 = Color(0xFFF97316);
  static const red400 = Color(0xFFF87171);
  static const red500 = Color(0xFFEF4444);
  static const red600 = Color(0xFFDC2626);
  static const purple500 = Color(0xFFA855F7);
  static const teal500 = Color(0xFF14B8A6);
  static const amber500 = Color(0xFFF59E0B);

  // Sidebar (always dark)
  static const sidebarBg       = slate900;
  static const sidebarBorder   = slate800;
  static const sidebarHover    = slate800;
  static const sidebarActive   = Color(0x26407BFF); // blue-600 @ 15%
  static const sidebarActiveBorder = blue500;
  static const sidebarText     = slate400;
  static const sidebarTextActive = Colors.white;
  static const sidebarLabel    = slate600;
}

class AppTheme {
  AppTheme._();

  static TextTheme _textTheme(ColorScheme scheme) {
    final base = GoogleFonts.interTextTheme();
    return base.copyWith(
      displayLarge:   base.displayLarge?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.5, color: scheme.onSurface),
      displayMedium:  base.displayMedium?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.5, color: scheme.onSurface),
      displaySmall:   base.displaySmall?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.5, color: scheme.onSurface),
      headlineLarge:  base.headlineLarge?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.3, color: scheme.onSurface),
      headlineMedium: base.headlineMedium?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.3, color: scheme.onSurface),
      headlineSmall:  base.headlineSmall?.copyWith(fontWeight: FontWeight.w600, letterSpacing: -0.2, color: scheme.onSurface),
      titleLarge:     base.titleLarge?.copyWith(fontWeight: FontWeight.w600, letterSpacing: -0.1, color: scheme.onSurface),
      titleMedium:    base.titleMedium?.copyWith(fontWeight: FontWeight.w600, color: scheme.onSurface),
      titleSmall:     base.titleSmall?.copyWith(fontWeight: FontWeight.w600, color: scheme.onSurface),
      bodyLarge:      base.bodyLarge?.copyWith(color: scheme.onSurface),
      bodyMedium:     base.bodyMedium?.copyWith(color: scheme.onSurface),
      bodySmall:      base.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
      labelLarge:     base.labelLarge?.copyWith(fontWeight: FontWeight.w600, letterSpacing: 0.1),
      labelMedium:    base.labelMedium?.copyWith(fontWeight: FontWeight.w500),
      labelSmall:     base.labelSmall?.copyWith(fontWeight: FontWeight.w600, letterSpacing: 0.8),
    );
  }

  static ThemeData light() {
    final base = ColorScheme.fromSeed(
      seedColor: WsColors.blue600,
      brightness: Brightness.light,
    ).copyWith(
      primary:                WsColors.blue600,
      onPrimary:              Colors.white,
      primaryContainer:       WsColors.blue50,
      onPrimaryContainer:     WsColors.blue700,
      secondary:              WsColors.slate700,
      onSecondary:            Colors.white,
      secondaryContainer:     WsColors.slate100,
      onSecondaryContainer:   WsColors.slate800,
      surface:                Colors.white,
      onSurface:              WsColors.slate900,
      surfaceContainerLowest: WsColors.slate50,
      surfaceContainerLow:    WsColors.slate50,
      surfaceContainer:       WsColors.slate100,
      surfaceContainerHigh:   WsColors.slate100,
      surfaceContainerHighest:WsColors.slate200,
      onSurfaceVariant:       WsColors.slate500,
      outline:                WsColors.slate300,
      outlineVariant:         WsColors.slate200,
      error:                  WsColors.red600,
      errorContainer:         const Color(0xFFFEF2F2),
      onErrorContainer:       WsColors.red600,
      scrim:                  Colors.black,
    );

    return _buildTheme(base);
  }

  static ThemeData dark() {
    final base = ColorScheme.fromSeed(
      seedColor: WsColors.blue600,
      brightness: Brightness.dark,
    ).copyWith(
      primary:                WsColors.blue400,
      onPrimary:              WsColors.slate900,
      primaryContainer:       WsColors.blue900,
      onPrimaryContainer:     WsColors.blue100,
      secondary:              WsColors.slate400,
      onSecondary:            WsColors.slate900,
      secondaryContainer:     WsColors.slate800,
      onSecondaryContainer:   WsColors.slate100,
      surface:                WsColors.slate800,
      onSurface:              WsColors.slate50,
      surfaceContainerLowest: WsColors.slate900,
      surfaceContainerLow:    const Color(0xFF18202E),
      surfaceContainer:       WsColors.slate800,
      surfaceContainerHigh:   WsColors.slate700,
      surfaceContainerHighest:WsColors.slate700,
      onSurfaceVariant:       WsColors.slate400,
      outline:                WsColors.slate600,
      outlineVariant:         WsColors.slate700,
      error:                  WsColors.red400,
      errorContainer:         const Color(0xFF450A0A),
      onErrorContainer:       WsColors.red400,
    );

    return _buildTheme(base);
  }

  static ThemeData _buildTheme(ColorScheme scheme) {
    final isDark = scheme.brightness == Brightness.dark;
    final text   = _textTheme(scheme);

    // Shared shadow
    final cardShadow = [
      BoxShadow(
        color: (isDark ? Colors.black : const Color(0xFF64748B)).withValues(alpha: isDark ? 0.3 : 0.06),
        blurRadius: 8,
        spreadRadius: 0,
        offset: const Offset(0, 2),
      ),
      BoxShadow(
        color: (isDark ? Colors.black : const Color(0xFF64748B)).withValues(alpha: isDark ? 0.2 : 0.04),
        blurRadius: 3,
        spreadRadius: 0,
        offset: const Offset(0, 1),
      ),
    ];

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      textTheme: text,
      scaffoldBackgroundColor: scheme.surfaceContainerLowest,

      // AppBar — flat, no elevation
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        titleTextStyle: text.titleLarge?.copyWith(fontWeight: FontWeight.w600),
        surfaceTintColor: Colors.transparent,
      ),

      // Cards — white, shadow, no border
      cardTheme: CardThemeData(
        elevation: 0,
        color: scheme.surface,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(
            color: isDark ? WsColors.slate700 : WsColors.slate200,
            width: 1,
          ),
        ),
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
      ),

      // Elevated button
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          elevation: 0,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: text.labelLarge,
        ),
      ),

      // Filled button
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          elevation: 0,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: text.labelLarge?.copyWith(fontSize: 14),
        ),
      ),

      // Outlined button
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: scheme.primary,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          side: BorderSide(color: scheme.outline.withValues(alpha: 0.6)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: text.labelLarge?.copyWith(fontSize: 14),
        ),
      ),

      // Text button
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: scheme.primary,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
      ),

      // Input fields — clean bordered style
      inputDecorationTheme: InputDecorationTheme(
        filled: false,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: scheme.outline.withValues(alpha: 0.6)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: scheme.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: scheme.error),
        ),
        labelStyle: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
        hintStyle: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant.withValues(alpha: 0.6)),
        isDense: true,
      ),

      // Chips
      chipTheme: ChipThemeData(
        backgroundColor: scheme.surfaceContainerHigh,
        side: BorderSide(color: scheme.outlineVariant),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        labelStyle: text.labelMedium,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        selectedColor: scheme.primaryContainer,
        checkmarkColor: scheme.primary,
      ),

      // Tab bar
      tabBarTheme: TabBarThemeData(
        labelColor: scheme.primary,
        unselectedLabelColor: scheme.onSurfaceVariant,
        indicatorColor: scheme.primary,
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: scheme.outlineVariant,
        labelStyle: text.labelLarge?.copyWith(fontSize: 14),
        unselectedLabelStyle: text.labelLarge?.copyWith(
            fontSize: 14, fontWeight: FontWeight.w500),
      ),

      // Dialog
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),

      // Popup menu
      popupMenuTheme: PopupMenuThemeData(
        color: scheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: scheme.outlineVariant),
        ),
        textStyle: text.bodyMedium,
      ),

      // Divider
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant,
        thickness: 1,
        space: 0,
      ),

      // Navigation rail
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: scheme.surface,
        indicatorColor: scheme.primaryContainer,
        labelType: NavigationRailLabelType.all,
        selectedLabelTextStyle: text.labelSmall?.copyWith(
            color: scheme.primary, fontWeight: FontWeight.w600),
        unselectedLabelTextStyle: text.labelSmall?.copyWith(
            color: scheme.onSurfaceVariant),
      ),

      // Snackbar
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isDark ? WsColors.slate700 : WsColors.slate800,
        contentTextStyle: text.bodyMedium?.copyWith(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        elevation: 0,
      ),

      // List tile
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        titleTextStyle: text.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
        subtitleTextStyle: text.bodySmall,
        dense: true,
        minVerticalPadding: 8,
      ),

      // Data table
      dataTableTheme: DataTableThemeData(
        headingTextStyle: text.labelSmall?.copyWith(
          letterSpacing: 0.6,
          fontWeight: FontWeight.w700,
          color: scheme.onSurfaceVariant,
        ),
        dataTextStyle: text.bodyMedium,
        headingRowColor: WidgetStateProperty.all(scheme.surfaceContainerLowest),
        dividerThickness: 1,
        horizontalMargin: 20,
        columnSpacing: 20,
        headingRowHeight: 48,
        dataRowMinHeight: 52,
        dataRowMaxHeight: 64,
      ),
    );
  }
}
