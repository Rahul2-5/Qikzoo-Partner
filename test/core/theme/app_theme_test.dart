import 'package:delivery_partner_app/core/theme/app_theme.dart';
import 'package:delivery_partner_app/core/theme/app_typography.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('uses Plus Jakarta Sans throughout the app theme', () {
    final theme = AppTheme.light;

    expect(theme.textTheme.bodyLarge?.fontFamily, AppTypography.fontFamily);
    expect(theme.textTheme.labelLarge?.fontFamily, AppTypography.fontFamily);
    expect(theme.textTheme.titleLarge?.fontFamily, AppTypography.fontFamily);

    expect(AppTypography.display.fontFamily, AppTypography.fontFamily);
    expect(AppTypography.h1.fontFamily, AppTypography.fontFamily);
    expect(AppTypography.h2.fontFamily, AppTypography.fontFamily);
    expect(AppTypography.body.fontFamily, AppTypography.fontFamily);
    expect(AppTypography.bodyMedium.fontFamily, AppTypography.fontFamily);
    expect(AppTypography.caption.fontFamily, AppTypography.fontFamily);
    expect(AppTypography.button.fontFamily, AppTypography.fontFamily);
    expect(AppTypography.numericLg.fontFamily, AppTypography.fontFamily);
    expect(AppTypography.numericMd.fontFamily, AppTypography.fontFamily);
  });
}
