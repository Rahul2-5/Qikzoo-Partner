import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../shared/widgets/buttons/primary_cta_button.dart';

class SignupBonusDialog extends StatelessWidget {
  const SignupBonusDialog({super.key});

  static const bonusAmount = 500;

  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: AppColors.primary.withValues(alpha: 0.72),
      builder: (_) => const SignupBonusDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final formattedBonus = CurrencyFormatter.rupees(bonusAmount);

    return PopScope(
      canPop: false,
      child: Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.lg,
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Semantics(
            container: true,
            label:
                'Welcome to Qikzoo. First-time signup bonus, $formattedBonus.',
            child: Container(
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.sheet + 8),
                border: Border.all(
                  color: const Color(0xFFFFD784).withValues(alpha: 0.8),
                ),
                boxShadow: AppShadows.card,
              ),
              child: Stack(
                children: [
                  const Positioned(
                    right: -52,
                    top: -58,
                    child: _BonusGlow(size: 180),
                  ),
                  const Positioned(
                    left: -36,
                    bottom: 72,
                    child: _BonusGlow(size: 120),
                  ),
                  SingleChildScrollView(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const _GiftMark(),
                        const SizedBox(height: AppSpacing.md),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm + 2,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF3D6),
                            borderRadius: BorderRadius.circular(AppRadius.chip),
                            border: Border.all(color: const Color(0xFFFFD784)),
                          ),
                          child: Text(
                            'FIRST-TIME SIGNUP BONUS',
                            style: AppTypography.caption.copyWith(
                              color: const Color(0xFF925600),
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.75,
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Semantics(
                          header: true,
                          child: Text(
                            'Welcome to Qikzoo!',
                            textAlign: TextAlign.center,
                            style: AppTypography.h1.copyWith(fontSize: 25),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          'Your signup bonus is here',
                          textAlign: TextAlign.center,
                          style: AppTypography.body.copyWith(
                            color: AppColors.textSecondary,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: AppSpacing.md,
                          ),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Color(0xFFFFFAED), Color(0xFFFFE9B5)],
                            ),
                            borderRadius:
                                BorderRadius.circular(AppRadius.sheet),
                            border: Border.all(
                              color: const Color(0xFFFFD784),
                            ),
                          ),
                          child: Column(
                            children: [
                              Text(
                                formattedBonus,
                                style: AppTypography.numericLg.copyWith(
                                  color: AppColors.primary,
                                  fontSize: 46,
                                  height: 1,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                'WELCOME REWARD',
                                style: AppTypography.caption.copyWith(
                                  color: const Color(0xFF925600),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.1,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          'A little boost to get your partner journey started.',
                          textAlign: TextAlign.center,
                          style: AppTypography.body.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        PrimaryCtaButton(
                          label: 'Start earning',
                          trailingIcon: LucideIcons.arrowRight,
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GiftMark extends StatelessWidget {
  const _GiftMark();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      image: true,
      label: 'Welcome gift',
      child: Container(
        width: 84,
        height: 84,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFFE8B7), Color(0xFFFFC85A)],
          ),
          shape: BoxShape.circle,
          border: Border.all(
            color: AppColors.surface,
            width: 5,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x35D89A23),
              offset: Offset(0, 12),
              blurRadius: 26,
            ),
          ],
        ),
        child: const Icon(
          LucideIcons.gift,
          color: Color(0xFF8A5200),
          size: 38,
          semanticLabel: 'Signup bonus gift',
        ),
      ),
    );
  }
}

class _BonusGlow extends StatelessWidget {
  const _BonusGlow({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              const Color(0xFFFFC85A).withValues(alpha: 0.2),
              const Color(0xFFFFF7E8).withValues(alpha: 0),
            ],
          ),
        ),
      ),
    );
  }
}
