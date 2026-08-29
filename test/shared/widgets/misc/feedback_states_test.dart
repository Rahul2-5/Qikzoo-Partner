import 'package:delivery_partner_app/core/theme/app_theme.dart';
import 'package:delivery_partner_app/shared/widgets/misc/empty_state.dart';
import 'package:delivery_partner_app/shared/widgets/misc/error_widget_custom.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons/lucide_icons.dart';

void main() {
  Widget testApp(Widget child) => MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(body: child),
      );

  testWidgets('empty state explains the absence and exposes its action',
      (tester) async {
    var refreshes = 0;

    await tester.pumpWidget(
      testApp(
        EmptyState(
          icon: LucideIcons.packageSearch,
          title: 'No offers yet',
          message: 'New deliveries will appear here.',
          actionLabel: 'Refresh',
          onAction: () => refreshes++,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('No offers yet'), findsOneWidget);
    expect(find.text('New deliveries will appear here.'), findsOneWidget);
    await tester.tap(find.text('Refresh'));
    expect(refreshes, 1);
  });

  testWidgets('error state offers a recovery action when supplied',
      (tester) async {
    var retries = 0;

    await tester.pumpWidget(
      testApp(
        ErrorWidgetCustom(
          message: 'Check your connection and try again.',
          onRetry: () => retries++,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text("We couldn't load this"), findsOneWidget);
    await tester.tap(find.text('Retry'));
    expect(retries, 1);
  });
}
