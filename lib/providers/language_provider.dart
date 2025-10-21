import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/language.dart';
import '../constants/app_translations.dart';

/// Provider for managing app language state
class LanguageProvider with ChangeNotifier {
  static const String _languageKey = 'app_language';

  Language _currentLanguage = AppLanguages.english;

  Language get currentLanguage => _currentLanguage;
  String get languageCode => _currentLanguage.code;

  /// Initialize language from stored preference
  Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedLanguageCode = prefs.getString(_languageKey);

      if (savedLanguageCode != null) {
        _currentLanguage = AppLanguages.fromCode(savedLanguageCode);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error initializing language: $e');
    }
  }

  /// Change the app language
  Future<void> changeLanguage(Language language) async {
    if (_currentLanguage == language) return;

    _currentLanguage = language;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_languageKey, language.code);
    } catch (e) {
      debugPrint('Error saving language preference: $e');
    }
  }

  /// Get translated text for a key
  String translate(String key) {
    return AppTranslations.get(key, _currentLanguage.code);
  }

  /// Shorthand method for translation (can be used as tr('key'))
  String tr(String key) {
    return translate(key);
  }
}
