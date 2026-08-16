import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../models/dashboard/dashboard_stats_model.dart';

/// Maps [RiderStatusTone] to this app's status color language (green =
/// online, amber = busy, grey = offline) — the shared place a rider-status
/// pill/chip reads its color from, so a missed BUSY case can't recur
/// independently in a screen that re-derives it locally. Kept out of the
/// model layer (`dashboard_stats_model.dart`) since it depends on Flutter's
/// `Color`/`AppColors`, not just the plain-Dart enum semantics.
Color riderStatusToneColor(RiderStatusTone tone) => switch (tone) {
      RiderStatusTone.online => AppColors.success,
      RiderStatusTone.busy => AppColors.warning,
      RiderStatusTone.offline => AppColors.textSecondary,
    };
