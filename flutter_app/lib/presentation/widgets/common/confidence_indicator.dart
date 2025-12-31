import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

/// Visual indicator for confidence/quality score.
class ConfidenceIndicator extends StatelessWidget {
  final double score;
  final double size;
  final bool showLabel;

  const ConfidenceIndicator({
    super.key,
    required this.score,
    this.size = 32,
    this.showLabel = true,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = (score / 10 * 100).round();
    final color = _getColor();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: Stack(
            children: [
              // Background circle
              CircularProgressIndicator(
                value: 1,
                strokeWidth: 3,
                backgroundColor: color.withOpacity(0.2),
                valueColor: AlwaysStoppedAnimation(Colors.transparent),
              ),
              // Progress circle
              CircularProgressIndicator(
                value: score / 10,
                strokeWidth: 3,
                backgroundColor: Colors.transparent,
                valueColor: AlwaysStoppedAnimation(color),
              ),
              // Score text
              Center(
                child: Text(
                  score.toInt().toString(),
                  style: TextStyle(
                    fontSize: size * 0.4,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (showLabel) ...[
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _getLabel(),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: color,
                ),
              ),
              Text(
                '$percentage%',
                style: TextStyle(
                  fontSize: 10,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Color _getColor() {
    if (score >= 8) return AppTheme.successColor;
    if (score >= 6) return AppTheme.warningColor;
    if (score >= 4) return Colors.orange;
    return AppTheme.errorColor;
  }

  String _getLabel() {
    if (score >= 9) return 'Excellent';
    if (score >= 8) return 'Great';
    if (score >= 7) return 'Good';
    if (score >= 6) return 'Fair';
    if (score >= 4) return 'Okay';
    return 'Poor';
  }
}

/// Compact confidence bar.
class ConfidenceBar extends StatelessWidget {
  final double score;
  final double width;
  final double height;

  const ConfidenceBar({
    super.key,
    required this.score,
    this.width = 60,
    this.height = 6,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = score / 10;
    final color = _getColor();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(height / 2),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: percentage,
            child: Container(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(height / 2),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Color _getColor() {
    if (score >= 8) return AppTheme.successColor;
    if (score >= 6) return AppTheme.warningColor;
    if (score >= 4) return Colors.orange;
    return AppTheme.errorColor;
  }
}
