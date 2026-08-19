import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

class CountdownTimer extends StatefulWidget {
  final int? seconds;
  final DateTime? expiresAt;
  final VoidCallback onExpired;
  final Color color;

  const CountdownTimer({
    super.key,
    this.seconds,
    this.expiresAt,
    required this.onExpired,
    this.color = AppColors.warning,
  });

  @override
  State<CountdownTimer> createState() => _CountdownTimerState();
}

class _CountdownTimerState extends State<CountdownTimer> {
  late int _remaining;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    assert(widget.expiresAt != null || widget.seconds != null);
    _remaining = _secondsRemaining();
    if (_remaining == 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) => widget.onExpired());
      return;
    }
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final elapsedRemaining = (_remaining - 1).clamp(0, 359999);
      final deadlineRemaining = _secondsRemaining();
      final next = widget.expiresAt == null
          ? elapsedRemaining
          : deadlineRemaining < elapsedRemaining
              ? deadlineRemaining
              : elapsedRemaining;
      if (next <= 0) {
        timer.cancel();
        widget.onExpired();
        if (mounted) setState(() => _remaining = 0);
      } else if (mounted) {
        setState(() => _remaining = next);
      }
    });
  }

  int _secondsRemaining() {
    final expiresAt = widget.expiresAt;
    if (expiresAt == null) return widget.seconds!.clamp(0, 359999);
    final milliseconds = expiresAt.difference(DateTime.now()).inMilliseconds;
    if (milliseconds <= 0) return 0;
    return (milliseconds / 1000).ceil();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      '${(_remaining ~/ 60).toString().padLeft(2, '0')}:'
      '${(_remaining % 60).toString().padLeft(2, '0')}',
      style: AppTypography.numericMd.copyWith(color: widget.color),
    );
  }
}
