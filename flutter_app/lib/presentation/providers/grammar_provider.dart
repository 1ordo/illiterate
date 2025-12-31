import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/api_constants.dart';
import '../../data/models/correction_result.dart';
import '../../data/models/grammar_issue.dart';
import '../../data/models/check_request.dart';
import '../../data/repositories/grammar_repository.dart';
import 'settings_provider.dart';

/// Grammar check state.
enum GrammarStatus {
  initial,
  loading,
  success,
  error,
}

/// Grammar check state model.
class GrammarState {
  final GrammarStatus status;
  final String inputText;
  final CorrectionResult? result;
  final String? errorMessage;
  final GrammarIssue? selectedIssue;
  final int? selectedRewriteIndex;

  const GrammarState({
    this.status = GrammarStatus.initial,
    this.inputText = '',
    this.result,
    this.errorMessage,
    this.selectedIssue,
    this.selectedRewriteIndex,
  });

  GrammarState copyWith({
    GrammarStatus? status,
    String? inputText,
    CorrectionResult? result,
    String? errorMessage,
    GrammarIssue? selectedIssue,
    int? selectedRewriteIndex,
    bool clearResult = false,
    bool clearError = false,
    bool clearSelectedIssue = false,
    bool clearSelectedRewrite = false,
  }) {
    return GrammarState(
      status: status ?? this.status,
      inputText: inputText ?? this.inputText,
      result: clearResult ? null : (result ?? this.result),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      selectedIssue: clearSelectedIssue ? null : (selectedIssue ?? this.selectedIssue),
      selectedRewriteIndex: clearSelectedRewrite
          ? null
          : (selectedRewriteIndex ?? this.selectedRewriteIndex),
    );
  }

  /// Convenience getters for the new UI
  bool get isLoading => status == GrammarStatus.loading;
  String? get error => status == GrammarStatus.error ? errorMessage : null;

  /// Whether there are any issues to display.
  bool get hasIssues => result?.hasIssues ?? false;

  /// Whether there are rewrites available.
  bool get hasRewrites => result?.hasRewrites ?? false;

  /// Whether the text has been corrected.
  bool get hasCorrections => result?.hasChanges ?? false;

  /// Current displayed text (corrected or original).
  String get displayText {
    if (selectedRewriteIndex != null &&
        result != null &&
        selectedRewriteIndex! < result!.rewrites.length) {
      return result!.rewrites[selectedRewriteIndex!].text;
    }
    return result?.correctedText ?? inputText;
  }
}

/// Grammar check notifier.
class GrammarNotifier extends StateNotifier<GrammarState> {
  final GrammarRepository _repository;
  final Ref _ref;

  GrammarNotifier(this._ref)
      : _repository = GrammarRepository(),
        super(const GrammarState());

  /// Update input text.
  void updateText(String text) {
    state = state.copyWith(
      inputText: text,
      clearResult: true,
      clearError: true,
      clearSelectedIssue: true,
      clearSelectedRewrite: true,
    );
  }

  /// Check grammar with a request object (for new UI).
  Future<void> checkGrammar(CheckRequest request) async {
    if (request.text.trim().isEmpty) {
      return;
    }

    state = state.copyWith(
      status: GrammarStatus.loading,
      inputText: request.text,
      clearError: true,
      clearSelectedIssue: true,
      clearSelectedRewrite: true,
    );

    try {
      final result = await _repository.checkGrammar(
        text: request.text,
        language: request.language,
        mode: request.mode,
        tone: request.tone,
        includeExplanations: request.includeExplanations,
      );

      state = state.copyWith(
        status: GrammarStatus.success,
        result: result,
      );
    } catch (e) {
      state = state.copyWith(
        status: GrammarStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  /// Check grammar using current settings (legacy).
  Future<void> checkGrammarWithSettings() async {
    if (state.inputText.trim().isEmpty) {
      return;
    }

    state = state.copyWith(
      status: GrammarStatus.loading,
      clearError: true,
      clearSelectedIssue: true,
      clearSelectedRewrite: true,
    );

    try {
      final settings = _ref.read(settingsProvider);

      final result = await _repository.checkGrammar(
        text: state.inputText,
        language: settings.language,
        mode: settings.mode,
        tone: settings.tone,
        includeExplanations: true,
      );

      state = state.copyWith(
        status: GrammarStatus.success,
        result: result,
      );
    } catch (e) {
      state = state.copyWith(
        status: GrammarStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  /// Select an issue to highlight.
  void selectIssue(GrammarIssue? issue) {
    state = state.copyWith(
      selectedIssue: issue,
      clearSelectedIssue: issue == null,
    );
  }

  /// Select a rewrite suggestion.
  void selectRewrite(int? index) {
    state = state.copyWith(
      selectedRewriteIndex: index,
      clearSelectedRewrite: index == null,
    );
  }

  /// Apply the selected rewrite to the input.
  void applyRewrite() {
    if (state.selectedRewriteIndex != null &&
        state.result != null &&
        state.selectedRewriteIndex! < state.result!.rewrites.length) {
      final rewrite = state.result!.rewrites[state.selectedRewriteIndex!];
      state = state.copyWith(
        inputText: rewrite.text,
        clearResult: true,
        clearSelectedRewrite: true,
      );
    }
  }

  /// Apply the corrected text to the input.
  void applyCorrectedText() {
    if (state.result != null) {
      state = state.copyWith(
        inputText: state.result!.correctedText,
        clearResult: true,
      );
    }
  }

  /// Revert to original text.
  void revertToOriginal() {
    if (state.result != null) {
      state = state.copyWith(
        inputText: state.result!.originalText,
        clearResult: true,
      );
    }
  }

  /// Clear all state.
  void clear() {
    state = const GrammarState();
  }
}

/// Grammar provider.
final grammarProvider =
    StateNotifierProvider<GrammarNotifier, GrammarState>((ref) {
  return GrammarNotifier(ref);
});

/// Issues list provider (derived).
final issuesProvider = Provider<List<GrammarIssue>>((ref) {
  return ref.watch(grammarProvider).result?.issues ?? [];
});

/// Is loading provider (derived).
final isLoadingProvider = Provider<bool>((ref) {
  return ref.watch(grammarProvider).status == GrammarStatus.loading;
});

/// Has results provider (derived).
final hasResultsProvider = Provider<bool>((ref) {
  return ref.watch(grammarProvider).result != null;
});
