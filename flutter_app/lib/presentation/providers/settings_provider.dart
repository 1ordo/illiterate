import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/api_constants.dart';
import '../../core/config/language_config.dart';

/// Application settings state.
class SettingsState {
  final String language;
  final CheckMode mode;
  final Tone tone;
  final bool showExplanations;
  final bool isDarkMode;
  final bool learningMode;

  const SettingsState({
    this.language = 'nl',
    this.mode = CheckMode.strict,
    this.tone = Tone.neutral,
    this.showExplanations = true,
    this.isDarkMode = false,
    this.learningMode = false,
  });

  SettingsState copyWith({
    String? language,
    CheckMode? mode,
    Tone? tone,
    bool? showExplanations,
    bool? isDarkMode,
    bool? learningMode,
  }) {
    return SettingsState(
      language: language ?? this.language,
      mode: mode ?? this.mode,
      tone: tone ?? this.tone,
      showExplanations: showExplanations ?? this.showExplanations,
      isDarkMode: isDarkMode ?? this.isDarkMode,
      learningMode: learningMode ?? this.learningMode,
    );
  }

  /// Get the current language config.
  LanguageConfig get languageConfig =>
      getLanguageConfig(language) ?? defaultLanguage;

  /// Get mode as string for API.
  String get checkMode => mode == CheckMode.style ? 'style' : 'strict';
}

/// Legacy alias for backward compatibility.
typedef Settings = SettingsState;

/// Settings state notifier.
class SettingsNotifier extends StateNotifier<SettingsState> {
  SettingsNotifier() : super(const SettingsState());

  void setLanguage(String language) {
    state = state.copyWith(language: language);
  }

  void setMode(CheckMode mode) {
    state = state.copyWith(mode: mode);
  }

  /// Set check mode from string.
  void setCheckMode(String mode) {
    state = state.copyWith(
      mode: mode == 'style' ? CheckMode.style : CheckMode.strict,
    );
  }

  void setTone(Tone tone) {
    state = state.copyWith(tone: tone);
  }

  void toggleExplanations() {
    state = state.copyWith(showExplanations: !state.showExplanations);
  }

  void toggleDarkMode() {
    state = state.copyWith(isDarkMode: !state.isDarkMode);
  }

  void toggleLearningMode() {
    state = state.copyWith(learningMode: !state.learningMode);
  }

  void reset() {
    state = const SettingsState();
  }
}

/// Settings provider.
final settingsProvider =
    StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  return SettingsNotifier();
});

/// Current language provider (derived).
final currentLanguageProvider = Provider<String>((ref) {
  return ref.watch(settingsProvider).language;
});

/// Current mode provider (derived).
final currentModeProvider = Provider<CheckMode>((ref) {
  return ref.watch(settingsProvider).mode;
});

/// Is style mode enabled.
final isStyleModeProvider = Provider<bool>((ref) {
  return ref.watch(settingsProvider).mode == CheckMode.style;
});
