import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax/iconsax.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/models/rewrite_suggestion.dart';
import '../common/glass_card.dart';

/// A modern card for displaying rewrite suggestions.
class ModernRewriteCard extends StatelessWidget {
  final RewriteSuggestion rewrite;
  final int index;
  final VoidCallback? onApply;

  const ModernRewriteCard({
    super.key,
    required this.rewrite,
    required this.index,
    this.onApply,
  });

  Color get _toneColor {
    switch (rewrite.tone.toLowerCase()) {
      case 'formal':
        return AppTheme.primaryPurple;
      case 'casual':
        return AppTheme.accentPink;
      case 'academic':
        return AppTheme.primaryViolet;
      default:
        return AppTheme.accentCyan;
    }
  }

  IconData get _toneIcon {
    switch (rewrite.tone.toLowerCase()) {
      case 'formal':
        return Iconsax.briefcase;
      case 'casual':
        return Iconsax.message_text;
      case 'academic':
        return Iconsax.book;
      default:
        return Iconsax.edit_2;
    }
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
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Tone badge
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _toneColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _toneIcon,
                    color: _toneColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),

                // Tone label and score
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: _toneColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          rewrite.tone[0].toUpperCase() + rewrite.tone.substring(1),
                          style: AppTheme.labelLarge.copyWith(
                            color: _toneColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (rewrite.changesSummary != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          rewrite.changesSummary!,
                          style: AppTheme.bodyMedium.copyWith(
                            color: const Color(0xFF94A3B8),
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),

                // Score
                _buildScoreBadge(isDark),
              ],
            ),
          ),

          // Divider
          Container(
            height: 1,
            color: isDark ? Colors.white.withOpacity(0.1) : const Color(0xFFE2E8F0),
          ),

          // Rewrite text
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              rewrite.text,
              style: AppTheme.bodyLarge.copyWith(
                color: isDark ? Colors.white : const Color(0xFF1E293B),
                height: 1.6,
              ),
            ),
          ),

          // Divider
          Container(
            height: 1,
            color: isDark ? Colors.white.withOpacity(0.1) : const Color(0xFFE2E8F0),
          ),

          // Actions
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Copy button
                Expanded(
                  child: TextButton.icon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: rewrite.text));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Copied to clipboard'),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Iconsax.copy, size: 18),
                    label: const Text('Copy'),
                  ),
                ),
                const SizedBox(width: 12),
                // Apply button
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onApply,
                    icon: const Icon(Iconsax.tick_circle, size: 18),
                    label: const Text('Use This'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _toneColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    )
        .animate(delay: Duration(milliseconds: index * 100))
        .fadeIn(duration: 400.ms)
        .slideX(begin: 0.1);
  }

  Widget _buildScoreBadge(bool isDark) {
    final scoreColor = rewrite.score >= 8
        ? AppTheme.successGreen
        : rewrite.score >= 6
            ? AppTheme.warningAmber
            : AppTheme.errorRed;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: scoreColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: scoreColor.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Iconsax.star1,
            color: scoreColor,
            size: 14,
          ),
          const SizedBox(width: 4),
          Text(
            rewrite.score.toStringAsFixed(0),
            style: AppTheme.labelLarge.copyWith(
              color: scoreColor,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
