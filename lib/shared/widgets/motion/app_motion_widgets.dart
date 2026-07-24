import 'package:flutter/material.dart';

import '../../../core/theme/app_motion.dart';

/// Adds tactile scale feedback without owning the child's tap gesture.
///
/// A [Listener] is intentional here: it does not compete with an InkWell or
/// GestureDetector inside the child, so semantics and existing callbacks stay
/// intact.
class AppPressEffect extends StatefulWidget {
  const AppPressEffect({
    super.key,
    required this.child,
    this.enabled = true,
    this.pressedScale = 0.985,
  });

  final Widget child;
  final bool enabled;
  final double pressedScale;

  @override
  State<AppPressEffect> createState() => _AppPressEffectState();
}

class _AppPressEffectState extends State<AppPressEffect> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (!mounted || _pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  void didUpdateWidget(covariant AppPressEffect oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.enabled && _pressed) _pressed = false;
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.enabled && !AppMotion.reduceMotion(context);
    final scale = enabled && _pressed ? widget.pressedScale : 1.0;

    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: enabled ? (_) => _setPressed(true) : null,
      onPointerUp: enabled ? (_) => _setPressed(false) : null,
      onPointerCancel: enabled ? (_) => _setPressed(false) : null,
      child: AnimatedScale(
        scale: scale,
        alignment: Alignment.center,
        duration: AppMotion.duration(context, AppMotion.press),
        curve: _pressed ? Curves.easeOut : AppMotion.enter,
        child: widget.child,
      ),
    );
  }
}

/// A one-shot fade and lift used for page sections and list items.
class AppReveal extends StatefulWidget {
  const AppReveal({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = AppMotion.emphasized,
    this.offset = const Offset(0, 0.035),
  });

  final Widget child;
  final Duration delay;
  final Duration duration;
  final Offset offset;

  @override
  State<AppReveal> createState() => _AppRevealState();
}

class _AppRevealState extends State<AppReveal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late Animation<double> _opacity;
  late Animation<Offset> _position;
  bool _started = false;

  Duration get _totalDuration => widget.delay + widget.duration;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: _totalDuration);
    _configureAnimations();
  }

  void _configureAnimations() {
    final totalMicros = _totalDuration.inMicroseconds;
    final delayFraction =
        totalMicros == 0 ? 0.0 : widget.delay.inMicroseconds / totalMicros;
    final animation = CurvedAnimation(
      parent: _controller,
      curve: Interval(delayFraction, 1, curve: AppMotion.enter),
    );
    _opacity = Tween<double>(begin: 0, end: 1).animate(animation);
    _position = Tween<Offset>(begin: widget.offset, end: Offset.zero)
        .animate(animation);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (AppMotion.reduceMotion(context)) {
      _controller.value = 1;
      _started = true;
    } else if (!_started) {
      _started = true;
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(covariant AppReveal oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.delay != widget.delay ||
        oldWidget.duration != widget.duration ||
        oldWidget.offset != widget.offset) {
      _controller.duration = _totalDuration;
      _configureAnimations();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      alwaysIncludeSemantics: true,
      child: SlideTransition(position: _position, child: widget.child),
    );
  }
}

/// Applies a capped delay so long lists do not take seconds to settle.
class AppStaggeredReveal extends StatelessWidget {
  const AppStaggeredReveal({
    super.key,
    required this.index,
    required this.child,
  });

  final int index;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final delay = Duration(milliseconds: (index.clamp(0, 5)) * 45);
    return AppReveal(delay: delay, child: child);
  }
}

/// A restrained fade/lift transition for meaningful content state changes.
class AppAnimatedSwap extends StatelessWidget {
  const AppAnimatedSwap({
    super.key,
    required this.child,
    this.duration = AppMotion.standard,
  });

  final Widget child;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: AppMotion.duration(context, duration),
      switchInCurve: AppMotion.enter,
      switchOutCurve: AppMotion.exit,
      transitionBuilder: (child, animation) {
        final position = Tween<Offset>(
          begin: const Offset(0, 0.02),
          end: Offset.zero,
        ).animate(animation);
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(position: position, child: child),
        );
      },
      child: child,
    );
  }
}
