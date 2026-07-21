import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../models/training/training_module_model.dart';

const profileLearningModules = <TrainingModuleModel>[
  TrainingModuleModel(
    id: 'safe-food-delivery',
    title: 'Safe Food Delivery',
    description: 'Keep every order fresh, sealed, and spill-free.',
    durationMinutes: 4,
    isCompleted: false,
  ),
  TrainingModuleModel(
    id: 'road-safety',
    title: 'Road Safety Essentials',
    description: 'Ride smart through traffic and difficult weather.',
    durationMinutes: 6,
    isCompleted: false,
  ),
  TrainingModuleModel(
    id: 'customer-handoffs',
    title: 'Great Customer Handoffs',
    description: 'Make every doorstep interaction smooth and respectful.',
    durationMinutes: 3,
    isCompleted: false,
  ),
];

class ProfileLearningSection extends StatelessWidget {
  final List<TrainingModuleModel> modules;
  final ValueChanged<TrainingModuleModel> onModuleTap;

  const ProfileLearningSection({
    super.key,
    required this.modules,
    required this.onModuleTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.sheet),
        boxShadow: const [
          BoxShadow(
            color: Color(0x333F51B5),
            offset: Offset(0, 12),
            blurRadius: 28,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(AppRadius.control),
                ),
                child: const Icon(
                  LucideIcons.graduationCap,
                  color: Colors.white,
                  size: 23,
                ),
              ),
              const SizedBox(width: AppSpacing.sm + 2),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Learnings',
                      style: AppTypography.h2.copyWith(color: Colors.white),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Quick videos for safer, better deliveries',
                      style: AppTypography.caption.copyWith(
                        color: Colors.white.withValues(alpha: 0.78),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(AppRadius.chip),
                ),
                child: Text(
                  'VIDEOS',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.primary,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            height: 190,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: modules.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(width: AppSpacing.sm + 2),
              itemBuilder: (context, index) => LearningVideoCard(
                module: modules[index],
                accentIndex: index,
                onTap: () => onModuleTap(modules[index]),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class LearningVideoCard extends StatelessWidget {
  final TrainingModuleModel module;
  final int accentIndex;
  final VoidCallback onTap;

  const LearningVideoCard({
    super.key,
    required this.module,
    required this.onTap,
    this.accentIndex = 0,
  });

  static const _thumbnailGradients = <List<Color>>[
    [Color(0xFFFFEDD5), Color(0xFFFDBA74)],
    [Color(0xFFDBEAFE), Color(0xFF93C5FD)],
    [Color(0xFFE8EAF6), Color(0xFF9FA8DA)],
  ];

  static const _thumbnailIcons = <IconData>[
    LucideIcons.packageCheck,
    LucideIcons.shieldCheck,
    LucideIcons.users,
  ];

  @override
  Widget build(BuildContext context) {
    final colorIndex = accentIndex % _thumbnailGradients.length;

    return Semantics(
      button: true,
      label: '${module.title}, ${module.durationMinutes} minute video',
      child: SizedBox(
        width: 208,
        child: Material(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.button),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 92,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: _thumbnailGradients[colorIndex],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Stack(
                    children: [
                      Center(
                        child: Icon(
                          _thumbnailIcons[colorIndex],
                          size: 42,
                          color: AppColors.primary.withValues(alpha: 0.72),
                        ),
                      ),
                      Center(
                        child: Container(
                          width: 42,
                          height: 42,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.9),
                            shape: BoxShape.circle,
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x33111827),
                                offset: Offset(0, 4),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                          child: const Icon(
                            LucideIcons.play,
                            color: Colors.white,
                            size: 19,
                          ),
                        ),
                      ),
                      Positioned(
                        right: AppSpacing.sm,
                        bottom: AppSpacing.sm,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.86),
                            borderRadius: BorderRadius.circular(AppRadius.chip),
                          ),
                          child: Text(
                            '${module.durationMinutes} min',
                            style: AppTypography.caption.copyWith(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.sm + 2,
                      AppSpacing.sm,
                      AppSpacing.sm + 2,
                      AppSpacing.sm,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          module.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.bodyMedium.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          module.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.caption.copyWith(fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

@Preview(name: 'Learnings Section', group: 'Profile', size: Size(390, 270))
Widget profileLearningSectionPreview() => MaterialApp(
      home: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: ProfileLearningSection(
              modules: profileLearningModules,
              onModuleTap: (_) {},
            ),
          ),
        ),
      ),
    );
