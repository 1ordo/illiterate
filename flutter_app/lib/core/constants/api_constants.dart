/// API endpoint constants.
class ApiConstants {
  ApiConstants._();

  /// Check grammar endpoint
  static const String check = '/check';

  /// Get supported languages
  static const String languages = '/languages';

  /// Health check endpoint
  static const String health = '/health';
}

/// Check modes.
enum CheckMode {
  strict('strict'),
  style('style');

  final String value;
  const CheckMode(this.value);
}

/// Tone options for rewrites.
enum Tone {
  neutral('neutral', 'Neutral'),
  formal('formal', 'Formal'),
  casual('casual', 'Casual'),
  academic('academic', 'Academic');

  final String value;
  final String displayName;
  const Tone(this.value, this.displayName);
}
