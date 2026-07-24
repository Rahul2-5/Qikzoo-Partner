import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/assets/app_assets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/misc/app_3d_illustration.dart';

class WelcomeKitIllustration extends StatelessWidget {
  const WelcomeKitIllustration({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 184,
      child: Center(
        child: App3dIllustration(
          assetPath: AppAssets.welcomeKit3d,
          semanticLabel: 'Qikzoo delivery bag and safety helmet',
          size: 210,
          glowColor: AppColors.secondary,
          fallbackIcon: LucideIcons.packageCheck,
        ),
      ),
    );
  }
}
