/// Explanation for a correction.
class Explanation {
  final String span;
  final String original;
  final String corrected;
  final String reason;

  const Explanation({
    required this.span,
    required this.original,
    required this.corrected,
    required this.reason,
  });

  factory Explanation.fromJson(Map<String, dynamic> json) {
    return Explanation(
      span: json['span'] as String,
      original: json['original'] as String,
      corrected: json['corrected'] as String,
      reason: json['reason'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'span': span,
      'original': original,
      'corrected': corrected,
      'reason': reason,
    };
  }

  Explanation copyWith({
    String? span,
    String? original,
    String? corrected,
    String? reason,
  }) {
    return Explanation(
      span: span ?? this.span,
      original: original ?? this.original,
      corrected: corrected ?? this.corrected,
      reason: reason ?? this.reason,
    );
  }
}
