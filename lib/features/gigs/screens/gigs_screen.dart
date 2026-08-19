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
                  Text(
                    'Gigs Schedule',
                    style: AppTypography.h1.copyWith(
                      color: AppColors.textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
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
              const SizedBox(height: 16),
              _buildMockCalendarRow(),
              const SizedBox(height: 20),

              // Slots list locked behind Coming Soon overlay
              Expanded(
                child: Stack(
                  children: [
                    // Mock Gigs slots lists
                    ListView(
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        _buildMockSlotCard(
                          time: '07:00 AM - 11:00 AM',
                          name: 'Breakfast Shift',
                          payout: '₹180 - ₹220',
                        ),
                        const SizedBox(height: 12),
                        _buildMockSlotCard(
                          time: '12:00 PM - 04:00 PM',
                          name: 'Lunch Shift',
                          payout: '₹220 - ₹280',
                        ),
                        const SizedBox(height: 12),
                        _buildMockSlotCard(
                          time: '07:00 PM - 11:00 PM',
                          name: 'Dinner Shift',
                          payout: '₹250 - ₹350',
                        ),
                      ],
                    ),

                    // Glassmorphic Coming Soon Overlay Card
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(16),
                        ),
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
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMockCalendarRow() {
    final days = [
      {'day': 'Mon', 'date': '17'},
      {'day': 'Tue', 'date': '18', 'selected': 'true'},
      {'day': 'Wed', 'date': '19'},
      {'day': 'Thu', 'date': '20'},
      {'day': 'Fri', 'date': '21'},
      {'day': 'Sat', 'date': '22'},
      {'day': 'Sun', 'date': '23'},
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: days.map((d) {
        final isSelected = d['selected'] == 'true';
        return Container(
          width: 44,
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: isSelected ? AppColors.primary : AppColors.border),
          ),
          child: Column(
            children: [
              Text(
                d['day']!,
                style: TextStyle(
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                d['date']!,
                style: TextStyle(
                  color: isSelected ? Colors.white : AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMockSlotCard({
    required String time,
    required String name,
    required String payout,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                time,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              Text(
                payout,
                style: const TextStyle(
                  color: AppColors.success,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            name,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
