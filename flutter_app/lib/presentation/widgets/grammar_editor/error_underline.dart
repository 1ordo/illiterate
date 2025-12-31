import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Animated squiggly underline widget.
class ErrorUnderline extends StatefulWidget {
  final double width;
  final Color color;
  final double strokeWidth;
  final bool animate;

  const ErrorUnderline({
    super.key,
    required this.width,
    this.color = Colors.red,
    this.strokeWidth = 1.5,
    this.animate = true,
  });

  @override
  State<ErrorUnderline> createState() => _ErrorUnderlineState();
}

class _ErrorUnderlineState extends State<ErrorUnderline>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    if (widget.animate) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(ErrorUnderline oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animate && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.animate && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          size: Size(widget.width, 4),
          painter: _SquigglyLinePainter(
            color: widget.color,
            strokeWidth: widget.strokeWidth,
            phase: _controller.value * 2 * math.pi,
          ),
        );
      },
    );
  }
}

class _SquigglyLinePainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double phase;

  _SquigglyLinePainter({
    required this.color,
    required this.strokeWidth,
    required this.phase,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    const waveHeight = 2.0;
    const waveLength = 6.0;

    path.moveTo(0, size.height / 2);

    for (double x = 0; x <= size.width; x += 1) {
      final y = size.height / 2 +
          waveHeight * math.sin((x / waveLength * 2 * math.pi) + phase);
      path.lineTo(x, y);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _SquigglyLinePainter oldDelegate) {
    return color != oldDelegate.color ||
        strokeWidth != oldDelegate.strokeWidth ||
        phase != oldDelegate.phase;
  }
}
