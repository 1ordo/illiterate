import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/grammar_issue.dart';

/// Rich text field with grammar error highlighting.
class GrammarTextField extends StatefulWidget {
  final TextEditingController controller;
  final List<GrammarIssue> issues;
  final GrammarIssue? selectedIssue;
  final ValueChanged<String>? onChanged;
  final ValueChanged<GrammarIssue?>? onIssueSelected;

  const GrammarTextField({
    super.key,
    required this.controller,
    this.issues = const [],
    this.selectedIssue,
    this.onChanged,
    this.onIssueSelected,
  });

  @override
  State<GrammarTextField> createState() => _GrammarTextFieldState();
}

class _GrammarTextFieldState extends State<GrammarTextField> {
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Text field
        TextField(
          controller: widget.controller,
          focusNode: _focusNode,
          onChanged: widget.onChanged,
          maxLines: null,
          minLines: 5,
          decoration: InputDecoration(
            hintText: 'Type or paste your text here...',
            hintStyle: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.5),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                height: 1.5,
              ),
        ),

        // Error overlay (positioned behind text)
        if (widget.issues.isNotEmpty)
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _ErrorUnderlinePainter(
                  text: widget.controller.text,
                  issues: widget.issues,
                  selectedIssue: widget.selectedIssue,
                  textStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        height: 1.5,
                      ),
                  padding: const EdgeInsets.all(16),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Custom painter for error underlines.
class _ErrorUnderlinePainter extends CustomPainter {
  final String text;
  final List<GrammarIssue> issues;
  final GrammarIssue? selectedIssue;
  final TextStyle? textStyle;
  final EdgeInsets padding;

  _ErrorUnderlinePainter({
    required this.text,
    required this.issues,
    this.selectedIssue,
    this.textStyle,
    this.padding = EdgeInsets.zero,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (text.isEmpty || issues.isEmpty) return;

    final textPainter = TextPainter(
      text: TextSpan(text: text, style: textStyle),
      textDirection: TextDirection.ltr,
      maxLines: null,
    );

    textPainter.layout(maxWidth: size.width - padding.horizontal);

    for (final issue in issues) {
      final isSelected = issue == selectedIssue;

      // Get positions
      final startOffset = issue.offset.clamp(0, text.length);
      final endOffset = issue.endOffset.clamp(0, text.length);

      if (startOffset >= endOffset) continue;

      try {
        final startBox = textPainter.getBoxesForSelection(
          TextSelection(baseOffset: startOffset, extentOffset: endOffset),
        );

        if (startBox.isEmpty) continue;

        final color = AppTheme.getIssueColor(issue.category);
        final paint = Paint()
          ..color = isSelected ? color : color.withOpacity(0.6)
          ..strokeWidth = isSelected ? 2.5 : 1.5
          ..style = PaintingStyle.stroke;

        for (final box in startBox) {
          _drawSquigglyLine(
            canvas,
            Offset(box.left + padding.left, box.bottom + padding.top),
            Offset(box.right + padding.left, box.bottom + padding.top),
            paint,
          );

          // Draw highlight background for selected
          if (isSelected) {
            final bgPaint = Paint()
              ..color = color.withOpacity(0.1)
              ..style = PaintingStyle.fill;

            canvas.drawRect(
              Rect.fromLTRB(
                box.left + padding.left,
                box.top + padding.top,
                box.right + padding.left,
                box.bottom + padding.top,
              ),
              bgPaint,
            );
          }
        }
      } catch (_) {
        // Ignore layout errors
      }
    }
  }

  void _drawSquigglyLine(Canvas canvas, Offset start, Offset end, Paint paint) {
    final path = Path();
    path.moveTo(start.dx, start.dy);

    final width = end.dx - start.dx;
    const waveHeight = 2.0;
    const waveLength = 4.0;

    for (double x = 0; x < width; x += waveLength) {
      final currentX = start.dx + x;
      final nextX = (start.dx + x + waveLength / 2).clamp(start.dx, end.dx);

      final waveY = (x ~/ waveLength).isEven ? waveHeight : -waveHeight;

      path.quadraticBezierTo(
        currentX + waveLength / 4,
        start.dy + waveY,
        nextX,
        start.dy,
      );
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _ErrorUnderlinePainter oldDelegate) {
    return text != oldDelegate.text ||
        issues != oldDelegate.issues ||
        selectedIssue != oldDelegate.selectedIssue;
  }
}
