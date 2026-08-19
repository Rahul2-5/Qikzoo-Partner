import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
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
    'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&travelmode=driving',
  );
  final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
  if (!ok && context.mounted) {
    AppSnackBar.error(context, 'Could not open Google Maps.');
  }
}

/// Shared pickup and delivery stop details for the active-order flow.
class ContactCard extends StatelessWidget {
  const ContactCard({
    super.key,
    required this.title,
    required this.name,
    required this.address,
    required this.landmark,
    required this.phone,
    required this.latitude,
    required this.longitude,
    this.distanceKm,
    this.isRestaurant,
  });

  final String title;
  final String? name;
  final String address;
  final String? landmark;
  final String? phone;
  final double? latitude;
  final double? longitude;
  final double? distanceKm;
  final bool? isRestaurant;

  @override
  Widget build(BuildContext context) {
    final hasLocation = latitude != null && longitude != null;
    final hasPhone = phone != null && phone!.trim().isNotEmpty;
    final isPickup = isRestaurant ??
        (title.toLowerCase().contains('pickup') ||
            title.toLowerCase().contains('restaurant'));
    final displayName =
        name?.trim().isNotEmpty == true ? name!.trim() : 'Location';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          isPickup ? LucideIcons.utensils : LucideIcons.mapPin,
                          size: 15,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          title,
                          style: AppTypography.body.copyWith(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      displayName,
                      style: AppTypography.h2.copyWith(
                        fontSize: 17,
                        height: 1.3,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              if (hasLocation) ...[
                const SizedBox(width: 12),
                _MapsBadge(
                  onPressed: () => launchMaps(context, latitude!, longitude!),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 12),
          Text(
            address.trim().isEmpty ? 'Address not available' : address.trim(),
            style: AppTypography.body.copyWith(
              color: const Color(0xFF5F6368),
              fontSize: 13,
              height: 1.45,
              fontWeight: FontWeight.w400,
            ),
          ),
          if (distanceKm != null) ...[
            const SizedBox(height: 7),
            Row(
              children: [
                const Icon(
                  LucideIcons.map,
                  size: 14,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 6),
                Text(
                  '${distanceKm!.toStringAsFixed(1)} km away',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
          if (landmark != null && landmark!.trim().isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            _InlineMeta(
              icon: LucideIcons.landmark,
              label: landmark!.trim(),
            ),
          ],
          if (hasPhone) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: OutlinedButton.icon(
                onPressed: () => launchPhoneCall(context, phone!.trim()),
                icon: const Icon(LucideIcons.phoneCall, size: 16),
                label: Text(isPickup ? 'Call restaurant' : 'Call customer'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textPrimary,
                  side: const BorderSide(color: AppColors.border, width: 0.8),
                  textStyle: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.control),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MapsBadge extends StatelessWidget {
  const _MapsBadge({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Navigate with Google Maps',
      child: Material(
        color: AppColors.secondarySoft,
        borderRadius: BorderRadius.circular(8),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          child: const SizedBox(
            width: 42,
            height: 42,
            child: Center(
              child: Icon(
                LucideIcons.navigation,
                color: AppColors.primary,
                size: 19,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _InlineMeta extends StatelessWidget {
  const _InlineMeta({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: AppColors.textSecondary),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            label,
            style: AppTypography.caption.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
