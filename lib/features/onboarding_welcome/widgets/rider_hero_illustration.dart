import 'package:flutter/material.dart';
import '../../../core/assets/app_assets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';

class RiderHeroIllustration extends StatelessWidget {
  final double height;

  const RiderHeroIllustration({super.key, this.height = 250});

  @override
  Widget build(BuildContext context) {
    final decodeHeight =
        (height * MediaQuery.devicePixelRatioOf(context)).round();

    return Semantics(
      image: true,
      label:
          'Qikzoo delivery partner riding a scooter and accepting nearby orders.',
      excludeSemantics: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.primarySoft,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.12)),
        ),
        child: SizedBox(
          width: double.infinity,
          height: height,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.card),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 12, 0),
              child: Image.asset(
                AppAssets.riderScooterIndigo3d,
                cacheHeight: decodeHeight,
                fit: BoxFit.contain,
                alignment: Alignment.bottomCenter,
                excludeFromSemantics: true,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
