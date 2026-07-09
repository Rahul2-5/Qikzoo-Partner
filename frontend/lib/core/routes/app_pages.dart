import 'package:get/get.dart';
import 'app_routes.dart';
import 'placeholder_screen.dart';
import '../../features/splash/screens/splash_screen.dart';
import '../../features/onboarding_welcome/screens/onboarding_welcome_screen.dart';
import '../../features/onboarding_welcome/screens/join_as_partner_screen.dart';

class AppPages {
  AppPages._();

  static final pages = <GetPage>[
    GetPage(name: AppRoutes.splash, page: () => const SplashScreen()),
    GetPage(name: AppRoutes.welcome, page: () => const OnboardingWelcomeScreen()),
    GetPage(name: AppRoutes.becomePartnerIntro, page: () => const JoinAsPartnerScreen()),
    GetPage(name: AppRoutes.otp, page: () => const PlaceholderScreen(title: 'OTP Verification')),
    GetPage(name: AppRoutes.personalInfo, page: () => const PlaceholderScreen(title: 'Personal Information')),
    GetPage(name: AppRoutes.vehicleSelection, page: () => const PlaceholderScreen(title: 'Vehicle Selection')),
    GetPage(name: AppRoutes.deliveryZone, page: () => const PlaceholderScreen(title: 'Delivery Zone')),
    GetPage(name: AppRoutes.documentUpload, page: () => const PlaceholderScreen(title: 'Document Upload')),
    GetPage(name: AppRoutes.bankDetails, page: () => const PlaceholderScreen(title: 'Bank Details')),
    GetPage(name: AppRoutes.verificationStatus, page: () => const PlaceholderScreen(title: 'Verification Status')),
    GetPage(name: AppRoutes.training, page: () => const PlaceholderScreen(title: 'Training')),
    GetPage(name: AppRoutes.agreement, page: () => const PlaceholderScreen(title: 'Agreement')),
    GetPage(name: AppRoutes.approval, page: () => const PlaceholderScreen(title: 'Approval')),
    GetPage(name: AppRoutes.dashboard, page: () => const PlaceholderScreen(title: 'Dashboard')),
    GetPage(name: AppRoutes.orders, page: () => const PlaceholderScreen(title: 'Orders')),
    GetPage(name: AppRoutes.wallet, page: () => const PlaceholderScreen(title: 'Wallet')),
    GetPage(name: AppRoutes.support, page: () => const PlaceholderScreen(title: 'Support')),
    GetPage(name: AppRoutes.profile, page: () => const PlaceholderScreen(title: 'Profile')),
    GetPage(name: AppRoutes.notifications, page: () => const PlaceholderScreen(title: 'Notifications')),
    GetPage(name: AppRoutes.settings, page: () => const PlaceholderScreen(title: 'Settings')),
  ];
}
