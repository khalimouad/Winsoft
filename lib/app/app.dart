import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'router.dart';
import 'theme.dart';

final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.light);

class WinsoftApp extends ConsumerWidget {
  const WinsoftApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final router = buildRouter(ref);

    return MaterialApp.router(
      title: 'WinSoft',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}
