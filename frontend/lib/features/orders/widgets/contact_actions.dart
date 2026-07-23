import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/buttons/icon_button_custom.dart';
import '../../../shared/widgets/feedback/app_snack_bar.dart';

Future<void> launchPhoneCall(BuildContext context, String phone) async {
  final uri = Uri(scheme: 'tel', path: phone);
  final ok = await launchUrl(uri);
  if (!ok && context.mounted) {
    AppSnackBar.error(context, 'Could not open the phone dialer.');
  }
}

Future<void> launchMaps(BuildContext context, double lat, double lng) async {
  final uri = Uri.parse(
    'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
  );
  final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
  if (!ok && context.mounted) {
    AppSnackBar.error(context, 'Could not open Google Maps.');
  }
}

/// A contact row (name/title + address) with Call and Navigate actions.
/// `phone` is nullable so the customer card can render without a call
/// button until the backend actually exposes the number (see
/// `hasArrivedAtRestaurant` gating on `RiderOrderModel.order.customerPhone`).
class ContactCard extends StatelessWidget {
  final String title;
  final String? name;
  final String address;
  final String? landmark;
  final String? phone;
  final double? latitude;
  final double? longitude;

  const ContactCard({
    super.key,
    required this.title,
    required this.name,
    required this.address,
    required this.landmark,
    required this.phone,
    required this.latitude,
    required this.longitude,
  });

  @override
  Widget build(BuildContext context) {
    final hasLocation = latitude != null && longitude != null;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        boxShadow: AppShadows.card,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: AppTypography.caption.copyWith(color: AppColors.textSecondary)),
                const SizedBox(height: 2),
                Text(name ?? '—', style: AppTypography.bodyMedium),
                const SizedBox(height: 4),
                Text(address, style: AppTypography.body),
                if (landmark != null && landmark!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(landmark!,
                      style: AppTypography.caption.copyWith(color: AppColors.textSecondary)),
                ],
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Column(
            children: [
              if (phone != null && phone!.isNotEmpty)
                IconButtonCustom(
                  icon: LucideIcons.phone,
                  onPressed: () => launchPhoneCall(context, phone!),
                ),
              if (hasLocation) ...[
                const SizedBox(height: AppSpacing.xs),
                IconButtonCustom(
                  icon: LucideIcons.navigation,
                  onPressed: () => launchMaps(context, latitude!, longitude!),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
