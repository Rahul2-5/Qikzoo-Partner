import 'package:flutter/material.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../models/partner_registration/personal_info_model.dart';
import '../../../shared/widgets/chips/filter_chip_custom.dart';

class GenderSelector extends StatelessWidget {
  final Gender? selected;
  final void Function(Gender) onChanged;

  const GenderSelector(
      {super.key, required this.selected, required this.onChanged});

  String _label(Gender g) => switch (g) {
        Gender.male => 'Male',
        Gender.female => 'Female',
        Gender.other => 'Other',
      };

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var index = 0; index < Gender.values.length; index++) ...[
          if (index > 0) const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: FilterChipCustom(
              label: _label(Gender.values[index]),
              selected: selected == Gender.values[index],
              onTap: () => onChanged(Gender.values[index]),
            ),
          ),
        ],
      ],
    );
  }
}
