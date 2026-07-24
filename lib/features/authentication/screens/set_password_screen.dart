import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/validators/validators.dart';
import '../../../shared/widgets/buttons/icon_button_custom.dart';
import '../../../shared/widgets/buttons/primary_cta_button.dart';
import '../../../shared/widgets/inputs/app_text_field.dart';
import '../../../shared/widgets/layout/responsive_frame.dart';
import '../widgets/password_requirement_row.dart';
import '../widgets/password_strength_bar.dart';

class SetPasswordScreen extends ConsumerStatefulWidget {
  const SetPasswordScreen({super.key});

  @override
  ConsumerState<SetPasswordScreen> createState() => _SetPasswordScreenState();
}

class _SetPasswordScreenState extends ConsumerState<SetPasswordScreen> {
  final _controller = TextEditingController();
  bool _obscure = true;
  String _password = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onContinue() => Get.offNamed(AppRoutes.personalInfo);

  @override
  Widget build(BuildContext context) {
    final strength = Validators.passwordStrength(_password);
    final isValid = Validators.isStrongPassword(_password);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ResponsiveFrame(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSpacing.sm),
              IconButtonCustom(
                  icon: LucideIcons.arrowLeft, onPressed: () => Get.back()),
              const SizedBox(height: AppSpacing.lg),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      RichText(
                        text: TextSpan(
                          style: AppTypography.display.copyWith(fontSize: 28),
                          children: [
                            const TextSpan(
                                text: 'Set a ',
                                style: TextStyle(color: AppColors.textPrimary)),
                            TextSpan(
                              text: 'Password',
                              style: TextStyle(
                                foreground: Paint()
                                  ..shader = const LinearGradient(
                                          colors: AppColors.ctaGradient)
                                      .createShader(
                                          const Rect.fromLTWH(0, 0, 190, 28)),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'Create a password for your account',
                        style: AppTypography.body
                            .copyWith(color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(AppRadius.card),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Password',
                              style: AppTypography.bodyMedium
                                  .copyWith(color: AppColors.textPrimary),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            AppTextField(
                              label: 'Password',
                              controller: _controller,
                              showFloatingLabel: false,
                              hint: 'Enter a password',
                              obscureText: _obscure,
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscure
                                      ? LucideIcons.eyeOff
                                      : LucideIcons.eye,
                                  color: AppColors.textSecondary,
                                  size: 20,
                                ),
                                onPressed: () =>
                                    setState(() => _obscure = !_obscure),
                              ),
                              onChanged: (value) =>
                                  setState(() => _password = value),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            PasswordStrengthBar(strength: strength),
                            const SizedBox(height: AppSpacing.md),
                            PasswordRequirementRow(
                              label: 'At least 8 characters',
                              met: Validators.passwordHasMinLength(_password),
                            ),
                            PasswordRequirementRow(
                              label: 'One uppercase letter',
                              met: Validators.passwordHasUppercase(_password),
                            ),
                            PasswordRequirementRow(
                              label: 'One number',
                              met: Validators.passwordHasNumber(_password),
                            ),
                            PasswordRequirementRow(
                              label: 'One special character',
                              met: Validators.passwordHasSpecialChar(_password),
                              showDivider: false,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                    ],
                  ),
                ),
              ),
              PrimaryCtaButton(
                label: 'Continue',
                trailingIcon: LucideIcons.arrowRight,
                onPressed: isValid ? _onContinue : null,
              ),
              const SizedBox(height: AppSpacing.md),
            ],
          ),
        ),
      ),
    );
  }
}
