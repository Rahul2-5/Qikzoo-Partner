import 'package:delivery_partner_app/shared/widgets/misc/loading_skeleton.dart';
import 'package:delivery_partner_app/shared/widgets/motion/app_motion_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shimmer/shimmer.dart';

Widget _host(Widget child, {bool reduceMotion = false}) {
  return MaterialApp(
    home: MediaQuery(
      data: MediaQueryData(disableAnimations: reduceMotion),
      child: Scaffold(body: Center(child: child)),
    ),
  );
}

void main() {
  testWidgets('AppReveal fades and lifts content into place', (tester) async {
    await tester.pumpWidget(
      _host(const AppReveal(child: Text('Ready'))),
    );

    final initialFade = tester.widget<FadeTransition>(
      find.descendant(
        of: find.byType(AppReveal),
        matching: find.byType(FadeTransition),
      ),
    );
    expect(initialFade.opacity.value, 0);

    await tester.pump(const Duration(milliseconds: 500));
    expect(initialFade.opacity.value, 1);
    expect(find.text('Ready'), findsOneWidget);
  });

  testWidgets('AppReveal finishes immediately when reduced motion is enabled',
      (tester) async {
    await tester.pumpWidget(
      _host(
        const AppReveal(
          delay: Duration(milliseconds: 300),
          child: Text('Accessible'),
        ),
        reduceMotion: true,
      ),
    );

    final fade = tester.widget<FadeTransition>(
      find.descendant(
        of: find.byType(AppReveal),
        matching: find.byType(FadeTransition),
      ),
    );
    expect(fade.opacity.value, 1);
  });

  testWidgets('AppPressEffect gives and releases tactile scale feedback',
      (tester) async {
    await tester.pumpWidget(
      _host(
        const AppPressEffect(
          child: SizedBox(key: ValueKey('target'), width: 100, height: 50),
        ),
      ),
    );

    final gesture = await tester.startGesture(
      tester.getCenter(find.byKey(const ValueKey('target'))),
    );
    await tester.pump();
    expect(tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale,
        lessThan(1));

    await gesture.up();
    await tester.pump();
    expect(tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale, 1);
  });

  testWidgets('loading skeleton stops shimmer for reduced motion',
      (tester) async {
    await tester.pumpWidget(
      _host(const LoadingSkeleton(), reduceMotion: true),
    );

    expect(find.byType(Shimmer), findsNothing);
    expect(find.byType(LoadingSkeleton), findsOneWidget);
  });
}
