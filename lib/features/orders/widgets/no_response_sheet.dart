import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

enum NoResponseOutcome { contactSupport, captureProof }

/// Local-only waiting flow. The timer will be replaced with a server-owned
/// countdown when the no-response workflow is integrated with the backend.
class NoResponseSheet {
  NoResponseSheet._();

  static Future<NoResponseOutcome?> show(
    BuildContext context, {
    Duration waitDuration = const Duration(minutes: 5),
  }) =>
      showModalBottomSheet<NoResponseOutcome>(
        context: context,
        isScrollControlled: true,
        backgroundColor: AppColors.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.sheet)),
        ),
        builder: (_) => _NoResponseSheetContent(waitDuration: waitDuration),
      );
}

class _NoResponseSheetContent extends StatefulWidget {
  final Duration waitDuration;

  const _NoResponseSheetContent({required this.waitDuration});

  @override
  State<_NoResponseSheetContent> createState() => _NoResponseSheetContentState();
}

class _NoResponseSheetContentState extends State<_NoResponseSheetContent> {
  Timer? _timer;
  late Duration _remaining;
  bool _calledAgain = false;

  @override
  void initState() {
    super.initState();
    _remaining = widget.waitDuration;
    if (_remaining > Duration.zero) {
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        setState(() {
          _remaining = _remaining > const Duration(seconds: 1)
              ? _remaining - const Duration(seconds: 1)
              : Duration.zero;
          if (_remaining == Duration.zero) _timer?.cancel();
        });
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String get _timerLabel {
    final minutes = _remaining.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = _remaining.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds remaining';
  }

  @override
  Widget build(BuildContext context) {
    final readyForProof = _remaining == Duration.zero;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const Icon(Icons.person_off_outlined, color: AppColors.error),
              const SizedBox(width: AppSpacing.sm),
              Text('Customer not responding', style: AppTypography.h2),
            ]),
            const SizedBox(height: AppSpacing.xs),
            Text('Try the steps below before escalating this delivery.',
                style: AppTypography.caption.copyWith(color: AppColors.textSecondary)),
            const SizedBox(height: AppSpacing.md),
            const _Step(text: 'Call the customer'),
            const _Step(text: 'Send “I’m at the gate”'),
            _Step(text: readyForProof ? 'Waiting period complete' : 'Wait for the customer'),
            const SizedBox(height: AppSpacing.md),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: readyForProof ? AppColors.successBg : AppColors.warningBg,
                borderRadius: BorderRadius.circular(AppRadius.control),
              ),
              child: Text(
                readyForProof ? 'You can now record contactless proof.' : _timerLabel,
                style: AppTypography.bodyMedium,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            if (readyForProof)
              FilledButton.icon(
                onPressed: () => Navigator.of(context).pop(NoResponseOutcome.captureProof),
                icon: const Icon(Icons.camera_alt_outlined),
                label: const Text('Capture drop-off photo'),
              )
            else
              OutlinedButton.icon(
                onPressed: _calledAgain ? null : () => setState(() => _calledAgain = true),
                icon: const Icon(Icons.phone_outlined),
                label: Text(_calledAgain ? 'Call attempt recorded' : 'Call again'),
              ),
            const SizedBox(height: AppSpacing.xs),
            TextButton.icon(
              onPressed: () => Navigator.of(context).pop(NoResponseOutcome.contactSupport),
              icon: const Icon(Icons.headset_mic_outlined, size: 18),
              label: const Text('Contact support'),
            ),
          ],
        ),
      ),
    );
  }
}

class _Step extends StatelessWidget {
  final String text;

  const _Step({required this.text});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
        child: Row(children: [
          const Icon(Icons.check_circle_outline, size: 18, color: AppColors.secondary),
          const SizedBox(width: AppSpacing.sm),
          Text(text, style: AppTypography.body),
        ]),
      );
}
