import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../core/push/push_service.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_typography.dart';
import '../../../models/notifications/notification_model.dart';
import '../../../providers/notifications/notifications_provider.dart';
import '../../../shared/widgets/feedback/app_snack_bar.dart';
import '../../../shared/widgets/layout/responsive_frame.dart';
import '../../../shared/widgets/misc/empty_state.dart';
import '../../../shared/widgets/misc/loading_skeleton.dart';

/// The partner's updates hub. It keeps important operational notices close to
/// short learning resources, so a rider does not need to hunt through several
/// screens before beginning a shift.
class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  Future<void> _markAllRead(
    WidgetRef ref,
    List<NotificationModel> notifications,
  ) async {
    for (final notification in notifications.where((item) => !item.isRead)) {
      await ref
          .read(notificationsProvider.notifier)
          .markAsRead(notification.id);
    }
  }

  Future<void> _refresh(WidgetRef ref) async {
    ref.invalidate(notificationsProvider);
    await ref.read(notificationsProvider.future);
  }

  /// Wires the "Enable alerts" card to the app's real notification
  /// permission + FCM token pipeline (`PushService`) instead of a snackbar
  /// that always claimed success. Reports the actual granted/denied
  /// outcome — a denial offers a direct path to Settings rather than
  /// pretending the request worked.
  Future<void> _onEnableAlerts(BuildContext context) async {
    final granted = await PushService.instance.requestPermissionAndRegister();
    if (!context.mounted) return;
    if (granted) {
      AppSnackBar.success(context, 'Order and gig alerts are now enabled.');
    } else {
      AppSnackBar.show(
        context,
        message:
            'Notification permission was not granted. Enable it from Settings to receive order and gig alerts.',
        type: AppSnackBarType.error,
        actionLabel: 'Open Settings',
        onAction: openAppSettings,
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Updates'),
        actions: [
          IconButton(
            tooltip: 'Help centre',
            onPressed: () => Get.toNamed(AppRoutes.support),
            icon: const Icon(LucideIcons.helpCircle),
          ),
          const SizedBox(width: AppSpacing.xs),
        ],
      ),
      body: SafeArea(
        top: false,
        child: ResponsiveFrame(
          maxWidth: 560,
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.md,
            0,
          ),
          child: Column(
            children: [
              Expanded(
                child: notificationsAsync.when(
                  loading: () => const PageLoadingShimmer(
                    padding: EdgeInsets.zero,
                  ),
                  error: (_, __) => _LoadError(
                    message: 'Could not load your updates.',
                    onRetry: () => ref.invalidate(notificationsProvider),
                  ),
                  data: (items) => RefreshIndicator(
                    color: AppColors.secondary,
                    onRefresh: () => _refresh(ref),
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics(),
                      ),
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      children: [
                        const _PartnerMomentumCard(),
                        const SizedBox(height: AppSpacing.md),
                        _AlertsPermissionCard(
                          onEnable: () => _onEnableAlerts(context),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        _SectionHeading(
                          title: 'Notifications',
                          action: items.any((item) => !item.isRead)
                              ? TextButton(
                                  onPressed: () => _markAllRead(ref, items),
                                  child: const Text('Mark all read'),
                                )
                              : null,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        if (items.isEmpty)
                          const _EmptyUpdatesCard()
                        else
                          _NotificationsPanel(
                            notifications: items,
                            onTap: (notification) => ref
                                .read(notificationsProvider.notifier)
                                .markAsRead(notification.id),
                          ),
                        const SizedBox(height: AppSpacing.xl),
                        const _SectionHeading(title: 'Videos for you'),
                        const SizedBox(height: AppSpacing.md),
                        const _LearningCarousel(),
                        const SizedBox(height: AppSpacing.lg),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PartnerMomentumCard extends StatelessWidget {
  const _PartnerMomentumCard();

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(color: AppColors.border.withValues(alpha: 0.75)),
          boxShadow: AppShadows.control,
        ),
        child: Row(
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: const Color(0xFFE8EEFF),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(
                LucideIcons.user,
                color: AppColors.primary,
                size: 27,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Your partner journey', style: AppTypography.bodyMedium),
                  const SizedBox(height: 3),
                  Text(
                    'Stay on top of gigs, rewards and important updates.',
                    style: AppTypography.caption,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            const _SuperPartnerBadge(),
          ],
        ),
      );
}

class _SuperPartnerBadge extends StatelessWidget {
  const _SuperPartnerBadge();

  @override
  Widget build(BuildContext context) => Container(
        width: 72,
        height: 72,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFFF9FCF8),
          border: Border.all(color: AppColors.textPrimary, width: 1.2),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(LucideIcons.star, color: Color(0xFF3DAA37), size: 15),
            Text(
              'SUPER',
              style: AppTypography.caption.copyWith(
                color: AppColors.textPrimary,
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              'PARTNER',
              style: AppTypography.caption.copyWith(
                color: const Color(0xFF2F9B36),
                fontSize: 9,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      );
}

class _AlertsPermissionCard extends StatelessWidget {
  const _AlertsPermissionCard({required this.onEnable});

  final VoidCallback onEnable;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: const Color(0xFFF0F4FF),
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(color: const Color(0xFFD8E2FF)),
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: Color(0xFFDCE7FF),
                shape: BoxShape.circle,
              ),
              child: const Icon(LucideIcons.bellRing, color: AppColors.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Enable order & gig alerts',
                      style: AppTypography.bodyMedium),
                  const SizedBox(height: 3),
                  Text(
                    'Stay updated and never miss an opportunity.',
                    style: AppTypography.caption,
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            OutlinedButton(
              onPressed: onEnable,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                minimumSize: const Size(76, 42),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.control),
                ),
              ),
              child: const Text('Enable'),
            ),
          ],
        ),
      );
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.title, this.action});

  final String title;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Text(title, style: AppTypography.h2.copyWith(fontSize: 21)),
          const Spacer(),
          if (action != null) action!,
        ],
      );
}

class _NotificationsPanel extends StatelessWidget {
  const _NotificationsPanel({
    required this.notifications,
    required this.onTap,
  });

  final List<NotificationModel> notifications;
  final ValueChanged<NotificationModel> onTap;

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(color: AppColors.border.withValues(alpha: 0.72)),
          boxShadow: AppShadows.control,
        ),
        child: ListView.separated(
          shrinkWrap: true,
          primary: false,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: notifications.length,
          separatorBuilder: (_, __) => const Divider(height: 1, indent: 76),
          itemBuilder: (context, index) => NotificationTile(
            notification: notifications[index],
            onTap: () => onTap(notifications[index]),
          ),
        ),
      );
}

class NotificationTile extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback onTap;

  const NotificationTile(
      {super.key, required this.notification, required this.onTap});

  IconData get _icon => switch (notification.type) {
        NotificationType.newOrder => LucideIcons.shoppingBag,
        NotificationType.orderCancelled => LucideIcons.xCircle,
        NotificationType.addressUpdated => LucideIcons.mapPin,
        NotificationType.incentiveUnlocked => LucideIcons.sparkles,
        NotificationType.paymentCredited => LucideIcons.wallet,
        NotificationType.accountUpdate => LucideIcons.shieldCheck,
        NotificationType.system => LucideIcons.bell,
      };

  Color get _iconColor => switch (notification.type) {
        NotificationType.newOrder => AppColors.primary,
        NotificationType.orderCancelled => AppColors.error,
        NotificationType.addressUpdated => const Color(0xFFF97316),
        NotificationType.incentiveUnlocked => const Color(0xFF8B5CF6),
        NotificationType.paymentCredited => AppColors.success,
        NotificationType.accountUpdate => const Color(0xFF0284C7),
        NotificationType.system => AppColors.textSecondary,
      };

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: notification.title,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.card),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: 52,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: _iconColor.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(_icon, color: _iconColor, size: 23),
                      ),
                      if (!notification.isRead)
                        Positioned(
                          top: -7,
                          left: -1,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFFBF5),
                              borderRadius: BorderRadius.circular(5),
                              border:
                                  Border.all(color: const Color(0xFFF4BF71)),
                            ),
                            child: Text(
                              'NEW',
                              style: AppTypography.caption.copyWith(
                                color: const Color(0xFFB66B0D),
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        notification.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.bodyMedium.copyWith(fontSize: 15),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _notificationDetail(notification),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.caption,
                      ),
                    ],
                  ),
                ),
                if (!notification.isRead)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Color(0xFF2B62DD),
                        shape: BoxShape.circle,
                      ),
                      child: SizedBox(width: 9, height: 9),
                    ),
                  ),
                const Icon(
                  LucideIcons.chevronRight,
                  color: AppColors.textSecondary,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      );
}

String _notificationDetail(NotificationModel notification) {
  final age = _relativeTime(notification.createdAt);
  return notification.body.isEmpty ? age : '${notification.body} · $age';
}

String _relativeTime(DateTime value) {
  final difference = DateTime.now().difference(value);
  if (difference.inMinutes < 1) return 'Just now';
  if (difference.inHours < 1) return '${difference.inMinutes} min ago';
  if (difference.inDays < 1) return '${difference.inHours} hr ago';
  return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
}

class _EmptyUpdatesCard extends StatelessWidget {
  const _EmptyUpdatesCard();

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(color: AppColors.border),
        ),
        child: const EmptyState(message: 'You are all caught up.'),
      );
}

class _LearningCarousel extends StatelessWidget {
  const _LearningCarousel();

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 235,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.only(right: AppSpacing.md),
          physics: const BouncingScrollPhysics(),
          itemCount: _learningVideos.length,
          separatorBuilder: (_, __) => const SizedBox(width: 12),
          itemBuilder: (context, index) => _LearningVideoCard(
            video: _learningVideos[index],
          ),
        ),
      );
}

class _LearningVideo {
  const _LearningVideo({
    required this.title,
    required this.duration,
    required this.icon,
    required this.color,
  });

  final String title;
  final String duration;
  final IconData icon;
  final Color color;
}

const _learningVideos = [
  _LearningVideo(
    title: 'How to maximise your earnings with Super Gigs',
    duration: '2:45',
    icon: LucideIcons.bike,
    color: Color(0xFFBEEFD7),
  ),
  _LearningVideo(
    title: 'Tips to improve acceptance rate',
    duration: '3:10',
    icon: LucideIcons.mapPin,
    color: Color(0xFFE3E5FF),
  ),
  _LearningVideo(
    title: 'New features in Qikzoo Partner',
    duration: '2:20',
    icon: LucideIcons.smartphone,
    color: Color(0xFFFFE8CF),
  ),
];

class _LearningVideoCard extends StatelessWidget {
  const _LearningVideoCard({required this.video});

  final _LearningVideo video;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 184,
        child: Semantics(
          button: true,
          label: 'Play ${video.title}',
          child: InkWell(
            onTap: () => ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('${video.title} is coming soon.')),
            ),
            borderRadius: BorderRadius.circular(AppRadius.card),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: video.color,
                          borderRadius: BorderRadius.circular(AppRadius.card),
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Positioned(
                              right: 12,
                              top: 10,
                              child: Icon(
                                video.icon,
                                color:
                                    AppColors.primary.withValues(alpha: 0.86),
                                size: 66,
                              ),
                            ),
                            Container(
                              width: 54,
                              height: 54,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                LucideIcons.play,
                                color: AppColors.primary,
                                size: 26,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Positioned(
                        bottom: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.textPrimary,
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Text(
                            video.duration,
                            style: AppTypography.caption.copyWith(
                              color: Colors.white,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  video.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodyMedium.copyWith(fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text('Qikzoo Partner', style: AppTypography.caption),
              ],
            ),
          ),
        ),
      );
}

class _LoadError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _LoadError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(LucideIcons.wifiOff, color: AppColors.textSecondary),
            const SizedBox(height: AppSpacing.sm),
            Text(message, style: AppTypography.body),
            TextButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      );
}

@Preview(name: 'Updates screen', group: 'Notifications', size: Size(390, 844))
Widget notificationsScreenPreview() => ProviderScope(
      child: MaterialApp(
        theme: AppTheme.light,
        home: const NotificationsScreen(),
      ),
    );
