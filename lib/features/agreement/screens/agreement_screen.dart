import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';

import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../providers/agreement/agreement_provider.dart';
import '../../../shared/widgets/buttons/primary_cta_button.dart';
import '../../../shared/widgets/feedback/app_snack_bar.dart';
import '../../../shared/widgets/layout/responsive_frame.dart';

class AgreementScreen extends ConsumerWidget {
  const AgreementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final agreement = ref.watch(agreementProvider);
    final notifier = ref.read(agreementProvider.notifier);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Partner agreement')),
      body: SafeArea(
        child: ResponsiveFrame(
          maxWidth: 520,
          child: CustomScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.only(top: AppSpacing.md),
                sliver: SliverList.list(
                  children: [
                    Text(
                      'Review and accept the terms to continue.',
                      style: AppTypography.body,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _AgreementOption(
                      value: agreement.termsAccepted,
                      label: 'I accept the Terms of Service',
                      onChanged: notifier.toggleTerms,
                    ),
                    _AgreementOption(
                      value: agreement.privacyAccepted,
                      label: 'I accept the Privacy Policy',
                      onChanged: notifier.togglePrivacy,
                    ),
                    _AgreementOption(
                      value: agreement.partnerAgreementAccepted,
                      label: 'I accept the Delivery Partner Agreement',
                      onChanged: notifier.togglePartnerAgreement,
                    ),
                  ],
                ),
              ),
              SliverFillRemaining(
                hasScrollBody: false,
                child: Padding(
                  padding: const EdgeInsets.only(
                    top: AppSpacing.lg,
                    bottom: AppSpacing.md,
                  ),
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: PrimaryCtaButton(
                      label: 'Accept and continue',
                      onPressed: agreement.allAccepted
                          ? () async {
                              await notifier.submit();
                              if (!context.mounted) return;
                              AppSnackBar.success(
                                context,
                                'Agreement accepted',
                              );
                              Get.offNamed(AppRoutes.approval);
                            }
                          : null,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AgreementOption extends StatelessWidget {
  const _AgreementOption({
    required this.value,
    required this.label,
    required this.onChanged,
  });

  final bool value;
  final String label;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return CheckboxListTile(
      value: value,
      onChanged: (nextValue) => onChanged(nextValue ?? false),
      title: Text(label, style: AppTypography.bodyMedium),
      controlAffinity: ListTileControlAffinity.leading,
      contentPadding: EdgeInsets.zero,
      visualDensity: VisualDensity.comfortable,
      shape: const Border(
        bottom: BorderSide(color: AppColors.border),
      ),
    );
  }
}
