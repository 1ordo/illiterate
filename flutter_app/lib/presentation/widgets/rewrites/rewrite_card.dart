import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/rewrite_suggestion.dart';
import '../common/confidence_indicator.dart';

/// Card displaying a rewrite suggestion.
class RewriteCard extends StatelessWidget {
  final RewriteSuggestion rewrite;
  final bool isSelected;
  final VoidCallback? onTap;
  final VoidCallback? onApply;

  const RewriteCard({
    super.key,
    required this.rewrite,
    this.isSelected = false,
    this.onTap,
    this.onApply,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: isSelected ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : Colors.transparent,
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  // Tone badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _getToneColor(rewrite.tone).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getToneIcon(rewrite.tone),
                          size: 16,
                          color: _getToneColor(rewrite.tone),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          rewrite.toneDisplayName,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: _getToneColor(rewrite.tone),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  // Score
                  ConfidenceIndicator(score: rewrite.score),
                ],
              ),

              const SizedBox(height: 16),

              // Rewrite text
              Text(
                rewrite.text,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      height: 1.5,
                    ),
                maxLines: isSelected ? null : 3,
                overflow: isSelected ? null : TextOverflow.ellipsis,
              ),

              // Changes summary
              if (rewrite.changesSummary != null && isSelected) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .surfaceContainerHighest
                        .withOpacity(0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 16,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          rewrite.changesSummary!,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Apply button
              if (isSelected) ...[
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: onApply,
                    icon: const Icon(Icons.check),
                    label: const Text('Apply This Version'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _getToneColor(String tone) {
    switch (tone) {
      case 'formal':
        return AppTheme.primaryColor;
      case 'casual':
        return AppTheme.accentColor;
      case 'academic':
        return AppTheme.secondaryColor;
      case 'neutral':
      default:
        return Colors.grey;
    }
  }

  IconData _getToneIcon(String tone) {
    switch (tone) {
      case 'formal':
        return Icons.business;
      case 'casual':
        return Icons.chat_bubble_outline;
      case 'academic':
        return Icons.school;
      case 'neutral':
      default:
        return Icons.balance;
    }
  }
}
