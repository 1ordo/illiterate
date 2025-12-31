import 'grammar_issue.dart';
import 'rewrite_suggestion.dart';
import 'explanation.dart';

/// Complete result from the grammar checking pipeline.
class CorrectionResult {
  final String originalText;
  final String correctedText;
  final List<GrammarIssue> issues;
  final List<RewriteSuggestion> rewrites;
  final List<Explanation> explanations;
  final bool validationPassed;
  final bool fallbackUsed;
  final String language;
  final int issueCount;

  const CorrectionResult({
    required this.originalText,
    required this.correctedText,
    required this.issues,
    required this.rewrites,
    required this.explanations,
    required this.validationPassed,
    required this.fallbackUsed,
    required this.language,
    required this.issueCount,
  });

  factory CorrectionResult.fromJson(Map<String, dynamic> json) {
    return CorrectionResult(
      originalText: json['original_text'] as String,
      correctedText: json['corrected_text'] as String,
      issues: (json['issues'] as List<dynamic>)
          .map((e) => GrammarIssue.fromJson(e as Map<String, dynamic>))
          .toList(),
      rewrites: (json['rewrites'] as List<dynamic>)
          .map((e) => RewriteSuggestion.fromJson(e as Map<String, dynamic>))
          .toList(),
      explanations: (json['explanations'] as List<dynamic>)
          .map((e) => Explanation.fromJson(e as Map<String, dynamic>))
          .toList(),
      validationPassed: json['validation_passed'] as bool,
      fallbackUsed: json['fallback_used'] as bool,
      language: json['language'] as String,
      issueCount: json['issue_count'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'original_text': originalText,
      'corrected_text': correctedText,
      'issues': issues.map((e) => e.toJson()).toList(),
      'rewrites': rewrites.map((e) => e.toJson()).toList(),
      'explanations': explanations.map((e) => e.toJson()).toList(),
      'validation_passed': validationPassed,
      'fallback_used': fallbackUsed,
      'language': language,
      'issue_count': issueCount,
    };
  }

  /// Check if there are any issues.
  bool get hasIssues => issues.isNotEmpty;

  /// Check if the text was changed.
  bool get hasChanges => originalText != correctedText;

  /// Check if there are rewrite suggestions.
  bool get hasRewrites => rewrites.isNotEmpty;

  /// Get error count (issues with severity 'error').
  int get errorCount => issues.where((i) => i.isError).length;

  /// Get warning count.
  int get warningCount => issues.where((i) => !i.isError).length;

  /// Empty result for initial state.
  static const CorrectionResult empty = CorrectionResult(
    originalText: '',
    correctedText: '',
    issues: [],
    rewrites: [],
    explanations: [],
    validationPassed: true,
    fallbackUsed: false,
    language: 'nl',
    issueCount: 0,
  );

  CorrectionResult copyWith({
    String? originalText,
    String? correctedText,
    List<GrammarIssue>? issues,
    List<RewriteSuggestion>? rewrites,
    List<Explanation>? explanations,
    bool? validationPassed,
    bool? fallbackUsed,
    String? language,
    int? issueCount,
  }) {
    return CorrectionResult(
      originalText: originalText ?? this.originalText,
      correctedText: correctedText ?? this.correctedText,
      issues: issues ?? this.issues,
      rewrites: rewrites ?? this.rewrites,
      explanations: explanations ?? this.explanations,
      validationPassed: validationPassed ?? this.validationPassed,
      fallbackUsed: fallbackUsed ?? this.fallbackUsed,
      language: language ?? this.language,
      issueCount: issueCount ?? this.issueCount,
    );
  }
}
