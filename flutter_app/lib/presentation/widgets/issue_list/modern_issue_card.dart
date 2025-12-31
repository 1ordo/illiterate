import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax/iconsax.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/models/grammar_issue.dart';
import '../common/glass_card.dart';

/// A modern, animated card for displaying grammar issues.
class ModernIssueCard extends StatefulWidget {
  final GrammarIssue issue;
  final int index;
  final Function(String suggestion)? onApplyFix;

  const ModernIssueCard({
    super.key,
    required this.issue,
    required this.index,
    this.onApplyFix,
  });

  @override
  State<ModernIssueCard> createState() => _ModernIssueCardState();
}

class _ModernIssueCardState extends State<ModernIssueCard> {
  bool _isExpanded = false;

  Color get _issueColor => AppTheme.getIssueColor(
        widget.issue.category,
        ruleId: widget.issue.ruleId,
      );

  IconData get _issueIcon {
    if (widget.issue.ruleId == 'LLM_DETECTED') {
      return Iconsax.magic_star;
    }
    switch (widget.issue.severity.toLowerCase()) {
      case 'error':
        return Iconsax.close_circle;
      case 'warning':
        return Iconsax.warning_2;
      default:
        return Iconsax.info_circle;
    }
  }

  String get _issueLabel {
    if (widget.issue.ruleId == 'LLM_DETECTED') {
      return 'AI Detected';
    }
    return widget.issue.category.isNotEmpty
        ? widget.issue.category[0].toUpperCase() + widget.issue.category.substring(1)
        : 'Issue';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GlassCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Issue type badge
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _issueColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _issueIcon,
                      color: _issueColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Issue info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: _issueColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                _issueLabel,
                                style: AppTheme.labelLarge.copyWith(
                                  color: _issueColor,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          widget.issue.message,
                          style: AppTheme.bodyMedium.copyWith(
                            color: isDark ? Colors.white : const Color(0xFF1E293B),
                          ),
                          maxLines: _isExpanded ? null : 2,
                          overflow: _isExpanded ? null : TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),

                  // Expand indicator
                  AnimatedRotation(
                    turns: _isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Iconsax.arrow_down_1,
                      color: isDark ? Colors.white54 : const Color(0xFF94A3B8),
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Expanded content
          AnimatedCrossFade(
            firstChild: const SizedBox(width: double.infinity),
            secondChild: _buildExpandedContent(isDark),
            crossFadeState:
                _isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
        ],
      ),
    )
        .animate(delay: Duration(milliseconds: widget.index * 100))
        .fadeIn(duration: 400.ms)
        .slideX(begin: 0.1);
  }

  Widget _buildExpandedContent(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Divider
        Container(
          height: 1,
          color: isDark ? Colors.white.withOpacity(0.1) : const Color(0xFFE2E8F0),
        ),

        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Original text
              Row(
                children: [
                  Container(
                    width: 4,
                    height: 24,
                    decoration: BoxDecoration(
                      color: AppTheme.errorRed,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.errorRed.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '"${widget.issue.originalText}"',
                        style: AppTheme.bodyMedium.copyWith(
                          color: AppTheme.errorRed,
                          decoration: TextDecoration.lineThrough,
                          decorationColor: AppTheme.errorRed,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Suggestions
              if (widget.issue.suggestions.isNotEmpty) ...[
                Text(
                  'Suggestions',
                  style: AppTheme.labelLarge.copyWith(
                    color: isDark ? Colors.white70 : const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: widget.issue.suggestions.map((suggestion) {
                    return InkWell(
                      onTap: () => widget.onApplyFix?.call(suggestion),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.successGreen.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppTheme.successGreen.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              suggestion,
                              style: AppTheme.bodyMedium.copyWith(
                                color: AppTheme.successGreen,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              Iconsax.tick_circle,
                              color: AppTheme.successGreen,
                              size: 16,
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],

              // Context
              if (widget.issue.context != null && widget.issue.context!.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  'Context',
                  style: AppTheme.labelLarge.copyWith(
                    color: isDark ? Colors.white70 : const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withOpacity(0.05)
                        : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    widget.issue.context!,
                    style: AppTheme.monoText.copyWith(
                      color: isDark ? Colors.white70 : const Color(0xFF475569),
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
