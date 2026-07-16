import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/assets/app_assets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/misc/app_3d_illustration.dart';

class SubmittedIllustration extends StatelessWidget {
  const SubmittedIllustration({super.key});

  @override
  Widget build(BuildContext context) {
    return const App3dIllustration(
      assetPath: AppAssets.applicationSubmitted3d,
      semanticLabel: 'Verified application checklist',
      size: 220,
      glowColor: AppColors.success,
      fallbackIcon: LucideIcons.clipboardCheck,
    );
  }
}
