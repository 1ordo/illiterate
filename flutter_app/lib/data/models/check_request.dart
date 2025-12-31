import '../../core/constants/api_constants.dart';

/// Request model for grammar checking.
class CheckRequest {
  final String text;
  final String language;
  final CheckMode mode;
  final Tone tone;
  final bool includeExplanations;

  const CheckRequest({
    required this.text,
    this.language = 'nl',
    this.mode = CheckMode.strict,
    this.tone = Tone.neutral,
    this.includeExplanations = true,
  });

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'language': language,
      'mode': mode.value,
      'tone': tone.value,
      'include_explanations': includeExplanations,
    };
  }

  CheckRequest copyWith({
    String? text,
    String? language,
    CheckMode? mode,
    Tone? tone,
    bool? includeExplanations,
  }) {
    return CheckRequest(
      text: text ?? this.text,
      language: language ?? this.language,
      mode: mode ?? this.mode,
      tone: tone ?? this.tone,
      includeExplanations: includeExplanations ?? this.includeExplanations,
    );
  }
}
