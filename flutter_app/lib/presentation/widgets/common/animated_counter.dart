import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// An animated counter that smoothly transitions between values.
class AnimatedCounter extends StatelessWidget {
  final int value;
  final Color? color;
  final TextStyle? style;
  final Duration duration;

  const AnimatedCounter({
    super.key,
    required this.value,
    this.color,
    this.style,
    this.duration = const Duration(milliseconds: 500),
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<int>(
      tween: IntTween(begin: 0, end: value),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (context, animatedValue, child) {
        return Text(
          animatedValue.toString(),
          style: style ??
              AppTheme.headlineMedium.copyWith(
                color: color ?? Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w700,
              ),
        );
      },
    );
  }
}

/// A more elaborate animated counter with digit animations.
class FancyAnimatedCounter extends StatefulWidget {
  final int value;
  final Color? color;
  final double fontSize;

  const FancyAnimatedCounter({
    super.key,
    required this.value,
    this.color,
    this.fontSize = 28,
  });

  @override
  State<FancyAnimatedCounter> createState() => _FancyAnimatedCounterState();
}

class _FancyAnimatedCounterState extends State<FancyAnimatedCounter>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  int _previousValue = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    );
    _controller.forward();
  }

  @override
  void didUpdateWidget(FancyAnimatedCounter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _previousValue = oldWidget.value;
      _controller.reset();
      _controller.forward();
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
      animation: _animation,
      builder: (context, child) {
        final interpolatedValue = _previousValue +
            ((_animation.value) * (widget.value - _previousValue)).round();

        return Transform.scale(
          scale: 0.8 + (_animation.value * 0.2),
          child: Opacity(
            opacity: _animation.value,
            child: Text(
              interpolatedValue.toString(),
              style: AppTheme.headlineMedium.copyWith(
                color: widget.color ?? Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w700,
                fontSize: widget.fontSize,
              ),
            ),
          ),
        );
      },
    );
  }
}
