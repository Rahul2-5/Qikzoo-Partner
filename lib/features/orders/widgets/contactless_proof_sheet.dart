import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/buttons/primary_cta_button.dart';
import '../../../shared/widgets/layout/glass_container.dart';

/// A frontend-ready contactless drop-off proof interaction.
class ContactlessProofSheet {
  ContactlessProofSheet._();

  static Future<bool?> show(BuildContext context) => showModalBottomSheet<bool>(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (_) => const GlassBottomSheet(
          child: _ContactlessProofSheetContent(),
        ),
      );
}

class _ContactlessProofSheetContent extends StatefulWidget {
  const _ContactlessProofSheetContent();

  @override
  State<_ContactlessProofSheetContent> createState() =>
      _ContactlessProofSheetContentState();
}

class _ContactlessProofSheetContentState
    extends State<_ContactlessProofSheetContent> {
  bool _captured = false;

  @override
  Widget build(BuildContext context) => SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 60,
                height: 60,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _captured
                      ? AppColors.success.withValues(alpha: 0.12)
                      : AppColors.primarySoft,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _captured ? LucideIcons.checkCircle2 : LucideIcons.camera,
                  size: 30,
                  color: _captured ? AppColors.success : AppColors.primary,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                _captured ? 'Proof captured' : 'Capture drop-off photo',
                textAlign: TextAlign.center,
                style: AppTypography.h2,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                _captured
                    ? 'Your delivery photo proof is ready to save.'
                    : 'Capture a clear photo of the package at the customer doorstep or security desk.',
                textAlign: TextAlign.center,
                style:
                    AppTypography.body.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: AppSpacing.lg),
              PrimaryCtaButton(
                label: _captured ? 'Confirm Proof' : 'Take Photo',
                trailingIcon:
                    _captured ? LucideIcons.check : LucideIcons.camera,
                backgroundColor:
                    _captured ? AppColors.success : AppColors.primary,
                onPressed: () {
                  if (_captured) {
                    Navigator.of(context).pop(true);
                  } else {
                    setState(() => _captured = true);
                  }
                },
              ),
            ],
          ),
        ),
      );
}
