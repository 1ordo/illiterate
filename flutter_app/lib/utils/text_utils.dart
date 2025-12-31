/// Text manipulation utilities.
class TextUtils {
  TextUtils._();

  /// Truncate text to a maximum length with ellipsis.
  static String truncate(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength - 3)}...';
  }

  /// Get word count.
  static int wordCount(String text) {
    if (text.trim().isEmpty) return 0;
    return text.trim().split(RegExp(r'\s+')).length;
  }

  /// Get character count (excluding whitespace).
  static int charCount(String text, {bool includeSpaces = false}) {
    if (includeSpaces) return text.length;
    return text.replaceAll(RegExp(r'\s'), '').length;
  }

  /// Get sentence count.
  static int sentenceCount(String text) {
    if (text.trim().isEmpty) return 0;
    return RegExp(r'[.!?]+').allMatches(text).length;
  }

  /// Get paragraph count.
  static int paragraphCount(String text) {
    if (text.trim().isEmpty) return 0;
    return text.split(RegExp(r'\n\n+')).where((p) => p.trim().isNotEmpty).length;
  }

  /// Extract context around an offset.
  static String getContext(String text, int offset, int length, {int contextSize = 30}) {
    final start = (offset - contextSize).clamp(0, text.length);
    final end = (offset + length + contextSize).clamp(0, text.length);

    String context = text.substring(start, end);

    if (start > 0) context = '...$context';
    if (end < text.length) context = '$context...';

    return context;
  }

  /// Normalize whitespace (collapse multiple spaces, trim).
  static String normalizeWhitespace(String text) {
    return text.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  /// Check if text is mostly uppercase.
  static bool isMostlyUppercase(String text) {
    final letters = text.replaceAll(RegExp(r'[^a-zA-Z]'), '');
    if (letters.isEmpty) return false;

    final uppercase = letters.replaceAll(RegExp(r'[^A-Z]'), '');
    return uppercase.length / letters.length > 0.8;
  }

  /// Split text into chunks by paragraph.
  static List<String> splitByParagraphs(String text) {
    return text.split(RegExp(r'\n\n+')).where((p) => p.trim().isNotEmpty).toList();
  }

  /// Calculate reading time in minutes.
  static double readingTime(String text, {int wordsPerMinute = 200}) {
    final words = wordCount(text);
    return words / wordsPerMinute;
  }

  /// Format reading time as human-readable string.
  static String formatReadingTime(String text) {
    final minutes = readingTime(text);
    if (minutes < 1) return 'Less than 1 min read';
    if (minutes < 2) return '1 min read';
    return '${minutes.round()} min read';
  }
}
