import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// Hero illustration for the Welcome screen — the branded 3D delivery-rider
/// asset (transparent background, route pin baked in) supplied by the user.
class RiderHeroIllustration extends StatelessWidget {
  final double height;

  const RiderHeroIllustration({super.key, this.height = 236});

  @override
  Widget build(BuildContext context) {
    final circleSize = height * 0.78;

    return SizedBox(
      height: height,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: circleSize,
            height: circleSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.secondaryBg,
            ),
          ),
          Image.asset(
            'assets/images/3d_asset.png',
            height: height,
            fit: BoxFit.contain,
          ),
        ],
      ),
    );
  }
}
