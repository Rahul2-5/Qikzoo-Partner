import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../models/settings/app_settings_model.dart';
import '../../../providers/settings/settings_provider.dart';
import '../../../shared/widgets/feedback/app_snack_bar.dart';
import '../../../shared/widgets/layout/responsive_frame.dart';
import '../../profile/widgets/account_screen_components.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  Future<void> _update(
    BuildContext context,
    WidgetRef ref,
    AppSettingsModel settings,
  ) async {
    await ref.read(settingsProvider.notifier).updateSettings(settings);
    if (!context.mounted) return;
    if (ref.read(settingsProvider).hasError) {
      AppSnackBar.error(context, 'Could not update settings');
    } else {
      AppSnackBar.success(context, 'Settings updated');
    }
  }

  void _comingSoon(BuildContext context, String title) {
    AppSnackBar.info(context, '$title will be available soon');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(settingsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ResponsiveFrame(
          maxWidth: 520,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AccountScreenHeader(
                title: 'Settings',
                subtitle: 'Manage notifications and account preferences.',
              ),
              const SizedBox(height: AppSpacing.lg),
              Expanded(
                child: settingsAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, _) => Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          LucideIcons.alertCircle,
                          size: 40,
                          color: AppColors.warning,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text('Could not load settings',
                            style: AppTypography.body),
                        TextButton(
                          onPressed: () => ref.invalidate(settingsProvider),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                  data: (settings) => ListView(
                    physics: const BouncingScrollPhysics(),
                    children: [
                      Text('Preferences', style: AppTypography.bodyMedium),
                      const SizedBox(height: AppSpacing.sm),
                      AccountSectionCard(
                        padding: EdgeInsets.zero,
                        child: _SettingsTile(
                          icon: LucideIcons.bell,
                          title: 'Push notifications',
                          subtitle: settings.notificationsEnabled
                              ? 'Order and payout alerts are on'
                              : 'Order and payout alerts are off',
                          trailing: Switch.adaptive(
                            value: settings.notificationsEnabled,
                            activeThumbColor: AppColors.secondary,
                            onChanged: (enabled) => _update(
                              context,
                              ref,
                              settings.copyWith(
                                notificationsEnabled: enabled,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Text('Security & privacy',
                          style: AppTypography.bodyMedium),
                      const SizedBox(height: AppSpacing.sm),
                      AccountSectionCard(
                        padding: EdgeInsets.zero,
                        child: Column(
                          children: [
                            _SettingsTile(
                              icon: LucideIcons.lock,
                              title: 'Change password',
                              subtitle: 'Update your account password',
                              onTap: () =>
                                  _comingSoon(context, 'Change password'),
                            ),
                            const Divider(height: 1),
                            _SettingsTile(
                              icon: LucideIcons.shieldCheck,
                              title: 'Privacy & permissions',
                              subtitle: 'Review app access and data use',
                              onTap: () => _comingSoon(
                                context,
                                'Privacy & permissions',
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Text('About', style: AppTypography.bodyMedium),
                      const SizedBox(height: AppSpacing.sm),
                      AccountSectionCard(
                        padding: EdgeInsets.zero,
                        child: Column(
                          children: [
                            _SettingsTile(
                              icon: LucideIcons.fileText,
                              title: 'Terms & conditions',
                              subtitle: 'Partner terms of service',
                              onTap: () =>
                                  _comingSoon(context, 'Terms & conditions'),
                            ),
                            const Divider(height: 1),
                            const _SettingsTile(
                              icon: LucideIcons.info,
                              title: 'App version',
                              subtitle: '0.1.0 (1)',
                              showChevron: false,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      const AccountInfoBanner(
                        icon: LucideIcons.shieldCheck,
                        title: 'Qikzoo Partner',
                        message:
                            'Your preferences are synced securely with your partner account.',
                        color: AppColors.primary,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                    ],
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

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool showChevron;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onTap,
    this.showChevron = true,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 72),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(AppRadius.control),
                  ),
                  child: Icon(icon, size: 19, color: AppColors.primary),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: AppTypography.bodyMedium),
                      const SizedBox(height: 2),
                      Text(subtitle, style: AppTypography.caption),
                    ],
                  ),
                ),
                if (trailing != null)
                  trailing!
                else if (showChevron && onTap != null)
                  const Icon(
                    LucideIcons.chevronRight,
                    color: AppColors.textSecondary,
                    size: 19,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
