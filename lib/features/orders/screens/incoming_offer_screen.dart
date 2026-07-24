import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../models/orders/dispatch_offer_model.dart';
import '../../../providers/authentication/auth_provider.dart';
import '../../../providers/orders/dispatch_offer_provider.dart';
import '../../../shared/widgets/buttons/outlined_button_custom.dart';
import '../../../shared/widgets/buttons/primary_cta_button.dart';
import '../../../shared/widgets/feedback/app_snack_bar.dart';
import '../../../shared/widgets/layout/responsive_frame.dart';
import '../../../shared/widgets/misc/countdown_timer.dart';
import '../../../shared/widgets/misc/empty_state.dart';
import '../../../shared/widgets/misc/error_widget_custom.dart';

/// Shown when the dashboard's offer poll detects a WAITING_RIDER attempt.
/// The backend's `GET /rider/dispatch/current` only returns the bare
/// DispatchAttempt row (id, distanceKm, broadcast, expiresAt, ...) — no
/// restaurant name, address, ETA, or estimated earnings are available at
/// this stage, so this screen only ever shows what the backend actually
/// provides rather than inventing the rest.
class IncomingOfferScreen extends ConsumerStatefulWidget {
  const IncomingOfferScreen({super.key});

  @override
  ConsumerState<IncomingOfferScreen> createState() =>
      _IncomingOfferScreenState();
}

class _IncomingOfferScreenState extends ConsumerState<IncomingOfferScreen> {
  bool _isProcessing = false;
  bool _expired = false;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _pollTimer = Timer.periodic(
      AppConstants.dispatchOfferPollInterval,
      (_) => ref.read(dispatchOfferProvider.notifier).refresh(),
    );
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _accept(DispatchOfferModel offer) async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);
    try {
      await ref.read(dispatchOfferProvider.notifier).accept(offer.id);
      if (!mounted) return;
      Get.offNamed(AppRoutes.activeOrder);
    } on ApiException catch (e) {
      if (!mounted) return;
      if (e.statusCode == 401) {
        await ref.read(authSessionProvider.notifier).logout();
        if (!mounted) return;
        Get.offAllNamed(AppRoutes.welcome);
        return;
      }
      AppSnackBar.error(context, e.message);
      setState(() => _isProcessing = false);
    } catch (_) {
      if (!mounted) return;
      AppSnackBar.error(context, 'Something went wrong. Please try again.');
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _reject(DispatchOfferModel offer) async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);
    try {
      await ref.read(dispatchOfferProvider.notifier).reject(offer.id);
      if (!mounted) return;
      Get.back();
    } on ApiException catch (e) {
      if (!mounted) return;
      if (e.statusCode == 401) {
        await ref.read(authSessionProvider.notifier).logout();
        if (!mounted) return;
        Get.offAllNamed(AppRoutes.welcome);
        return;
      }
      AppSnackBar.error(context, e.message);
      setState(() => _isProcessing = false);
    } catch (_) {
      if (!mounted) return;
      AppSnackBar.error(context, 'Something went wrong. Please try again.');
      setState(() => _isProcessing = false);
    }
  }

  void _onCountdownExpired() {
    if (!mounted) return;
    setState(() => _expired = true);
  }

  @override
  Widget build(BuildContext context) {
    final offerAsync = ref.watch(dispatchOfferProvider);

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: ResponsiveFrame(
            maxWidth: 480,
            padding: const EdgeInsets.all(AppSpacing.md),
            child: offerAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => ErrorWidgetCustom(
                message: error is ApiException
                    ? error.message
                    : 'Could not load this offer.',
                onRetry: () => ref.read(dispatchOfferProvider.notifier).refresh(),
              ),
              data: (offer) {
                if (offer == null) {
                  return _NoOfferView(onBack: () => Get.back());
                }
                if (_expired || offer.isExpired) {
                  return _ExpiredOfferView(onBack: () => Get.back());
                }
                return _OfferView(
                  offer: offer,
                  isProcessing: _isProcessing,
                  onExpired: _onCountdownExpired,
                  onAccept: () => _accept(offer),
                  onReject: () => _reject(offer),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _OfferView extends StatelessWidget {
  final DispatchOfferModel offer;
  final bool isProcessing;
  final VoidCallback onExpired;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  const _OfferView({
    required this.offer,
    required this.isProcessing,
    required this.onExpired,
    required this.onAccept,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Spacer(),
        Container(
          width: 88,
          height: 88,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.secondary.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: const Icon(LucideIcons.bike, size: 40, color: AppColors.secondary),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text('New delivery request', style: AppTypography.h1),
        const SizedBox(height: AppSpacing.sm),
        CountdownTimer(
          key: ValueKey(offer.id),
          seconds: offer.remaining.inSeconds,
          onExpired: onExpired,
        ),
        const SizedBox(height: AppSpacing.lg),
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.card),
            boxShadow: AppShadows.card,
          ),
          child: Column(
            children: [
              _InfoRow(
                icon: LucideIcons.mapPin,
                label: 'Distance to pickup',
                value: '${offer.distanceKm.toStringAsFixed(1)} km',
              ),
              if (offer.broadcast) ...[
                const SizedBox(height: AppSpacing.sm),
                const _InfoRow(
                  icon: LucideIcons.users,
                  label: 'Offered to several riders',
                  value: 'First to accept wins',
                ),
              ],
            ],
          ),
        ),
        const Spacer(),
        Row(
          children: [
            Expanded(
              child: OutlinedButtonCustom(
                label: 'Reject',
                onPressed: isProcessing ? null : onReject,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: PrimaryCtaButton(
                label: 'Accept',
                isLoading: isProcessing,
                onPressed: isProcessing ? null : onAccept,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.textSecondary),
        const SizedBox(width: AppSpacing.sm),
        Expanded(child: Text(label, style: AppTypography.body)),
        Text(value, style: AppTypography.bodyMedium),
      ],
    );
  }
}

class _NoOfferView extends StatelessWidget {
  final VoidCallback onBack;

  const _NoOfferView({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Expanded(
          child: EmptyState(
            icon: LucideIcons.inbox,
            message: 'This offer is no longer available.',
          ),
        ),
        PrimaryCtaButton(label: 'Back to Dashboard', onPressed: onBack),
      ],
    );
  }
}

class _ExpiredOfferView extends StatelessWidget {
  final VoidCallback onBack;

  const _ExpiredOfferView({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Expanded(
          child: EmptyState(
            icon: LucideIcons.clock,
            message: 'This offer has expired.',
          ),
        ),
        PrimaryCtaButton(label: 'Back to Dashboard', onPressed: onBack),
      ],
    );
  }
}
