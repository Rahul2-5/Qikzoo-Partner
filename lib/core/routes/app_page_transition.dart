import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../theme/app_motion.dart';

Widget _buildPageTransition({
  required BuildContext context,
  required Animation<double> animation,
  required Widget child,
}) {
  if (AppMotion.reduceMotion(context)) return child;

  final curved = CurvedAnimation(
    parent: animation,
    curve: AppMotion.enter,
    reverseCurve: AppMotion.exit,
  );

  return FadeTransition(
    opacity: Tween<double>(begin: 0, end: 1).animate(curved),
    child: SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0.035, 0.012),
        end: Offset.zero,
      ).animate(curved),
      child: child,
    ),
  );
}

/// GetX route transition used by named routes.
class AppPageTransition extends CustomTransition {
  @override
  Widget buildTransition(
    BuildContext context,
    Curve? curve,
    Alignment? alignment,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return _buildPageTransition(
      context: context,
      animation: animation,
      child: child,
    );
  }
}

/// Material route transition used by Navigator/MaterialPageRoute flows.
class AppPageTransitionsBuilder extends PageTransitionsBuilder {
  const AppPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return _buildPageTransition(
      context: context,
      animation: animation,
      child: child,
    );
  }
}
