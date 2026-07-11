import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:delivery_partner_app/features/partner_registration/widgets/submitted_illustration.dart';

void main() {
  testWidgets('renders the checklist checks and the success badge check', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: SubmittedIllustration())),
    );

    // 5 checklist-row checks + 1 big badge check.
    expect(find.byIcon(LucideIcons.check), findsNWidgets(6));
  });
}
