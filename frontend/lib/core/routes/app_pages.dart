import 'package:get/get.dart';
import 'app_routes.dart';
import 'placeholder_screen.dart';
import '../../features/splash/screens/splash_screen.dart';
import '../../features/onboarding_welcome/screens/onboarding_welcome_screen.dart';
import '../../features/onboarding_welcome/screens/join_as_partner_screen.dart';
import '../../features/authentication/screens/mobile_number_screen.dart';
import '../../features/authentication/screens/otp_verification_screen.dart';
import '../../features/authentication/screens/set_password_screen.dart';
import '../../features/partner_registration/screens/personal_info_screen.dart';
import '../../features/partner_registration/screens/select_city_screen.dart';
import '../../features/partner_registration/screens/vehicle_selection_screen.dart';
import '../../features/partner_registration/screens/vehicle_details_screen.dart';
import '../../features/partner_registration/screens/document_upload_screen.dart';
import '../../features/partner_registration/screens/selfie_verification_screen.dart';
import '../../features/partner_registration/screens/application_submitted_screen.dart';
import '../../features/dashboard/screens/dashboard_screen.dart';

class AppPages {
  AppPages._();

  static final pages = <GetPage>[
    GetPage(name: AppRoutes.splash, page: () => const SplashScreen()),
    GetPage(
        name: AppRoutes.welcome, page: () => const OnboardingWelcomeScreen()),
    GetPage(
        name: AppRoutes.becomePartnerIntro,
        page: () => const JoinAsPartnerScreen()),
    GetPage(name: AppRoutes.otp, page: () => const MobileNumberScreen()),
    GetPage(
        name: AppRoutes.otpVerification,
        page: () => const OtpVerificationScreen()),
    GetPage(name: AppRoutes.setPassword, page: () => const SetPasswordScreen()),
    GetPage(
        name: AppRoutes.personalInfo, page: () => const PersonalInfoScreen()),
    GetPage(
        name: AppRoutes.vehicleSelection,
        page: () => const VehicleSelectionScreen()),
    GetPage(
        name: AppRoutes.vehicleDetails,
        page: () => const VehicleDetailsScreen()),
    GetPage(name: AppRoutes.deliveryZone, page: () => const SelectCityScreen()),
    GetPage(
        name: AppRoutes.documentUpload,
        page: () => const DocumentUploadScreen()),
    GetPage(
        name: AppRoutes.selfieVerification,
        page: () => const SelfieVerificationScreen()),
    GetPage(
        name: AppRoutes.applicationSubmitted,
        page: () => const ApplicationSubmittedScreen()),
    GetPage(
        name: AppRoutes.bankDetails,
        page: () => const PlaceholderScreen(title: 'Bank Details')),
    GetPage(
        name: AppRoutes.verificationStatus,
        page: () => const PlaceholderScreen(title: 'Verification Status')),
    GetPage(
        name: AppRoutes.training,
        page: () => const PlaceholderScreen(title: 'Training')),
    GetPage(
        name: AppRoutes.agreement,
        page: () => const PlaceholderScreen(title: 'Agreement')),
    GetPage(
        name: AppRoutes.approval,
        page: () => const PlaceholderScreen(title: 'Approval')),
    GetPage(name: AppRoutes.dashboard, page: () => const DashboardScreen()),
    GetPage(
        name: AppRoutes.orders,
        page: () => const PlaceholderScreen(title: 'Orders')),
    GetPage(
        name: AppRoutes.wallet,
        page: () => const PlaceholderScreen(title: 'Wallet')),
    GetPage(
        name: AppRoutes.support,
        page: () => const PlaceholderScreen(title: 'Support')),
    GetPage(
        name: AppRoutes.profile,
        page: () => const PlaceholderScreen(title: 'Profile')),
    GetPage(
        name: AppRoutes.notifications,
        page: () => const PlaceholderScreen(title: 'Notifications')),
    GetPage(
        name: AppRoutes.settings,
        page: () => const PlaceholderScreen(title: 'Settings')),
  ];
}
