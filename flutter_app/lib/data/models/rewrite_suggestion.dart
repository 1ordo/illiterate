/// A rewrite suggestion for the text.
class RewriteSuggestion {
  final String text;
  final String tone;
  final double score;
  final String? changesSummary;

  const RewriteSuggestion({
    required this.text,
    required this.tone,
    required this.score,
    this.changesSummary,
  });

  factory RewriteSuggestion.fromJson(Map<String, dynamic> json) {
    return RewriteSuggestion(
      text: json['text'] as String,
      tone: json['tone'] as String,
      score: (json['score'] as num).toDouble(),
      changesSummary: json['changes_summary'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'tone': tone,
      'score': score,
      'changes_summary': changesSummary,
    };
  }

  /// Get display name for the tone.
  String get toneDisplayName {
    switch (tone) {
      case 'formal':
        return 'Formal';
      case 'casual':
        return 'Casual';
      case 'academic':
        return 'Academic';
      case 'neutral':
      default:
        return 'Neutral';
    }
  }

  /// Get score as percentage (0-100).
  int get scorePercentage => (score * 10).round();

  RewriteSuggestion copyWith({
    String? text,
    String? tone,
    double? score,
    String? changesSummary,
  }) {
    return RewriteSuggestion(
      text: text ?? this.text,
      tone: tone ?? this.tone,
      score: score ?? this.score,
      changesSummary: changesSummary ?? this.changesSummary,
    );
  }
}
