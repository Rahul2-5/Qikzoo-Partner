import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/helpers/date_helper.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/inputs/app_text_field.dart';

class DateOfBirthField extends StatelessWidget {
  final DateTime? value;
  final void Function(DateTime) onChanged;

  const DateOfBirthField({super.key, required this.value, required this.onChanged});

  Future<void> _pickDate(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: value ?? DateTime(now.year - 18, now.month, now.day),
      firstDate: DateTime(now.year - 80),
      lastDate: DateTime(now.year - 18, now.month, now.day),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(primary: AppColors.secondary),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) onChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    final controller = TextEditingController(
      text: value != null ? DateHelper.formatShort(value!) : '',
    );
    return AppTextField(
      label: 'Date of Birth',
      controller: controller,
      showFloatingLabel: false,
      hint: 'Select your date of birth',
      readOnly: true,
      onTap: () => _pickDate(context),
      prefixIcon: const Icon(LucideIcons.calendar, color: AppColors.secondary, size: 20),
      suffixIcon: const Icon(LucideIcons.calendarDays, color: AppColors.textSecondary, size: 20),
    );
  }
}
