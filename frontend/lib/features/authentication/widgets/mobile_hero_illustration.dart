import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';

/// Geometric decorative motif for the mobile-entry screen — route pin,
/// dashed path, faint skyline and clouds — built entirely from theme
/// tokens (no stock imagery), echoing the Welcome hero's route pin.
class MobileHeroIllustration extends StatelessWidget {
  final double width;
  final double height;

  const MobileHeroIllustration({
    super.key,
    this.width = 128,
    this.height = 194,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        children: [
          const Positioned(
            left: 8,
            top: 8,
            child: _Cloud(size: 26),
          ),
          const Positioned(
            left: 46,
            top: 32,
            child: _Cloud(size: 18),
          ),
          Positioned(
            right: 4,
            top: 60,
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: AppColors.ctaGradient,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                          color: Color(0x3312A783),
                          blurRadius: 14,
                          offset: Offset(0, 6)),
                    ],
                  ),
                  child: const Center(
                    child:
                        CircleAvatar(radius: 7, backgroundColor: Colors.white),
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                ...List.generate(4, (index) {
                  return Padding(
                    padding: EdgeInsets.only(
                      left: (index.isEven ? 10 : 0).toDouble(),
                      right: (index.isEven ? 0 : 10).toDouble(),
                      bottom: AppSpacing.xs,
                    ),
                    child: Container(
                      width: 3,
                      height: 10,
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
          const Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _Skyline(),
          ),
        ],
      ),
    );
  }
}

class _Cloud extends StatelessWidget {
  final double size;

  const _Cloud({required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size * 1.6,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.textSecondary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(size),
      ),
    );
  }
}

class _Skyline extends StatelessWidget {
  final List<double> _heights = const [30, 46, 26, 54, 34, 20];

  const _Skyline();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisAlignment: MainAxisAlignment.end,
      children: _heights
          .map(
            (h) => Expanded(
              child: Container(
                height: h,
                margin: const EdgeInsets.only(left: 3),
                decoration: BoxDecoration(
                  color: AppColors.textSecondary.withValues(alpha: 0.08),
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(3)),
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}
