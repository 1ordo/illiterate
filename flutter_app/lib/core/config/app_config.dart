/// Application configuration.
///
/// Centralized configuration for the grammar checker app.
/// Modify these values for different environments.
class AppConfig {
  AppConfig._();

  /// Backend API URL
  /// Change this to your backend URL
  static const String apiBaseUrl = 'http://localhost:8001';

  /// Request timeout in milliseconds
  static const int requestTimeout = 30000;

  /// Maximum text length for checking
  static const int maxTextLength = 10000;

  /// Default language code
  static const String defaultLanguage = 'nl';

  /// Enable debug logging
  static const bool debugMode = true;

  /// App version
  static const String version = '1.0.0';
}
