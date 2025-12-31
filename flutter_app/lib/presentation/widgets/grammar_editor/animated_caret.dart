import 'package:flutter/material.dart';

/// Animated caret/cursor widget.
class AnimatedCaret extends StatefulWidget {
  final double height;
  final Color color;
  final Duration blinkDuration;

  const AnimatedCaret({
    super.key,
    this.height = 20,
    this.color = Colors.blue,
    this.blinkDuration = const Duration(milliseconds: 500),
  });

  @override
  State<AnimatedCaret> createState() => _AnimatedCaretState();
}

class _AnimatedCaretState extends State<AnimatedCaret>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.blinkDuration,
      vsync: this,
    );

    _animation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Opacity(
          opacity: _animation.value,
          child: Container(
            width: 2,
            height: widget.height,
            decoration: BoxDecoration(
              color: widget.color,
              borderRadius: BorderRadius.circular(1),
            ),
          ),
        );
      },
    );
  }
}
