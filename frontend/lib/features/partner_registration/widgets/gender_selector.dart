import 'package:flutter/material.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../models/partner_registration/personal_info_model.dart';
import '../../../shared/widgets/chips/filter_chip_custom.dart';

class GenderSelector extends StatelessWidget {
  final Gender? selected;
  final void Function(Gender) onChanged;

  const GenderSelector({super.key, required this.selected, required this.onChanged});

  String _label(Gender g) => switch (g) {
        Gender.male => 'Male',
        Gender.female => 'Female',
        Gender.other => 'Other',
      };

  @override
  Widget build(BuildContext context) {
    return Row(
      children: Gender.values
          .map(
            (g) => Padding(
              padding: const EdgeInsets.only(right: AppSpacing.sm),
              child: FilterChipCustom(
                label: _label(g),
                selected: selected == g,
                onTap: () => onChanged(g),
              ),
            ),
          )
          .toList(),
    );
  }
}
