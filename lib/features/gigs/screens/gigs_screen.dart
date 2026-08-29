import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/layout/responsive_frame.dart';
import '../../../shared/widgets/navigation/app_tab_scaffold.dart';

class GigsScreen extends StatelessWidget {
  const GigsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: AppTabScaffold(
        currentIndex: 1, // 2nd tab
        child: ResponsiveFrame(
          maxWidth: 520,
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 12),
              // Calendar Mockup Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      'Gigs Schedule',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.h1.copyWith(
                        color: AppColors.textPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      Get.rawSnackbar(
                        message: 'Gigs history is coming soon',
                        backgroundColor: Colors.black,
                        duration: const Duration(seconds: 2),
                      );
                    },
                    icon: const Icon(LucideIcons.history, size: 14, color: AppColors.primary),
                    label: const Text(
                      'History',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // No fixed-slot data exists yet for this rider's area, so the
              // screen shows the coming-soon state honestly instead of
              // rendering placeholder shift/calendar content behind it.
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 15,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: const BoxDecoration(
                              color: AppColors.primarySoft,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(LucideIcons.calendarClock, color: AppColors.primary, size: 32),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Gigs Scheduling is Coming Soon',
                            textAlign: TextAlign.center,
                            style: AppTypography.bodyMedium.copyWith(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'You will be able to book fixed-hour slots and see estimated payouts once it launches in your area.',
                            textAlign: TextAlign.center,
                            style: AppTypography.caption.copyWith(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            height: 44,
                            child: ElevatedButton(
                              onPressed: () {
                                Get.rawSnackbar(
                                  message: 'Gigs history is coming soon',
                                  backgroundColor: Colors.black,
                                  duration: const Duration(seconds: 2),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text(
                                'View Gig History',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                            ),
                          ),
                        ],
                      ),
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
