import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Modern application theme with glassmorphism and gradients.
class AppTheme {
  AppTheme._();

  // ===== BRAND COLORS =====
  static const Color primaryPurple = Color(0xFF6366F1);
  static const Color primaryViolet = Color(0xFF8B5CF6);
  static const Color primaryFuchsia = Color(0xFFA855F7);

  // Accent Colors
  static const Color accentCyan = Color(0xFF22D3EE);
  static const Color accentTeal = Color(0xFF06B6D4);
  static const Color accentPink = Color(0xFFF472B6);

  // Semantic Colors
  static const Color errorRed = Color(0xFFEF4444);
  static const Color warningAmber = Color(0xFFF59E0B);
  static const Color successGreen = Color(0xFF10B981);
  static const Color infoBlue = Color(0xFF3B82F6);

  // Grammar Issue Colors
  static const Color grammarError = Color(0xFFEF4444);
  static const Color spellingError = Color(0xFFF59E0B);
  static const Color styleWarning = Color(0xFF8B5CF6);
  static const Color punctuationIssue = Color(0xFF6366F1);
  static const Color llmDetected = Color(0xFF22D3EE);

  // Legacy color aliases for backward compatibility
  static const Color primaryColor = primaryPurple;
  static const Color secondaryColor = primaryViolet;
  static const Color accentColor = accentCyan;
  static const Color errorColor = errorRed;
  static const Color warningColor = warningAmber;
  static const Color successColor = successGreen;

  // ===== GRADIENTS =====
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryPurple, primaryViolet, primaryFuchsia],
  );

  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [accentCyan, accentTeal],
  );

  static const LinearGradient darkGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF1E1B4B), Color(0xFF0F0D1A)],
  );

  static const LinearGradient lightGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFF8FAFC), Color(0xFFE0E7FF)],
  );

  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFFFFF), Color(0xFFF1F5F9)],
  );

  // ===== SHADOWS =====
  static List<BoxShadow> get softShadow => [
        BoxShadow(
          color: primaryPurple.withOpacity(0.1),
          blurRadius: 20,
          offset: const Offset(0, 10),
        ),
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 24,
          offset: const Offset(0, 8),
        ),
      ];

  static List<BoxShadow> get glowShadow => [
        BoxShadow(
          color: primaryPurple.withOpacity(0.3),
          blurRadius: 30,
          spreadRadius: -5,
        ),
      ];

  // ===== TEXT STYLES =====
  static TextStyle get displayLarge => GoogleFonts.plusJakartaSans(
        fontSize: 48,
        fontWeight: FontWeight.w700,
        letterSpacing: -1.5,
      );

  static TextStyle get displayMedium => GoogleFonts.plusJakartaSans(
        fontSize: 36,
        fontWeight: FontWeight.w700,
        letterSpacing: -1,
      );

  static TextStyle get headlineLarge => GoogleFonts.plusJakartaSans(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.5,
      );

  static TextStyle get headlineMedium => GoogleFonts.plusJakartaSans(
        fontSize: 24,
        fontWeight: FontWeight.w600,
      );

  static TextStyle get titleLarge => GoogleFonts.plusJakartaSans(
        fontSize: 20,
        fontWeight: FontWeight.w600,
      );

  static TextStyle get titleMedium => GoogleFonts.plusJakartaSans(
        fontSize: 16,
        fontWeight: FontWeight.w600,
      );

  static TextStyle get bodyLarge => GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.6,
      );

  static TextStyle get bodyMedium => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.5,
      );

  static TextStyle get labelLarge => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
      );

  static TextStyle get monoText => GoogleFonts.jetBrainsMono(
        fontSize: 14,
        fontWeight: FontWeight.w400,
      );

  // ===== LIGHT THEME =====
  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryPurple,
      brightness: Brightness.light,
      primary: primaryPurple,
      secondary: accentCyan,
      error: errorRed,
      surface: Colors.white,
      onSurface: const Color(0xFF1E293B),
    ),
    scaffoldBackgroundColor: const Color(0xFFF8FAFC),
    textTheme: TextTheme(
      displayLarge: displayLarge.copyWith(color: const Color(0xFF1E293B)),
      displayMedium: displayMedium.copyWith(color: const Color(0xFF1E293B)),
      headlineLarge: headlineLarge.copyWith(color: const Color(0xFF1E293B)),
      headlineMedium: headlineMedium.copyWith(color: const Color(0xFF1E293B)),
      titleLarge: titleLarge.copyWith(color: const Color(0xFF1E293B)),
      titleMedium: titleMedium.copyWith(color: const Color(0xFF1E293B)),
      bodyLarge: bodyLarge.copyWith(color: const Color(0xFF475569)),
      bodyMedium: bodyMedium.copyWith(color: const Color(0xFF64748B)),
      labelLarge: labelLarge.copyWith(color: const Color(0xFF64748B)),
    ),
    appBarTheme: AppBarTheme(
      centerTitle: true,
      elevation: 0,
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: titleLarge.copyWith(color: const Color(0xFF1E293B)),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.all(20),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: primaryPurple, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: errorRed, width: 2),
      ),
      hintStyle: bodyMedium.copyWith(color: const Color(0xFF94A3B8)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 0,
        backgroundColor: primaryPurple,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        textStyle: labelLarge.copyWith(color: Colors.white),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primaryPurple,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        side: const BorderSide(color: primaryPurple, width: 2),
        textStyle: labelLarge,
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: const Color(0xFFEEF2FF),
      labelStyle: labelLarge.copyWith(color: primaryPurple),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      side: BorderSide.none,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    ),
    dividerTheme: const DividerThemeData(
      color: Color(0xFFE2E8F0),
      thickness: 1,
    ),
  );

  // ===== DARK THEME =====
  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryPurple,
      brightness: Brightness.dark,
      primary: primaryViolet,
      secondary: accentCyan,
      error: errorRed,
      surface: const Color(0xFF1E1B4B),
      onSurface: Colors.white,
    ),
    scaffoldBackgroundColor: const Color(0xFF0F0D1A),
    textTheme: TextTheme(
      displayLarge: displayLarge.copyWith(color: Colors.white),
      displayMedium: displayMedium.copyWith(color: Colors.white),
      headlineLarge: headlineLarge.copyWith(color: Colors.white),
      headlineMedium: headlineMedium.copyWith(color: Colors.white),
      titleLarge: titleLarge.copyWith(color: Colors.white),
      titleMedium: titleMedium.copyWith(color: Colors.white),
      bodyLarge: bodyLarge.copyWith(color: const Color(0xFFCBD5E1)),
      bodyMedium: bodyMedium.copyWith(color: const Color(0xFF94A3B8)),
      labelLarge: labelLarge.copyWith(color: const Color(0xFF94A3B8)),
    ),
    appBarTheme: AppBarTheme(
      centerTitle: true,
      elevation: 0,
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: titleLarge.copyWith(color: Colors.white),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: const Color(0xFF1E1B4B).withOpacity(0.6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF1E1B4B).withOpacity(0.5),
      contentPadding: const EdgeInsets.all(20),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: primaryViolet, width: 2),
      ),
      hintStyle: bodyMedium.copyWith(color: const Color(0xFF64748B)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 0,
        backgroundColor: primaryViolet,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        textStyle: labelLarge.copyWith(color: Colors.white),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primaryViolet,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        side: const BorderSide(color: primaryViolet, width: 2),
        textStyle: labelLarge,
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: primaryViolet.withOpacity(0.2),
      labelStyle: labelLarge.copyWith(color: primaryViolet),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      side: BorderSide.none,
    ),
  );

  /// Get color for grammar issue category.
  static Color getIssueColor(String category, {String? ruleId}) {
    // Check for LLM detected issues
    if (ruleId == 'LLM_DETECTED') {
      return llmDetected;
    }

    switch (category.toLowerCase()) {
      case 'grammar':
      case 'agreement':
        return grammarError;
      case 'spelling':
        return spellingError;
      case 'style':
        return styleWarning;
      case 'punctuation':
      case 'typography':
        return punctuationIssue;
      default:
        return warningAmber;
    }
  }

  /// Get severity icon.
  static IconData getSeverityIcon(String severity) {
    switch (severity.toLowerCase()) {
      case 'error':
        return Icons.error_rounded;
      case 'warning':
        return Icons.warning_rounded;
      case 'info':
        return Icons.info_rounded;
      default:
        return Icons.help_rounded;
    }
  }
}
