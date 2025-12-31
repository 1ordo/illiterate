import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/grammar_issue.dart';

/// Card displaying a single grammar issue.
class IssueCard extends StatelessWidget {
  final GrammarIssue issue;
  final bool isSelected;
  final VoidCallback? onTap;
  final VoidCallback? onApplySuggestion;

  const IssueCard({
    super.key,
    required this.issue,
    this.isSelected = false,
    this.onTap,
    this.onApplySuggestion,
  });

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.getIssueColor(issue.category);

    return Card(
      elevation: isSelected ? 2 : 0,
      color: isSelected
          ? color.withOpacity(0.1)
          : Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? color : Theme.of(context).dividerColor,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                children: [
                  // Category badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getCategoryIcon(issue.category),
                          size: 14,
                          color: color,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatCategory(issue.category),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: color,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  // Severity indicator
                  Icon(
                    issue.isError ? Icons.error : Icons.warning_amber,
                    size: 16,
                    color: color,
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Original text with strike-through
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: issue.originalText,
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w500,
                        decoration: TextDecoration.lineThrough,
                        decorationColor: color,
                      ),
                    ),
                    if (issue.firstSuggestion != null) ...[
                      const TextSpan(text: '  →  '),
                      TextSpan(
                        text: issue.firstSuggestion,
                        style: TextStyle(
                          color: AppTheme.successColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // Message
              Text(
                issue.message,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),

              // Suggestions
              if (issue.suggestions.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: issue.suggestions.take(3).map((suggestion) {
                    return ActionChip(
                      label: Text(suggestion),
                      onPressed: onApplySuggestion,
                      avatar: const Icon(Icons.check, size: 16),
                      visualDensity: VisualDensity.compact,
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'grammar':
        return Icons.menu_book;
      case 'spelling':
        return Icons.spellcheck;
      case 'punctuation':
        return Icons.format_quote;
      case 'style':
        return Icons.style;
      case 'typography':
        return Icons.text_format;
      default:
        return Icons.info_outline;
    }
  }

  String _formatCategory(String category) {
    return category.substring(0, 1).toUpperCase() +
        category.substring(1).toLowerCase();
  }
}
