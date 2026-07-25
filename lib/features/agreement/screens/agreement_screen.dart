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
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Review and accept the terms to continue.', style: AppTypography.body),
            const SizedBox(height: AppSpacing.md),
            CheckboxListTile(
              value: agreement.termsAccepted,
              onChanged: (value) => notifier.toggleTerms(value ?? false),
              title: const Text('I accept the Terms of Service'),
              controlAffinity: ListTileControlAffinity.leading,
            ),
            CheckboxListTile(
              value: agreement.privacyAccepted,
              onChanged: (value) => notifier.togglePrivacy(value ?? false),
              title: const Text('I accept the Privacy Policy'),
              controlAffinity: ListTileControlAffinity.leading,
            ),
            CheckboxListTile(
              value: agreement.partnerAgreementAccepted,
              onChanged: (value) => notifier.togglePartnerAgreement(value ?? false),
              title: const Text('I accept the Delivery Partner Agreement'),
              controlAffinity: ListTileControlAffinity.leading,
            ),
            const Spacer(),
            PrimaryCtaButton(
              label: 'Accept and continue',
              onPressed: agreement.allAccepted
                  ? () async {
                      await notifier.submit();
                      if (!context.mounted) return;
                      AppSnackBar.success(context, 'Agreement accepted');
                      Get.offNamed(AppRoutes.approval);
                    }
                  : null,
            ),
          ]),
        ),
      ),
    );
  }
}
