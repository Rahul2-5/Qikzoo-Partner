import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/branding/qikzoo_partner_logo.dart';
import '../../../shared/widgets/buttons/primary_cta_button.dart';

class OnboardingPageShell extends StatelessWidget {
  const OnboardingPageShell({
    super.key,
    required this.step,
    required this.title,
    required this.description,
    required this.image,
    required this.buttonLabel,
    required this.onNext,
    this.onSkip,
  });

  final int step;
  final String title;
  final String description;
  final String image;
  final String buttonLabel;
  final VoidCallback onNext;
  final VoidCallback? onSkip;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxHeight < 720;
            final imageHeight = (constraints.maxHeight * (compact ? .34 : .39))
                .clamp(205.0, 330.0);

            return Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
              child: Column(
                children: [
                  const SizedBox(
                    height: 52,
                    child: QikzooPartnerLogo(width: 142),
                  ),
                  const SizedBox(height: 4),
                  _StepDots(currentStep: step),
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        children: [
                          SizedBox(height: compact ? 12 : 24),
                          SizedBox(
                            height: imageHeight,
                            width: double.infinity,
                            child: Image.asset(
                              image,
                              fit: BoxFit.contain,
                              semanticLabel:
                                  'Qikzoo delivery partner illustration',
                            ),
                          ),
                          SizedBox(height: compact ? 14 : 24),
                          Text(
                            title,
                            textAlign: TextAlign.center,
                            style: AppTypography.h1.copyWith(
                              color: AppColors.textPrimary,
                              fontSize: compact ? 22 : 25,
                              fontWeight: FontWeight.w800,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 10),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 300),
                            child: Text(
                              description,
                              textAlign: TextAlign.center,
                              style: AppTypography.body.copyWith(
                                color: AppColors.textSecondary,
                                fontSize: 13.5,
                                height: 1.45,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  PrimaryCtaButton(label: buttonLabel, onPressed: onNext),
                  if (onSkip != null) ...[
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 34,
                      child: TextButton(
                        onPressed: onSkip,
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          padding: EdgeInsets.zero,
                        ),
                        child: Text(
                          'Skip',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _StepDots extends StatelessWidget {
  const _StepDots({required this.currentStep});

  final int currentStep;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (index) {
        final active = index + 1 == currentStep;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: active ? 20 : 7,
          height: 7,
          decoration: BoxDecoration(
            color: active ? AppColors.primary : AppColors.border,
            borderRadius: BorderRadius.circular(8),
          ),
        );
      }),
    );
  }
}
