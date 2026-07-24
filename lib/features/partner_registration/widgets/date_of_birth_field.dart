import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/helpers/date_helper.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/inputs/app_text_field.dart';

class DateOfBirthField extends StatefulWidget {
  final DateTime? value;
  final void Function(DateTime) onChanged;

  const DateOfBirthField(
      {super.key, required this.value, required this.onChanged});

  @override
  State<DateOfBirthField> createState() => _DateOfBirthFieldState();
}

class _DateOfBirthFieldState extends State<DateOfBirthField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: _formattedValue);
  }

  @override
  void didUpdateWidget(DateOfBirthField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _controller.text = _formattedValue;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String get _formattedValue =>
      widget.value != null ? DateHelper.formatShort(widget.value!) : '';

  Future<void> _pickDate(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: widget.value ?? DateTime(now.year - 18, now.month, now.day),
      firstDate: DateTime(now.year - 80),
      lastDate: DateTime(now.year - 18, now.month, now.day),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context)
                .colorScheme
                .copyWith(primary: AppColors.secondary),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) widget.onChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      label: 'Date of Birth',
      controller: _controller,
      showFloatingLabel: false,
      hint: 'Select your date of birth',
      readOnly: true,
      onTap: () => _pickDate(context),
      prefixIcon: const Icon(LucideIcons.calendar,
          color: AppColors.secondary, size: 20),
      suffixIcon: const Icon(LucideIcons.calendarDays,
          color: AppColors.textSecondary, size: 20),
    );
  }
}
