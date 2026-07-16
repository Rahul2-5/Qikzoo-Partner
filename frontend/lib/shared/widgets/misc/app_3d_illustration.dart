import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/assets/app_assets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';

/// Displays decorative 3D artwork without coupling screens to image details.
///
/// The decode-size hint keeps the 640 px sources memory-efficient at compact
/// card sizes, while [errorBuilder] gives development builds a useful fallback
/// if an asset is unavailable.
class App3dIllustration extends StatelessWidget {
  final String assetPath;
  final String semanticLabel;
  final double size;
  final Color glowColor;
  final IconData fallbackIcon;

  const App3dIllustration({
    super.key,
    required this.assetPath,
    required this.semanticLabel,
    required this.size,
    required this.glowColor,
    required this.fallbackIcon,
  });

  @override
  Widget build(BuildContext context) {
    final pixelRatio = MediaQuery.maybeDevicePixelRatioOf(context) ?? 1;
    final cacheSize = (size * pixelRatio).round().clamp(1, 640);

    return Semantics(
      image: true,
      label: semanticLabel,
      excludeSemantics: true,
      child: RepaintBoundary(
        child: SizedBox.square(
          dimension: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: size * 0.76,
                height: size * 0.76,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      glowColor.withValues(alpha: 0.18),
                      glowColor.withValues(alpha: 0),
                    ],
                    stops: const [0, 1],
                  ),
                ),
              ),
              Image.asset(
                assetPath,
                width: size,
                height: size,
                fit: BoxFit.contain,
                cacheWidth: cacheSize,
                cacheHeight: cacheSize,
                filterQuality: FilterQuality.medium,
                isAntiAlias: true,
                excludeFromSemantics: true,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: size * 0.62,
                    height: size * 0.62,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: glowColor.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      fallbackIcon,
                      color: glowColor,
                      size: size * 0.27,
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

@Preview(
  name: '3D status icon set',
  group: 'Brand assets',
  size: Size(390, 420),
)
Widget app3dIllustrationSetPreview() {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: AppTheme.light,
    home: const Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Wrap(
            spacing: 20,
            runSpacing: 20,
            children: [
              App3dIllustration(
                assetPath: AppAssets.partnerStatusOffline3d,
                semanticLabel: 'Offline status',
                size: 150,
                glowColor: AppColors.primary,
                fallbackIcon: LucideIcons.power,
              ),
              App3dIllustration(
                assetPath: AppAssets.orderSearch3d,
                semanticLabel: 'Searching for orders',
                size: 150,
                glowColor: AppColors.secondary,
                fallbackIcon: LucideIcons.bike,
              ),
              App3dIllustration(
                assetPath: AppAssets.applicationSubmitted3d,
                semanticLabel: 'Application submitted',
                size: 150,
                glowColor: AppColors.success,
                fallbackIcon: LucideIcons.clipboardCheck,
              ),
              App3dIllustration(
                assetPath: AppAssets.welcomeKit3d,
                semanticLabel: 'Partner welcome kit',
                size: 150,
                glowColor: AppColors.secondary,
                fallbackIcon: LucideIcons.packageCheck,
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
