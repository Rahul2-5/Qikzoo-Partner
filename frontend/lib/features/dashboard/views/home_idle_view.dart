import 'package:flutter/material.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/buttons/outlined_button_custom.dart';
import '../widgets/greeting_header.dart';
import '../widgets/offline_hero_card.dart';
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
        GreetingHeader(
          online: online,
          onToggleStatus: online ? onGoOffline : onGoOnline,
        ),
        const SizedBox(height: AppSpacing.md),
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Hi, Rahul 👋',
                    style: AppTypography.body.copyWith(fontSize: 16)),
                const SizedBox(height: AppSpacing.xs),
                Text(online ? 'Ready for orders' : 'Ready to deliver?',
                    style: AppTypography.h1.copyWith(fontSize: 26)),
                const SizedBox(height: AppSpacing.lg),
                const TodaysEarningsCard(amount: 920.50),
                const SizedBox(height: AppSpacing.md),
                if (online)
                  const WaitingForOrdersCard()
                else
                  OfflineHeroCard(onGoOnline: onGoOnline),
                const SizedBox(height: AppSpacing.md),
                const StatTileRow(
                    deliveries: 12, hoursOnline: '4h 30m', rating: 4.8),
                const SizedBox(height: AppSpacing.md),
                if (online)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: OutlinedButtonCustom(
                      label: 'Go Offline',
                      onPressed: onGoOffline,
                    ),
                  ),
                const SizedBox(height: AppSpacing.md),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
