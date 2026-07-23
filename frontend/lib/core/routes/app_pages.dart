import 'package:get/get.dart';
import 'app_routes.dart';
import 'placeholder_screen.dart';
import '../../features/splash/screens/splash_screen.dart';
import '../../features/onboarding_welcome/screens/onboarding_welcome_screen.dart';
import '../../features/onboarding_welcome/screens/partner_benefits_screen.dart';
import '../../features/authentication/screens/mobile_number_screen.dart';
import '../../features/authentication/screens/otp_verification_screen.dart';
import '../../features/authentication/screens/set_password_screen.dart';
import '../../features/partner_registration/screens/address_screen.dart';
import '../../features/partner_registration/screens/emergency_contact_screen.dart';
import '../../features/partner_registration/screens/kyc_screen.dart';
import '../../features/partner_registration/screens/personal_info_screen.dart';
import '../../features/partner_registration/screens/review_screen.dart';
import '../../features/partner_registration/screens/select_city_screen.dart';
import '../../features/partner_registration/screens/vehicle_registration_screen.dart';
import '../../features/partner_registration/screens/verification_status_screen.dart';
import '../../features/partner_registration/screens/vehicle_selection_screen.dart';
import '../../features/partner_registration/screens/vehicle_details_screen.dart';
import '../../features/partner_registration/screens/document_upload_screen.dart';
import '../../features/partner_registration/screens/selfie_verification_screen.dart';
import '../../features/partner_registration/screens/welcome_kit_screen.dart';
import '../../features/partner_registration/screens/payment_status_screens.dart';
import '../../features/partner_registration/screens/application_submitted_screen.dart';
import '../../features/dashboard/screens/dashboard_home_screen.dart';
import '../../features/earnings/screens/earnings_screen.dart';
import '../../features/orders/screens/active_order_screen.dart';
import '../../features/orders/screens/incoming_offer_screen.dart';
import '../../features/orders/screens/order_details_screen.dart';
import '../../features/orders/screens/orders_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/bank_details/screens/bank_details_screen.dart';
import '../../features/documents/screens/manage_documents_screen.dart';
import '../../features/settings/screens/settings_screen.dart';
import '../../features/support/screens/help_support_screen.dart';
import '../../features/vehicle_details/screens/manage_vehicle_details_screen.dart';
import '../../models/authentication/auth_flow.dart';

class AppPages {
  AppPages._();

  static final pages = <GetPage>[
    GetPage(name: AppRoutes.splash, page: () => const SplashScreen()),
    GetPage(
        name: AppRoutes.welcome, page: () => const OnboardingWelcomeScreen()),
    GetPage(
        name: AppRoutes.partnerBenefits,
        page: () => const PartnerBenefitsScreen()),
    GetPage(
      name: AppRoutes.otp,
      page: () => MobileNumberScreen(
        flow: authFlowFromRoute(Get.parameters['flow']),
      ),
    ),
    GetPage(
      name: AppRoutes.otpVerification,
      page: () => OtpVerificationScreen(
        flow: authFlowFromRoute(Get.parameters['flow']),
      ),
    ),
    GetPage(name: AppRoutes.setPassword, page: () => const SetPasswordScreen()),
    GetPage(
        name: AppRoutes.personalInfo, page: () => const PersonalInfoScreen()),
    GetPage(name: AppRoutes.address, page: () => const AddressScreen()),
    GetPage(name: AppRoutes.kyc, page: () => const KycScreen()),
    GetPage(
        name: AppRoutes.vehicleRegistration,
        page: () => const VehicleRegistrationScreen()),
    GetPage(
        name: AppRoutes.emergencyContact,
        page: () => const EmergencyContactScreen()),
    GetPage(name: AppRoutes.review, page: () => const ReviewScreen()),
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
    GetPage(name: AppRoutes.welcomeKit, page: () => const WelcomeKitScreen()),
    GetPage(
      name: AppRoutes.paymentComingSoon,
      page: () => const PaymentComingSoonScreen(),
    ),
    GetPage(
      name: AppRoutes.applicationUnderReview,
      page: () => ApplicationUnderReviewScreen(),
    ),
    GetPage(
        name: AppRoutes.applicationSubmitted,
        page: () => const ApplicationSubmittedScreen()),
    GetPage(name: AppRoutes.bankDetails, page: () => const BankDetailsScreen()),
    GetPage(
        name: AppRoutes.verificationStatus,
        page: () => const VerificationStatusScreen()),
    GetPage(
        name: AppRoutes.training,
        page: () => const PlaceholderScreen(title: 'Training')),
    GetPage(
        name: AppRoutes.agreement,
        page: () => const PlaceholderScreen(title: 'Agreement')),
    GetPage(
        name: AppRoutes.approval,
        page: () => const PlaceholderScreen(title: 'Approval')),
    GetPage(
      name: AppRoutes.dashboard,
      page: () => const DashboardHomeScreen(),
    ),
    GetPage(name: AppRoutes.earnings, page: () => const EarningsScreen()),
    GetPage(name: AppRoutes.orders, page: () => const OrdersScreen()),
    GetPage(
        name: AppRoutes.incomingOffer, page: () => const IncomingOfferScreen()),
    GetPage(name: AppRoutes.activeOrder, page: () => const ActiveOrderScreen()),
    GetPage(
      name: AppRoutes.orderDetails,
      page: () => OrderDetailsScreen(riderOrderId: Get.arguments as String),
    ),
    GetPage(
        name: AppRoutes.wallet,
        page: () => const PlaceholderScreen(title: 'Wallet')),
    GetPage(name: AppRoutes.support, page: () => const HelpSupportScreen()),
    GetPage(name: AppRoutes.profile, page: () => const ProfileScreen()),
    GetPage(
        name: AppRoutes.manageVehicleDetails,
        page: () => const ManageVehicleDetailsScreen()),
    GetPage(
        name: AppRoutes.manageDocuments,
        page: () => const ManageDocumentsScreen()),
    GetPage(
        name: AppRoutes.notifications,
        page: () => const PlaceholderScreen(title: 'Notifications')),
    GetPage(name: AppRoutes.settings, page: () => const SettingsScreen()),
  ];
}
