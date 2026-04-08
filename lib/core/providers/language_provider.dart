import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../l10n/app_translations.dart';

/// Persisted language preference: 'fr' | 'ar' | 'en'
class LanguageNotifier extends AsyncNotifier<String> {
  static const _key = 'app_language';

  @override
  Future<String> build() async {
    final prefs = await SharedPreferences.getInstance();
    final lang = prefs.getString(_key) ?? 'fr';
    AppTranslations.setLanguage(lang);
    return lang;
  }

  Future<void> setLanguage(String lang) async {
    AppTranslations.setLanguage(lang);
    state = AsyncValue.data(lang);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, lang);
  }
}

final languageProvider =
    AsyncNotifierProvider<LanguageNotifier, String>(LanguageNotifier.new);
