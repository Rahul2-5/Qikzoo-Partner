import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../models/partner_registration/personal_info_model.dart';
import '../../../shared/widgets/chips/filter_chip_custom.dart';
import '../../../shared/widgets/inputs/app_text_field.dart';

class RelationSelector extends StatelessWidget {
  final Relation? selected;
  final void Function(Relation) onChanged;
  final TextEditingController otherController;
  final void Function(String) onOtherChanged;

  const RelationSelector({
    super.key,
    required this.selected,
    required this.onChanged,
    required this.otherController,
    required this.onOtherChanged,
  });

  String _label(Relation r) => switch (r) {
        Relation.father => 'Father',
        Relation.mother => 'Mother',
        Relation.brother => 'Brother',
        Relation.other => 'Other',
      };

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final relation in Relation.values)
              FilterChipCustom(
                label: _label(relation),
                selected: selected == relation,
                onTap: () => onChanged(relation),
              ),
          ],
        ),
        if (selected == Relation.other) ...[
          const SizedBox(height: AppSpacing.sm),
          AppTextField(
            label: 'Relation',
            controller: otherController,
            showFloatingLabel: false,
            hint: 'Enter relation',
            prefixIcon: const Icon(
              LucideIcons.edit3,
              color: AppColors.secondary,
              size: 20,
            ),
            onChanged: onOtherChanged,
          ),
        ],
      ],
    );
  }
}
