import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/config/language_config.dart';
import '../../data/repositories/grammar_repository.dart';

/// Backend health state.
class BackendHealth {
  final bool isHealthy;
  final bool languageToolAvailable;
  final bool llmAvailable;
  final DateTime? lastChecked;

  const BackendHealth({
    this.isHealthy = false,
    this.languageToolAvailable = false,
    this.llmAvailable = false,
    this.lastChecked,
  });

  BackendHealth copyWith({
    bool? isHealthy,
    bool? languageToolAvailable,
    bool? llmAvailable,
    DateTime? lastChecked,
  }) {
    return BackendHealth(
      isHealthy: isHealthy ?? this.isHealthy,
      languageToolAvailable: languageToolAvailable ?? this.languageToolAvailable,
      llmAvailable: llmAvailable ?? this.llmAvailable,
      lastChecked: lastChecked ?? this.lastChecked,
    );
  }
}

/// Backend health notifier.
class BackendHealthNotifier extends StateNotifier<BackendHealth> {
  final GrammarRepository _repository;

  BackendHealthNotifier()
      : _repository = GrammarRepository(),
        super(const BackendHealth());

  /// Check backend health.
  Future<void> checkHealth() async {
    try {
      final health = await _repository.getHealthStatus();

      state = BackendHealth(
        isHealthy: health['status'] == 'healthy' || health['status'] == 'degraded',
        languageToolAvailable: health['languagetool_available'] ?? false,
        llmAvailable: health['llm_available'] ?? false,
        lastChecked: DateTime.now(),
      );
    } catch (_) {
      state = BackendHealth(
        isHealthy: false,
        languageToolAvailable: false,
        llmAvailable: false,
        lastChecked: DateTime.now(),
      );
    }
  }
}

/// Backend health provider.
final backendHealthProvider =
    StateNotifierProvider<BackendHealthNotifier, BackendHealth>((ref) {
  final notifier = BackendHealthNotifier();
  // Check health on creation
  notifier.checkHealth();
  return notifier;
});

/// Available languages provider.
final availableLanguagesProvider =
    Provider<List<LanguageConfig>>((ref) {
  return supportedLanguages;
});

/// Selected language config provider.
final selectedLanguageConfigProvider =
    Provider.family<LanguageConfig?, String>((ref, code) {
  return getLanguageConfig(code);
});
