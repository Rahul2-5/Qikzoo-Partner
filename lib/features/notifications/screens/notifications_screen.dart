import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_typography.dart';
import '../../../models/notifications/notification_model.dart';
import '../../../providers/notifications/notifications_provider.dart';
import '../../../shared/widgets/misc/empty_state.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  Future<void> _markAllRead(WidgetRef ref, List<NotificationModel> notifications) async {
    for (final notification in notifications.where((item) => !item.isRead)) {
      await ref.read(notificationsProvider.notifier).markAsRead(notification.id);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationsProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          notificationsAsync.maybeWhen(
            data: (items) => items.any((item) => !item.isRead)
                ? TextButton(
                    onPressed: () => _markAllRead(ref, items),
                    child: const Text('Mark all read'),
                  )
                : const SizedBox.shrink(),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: notificationsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => _LoadError(
          message: 'Could not load notifications.',
          onRetry: () => ref.invalidate(notificationsProvider),
        ),
        data: (items) => RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(notificationsProvider);
            await ref.read(notificationsProvider.future);
          },
          child: items.isEmpty
              ? ListView(children: const [SizedBox(height: 180), EmptyState(message: 'You are all caught up.')])
              : ListView.separated(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (_, index) => NotificationTile(
                    notification: items[index],
                    onTap: () => ref.read(notificationsProvider.notifier).markAsRead(items[index].id),
                  ),
                ),
        ),
      ),
    );
  }
}

class NotificationTile extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback onTap;

  const NotificationTile({super.key, required this.notification, required this.onTap});

  IconData get _icon => switch (notification.type) {
        NotificationType.order => Icons.delivery_dining_outlined,
        NotificationType.earnings => Icons.account_balance_wallet_outlined,
        NotificationType.promotion => Icons.local_offer_outlined,
        NotificationType.system => Icons.info_outline,
      };

  @override
  Widget build(BuildContext context) => Material(
        color: notification.isRead ? AppColors.surface : AppColors.primarySoft,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.card),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.card),
              boxShadow: AppShadows.card,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(_icon, color: AppColors.secondary),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(notification.title, style: AppTypography.bodyMedium),
                      const SizedBox(height: 2),
                      Text(notification.body, style: AppTypography.body),
                      const SizedBox(height: AppSpacing.xs),
                      Text(_relativeTime(notification.createdAt), style: AppTypography.caption),
                    ],
                  ),
                ),
                if (!notification.isRead)
                  Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.only(top: AppSpacing.xs),
                    decoration: const BoxDecoration(color: AppColors.secondary, shape: BoxShape.circle),
                  ),
              ],
            ),
          ),
        ),
      );
}

String _relativeTime(DateTime value) {
  final difference = DateTime.now().difference(value);
  if (difference.inMinutes < 1) return 'Just now';
  if (difference.inHours < 1) return '${difference.inMinutes} min ago';
  if (difference.inDays < 1) return '${difference.inHours} hr ago';
  return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
}

class _LoadError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _LoadError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(message, style: AppTypography.body),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ]),
      );
}

@Preview(name: 'Unread notification', group: 'Notifications', size: Size(390, 160))
Widget notificationTilePreview() => MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(
        backgroundColor: AppColors.background,
        body: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: NotificationTile(
            notification: NotificationModel(
              id: 'preview',
              title: 'New incentive available',
              body: 'Complete 5 more orders today to earn a bonus.',
              isRead: false,
              createdAt: DateTime.now().subtract(const Duration(minutes: 30)),
              type: NotificationType.promotion,
            ),
            onTap: notificationPreviewAction,
          ),
        ),
      ),
    );

void notificationPreviewAction() {}
