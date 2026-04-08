import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'router.dart';
import 'theme.dart';
import '../core/providers/language_provider.dart';
import '../l10n/app_translations.dart';

final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.light);

class WinsoftApp extends ConsumerWidget {
  const WinsoftApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final router = buildRouter(ref);

    // Watch language and update AppTranslations singleton
    final langAsync = ref.watch(languageProvider);
    final lang = langAsync.maybeWhen(data: (l) => l, orElse: () => 'fr');
    AppTranslations.setLanguage(lang);

    return Directionality(
      textDirection: AppTranslations.textDirection,
      child: MaterialApp.router(
        title: 'WinSoft',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: themeMode,
        routerConfig: router,
        // Pass locale so intl formatters follow lang
        locale: Locale(lang),
        supportedLocales: const [Locale('fr'), Locale('ar'), Locale('en')],
      ),
    );
  }
}
