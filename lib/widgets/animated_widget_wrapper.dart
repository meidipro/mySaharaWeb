import 'package:flutter/material.dart';

/// Animated Widget Wrapper - Adds smooth fade-in and slide animations to widgets
class AnimatedWidgetWrapper extends StatefulWidget {
  final Widget child;
  final Duration delay;
  final Duration duration;
  final Offset slideOffset;

  const AnimatedWidgetWrapper({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 600),
    this.slideOffset = const Offset(0, 0.05),
  });

  @override
  State<AnimatedWidgetWrapper> createState() => _AnimatedWidgetWrapperState();
}

class _AnimatedWidgetWrapperState extends State<AnimatedWidgetWrapper>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOut,
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: widget.slideOffset,
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ),
    );

    // Start animation after delay
    Future.delayed(widget.delay, () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: widget.child,
      ),
    );
  }
}

/// Staggered animation helper - Creates sequential delays for multiple widgets
class StaggeredAnimationHelper {
  static Duration getDelay(int index, {int baseDelayMs = 80}) {
    return Duration(milliseconds: index * baseDelayMs);
  }
}
