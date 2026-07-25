import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

/// A deliberately frontend-only proof interaction. It visualises the fallback
/// flow without opening the camera or persisting an image.
class ContactlessProofSheet {
  ContactlessProofSheet._();

  static Future<bool?> show(BuildContext context) => showModalBottomSheet<bool>(
        context: context,
        backgroundColor: AppColors.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.sheet)),
        ),
        builder: (_) => const _ContactlessProofSheetContent(),
      );
}

class _ContactlessProofSheetContent extends StatefulWidget {
  const _ContactlessProofSheetContent();

  @override
  State<_ContactlessProofSheetContent> createState() => _ContactlessProofSheetContentState();
}

class _ContactlessProofSheetContentState extends State<_ContactlessProofSheetContent> {
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
              Icon(_captured ? Icons.verified_outlined : Icons.camera_alt_outlined,
                  size: 34, color: _captured ? AppColors.secondary : AppColors.primary),
              const SizedBox(height: AppSpacing.sm),
              Text(_captured ? 'Proof captured' : 'Capture drop-off photo',
                  textAlign: TextAlign.center, style: AppTypography.h2),
              const SizedBox(height: AppSpacing.sm),
              Text(
                _captured
                    ? 'Your delivery proof is ready to be saved.'
                    : 'Capture the package at the approved drop point. This is a frontend preview only.',
                textAlign: TextAlign.center,
                style: AppTypography.body.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: AppSpacing.lg),
              FilledButton.icon(
                onPressed: () {
                  if (_captured) {
                    Navigator.of(context).pop(true);
                  } else {
                    setState(() => _captured = true);
                  }
                },
                icon: Icon(_captured ? Icons.check : Icons.camera_alt_outlined),
                label: Text(_captured ? 'Done' : 'Capture photo'),
              ),
            ],
          ),
        ),
      );
}
