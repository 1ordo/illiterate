import 'package:flutter/foundation.dart';

/// Application configuration.
///
/// Centralized configuration for the ileterate grammar checker app.
/// Configuration is loaded from environment variables or compile-time defines.
class AppConfig {
  AppConfig._();

  /// Backend API URL
  /// Override with --dart-define=API_BASE_URL=https://your-api.com
  static String get apiBaseUrl {
    const url = String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: 'https://illiterate.moke.studio',
    );
    return url;
  }

  /// API Key for authentication
  /// Override with --dart-define=API_KEY=your-key
  static String? get apiKey {
    const key = String.fromEnvironment('API_KEY', defaultValue: '');
    return key.isEmpty ? null : key;
  }

  /// Enable end-to-end encryption
  /// Override with --dart-define=ENCRYPTION_ENABLED=true
  static bool get encryptionEnabled {
    const enabled = String.fromEnvironment(
      'ENCRYPTION_ENABLED',
      defaultValue: 'false',
    );
    return enabled.toLowerCase() == 'true';
  }

  /// Request timeout in milliseconds
  static const int requestTimeout = 30000;

  /// Maximum text length for checking
  static const int maxTextLength = 10000;

  /// Default language code
  static const String defaultLanguage = 'nl';

  /// Enable debug logging
  static bool get debugMode {
    if (kReleaseMode) return false;
    const debug = String.fromEnvironment('DEBUG', defaultValue: 'true');
    return debug.toLowerCase() == 'true';
  }

  /// App version
  static const String version = '1.0.0';

  /// App name
  static const String appName = 'ileterate';

  /// Validate configuration
  static void validate() {
    if (apiBaseUrl.isEmpty) {
      throw ConfigurationException('API_BASE_URL is required');
    }

    if (encryptionEnabled && apiKey == null) {
      debugPrint(
        'WARNING: Encryption enabled but no API key configured. '
        'This may cause authentication issues.',
      );
    }
  }

  /// Print current configuration (debug only)
  static void printConfig() {
    if (!debugMode) return;

    debugPrint('=== ileterate Configuration ===');
    debugPrint('API Base URL: $apiBaseUrl');
    debugPrint('API Key: ${apiKey != null ? "configured" : "not set"}');
    debugPrint('Encryption: ${encryptionEnabled ? "enabled" : "disabled"}');
    debugPrint('Debug Mode: $debugMode');
    debugPrint('===============================');
  }
}

/// Configuration exception
class ConfigurationException implements Exception {
  final String message;
  const ConfigurationException(this.message);

  @override
  String toString() => 'ConfigurationException: $message';
}
