import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/assets/app_assets.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/layout/responsive_frame.dart';

class OnboardingWelcomeScreen extends StatefulWidget {
  const OnboardingWelcomeScreen({super.key});

  @override
  State<OnboardingWelcomeScreen> createState() =>
      _OnboardingWelcomeScreenState();
}

class _OnboardingWelcomeScreenState extends State<OnboardingWelcomeScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  void _onPageChanged(int index) {
    setState(() => _currentPage = index);
  }

  void _goToNextPage() {
    if (_currentPage < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeInOut,
      );
    } else {
      _finishOnboarding();
    }
  }

  void _finishOnboarding() {
    Get.offAllNamed(AppRoutes.mobileNumber);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: ResponsiveFrame(
          maxWidth: 480,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            children: [
              // Swipeable Page Area
              Expanded(
                child: PageView(
                  controller: _pageController,
                  onPageChanged: _onPageChanged,
                  physics: const BouncingScrollPhysics(),
                  children: [
                    // Step 1: Deliver. Earn. Grow.
                    _OnboardingStepView(
                      showHeaderLogo: true,
                      imageAsset: AppAssets.onboardingStep1Rider,
                      fallbackAsset: AppAssets.riderScooterIndigo3d,
                      titleWidget: RichText(
                        textAlign: TextAlign.center,
                        text: const TextSpan(
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                            fontFamily: 'PlusJakartaSans',
                            letterSpacing: -0.3,
                          ),
                          children: [
                            TextSpan(text: 'Deliver. '),
                            TextSpan(
                              text: 'Earn. ',
                              style: TextStyle(color: Color(0xFF16A34A)),
                            ),
                            TextSpan(text: 'Grow.'),
                          ],
                        ),
                      ),
                      subtitle:
                          'Deliver orders, earn more and grow with Qikzoo.',
                    ),

                    // Step 2: Get Orders Nearby
                    const _OnboardingStepView(
                      showHeaderLogo: false,
                      imageAsset: AppAssets.onboardingStep2Map,
                      fallbackAsset: AppAssets.orderBagNew3d,
                      titleWidget: Text(
                        'Get Orders Nearby',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                          letterSpacing: -0.3,
                        ),
                      ),
                      subtitle:
                          'We notify you instantly when orders are available near you.',
                    ),

                    // Step 3: Track & Earn More
                    _OnboardingStepView(
                      showHeaderLogo: false,
                      imageAsset: AppAssets.onboardingStep3Wallet,
                      fallbackAsset: AppAssets.profileEarningsWallet3d,
                      titleWidget: const Text(
                        'Track & Earn More',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                          letterSpacing: -0.3,
                        ),
                      ),
                      subtitle:
                          'Track your earnings and incentives in real-time and grow your income.',
                      customHeroOverlay: _buildWalletOverlay(),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Page Dots Indicator
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(3, (index) {
                  final isActive = _currentPage == index;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: isActive ? 20 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: isActive
                          ? AppColors.primary
                          : const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  );
                }),
              ),

              const SizedBox(height: 28),

              // Bottom Primary Action Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _goToNextPage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    _currentPage == 2 ? 'Get Started' : 'Next',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ),

              // Secondary Skip Button (Steps 1 & 2 only)
              SizedBox(
                height: 44,
                child: _currentPage < 2
                    ? TextButton(
                        onPressed: _finishOnboarding,
                        child: const Text(
                          'Skip',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWalletOverlay() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Today's Earnings",
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF64748B),
                ),
              ),
              SizedBox(height: 2),
              Text(
                '₹1,240',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          SizedBox(width: 14),
          Icon(
            LucideIcons.trendingUp,
            color: Color(0xFF2563EB),
            size: 24,
          ),
        ],
      ),
    );
  }
}

class _OnboardingStepView extends StatelessWidget {
  const _OnboardingStepView({
    required this.showHeaderLogo,
    required this.imageAsset,
    required this.fallbackAsset,
    required this.titleWidget,
    required this.subtitle,
    this.customHeroOverlay,
  });

  final bool showHeaderLogo;
  final String imageAsset;
  final String fallbackAsset;
  final Widget titleWidget;
  final String subtitle;
  final Widget? customHeroOverlay;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Top Header Logo (Optional for step 1 or subtle on others)
        SizedBox(
          height: 60,
          child: showHeaderLogo
              ? Center(
                  child: Image.asset(
                    AppAssets.partnerLogoTight,
                    width: 175,
                    height: 58,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => Image.asset(
                      AppAssets.partnerLogoTight,
                      height: 58,
                      fit: BoxFit.contain,
                    ),
                  ),
                )
              : const SizedBox.shrink(),
        ),

        const Spacer(),

        // Center Hero Graphic
        Stack(
          alignment: Alignment.bottomCenter,
          clipBehavior: Clip.none,
          children: [
            Container(
              constraints: const BoxConstraints(maxHeight: 260, maxWidth: 280),
              child: Image.asset(
                imageAsset,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => Image.asset(
                  fallbackAsset,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            if (customHeroOverlay != null)
              Positioned(
                bottom: -10,
                child: customHeroOverlay!,
              ),
          ],
        ),

        const Spacer(),

        // Title & Subtitle Text
        titleWidget,
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14.5,
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w500,
              height: 1.4,
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
