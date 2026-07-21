import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/buttons/outlined_button_custom.dart';
import '../../../shared/widgets/motion/app_motion_widgets.dart';
import '../widgets/greeting_header.dart';
import '../widgets/offline_hero_card.dart';
import '../widgets/promotional_goals_card.dart';
import '../widgets/stat_tile_row.dart';
import '../widgets/todays_earnings_card.dart';
import '../widgets/waiting_for_orders_card.dart';

class HomeIdleView extends StatelessWidget {
  final bool online;
  final VoidCallback onGoOnline;
  final VoidCallback onGoOffline;

  const HomeIdleView({
    super.key,
    required this.online,
    required this.onGoOnline,
    required this.onGoOffline,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppStaggeredReveal(
          index: 0,
          child: GreetingHeader(
            online: online,
            onToggleStatus: online ? onGoOffline : onGoOnline,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final useColumns = constraints.maxWidth >= 760;

              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppStaggeredReveal(
                      index: 1,
                      child: _DashboardIntro(online: online),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    AppStaggeredReveal(
                      index: 2,
                      child: useColumns
                          ? _WideDashboard(
                              online: online,
                              onGoOnline: onGoOnline,
                              onGoOffline: onGoOffline,
                            )
                          : _CompactDashboard(
                              online: online,
                              onGoOnline: onGoOnline,
                              onGoOffline: onGoOffline,
                            ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _DashboardIntro extends StatelessWidget {
  final bool online;

  const _DashboardIntro({required this.online});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Good morning, Rahul',
          style: AppTypography.h1.copyWith(fontSize: 27),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          online
              ? 'Orders are nearby. Stay ready for your next trip.'
              : 'Go online and turn today\'s time into earnings.',
          style: AppTypography.body.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _CompactDashboard extends StatelessWidget {
  final bool online;
  final VoidCallback onGoOnline;
  final VoidCallback onGoOffline;

  const _CompactDashboard({
    required this.online,
    required this.onGoOnline,
    required this.onGoOffline,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const TodaysEarningsCard(amount: 920.50),
        const SizedBox(height: AppSpacing.md),
        if (online)
          const WaitingForOrdersCard()
        else
          OfflineHeroCard(onGoOnline: onGoOnline),
        const SizedBox(height: AppSpacing.lg),
        const PromotionalGoalsCard(
          completedOrders: 36,
          offerEndsLabel: 'Ends Sunday, 11:59 PM',
          goals: [
            DeliveryGoal(deliveries: 48, reward: 150),
            DeliveryGoal(deliveries: 60, reward: 250),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        const _SectionTitle(
          title: "Today's performance",
          subtitle: 'Your shift at a glance',
        ),
        const SizedBox(height: AppSpacing.sm + 2),
        const StatTileRow(
          deliveries: 12,
          hoursOnline: '4h 30m',
          rating: 4.8,
        ),
        if (online) ...[
          const SizedBox(height: AppSpacing.md),
          OutlinedButtonCustom(
            label: 'Go Offline',
            onPressed: onGoOffline,
          ),
        ],
      ],
    );
  }
}

class _WideDashboard extends StatelessWidget {
  final bool online;
  final VoidCallback onGoOnline;
  final VoidCallback onGoOffline;

  const _WideDashboard({
    required this.online,
    required this.onGoOnline,
    required this.onGoOffline,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 6,
          child: Column(
            children: [
              const TodaysEarningsCard(amount: 920.50),
              const SizedBox(height: AppSpacing.md),
              if (online)
                const WaitingForOrdersCard()
              else
                OfflineHeroCard(onGoOnline: onGoOnline),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.lg),
        Expanded(
          flex: 5,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const PromotionalGoalsCard(
                completedOrders: 36,
                offerEndsLabel: 'Ends Sunday, 11:59 PM',
                goals: [
                  DeliveryGoal(deliveries: 48, reward: 150),
                  DeliveryGoal(deliveries: 60, reward: 250),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              const _SectionTitle(
                title: "Today's performance",
                subtitle: 'Your shift at a glance',
              ),
              const SizedBox(height: AppSpacing.sm + 2),
              const StatTileRow(
                deliveries: 12,
                hoursOnline: '4h 30m',
                rating: 4.8,
              ),
              if (online) ...[
                const SizedBox(height: AppSpacing.md),
                OutlinedButtonCustom(
                  label: 'Go Offline',
                  onPressed: onGoOffline,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionTitle({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTypography.h2.copyWith(fontSize: 17)),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }
}
