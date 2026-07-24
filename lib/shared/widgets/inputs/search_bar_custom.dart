import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_typography.dart';

class SearchBarCustom extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final void Function(String)? onChanged;

  const SearchBarCustom({
    super.key,
    required this.controller,
    this.hint = 'Search',
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      style: AppTypography.body,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: const Icon(LucideIcons.search, color: AppColors.textSecondary, size: 20),
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.button),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
