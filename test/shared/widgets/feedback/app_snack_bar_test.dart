import 'package:delivery_partner_app/core/theme/app_colors.dart';
import 'package:delivery_partner_app/core/theme/app_theme.dart';
import 'package:delivery_partner_app/shared/widgets/feedback/app_snack_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons/lucide_icons.dart';

void main() {
  testWidgets('shows a themed floating success snackbar', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => AppSnackBar.success(context, 'Saved'),
              child: const Text('Show'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Show'));
    await tester.pump();

    expect(find.text('Saved'), findsOneWidget);
    expect(find.byIcon(LucideIcons.checkCircle2), findsOneWidget);
    final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
    expect(snackBar.backgroundColor, AppColors.success);
    expect(
        Theme.of(tester.element(find.byType(SnackBar))).snackBarTheme.behavior,
        SnackBarBehavior.floating);
  });
}
