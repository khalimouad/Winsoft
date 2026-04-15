import 'package:flutter/material.dart';

/// Breakpoints and helpers for responsive layouts.
///
/// Mobile  : width < 640
/// Tablet  : 640 ≤ width < 1100
/// Desktop : width ≥ 1100
abstract final class Responsive {
  static const double _mobile  = 640;
  static const double _desktop = 1100;

  static bool isMobile(BuildContext ctx) =>
      MediaQuery.sizeOf(ctx).width < _mobile;

  static bool isTablet(BuildContext ctx) {
    final w = MediaQuery.sizeOf(ctx).width;
    return w >= _mobile && w < _desktop;
  }

  static bool isDesktop(BuildContext ctx) =>
      MediaQuery.sizeOf(ctx).width >= _desktop;

  /// Horizontal/vertical content padding — tighter on mobile.
  static EdgeInsets pagePadding(BuildContext ctx) => isMobile(ctx)
      ? const EdgeInsets.all(16)
      : const EdgeInsets.all(24);

  /// Horizontal content padding only.
  static double hPad(BuildContext ctx) => isMobile(ctx) ? 16 : 24;

  /// Returns [mobile] on small screens, [other] otherwise.
  static T when<T>(BuildContext ctx, {required T mobile, required T other}) =>
      isMobile(ctx) ? mobile : other;

  /// Returns a value linearly picked from 3 breakpoints.
  static T adaptive<T>(
    BuildContext ctx, {
    required T mobile,
    required T tablet,
    required T desktop,
  }) {
    if (isDesktop(ctx)) return desktop;
    if (isTablet(ctx)) return tablet;
    return mobile;
  }
}
