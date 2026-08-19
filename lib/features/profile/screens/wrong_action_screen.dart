import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/feedback/app_snack_bar.dart';
import '../../../shared/widgets/layout/responsive_frame.dart';
import '../../../shared/widgets/misc/cached_avatar.dart';

class WrongActionScreen extends StatelessWidget {
  const WrongActionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft,
              color: Color(0xFF0F172A), size: 24),
          onPressed: () => Get.back(),
        ),
        toolbarHeight: 64,
        title: const Text(
          'Wrong action details',
          softWrap: true,
          style: TextStyle(
            fontFamily: 'PlusJakartaSans',
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Color(0xFF0F172A),
            letterSpacing: -0.2,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.helpCircle,
                color: Color(0xFF0F172A), size: 22),
            onPressed: () => Get.toNamed('/support'),
          ),
        ],
      ),
      body: SafeArea(
        child: ResponsiveFrame(
          maxWidth: 520,
          padding: const EdgeInsets.all(AppSpacing.md),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Card with Green Banner and Counter
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Green Header Banner
                      Container(
                        height: 70,
                        decoration: const BoxDecoration(
                          color: Color(0xFF10B981),
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(15),
                            topRight: Radius.circular(15),
                          ),
                        ),
                      ),

                      // Overlapping Avatar & Score
                      Transform.translate(
                        offset: const Offset(0, -32),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(3),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                border:
                                    Border.all(color: Colors.white, width: 3),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.1),
                                    blurRadius: 10,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: const CachedAvatar(radius: 29),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              '0',
                              style: TextStyle(
                                fontFamily: 'PlusJakartaSans',
                                color: Color(0xFF0F172A),
                                fontSize: 44,
                                fontWeight: FontWeight.w800,
                                height: 1,
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Wrong actions in last 30 days',
                              style: TextStyle(
                                fontFamily: 'PlusJakartaSans',
                                color: Color(0xFF64748B),
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const Divider(height: 1, color: Color(0xFFF1F5F9)),

                      // Green History Link
                      InkWell(
                        onTap: () {
                          AppSnackBar.info(context,
                              'No wrong actions logged for your account.');
                        },
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(15),
                          bottomRight: Radius.circular(15),
                        ),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 14),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Flexible(
                                child: Text(
                                  'See wrong actions history',
                                  softWrap: true,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontFamily: 'PlusJakartaSans',
                                    color: Color(0xFF16A34A),
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              SizedBox(width: 4),
                              Icon(
                                LucideIcons.chevronRight,
                                color: Color(0xFF16A34A),
                                size: 16,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                // Ways to avoid section header with divider lines
                const Row(
                  children: [
                    Expanded(child: Divider(color: Color(0xFFE2E8F0))),
                    Flexible(
                      flex: 4,
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          'Ways to avoid wrong actions',
                          textAlign: TextAlign.center,
                          softWrap: true,
                          style: TextStyle(
                            fontFamily: 'PlusJakartaSans',
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                      ),
                    ),
                    Expanded(child: Divider(color: Color(0xFFE2E8F0))),
                  ],
                ),
                const SizedBox(height: 16),

                // Avoidance tips list
                _buildCleanTipItem(
                  'Make sure to always deliver the package to the customer',
                ),
                const SizedBox(height: 12),
                _buildCleanTipItem(
                  'Verify customer details and order items before handing over',
                ),
                const SizedBox(height: 12),
                _buildCleanTipItem(
                  'Do not mark an order delivered before physically completing the trip',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCleanTipItem(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            LucideIcons.checkCircle2,
            color: Color(0xFF10B981),
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontFamily: 'PlusJakartaSans',
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E293B),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
