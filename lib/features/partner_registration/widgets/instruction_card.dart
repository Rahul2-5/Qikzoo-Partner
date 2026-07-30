import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

/// Concise, reusable capture guidance presented in a premium surface.
class SelfieInstructionCard extends StatelessWidget {
  const SelfieInstructionCard({super.key});

  static const _instructions = <({IconData icon, String label})>[
    (icon: LucideIcons.glasses, label: 'Remove glasses'),
    (icon: LucideIcons.scanFace, label: 'Look directly at the camera'),
    (icon: LucideIcons.sun, label: 'Ensure good lighting'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F0F172A),
            blurRadius: 22,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final useHorizontalLayout = constraints.maxWidth >= 540;

          if (useHorizontalLayout) {
            return Row(
              children: [
                for (var index = 0; index < _instructions.length; index++) ...[
                  if (index > 0) const SizedBox(width: 16),
                  Expanded(child: _InstructionItem(_instructions[index])),
                ],
              ],
            );
          }

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var index = 0; index < _instructions.length; index++) ...[
                if (index > 0) const SizedBox(height: 10),
                _InstructionItem(_instructions[index]),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _InstructionItem extends StatelessWidget {
  const _InstructionItem(this.instruction);

  final ({IconData icon, String label}) instruction;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 30,
          height: 30,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: Color(0xFFEFF6FF),
            shape: BoxShape.circle,
          ),
          child: Icon(
            instruction.icon,
            size: 16,
            color: const Color(0xFF2563EB),
          ),
        ),
        const SizedBox(width: 10),
        Flexible(
          child: Text(
            instruction.label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: const Color(0xFF475569),
                  fontWeight: FontWeight.w600,
                  height: 1.3,
                ),
          ),
        ),
      ],
    );
  }
}
