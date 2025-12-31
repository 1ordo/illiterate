import 'package:flutter/material.dart';
import 'package:diff_match_patch/diff_match_patch.dart';
import '../../../core/theme/app_theme.dart';

/// Widget displaying text differences between original and corrected text.
class TextDiffView extends StatelessWidget {
  final String original;
  final String corrected;
  final bool showInline;

  const TextDiffView({
    super.key,
    required this.original,
    required this.corrected,
    this.showInline = true,
  });

  @override
  Widget build(BuildContext context) {
    if (original == corrected) {
      return Text(
        corrected,
        style: Theme.of(context).textTheme.bodyLarge,
      );
    }

    final diffs = _computeDiffs();

    if (showInline) {
      return _buildInlineDiff(context, diffs);
    } else {
      return _buildSideBySideDiff(context, diffs);
    }
  }

  List<Diff> _computeDiffs() {
    final dmp = DiffMatchPatch();
    final diffs = dmp.diff(original, corrected);
    dmp.diffCleanupSemantic(diffs);
    return diffs;
  }

  Widget _buildInlineDiff(BuildContext context, List<Diff> diffs) {
    final spans = <InlineSpan>[];

    for (final diff in diffs) {
      if (diff.operation == DIFF_EQUAL) {
        spans.add(TextSpan(
          text: diff.text,
          style: Theme.of(context).textTheme.bodyLarge,
        ));
      } else if (diff.operation == DIFF_DELETE) {
        spans.add(TextSpan(
          text: diff.text,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppTheme.errorColor,
                decoration: TextDecoration.lineThrough,
                decorationColor: AppTheme.errorColor,
                backgroundColor: AppTheme.errorColor.withOpacity(0.1),
              ),
        ));
      } else if (diff.operation == DIFF_INSERT) {
        spans.add(TextSpan(
          text: diff.text,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppTheme.successColor,
                backgroundColor: AppTheme.successColor.withOpacity(0.1),
              ),
        ));
      }
    }

    return Text.rich(
      TextSpan(children: spans),
    );
  }

  Widget _buildSideBySideDiff(BuildContext context, List<Diff> diffs) {
    final originalSpans = <InlineSpan>[];
    final correctedSpans = <InlineSpan>[];

    for (final diff in diffs) {
      if (diff.operation == DIFF_EQUAL) {
        originalSpans.add(TextSpan(text: diff.text));
        correctedSpans.add(TextSpan(text: diff.text));
      } else if (diff.operation == DIFF_DELETE) {
        originalSpans.add(TextSpan(
          text: diff.text,
          style: TextStyle(
            color: AppTheme.errorColor,
            backgroundColor: AppTheme.errorColor.withOpacity(0.1),
          ),
        ));
      } else if (diff.operation == DIFF_INSERT) {
        correctedSpans.add(TextSpan(
          text: diff.text,
          style: TextStyle(
            color: AppTheme.successColor,
            backgroundColor: AppTheme.successColor.withOpacity(0.1),
          ),
        ));
      }
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Original',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.errorColor.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppTheme.errorColor.withOpacity(0.2),
                  ),
                ),
                child: Text.rich(
                  TextSpan(children: originalSpans),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Corrected',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.successColor.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppTheme.successColor.withOpacity(0.2),
                  ),
                ),
                child: Text.rich(
                  TextSpan(children: correctedSpans),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
