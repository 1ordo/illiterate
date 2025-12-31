/// Represents a single grammar issue detected in the text.
class GrammarIssue {
  final int offset;
  final int length;
  final String message;
  final String ruleId;
  final String category;
  final String severity;
  final String originalText;
  final List<String> suggestions;
  final String? context;

  const GrammarIssue({
    required this.offset,
    required this.length,
    required this.message,
    required this.ruleId,
    required this.category,
    required this.severity,
    required this.originalText,
    required this.suggestions,
    this.context,
  });

  factory GrammarIssue.fromJson(Map<String, dynamic> json) {
    return GrammarIssue(
      offset: json['offset'] as int,
      length: json['length'] as int,
      message: json['message'] as String,
      ruleId: json['rule_id'] as String,
      category: json['category'] as String,
      severity: json['severity'] as String,
      originalText: json['original_text'] as String,
      suggestions: (json['suggestions'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      context: json['context'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'offset': offset,
      'length': length,
      'message': message,
      'rule_id': ruleId,
      'category': category,
      'severity': severity,
      'original_text': originalText,
      'suggestions': suggestions,
      'context': context,
    };
  }

  /// Get the end offset of this issue.
  int get endOffset => offset + length;

  /// Check if this issue is an error (not just a warning).
  bool get isError => severity == 'error';

  /// Get the first suggestion, if any.
  String? get firstSuggestion =>
      suggestions.isNotEmpty ? suggestions.first : null;

  GrammarIssue copyWith({
    int? offset,
    int? length,
    String? message,
    String? ruleId,
    String? category,
    String? severity,
    String? originalText,
    List<String>? suggestions,
    String? context,
  }) {
    return GrammarIssue(
      offset: offset ?? this.offset,
      length: length ?? this.length,
      message: message ?? this.message,
      ruleId: ruleId ?? this.ruleId,
      category: category ?? this.category,
      severity: severity ?? this.severity,
      originalText: originalText ?? this.originalText,
      suggestions: suggestions ?? this.suggestions,
      context: context ?? this.context,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GrammarIssue &&
        other.offset == offset &&
        other.ruleId == ruleId;
  }

  @override
  int get hashCode => offset.hashCode ^ ruleId.hashCode;
}
