import '../services/api_service.dart';
import '../models/check_request.dart';
import '../models/correction_result.dart';
import '../../core/constants/api_constants.dart';

/// Repository for grammar checking operations.
///
/// Provides a clean interface between the UI and API layers.
class GrammarRepository {
  final ApiService _apiService;

  GrammarRepository({ApiService? apiService})
      : _apiService = apiService ?? ApiService();

  /// Check grammar for the given text.
  ///
  /// [text] - The text to check
  /// [language] - Language code (default: 'nl' for Dutch)
  /// [mode] - Check mode (strict or style)
  /// [tone] - Preferred tone for rewrites
  Future<CorrectionResult> checkGrammar({
    required String text,
    String language = 'nl',
    CheckMode mode = CheckMode.strict,
    Tone tone = Tone.neutral,
    bool includeExplanations = true,
  }) async {
    if (text.trim().isEmpty) {
      return CorrectionResult.empty;
    }

    final request = CheckRequest(
      text: text,
      language: language,
      mode: mode,
      tone: tone,
      includeExplanations: includeExplanations,
    );

    return _apiService.checkGrammar(request);
  }

  /// Get list of supported languages from the backend.
  Future<List<Map<String, dynamic>>> getSupportedLanguages() async {
    return _apiService.getLanguages();
  }

  /// Check if the backend services are healthy.
  Future<bool> isBackendHealthy() async {
    try {
      final health = await _apiService.checkHealth();
      return health['status'] == 'healthy' ||
          health['languagetool_available'] == true;
    } catch (_) {
      return false;
    }
  }

  /// Get detailed health status.
  Future<Map<String, dynamic>> getHealthStatus() async {
    return _apiService.checkHealth();
  }
}
