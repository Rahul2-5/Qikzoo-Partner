import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_typography.dart';
import '../../../models/partner_registration/vehicle_model.dart';

/// Read-only display of the vehicle type chosen on the Partner Type screen.
/// Not editable here — the user must go back to Partner Type to change it.
class VehicleTypeDisplayField extends StatelessWidget {
  final VehicleType vehicleType;

  const VehicleTypeDisplayField({super.key, required this.vehicleType});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.button),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Image.asset(vehicleType.imageAsset, width: 24, height: 24),
          const SizedBox(width: 12),
          Text(vehicleType.label, style: AppTypography.bodyMedium),
        ],
      ),
    );
  }
}
