import 'package:delivery_partner_app/core/assets/app_assets.dart';
import 'package:delivery_partner_app/core/theme/app_colors.dart';
import 'package:delivery_partner_app/shared/widgets/misc/app_3d_illustration.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons/lucide_icons.dart';

void main() {
  testWidgets('renders the production 3D asset set with semantic labels',
      (tester) async {
    final semantics = tester.ensureSemantics();

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Wrap(
            children: [
              App3dIllustration(
                assetPath: AppAssets.partnerStatusOffline3d,
                semanticLabel: 'Offline status artwork',
                size: 100,
                glowColor: AppColors.primary,
                fallbackIcon: LucideIcons.power,
              ),
              App3dIllustration(
                assetPath: AppAssets.orderSearch3d,
                semanticLabel: 'Order search artwork',
                size: 100,
                glowColor: AppColors.secondary,
                fallbackIcon: LucideIcons.bike,
              ),
              App3dIllustration(
                assetPath: AppAssets.applicationSubmitted3d,
                semanticLabel: 'Application submitted artwork',
                size: 100,
                glowColor: AppColors.success,
                fallbackIcon: LucideIcons.clipboardCheck,
              ),
              App3dIllustration(
                assetPath: AppAssets.welcomeKit3d,
                semanticLabel: 'Welcome kit artwork',
                size: 100,
                glowColor: AppColors.secondary,
                fallbackIcon: LucideIcons.packageCheck,
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(Image), findsNWidgets(4));
    expect(find.bySemanticsLabel('Offline status artwork'), findsOneWidget);
    expect(find.bySemanticsLabel('Order search artwork'), findsOneWidget);
    expect(
      find.bySemanticsLabel('Application submitted artwork'),
      findsOneWidget,
    );
    expect(find.bySemanticsLabel('Welcome kit artwork'), findsOneWidget);
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });
}
