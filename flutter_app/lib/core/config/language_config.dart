/// Language configuration for the grammar checker.
///
/// Defines supported languages with display names and flags.
class LanguageConfig {
  final String code;
  final String name;
  final String nativeName;
  final String flag;

  const LanguageConfig({
    required this.code,
    required this.name,
    required this.nativeName,
    required this.flag,
  });
}

/// All supported languages.
const List<LanguageConfig> supportedLanguages = [
  LanguageConfig(
    code: 'nl',
    name: 'Dutch',
    nativeName: 'Nederlands',
    flag: '🇳🇱',
  ),
  LanguageConfig(
    code: 'en',
    name: 'English',
    nativeName: 'English',
    flag: '🇬🇧',
  ),
  LanguageConfig(
    code: 'de',
    name: 'German',
    nativeName: 'Deutsch',
    flag: '🇩🇪',
  ),
  LanguageConfig(
    code: 'fr',
    name: 'French',
    nativeName: 'Français',
    flag: '🇫🇷',
  ),
  LanguageConfig(
    code: 'es',
    name: 'Spanish',
    nativeName: 'Español',
    flag: '🇪🇸',
  ),
];

/// Get language config by code.
LanguageConfig? getLanguageConfig(String code) {
  try {
    return supportedLanguages.firstWhere((lang) => lang.code == code);
  } catch (_) {
    return null;
  }
}

/// Default language.
const LanguageConfig defaultLanguage = LanguageConfig(
  code: 'nl',
  name: 'Dutch',
  nativeName: 'Nederlands',
  flag: '🇳🇱',
);
