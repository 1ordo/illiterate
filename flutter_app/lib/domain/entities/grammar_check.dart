/// Domain entity for a grammar check operation.
///
/// This represents the business logic view of a grammar check,
/// independent of data layer implementation details.
class GrammarCheck {
  final String id;
  final String text;
  final String language;
  final DateTime createdAt;
  final bool isComplete;
  final int issueCount;
  final int correctionCount;

  const GrammarCheck({
    required this.id,
    required this.text,
    required this.language,
    required this.createdAt,
    this.isComplete = false,
    this.issueCount = 0,
    this.correctionCount = 0,
  });

  /// Check if the text has any issues.
  bool get hasIssues => issueCount > 0;

  /// Check if any corrections were made.
  bool get hasCorrections => correctionCount > 0;

  GrammarCheck copyWith({
    String? id,
    String? text,
    String? language,
    DateTime? createdAt,
    bool? isComplete,
    int? issueCount,
    int? correctionCount,
  }) {
    return GrammarCheck(
      id: id ?? this.id,
      text: text ?? this.text,
      language: language ?? this.language,
      createdAt: createdAt ?? this.createdAt,
      isComplete: isComplete ?? this.isComplete,
      issueCount: issueCount ?? this.issueCount,
      correctionCount: correctionCount ?? this.correctionCount,
    );
  }
}
