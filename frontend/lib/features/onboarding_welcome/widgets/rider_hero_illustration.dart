import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// Hero illustration for the Welcome screen — the branded 3D delivery-rider
/// asset (transparent background, route pin baked in) supplied by the user.
class RiderHeroIllustration extends StatelessWidget {
  const RiderHeroIllustration({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 260,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 220,
            height: 220,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.secondaryBg,
            ),
          ),
          Image.asset(
            'assets/images/3d_asset.png',
            height: 260,
            fit: BoxFit.contain,
          ),
        ],
      ),
    );
  }
}
