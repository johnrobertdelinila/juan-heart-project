import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:juan_heart/core/constants/languages.dart';

/// Language Controller with Persistent Preference Storage
///
/// Manages app language preference using GetX and SharedPreferences
/// Language preference persists across app restarts
class LangController extends GetxController {
  static const String _languagePreferenceKey = 'app_language_code';

  String _languageCode = "en";

  final List<dynamic> _options = Languages.options;
  List<dynamic> get options => _options;

  String get getLanguageCode => _languageCode;

  @override
  void onInit() {
    super.onInit();
    _loadLanguagePreference();
  }

  /// Load saved language preference from SharedPreferences
  ///
  /// Called automatically when controller initializes
  /// Falls back to 'en' if no preference is saved
  Future<void> _loadLanguagePreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedLanguage = prefs.getString(_languagePreferenceKey);

      if (savedLanguage != null && savedLanguage.isNotEmpty) {
        _languageCode = savedLanguage;
        update();
      }
    } catch (e) {
      print('Error loading language preference: $e');
      // Continue with default language (en) if load fails
    }
  }

  /// Set language code and save preference
  ///
  /// Updates the language code, persists to SharedPreferences,
  /// and updates GetX locale
  Future<void> setLanguagecode(String data) async {
    _languageCode = data;
    update();

    // Save preference to SharedPreferences
    await _saveLanguagePreference(data);
  }

  /// Save language preference to SharedPreferences
  ///
  /// Persists language choice across app restarts
  Future<void> _saveLanguagePreference(String languageCode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_languagePreferenceKey, languageCode);
    } catch (e) {
      print('Error saving language preference: $e');
    }
  }

  /// Get saved language preference
  ///
  /// Returns saved language code or null if not set
  /// Useful for initializing GetX locale on app startup
  static Future<String?> getSavedLanguagePreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_languagePreferenceKey);
    } catch (e) {
      print('Error getting saved language preference: $e');
      return null;
    }
  }
}
