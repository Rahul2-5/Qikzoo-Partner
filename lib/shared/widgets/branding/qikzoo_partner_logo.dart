import 'package:flutter/material.dart';

import '../../../core/assets/app_assets.dart';

class QikzooPartnerLogo extends StatelessWidget {
  const QikzooPartnerLogo({
    super.key,
    this.width = 164,
    this.alignment = Alignment.center,
  });

  final double width;
  final AlignmentGeometry alignment;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      image: true,
      label: 'Qikzoo Delivery Partner',
      excludeSemantics: true,
      child: Align(
        alignment: alignment,
        child: Image.asset(
          AppAssets.partnerLogoTight,
          width: width,
          height: width * 0.333,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => Image.asset(
            AppAssets.partnerLogoTight,
            width: width,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}
