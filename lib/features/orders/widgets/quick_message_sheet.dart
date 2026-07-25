import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

/// Returns the locally selected message. Sending is intentionally deferred
/// until a customer-message API is connected.
class QuickMessageSheet {
  QuickMessageSheet._();

  static Future<String?> show(BuildContext context) => showModalBottomSheet<String>(
        context: context,
        isScrollControlled: true,
        backgroundColor: AppColors.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.sheet)),
        ),
        builder: (_) => const _QuickMessageSheetContent(),
      );
}

class _QuickMessageSheetContent extends StatefulWidget {
  const _QuickMessageSheetContent();

  @override
  State<_QuickMessageSheetContent> createState() => _QuickMessageSheetContentState();
}

class _QuickMessageSheetContentState extends State<_QuickMessageSheetContent> {
  static const _templates = <String, List<String>>{
    'English': [
      "I'm at the gate",
      'Please share a landmark',
      "I'm at the security desk",
      'Please share the delivery OTP',
    ],
    'हिन्दी': [
      'मैं गेट पर हूँ',
      'कृपया कोई लैंडमार्क साझा करें',
      'मैं सुरक्षा डेस्क पर हूँ',
      'कृपया डिलीवरी OTP साझा करें',
    ],
    'मराठी': [
      'मी गेटवर आहे',
      'कृपया जवळची खूण सांगा',
      'मी सुरक्षा डेस्कवर आहे',
      'कृपया डिलिव्हरी OTP सांगा',
    ],
  };

  String _language = 'English';

  @override
  Widget build(BuildContext context) => SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.chat_bubble_outline, color: AppColors.secondary),
                  const SizedBox(width: AppSpacing.sm),
                  Text('Quick message', style: AppTypography.h2),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Text('Choose a message for the customer.',
                  style: AppTypography.caption.copyWith(color: AppColors.textSecondary)),
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: AppSpacing.sm,
                children: [
                  for (final language in _templates.keys)
                    ChoiceChip(
                      label: Text(language),
                      selected: _language == language,
                      onSelected: (_) => setState(() => _language = language),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              for (final template in _templates[_language]!)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.send_outlined, color: AppColors.secondary),
                  title: Text(template, style: AppTypography.bodyMedium),
                  trailing: const Icon(Icons.chevron_right, color: AppColors.textSecondary),
                  onTap: () => Navigator.of(context).pop(template),
                ),
            ],
          ),
        ),
      );
}
