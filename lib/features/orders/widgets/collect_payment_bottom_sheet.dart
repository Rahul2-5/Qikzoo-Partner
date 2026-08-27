import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../models/orders/delivery_payment_session.dart';
import '../../../models/orders/rider_order_model.dart';
import '../../../providers/orders/delivery_payment_provider.dart';
import '../../../repositories/orders/rider_orders_repository.dart';
import '../../../shared/widgets/buttons/outlined_button_custom.dart';
import '../../../shared/widgets/buttons/primary_cta_button.dart';
import '../../../shared/widgets/misc/loading_skeleton.dart';

class CollectPaymentBottomSheet extends ConsumerStatefulWidget {
  const CollectPaymentBottomSheet({
    super.key,
    required this.order,
    required this.onPaymentConfirmed,
  });

  final RiderOrderModel order;
  final Future<void> Function() onPaymentConfirmed;

  static Future<bool?> show(
    BuildContext context, {
    required RiderOrderModel order,
    required Future<void> Function() onPaymentConfirmed,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      useSafeArea: true,
      backgroundColor: AppColors.surface,
      barrierColor: Colors.black.withValues(alpha: 0.48),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.sheet),
        ),
      ),
      builder: (_) => CollectPaymentBottomSheet(
        order: order,
        onPaymentConfirmed: onPaymentConfirmed,
      ),
    );
  }

  @override
  ConsumerState<CollectPaymentBottomSheet> createState() =>
      _CollectPaymentBottomSheetState();
}

class _CollectPaymentBottomSheetState
    extends ConsumerState<CollectPaymentBottomSheet>
    with WidgetsBindingObserver {
  bool _allowPop = false;
  bool _reportedSuccess = false;
  bool _collectingCash = false;

  DeliveryPaymentNotifier get _notifier =>
      ref.read(deliveryPaymentProvider(widget.order.id).notifier);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_notifier.open());
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _notifier.resume();
    } else if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.detached) {
      _notifier.pause();
    }
  }

  Future<void> _requestClose() async {
    final payment = ref.read(deliveryPaymentProvider(widget.order.id));
    if (payment.isPendingSafely) {
      final shouldClose = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Payment is still pending'),
          content: const Text(
            'You can close this screen safely. We’ll check the payment status when you return.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Close'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Keep Waiting'),
            ),
          ],
        ),
      );
      if (shouldClose != true || !mounted) return;
    }
    _close();
  }

  void _close({bool confirmed = false}) {
    if (!mounted) return;
    setState(() => _allowPop = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.of(context).pop(confirmed);
    });
  }

  Future<void> _collectCash() async {
    if (_collectingCash) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Confirm full cash received'),
        content: Text(
          'Confirm only after the customer gives you ${CurrencyFormatter.rupees(widget.order.order.totalPaise / 100)}. This COD amount is cash held for Qikzoo; your delivery earning stays separate.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Not yet'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Cash received'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _collectingCash = true);
    try {
      await ref
          .read(riderOrdersRepositoryProvider)
          .collectCash(widget.order.id);
      if (!mounted) return;
      await widget.onPaymentConfirmed();
      _close(confirmed: true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(error.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _collectingCash = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = deliveryPaymentProvider(widget.order.id);
    final payment = ref.watch(provider);
    ref.listen<DeliveryPaymentState>(provider, (previous, next) {
      if (next.status == DeliveryPaymentStatus.success &&
          previous?.status != DeliveryPaymentStatus.success &&
          !_reportedSuccess) {
        _reportedSuccess = true;
        unawaited(widget.onPaymentConfirmed());
      }
    });

    final screenHeight = MediaQuery.sizeOf(context).height;
    return PopScope(
      canPop: _allowPop,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) unawaited(_requestClose());
      },
      child: ConstrainedBox(
        constraints:
            BoxConstraints(maxHeight: math.min(screenHeight * 0.92, 780)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(AppRadius.chip),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.sm,
                AppSpacing.sm,
                AppSpacing.sm,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Collect Payment', style: AppTypography.h2),
                        const SizedBox(height: 2),
                        Text(
                          'Order #${widget.order.order.orderNumber}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.caption,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close payment collection',
                    constraints: const BoxConstraints(
                      minWidth: 48,
                      minHeight: 48,
                    ),
                    onPressed: _requestClose,
                    icon: const Icon(LucideIcons.x),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.border),
            Flexible(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.md,
                  AppSpacing.md,
                  AppSpacing.lg,
                ),
                child: Column(
                  children: [
                    Text(
                      'Amount to collect',
                      style: AppTypography.caption,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      CurrencyFormatter.rupees(
                        widget.order.order.totalPaise / 100,
                      ),
                      style: AppTypography.display.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Delivery earning: ${CurrencyFormatter.rupees(widget.order.earningsPaise / 100)} · credited separately',
                      style: AppTypography.caption,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AnimatedSwitcher(
                      duration: AppMotion.duration(
                        context,
                        AppMotion.emphasized,
                      ),
                      switchInCurve: AppMotion.enter,
                      switchOutCurve: AppMotion.exit,
                      child: _buildState(payment),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildState(DeliveryPaymentState payment) {
    if (payment.status == DeliveryPaymentStatus.initial ||
        payment.status == DeliveryPaymentStatus.creatingSession) {
      return const _CreatingSessionState(
        key: ValueKey('creating-payment-session'),
      );
    }
    final session = payment.session;
    if (session == null) {
      return _ConnectionOnlyState(
        key: const ValueKey('payment-connection-only'),
        onCheck: _notifier.open,
        onClose: _requestClose,
      );
    }
    return _PaymentSessionState(
      key: ValueKey('${session.sessionId}-${payment.status.name}'),
      state: payment,
      onCheckStatus: _notifier.checkStatus,
      onRegenerate: _notifier.regenerate,
      onClose: _requestClose,
      onContinue: () => _close(confirmed: true),
      onCollectCash: _collectCash,
      collectingCash: _collectingCash,
    );
  }
}

class _CreatingSessionState extends StatelessWidget {
  const _CreatingSessionState({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Semantics(
          label: 'Generating secure payment QR',
          liveRegion: true,
          child: LoadingSkeleton.card(
            width: 248,
            height: 248,
            borderRadius: BorderRadius.circular(AppRadius.card),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          'Generating secure payment QR…',
          style: AppTypography.bodyMedium,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Please keep this screen open for a moment.',
          style: AppTypography.caption,
        ),
      ],
    );
  }
}

class _ConnectionOnlyState extends StatelessWidget {
  const _ConnectionOnlyState({
    super.key,
    required this.onCheck,
    required this.onClose,
  });

  final VoidCallback onCheck;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Icon(
          LucideIcons.wifiOff,
          color: AppColors.warning,
          size: 44,
        ),
        const SizedBox(height: AppSpacing.md),
        Text('Unable to check payment status', style: AppTypography.h3),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'No new QR will be created until the existing payment status is verified.',
          textAlign: TextAlign.center,
          style: AppTypography.body.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: AppSpacing.lg),
        PrimaryCtaButton(label: 'Check Status', onPressed: onCheck),
        const SizedBox(height: AppSpacing.sm),
        OutlinedButtonCustom(label: 'Close', onPressed: onClose),
      ],
    );
  }
}

class _PaymentSessionState extends StatelessWidget {
  const _PaymentSessionState({
    super.key,
    required this.state,
    required this.onCheckStatus,
    required this.onRegenerate,
    required this.onClose,
    required this.onContinue,
    required this.onCollectCash,
    required this.collectingCash,
  });

  final DeliveryPaymentState state;
  final VoidCallback onCheckStatus;
  final VoidCallback onRegenerate;
  final VoidCallback onClose;
  final VoidCallback onContinue;
  final VoidCallback onCollectCash;
  final bool collectingCash;

  @override
  Widget build(BuildContext context) {
    final session = state.session!;
    final status = state.status;
    final pending = status == DeliveryPaymentStatus.pending ||
        (status == DeliveryPaymentStatus.connectionError &&
            state.lastConfirmedStatus == DeliveryPaymentStatus.pending);

    return Column(
      children: [
        Text(
          pending ? 'Ask the customer to scan this QR' : _titleFor(status),
          textAlign: TextAlign.center,
          style: AppTypography.h3,
        ),
        const SizedBox(height: AppSpacing.md),
        DeliveryPaymentQrCard(session: session, status: status),
        const SizedBox(height: AppSpacing.md),
        if (pending)
          PaymentPendingIndicator(
            isReconnecting: status == DeliveryPaymentStatus.connectionError,
          )
        else
          _TerminalPaymentDetails(session: session, status: status),
        if (pending) ...[
          const SizedBox(height: AppSpacing.sm),
          PaymentCountdown(
            expiresAt: session.expiresAt,
            onElapsed: onCheckStatus,
          ),
          const SizedBox(height: 4),
          Text(
            'Payment status updates automatically',
            style: AppTypography.caption,
          ),
          const SizedBox(height: AppSpacing.sm),
          const _SecurePaymentIndicator(),
        ],
        if (status == DeliveryPaymentStatus.connectionError) ...[
          const SizedBox(height: AppSpacing.md),
          _ConnectionWarning(onCheck: onCheckStatus),
        ],
        const SizedBox(height: AppSpacing.lg),
        if (status == DeliveryPaymentStatus.success)
          PrimaryCtaButton(
            label: 'Continue Delivery',
            trailingIcon: LucideIcons.arrowRight,
            onPressed: onContinue,
          )
        else if (status == DeliveryPaymentStatus.expired) ...[
          PrimaryCtaButton(
            label: 'Generate New QR',
            trailingIcon: LucideIcons.refreshCw,
            onPressed: onRegenerate,
          ),
          const SizedBox(height: AppSpacing.sm),
          OutlinedButtonCustom(label: 'Close', onPressed: onClose),
        ] else if (status == DeliveryPaymentStatus.failed) ...[
          PrimaryCtaButton(label: 'Try Again', onPressed: onRegenerate),
          const SizedBox(height: AppSpacing.sm),
          OutlinedButtonCustom(label: 'Close', onPressed: onClose),
        ] else if (status == DeliveryPaymentStatus.cancelled) ...[
          PrimaryCtaButton(
            label: 'Generate New QR',
            onPressed: onRegenerate,
          ),
          const SizedBox(height: AppSpacing.sm),
          OutlinedButtonCustom(label: 'Close', onPressed: onClose),
        ] else ...[
          if (status == DeliveryPaymentStatus.connectionError)
            PrimaryCtaButton(
              label: 'Check Status',
              onPressed: onCheckStatus,
            ),
          if (status == DeliveryPaymentStatus.connectionError)
            const SizedBox(height: AppSpacing.sm),
          OutlinedButtonCustom(label: 'Close', onPressed: onClose),
        ],
        if (pending) ...[
          const SizedBox(height: AppSpacing.md),
          OutlinedButtonCustom(
            label: collectingCash ? 'Confirming cash…' : 'Customer paid cash',
            onPressed: collectingCash ? null : onCollectCash,
          ),
          const SizedBox(height: 6),
          Text(
            'Use this only for physical COD. Cash in hand is tracked separately from earnings.',
            textAlign: TextAlign.center,
            style: AppTypography.caption,
          ),
        ],
      ],
    );
  }

  String _titleFor(DeliveryPaymentStatus status) => switch (status) {
        DeliveryPaymentStatus.success => 'Payment Received',
        DeliveryPaymentStatus.expired => 'Payment QR expired',
        DeliveryPaymentStatus.failed => 'Payment failed',
        DeliveryPaymentStatus.cancelled => 'Payment request cancelled',
        _ => 'Payment status',
      };
}

class DeliveryPaymentQrCard extends StatelessWidget {
  const DeliveryPaymentQrCard({
    super.key,
    required this.session,
    required this.status,
  });

  final DeliveryPaymentSession session;
  final DeliveryPaymentStatus status;

  @override
  Widget build(BuildContext context) {
    final blocked = status == DeliveryPaymentStatus.success ||
        status == DeliveryPaymentStatus.expired ||
        status == DeliveryPaymentStatus.failed ||
        status == DeliveryPaymentStatus.cancelled;
    final overlay = switch (status) {
      DeliveryPaymentStatus.success => const PaymentSuccessOverlay(),
      DeliveryPaymentStatus.expired => const _QrOverlay(
          icon: LucideIcons.timerOff,
          label: 'Expired',
          color: AppColors.warning,
        ),
      DeliveryPaymentStatus.failed => const _QrOverlay(
          icon: LucideIcons.xCircle,
          label: 'Payment failed',
          color: AppColors.error,
        ),
      DeliveryPaymentStatus.cancelled => const _QrOverlay(
          icon: LucideIcons.ban,
          label: 'Cancelled',
          color: AppColors.textSecondary,
        ),
      _ => null,
    };

    return Semantics(
      label: blocked
          ? 'Payment QR disabled. ${_statusLabel(status)}'
          : 'Secure payment QR for the customer to scan',
      image: true,
      child: Container(
        width: 252,
        height: 252,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(color: AppColors.border),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.control),
          child: Stack(
            fit: StackFit.expand,
            children: [
              TweenAnimationBuilder<double>(
                duration: AppMotion.duration(context, AppMotion.emphasized),
                curve: AppMotion.enter,
                tween: Tween<double>(end: blocked ? 6 : 0),
                builder: (_, blur, child) => ImageFiltered(
                  imageFilter: ImageFilter.blur(
                    sigmaX: blur,
                    sigmaY: blur,
                  ),
                  child: AnimatedOpacity(
                    duration: AppMotion.duration(
                      context,
                      AppMotion.emphasized,
                    ),
                    opacity: blocked ? 0.28 : 1,
                    child: AbsorbPointer(absorbing: blocked, child: child),
                  ),
                ),
                child: _QrImage(session: session),
              ),
              if (overlay != null) overlay,
            ],
          ),
        ),
      ),
    );
  }

  String _statusLabel(DeliveryPaymentStatus value) => switch (value) {
        DeliveryPaymentStatus.success => 'Payment received',
        DeliveryPaymentStatus.expired => 'Payment QR expired',
        DeliveryPaymentStatus.failed => 'Payment failed',
        DeliveryPaymentStatus.cancelled => 'Payment request cancelled',
        _ => 'Unavailable',
      };
}

class _QrImage extends StatelessWidget {
  const _QrImage({required this.session});

  final DeliveryPaymentSession session;

  @override
  Widget build(BuildContext context) {
    if (session.qrData.isEmpty) {
      return const Center(
        child: Icon(
          LucideIcons.imageOff,
          color: AppColors.textDisabled,
          size: 38,
        ),
      );
    }
    if (session.qrFormat == DeliveryQrFormat.imageUrl) {
      return Image.network(
        session.qrData,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => const _QrUnavailable(),
      );
    }
    if (session.qrFormat == DeliveryQrFormat.encodedImage) {
      try {
        final encoded = session.qrData.contains(',')
            ? session.qrData.split(',').last
            : session.qrData;
        return Image.memory(
          base64Decode(encoded),
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => const _QrUnavailable(),
        );
      } catch (_) {
        return const _QrUnavailable();
      }
    }
    return ColoredBox(
      color: Colors.white,
      child: QrImageView(
        data: session.qrData,
        version: QrVersions.auto,
        errorCorrectionLevel: QrErrorCorrectLevel.M,
        padding: const EdgeInsets.all(6),
        eyeStyle: const QrEyeStyle(
          eyeShape: QrEyeShape.square,
          color: AppColors.textPrimary,
        ),
        dataModuleStyle: const QrDataModuleStyle(
          dataModuleShape: QrDataModuleShape.square,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }
}

class _QrUnavailable extends StatelessWidget {
  const _QrUnavailable();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'QR unavailable\nCheck status',
        textAlign: TextAlign.center,
        style: AppTypography.caption,
      ),
    );
  }
}

class PaymentPendingIndicator extends StatefulWidget {
  const PaymentPendingIndicator({
    super.key,
    required this.isReconnecting,
  });

  final bool isReconnecting;

  @override
  State<PaymentPendingIndicator> createState() =>
      _PaymentPendingIndicatorState();
}

class _PaymentPendingIndicatorState extends State<PaymentPendingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppMotion.ambient,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      label: widget.isReconnecting
          ? 'Reconnecting to check payment status'
          : 'Waiting for customer payment',
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            widget.isReconnecting ? LucideIcons.wifiOff : LucideIcons.clock3,
            size: 18,
            color:
                widget.isReconnecting ? AppColors.warning : AppColors.primary,
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            widget.isReconnecting
                ? 'Reconnecting…'
                : 'Waiting for customer payment',
            style: AppTypography.bodyMedium,
          ),
          if (!widget.isReconnecting) ...[
            const SizedBox(width: 6),
            AnimatedBuilder(
              animation: _controller,
              builder: (_, __) {
                return Row(
                  children: List.generate(3, (index) {
                    final wave = math.sin(
                      (_controller.value * math.pi * 2) - index * 0.8,
                    );
                    return Opacity(
                      opacity: 0.35 + ((wave + 1) / 2) * 0.65,
                      child: const Text(
                        '·',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    );
                  }),
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}

class PaymentCountdown extends StatefulWidget {
  const PaymentCountdown({
    super.key,
    required this.expiresAt,
    required this.onElapsed,
  });

  final DateTime expiresAt;
  final VoidCallback onElapsed;

  @override
  State<PaymentCountdown> createState() => _PaymentCountdownState();
}

class _PaymentCountdownState extends State<PaymentCountdown> {
  Timer? _timer;
  bool _reportedElapsed = false;

  @override
  void initState() {
    super.initState();
    _start();
  }

  @override
  void didUpdateWidget(covariant PaymentCountdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.expiresAt != widget.expiresAt) {
      _reportedElapsed = false;
      _start();
    }
  }

  void _start() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {});
      _notifyIfElapsed();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _notifyIfElapsed();
    });
  }

  void _notifyIfElapsed() {
    if (_reportedElapsed || widget.expiresAt.isAfter(DateTime.now())) return;
    _reportedElapsed = true;
    _timer?.cancel();
    widget.onElapsed();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final difference = widget.expiresAt.difference(DateTime.now());
    final totalSeconds = difference.isNegative ? 0 : difference.inSeconds;
    final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return Semantics(
      label: 'Payment QR expires in $minutes minutes and $seconds seconds',
      child: Text(
        '$minutes:$seconds',
        key: const ValueKey('payment-countdown'),
        style: AppTypography.numericMd.copyWith(
          color: totalSeconds <= 60 ? AppColors.warning : AppColors.textPrimary,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}

class PaymentSuccessOverlay extends StatefulWidget {
  const PaymentSuccessOverlay({super.key});

  @override
  State<PaymentSuccessOverlay> createState() => _PaymentSuccessOverlayState();
}

class _PaymentSuccessOverlayState extends State<PaymentSuccessOverlay> {
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _visible = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AnimatedScale(
        scale: _visible ? 1 : 0.88,
        duration: AppMotion.duration(context, AppMotion.emphasized),
        curve: AppMotion.emphasizedCurve,
        child: AnimatedOpacity(
          opacity: _visible ? 1 : 0,
          duration: AppMotion.duration(context, AppMotion.emphasized),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.surface.withValues(alpha: 0.96),
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.success.withValues(alpha: 0.25),
              ),
            ),
            child: const Icon(
              LucideIcons.check,
              color: AppColors.success,
              size: 44,
            ),
          ),
        ),
      ),
    );
  }
}

class _QrOverlay extends StatelessWidget {
  const _QrOverlay({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: AppColors.surface.withValues(alpha: 0.94),
          borderRadius: BorderRadius.circular(AppRadius.button),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 34),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium.copyWith(color: color),
            ),
          ],
        ),
      ),
    );
  }
}

class _TerminalPaymentDetails extends StatelessWidget {
  const _TerminalPaymentDetails({
    required this.session,
    required this.status,
  });

  final DeliveryPaymentSession session;
  final DeliveryPaymentStatus status;

  @override
  Widget build(BuildContext context) {
    if (status == DeliveryPaymentStatus.success) {
      return Column(
        children: [
          Text(
            CurrencyFormatter.rupees(session.amountRupees),
            style: AppTypography.numericLg.copyWith(
              color: AppColors.success,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Payment confirmed successfully',
            style: AppTypography.bodyMedium,
          ),
          if (session.paidAt != null) ...[
            const SizedBox(height: AppSpacing.sm),
            _DetailRow(
              label: 'Payment time',
              value: DateFormat('d MMM yyyy, h:mm a').format(session.paidAt!),
            ),
          ],
          if (session.transactionId != null) ...[
            const SizedBox(height: 4),
            _DetailRow(
              label: 'Reference',
              value: session.transactionId!,
            ),
          ],
        ],
      );
    }
    final message = switch (status) {
      DeliveryPaymentStatus.expired =>
        'No payment was confirmed. Generate a new QR only after checking this status.',
      DeliveryPaymentStatus.failed => session.failureReason ??
          'The payment could not be completed. No money is marked as received.',
      DeliveryPaymentStatus.cancelled =>
        'This request is no longer payable. A new session is subject to backend rules.',
      _ => 'Check the latest payment status.',
    };
    return Text(
      message,
      textAlign: TextAlign.center,
      style: AppTypography.body.copyWith(color: AppColors.textSecondary),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTypography.caption),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: AppTypography.caption.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _ConnectionWarning extends StatelessWidget {
  const _ConnectionWarning({required this.onCheck});

  final VoidCallback onCheck;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.accentBg,
        borderRadius: BorderRadius.circular(AppRadius.control),
      ),
      child: Row(
        children: [
          const Icon(
            LucideIcons.wifiOff,
            size: 18,
            color: AppColors.warning,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'Connection interrupted. Reconnecting…',
              style: AppTypography.caption.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
          ),
          TextButton(
            onPressed: onCheck,
            child: const Text('Check Status'),
          ),
        ],
      ),
    );
  }
}

class _SecurePaymentIndicator extends StatelessWidget {
  const _SecurePaymentIndicator();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(
          LucideIcons.shieldCheck,
          size: 15,
          color: AppColors.success,
        ),
        const SizedBox(width: 5),
        Text('Secure backend-confirmed payment', style: AppTypography.caption),
      ],
    );
  }
}
