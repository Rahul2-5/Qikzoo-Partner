import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:delivery_partner_app/core/api/api_exception.dart';
import 'package:delivery_partner_app/core/routes/app_routes.dart';
import 'package:delivery_partner_app/features/partner_registration/screens/vehicle_registration_screen.dart';
import 'package:delivery_partner_app/models/authentication/auth_session_model.dart';
import 'package:delivery_partner_app/models/authentication/otp_model.dart';
import 'package:delivery_partner_app/models/onboarding_status/onboarding_status_model.dart';
import 'package:delivery_partner_app/models/partner_registration/personal_info_model.dart';
import 'package:delivery_partner_app/models/profile/partner_profile_model.dart';
import 'package:delivery_partner_app/models/profile/rating_model.dart';
import 'package:delivery_partner_app/models/vehicle/rider_vehicle_model.dart';
import 'package:delivery_partner_app/repositories/authentication/auth_repository.dart';
import 'package:delivery_partner_app/repositories/document_verification/document_image_picker.dart';
import 'package:delivery_partner_app/repositories/onboarding_status/onboarding_status_repository.dart';
import 'package:delivery_partner_app/repositories/profile/profile_repository.dart';
import 'package:delivery_partner_app/repositories/vehicle/vehicle_repository.dart';
import 'package:delivery_partner_app/shared/widgets/buttons/primary_cta_button.dart';

class FakeVehicleRepository implements VehicleRepository {
  FakeVehicleRepository([List<RiderVehicleModel>? initial])
      : _vehicles = initial ?? [];

  final List<RiderVehicleModel> _vehicles;
  Object? createError;
  Object? uploadRcError;
  int createCalls = 0;
  int uploadRcCalls = 0;
  int uploadInsuranceCalls = 0;

  @override
  Future<List<RiderVehicleModel>> listVehicles() async =>
      List.unmodifiable(_vehicles);

  @override
  Future<RiderVehicleModel> createVehicle({
    required VehicleType type,
    required String registrationNumber,
    String? insuranceNumber,
    DateTime? insuranceExpiry,
    String? rcNumber,
  }) async {
    createCalls++;
    if (createError != null) throw createError!;
    final vehicle = RiderVehicleModel(
      id: 'vehicle_${_vehicles.length + 1}',
      type: type,
      registrationNumber: registrationNumber,
      insuranceNumber: insuranceNumber,
      insuranceExpiry: insuranceExpiry,
      rcNumber: rcNumber,
      isActive: true,
    );
    _vehicles.insert(0, vehicle);
    return vehicle;
  }

  @override
  Future<RiderVehicleModel> setActive(String vehicleId) =>
      throw UnimplementedError();

  @override
  Future<RiderVehicleModel> uploadRcDocument(
    String vehicleId,
    File file, {
    void Function(int sent, int total)? onSendProgress,
    CancelToken? cancelToken,
  }) async {
    uploadRcCalls++;
    onSendProgress?.call(1, 1);
    if (uploadRcError != null) throw uploadRcError!;
    final index = _vehicles.indexWhere((v) => v.id == vehicleId);
    final updated = _copyWith(_vehicles[index], rcDocumentUrl: file.path);
    _vehicles[index] = updated;
    return updated;
  }

  @override
  Future<RiderVehicleModel> uploadInsuranceDocument(
    String vehicleId,
    File file, {
    void Function(int sent, int total)? onSendProgress,
    CancelToken? cancelToken,
  }) async {
    uploadInsuranceCalls++;
    onSendProgress?.call(1, 1);
    final index = _vehicles.indexWhere((v) => v.id == vehicleId);
    final updated =
        _copyWith(_vehicles[index], insuranceDocumentUrl: file.path);
    _vehicles[index] = updated;
    return updated;
  }

  RiderVehicleModel _copyWith(
    RiderVehicleModel v, {
    String? rcDocumentUrl,
    String? insuranceDocumentUrl,
  }) =>
      RiderVehicleModel(
        id: v.id,
        type: v.type,
        registrationNumber: v.registrationNumber,
        insuranceNumber: v.insuranceNumber,
        insuranceExpiry: v.insuranceExpiry,
        insuranceDocumentUrl: insuranceDocumentUrl ?? v.insuranceDocumentUrl,
        rcNumber: v.rcNumber,
        rcDocumentUrl: rcDocumentUrl ?? v.rcDocumentUrl,
        isActive: v.isActive,
        status: v.status,
        rejectionReason: v.rejectionReason,
      );
}

class FlakyVehicleRepository implements VehicleRepository {
  FlakyVehicleRepository(this._vehicles);
  final List<RiderVehicleModel> _vehicles;
  int listCalls = 0;

  @override
  Future<List<RiderVehicleModel>> listVehicles() async {
    listCalls++;
    if (listCalls == 1) {
      throw const ApiException(
        message: 'Unable to connect. Check your internet connection.',
      );
    }
    return _vehicles;
  }

  @override
  Future<RiderVehicleModel> createVehicle({
    required VehicleType type,
    required String registrationNumber,
    String? insuranceNumber,
    DateTime? insuranceExpiry,
    String? rcNumber,
  }) =>
      throw UnimplementedError();

  @override
  Future<RiderVehicleModel> setActive(String vehicleId) =>
      throw UnimplementedError();

  @override
  Future<RiderVehicleModel> uploadRcDocument(
    String vehicleId,
    File file, {
    void Function(int sent, int total)? onSendProgress,
    CancelToken? cancelToken,
  }) =>
      throw UnimplementedError();

  @override
  Future<RiderVehicleModel> uploadInsuranceDocument(
    String vehicleId,
    File file, {
    void Function(int sent, int total)? onSendProgress,
    CancelToken? cancelToken,
  }) =>
      throw UnimplementedError();
}

class FakeProfileRepository implements ProfileRepository {
  FakeProfileRepository(this._profile);
  final PartnerProfileModel _profile;

  @override
  Future<PartnerProfileModel> getProfile() async => _profile;

  @override
  Future<RatingModel> getRating() async =>
      const RatingModel(average: 0, totalRatings: 0);

  @override
  Future<PartnerProfileModel> updatePersonalDetails({
    required String name,
    String? email,
    required DateTime dateOfBirth,
    required Gender gender,
  }) =>
      throw UnimplementedError();

  @override
  Future<PartnerProfileModel> uploadProfilePhoto(
    File file, {
    void Function(int sent, int total)? onSendProgress,
    CancelToken? cancelToken,
  }) =>
      throw UnimplementedError();

  @override
  Future<PartnerProfileModel> updateAddress({
    required String addressLine1,
    String? addressLine2,
    String? landmark,
    required String city,
    required String state,
    required String pincode,
    double? addressLat,
    double? addressLng,
  }) =>
      throw UnimplementedError();

  @override
  Future<PartnerProfileModel> updateEmergencyContact({
    required String emergencyContactName,
    required String emergencyContactPhone,
  }) =>
      throw UnimplementedError();
}

class FakeOnboardingStatusRepository implements OnboardingStatusRepository {
  FakeOnboardingStatusRepository({this.status, this.error});
  final OnboardingStatusModel? status;
  final Object? error;

  @override
  Future<OnboardingStatusModel> getStatus() async {
    if (error != null) throw error!;
    return status!;
  }

  @override
  Future<void> submitOnboarding({
    required String termsVersion,
    required String privacyPolicyVersion,
  }) =>
      throw UnimplementedError();

  @override
  Future<void> reapply() => throw UnimplementedError();
}

class FakeAuthRepository implements AuthRepository {
  bool loggedOut = false;

  @override
  Future<OtpModel> requestOtp(String phoneNumber) => throw UnimplementedError();

  @override
  Future<AuthSessionModel> verifyOtp(String phoneNumber, String otp,
          {String? name}) =>
      throw UnimplementedError();

  @override
  Future<void> logout() async {
    loggedOut = true;
  }
}

class FakeDocumentImagePicker implements DocumentImagePicker {
  FakeDocumentImagePicker(this.path);
  final String? path;

  @override
  Future<String?> pickImage(ImageSource source) async => path;
}

PartnerProfileModel mockProfile() => PartnerProfileModel(
      id: 'rider_1',
      name: 'Ravi Kumar',
      phone: '9876543210',
      joinedDate: DateTime(2026, 1, 1),
    );

final List<int> _testPngBytes = [
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D,
  0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
  0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00,
  0x0A, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
  0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49,
  0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
];

File writeTestPngFile() {
  final file = File(
    '${Directory.systemTemp.path}/vehicle_test_${DateTime.now().microsecondsSinceEpoch}.png',
  );
  file.writeAsBytesSync(_testPngBytes);
  return file;
}

void setTallSurface(WidgetTester tester) {
  tester.view.physicalSize = const Size(400, 2600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Widget buildApp({
  required VehicleRepository vehicleRepository,
  FakeAuthRepository? authRepository,
  FakeDocumentImagePicker? imagePicker,
  FakeOnboardingStatusRepository? onboardingStatusRepository,
}) {
  return ProviderScope(
    overrides: [
      vehicleRepositoryProvider.overrideWithValue(vehicleRepository),
      profileRepositoryProvider
          .overrideWithValue(FakeProfileRepository(mockProfile())),
      if (authRepository != null)
        authRepositoryProvider.overrideWithValue(authRepository),
      if (imagePicker != null)
        documentImagePickerProvider.overrideWithValue(imagePicker),
      if (onboardingStatusRepository != null)
        onboardingStatusRepositoryProvider
            .overrideWithValue(onboardingStatusRepository),
    ],
    child: GetMaterialApp(
      initialRoute: AppRoutes.vehicleRegistration,
      getPages: [
        GetPage(
          name: AppRoutes.vehicleRegistration,
          page: () => const VehicleRegistrationScreen(),
        ),
        GetPage(
          name: AppRoutes.emergencyContact,
          page: () => const Scaffold(body: Text('Emergency Contact Screen')),
        ),
        GetPage(
          name: AppRoutes.dashboard,
          page: () => const Scaffold(body: Text('Dashboard Screen')),
        ),
      ],
    ),
  );
}

void main() {
  setUp(() {
    Get.testMode = true;
    GoogleFonts.config.allowRuntimeFetching = false;
  });
  tearDown(Get.reset);

  testWidgets('an empty vehicle list shows the registration form, Continue disabled',
      (tester) async {
    setTallSurface(tester);
    final repo = FakeVehicleRepository();
    await tester.pumpWidget(buildApp(vehicleRepository: repo));
    await tester.pumpAndSettle();

    expect(find.text('Register Your Vehicle'), findsOneWidget);
    final button = tester.widget<PrimaryCtaButton>(
        find.widgetWithText(PrimaryCtaButton, 'Continue'));
    expect(button.onPressed, isNull);
  });

  testWidgets('an invalid registration number keeps Register disabled',
      (tester) async {
    setTallSurface(tester);
    final repo = FakeVehicleRepository();
    await tester.pumpWidget(buildApp(vehicleRepository: repo));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Bike'));
    await tester.pump();
    await tester.enterText(find.byType(TextField).first, 'AB');
    await tester.pump();

    expect(find.text('Enter a valid registration number'), findsOneWidget);
  });

  testWidgets(
      'registering a vehicle succeeds and shows document upload rows',
      (tester) async {
    setTallSurface(tester);
    final repo = FakeVehicleRepository();
    await tester.pumpWidget(buildApp(vehicleRepository: repo));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Bike'));
    await tester.pump();
    await tester.enterText(find.byType(TextField).first, 'KA01AB1234');
    await tester.pump();
    await tester.tap(find.text('Register Vehicle'));
    await tester.pumpAndSettle();

    expect(repo.createCalls, 1);
    expect(find.text('Registered Vehicle'), findsOneWidget);
    expect(find.text('RC Document'), findsOneWidget);
    expect(find.text('Insurance Document'), findsOneWidget);
    expect(find.text('Not uploaded'), findsNWidgets(2));
  });

  testWidgets('a 409 duplicate registration number shows an error message',
      (tester) async {
    setTallSurface(tester);
    final repo = FakeVehicleRepository()
      ..createError = const ApiException(
        message: 'This vehicle is already registered to your account.',
        statusCode: 409,
      );
    await tester.pumpWidget(buildApp(vehicleRepository: repo));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Bike'));
    await tester.pump();
    await tester.enterText(find.byType(TextField).first, 'KA01AB1234');
    await tester.pump();
    await tester.tap(find.text('Register Vehicle'));
    await tester.pumpAndSettle();

    expect(find.textContaining('already registered'), findsWidgets);
  });

  testWidgets(
      'uploading both RC and Insurance documents enables Continue',
      (tester) async {
    setTallSurface(tester);
    final existingFile = writeTestPngFile();
    final repo = FakeVehicleRepository([
      const RiderVehicleModel(
        id: 'vehicle_1',
        type: VehicleType.bike,
        registrationNumber: 'KA01AB1234',
        isActive: true,
      ),
    ]);
    await tester.pumpWidget(buildApp(
      vehicleRepository: repo,
      imagePicker: FakeDocumentImagePicker(existingFile.path),
    ));
    await tester.pumpAndSettle();

    final button =
        tester.widget<PrimaryCtaButton>(find.byType(PrimaryCtaButton));
    expect(button.onPressed, isNull);

    await tester.runAsync(() async {
      await tester.tap(find.text('Upload').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Choose from Gallery'));
      await Future<void>.delayed(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));
    });
    await tester.pumpAndSettle();

    await tester.runAsync(() async {
      await tester.tap(find.text('Upload').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Choose from Gallery'));
      await Future<void>.delayed(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));
    });
    await tester.pumpAndSettle();

    expect(repo.uploadRcCalls, 1);
    expect(repo.uploadInsuranceCalls, 1);
    expect(find.text('Uploaded'), findsNWidgets(2));
    final updatedButton =
        tester.widget<PrimaryCtaButton>(find.byType(PrimaryCtaButton));
    expect(updatedButton.onPressed, isNotNull);
  });

  testWidgets('a rejected vehicle shows the rejection reason and a re-register link',
      (tester) async {
    setTallSurface(tester);
    final repo = FakeVehicleRepository([
      const RiderVehicleModel(
        id: 'vehicle_1',
        type: VehicleType.bike,
        registrationNumber: 'KA01AB1234',
        rcDocumentUrl: 'rider-vehicle-documents/rc.jpg',
        insuranceDocumentUrl: 'rider-vehicle-documents/insurance.jpg',
        isActive: true,
        status: VehicleDocumentStatus.rejected,
        rejectionReason: 'RC document is blurry.',
      ),
    ]);
    await tester.pumpWidget(buildApp(vehicleRepository: repo));
    await tester.pumpAndSettle();

    expect(find.textContaining('RC document is blurry'), findsOneWidget);
    expect(find.text('Register a different vehicle'), findsOneWidget);

    final button =
        tester.widget<PrimaryCtaButton>(find.byType(PrimaryCtaButton));
    expect(button.onPressed, isNull);
  });

  testWidgets('a locked (403) section shows a banner on create',
      (tester) async {
    setTallSurface(tester);
    final repo = FakeVehicleRepository()
      ..createError = const ApiException(
        message:
            'Onboarding has already been submitted — this section can no longer be edited.',
        statusCode: 403,
      );
    await tester.pumpWidget(buildApp(vehicleRepository: repo));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Bike'));
    await tester.pump();
    await tester.enterText(find.byType(TextField).first, 'KA01AB1234');
    await tester.pump();
    await tester.tap(find.text('Register Vehicle'));
    await tester.pumpAndSettle();

    expect(find.textContaining('can no longer be edited'), findsWidgets);
  });

  testWidgets('an offline failure on create shows a persistent offline banner',
      (tester) async {
    setTallSurface(tester);
    final repo = FakeVehicleRepository()
      ..createError = const ApiException(
        message: 'Unable to connect. Check your internet connection.',
        code: 'connectionError',
      );
    await tester.pumpWidget(buildApp(vehicleRepository: repo));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Bike'));
    await tester.pump();
    await tester.enterText(find.byType(TextField).first, 'KA01AB1234');
    await tester.pump();
    await tester.tap(find.text('Register Vehicle'));
    await tester.pumpAndSettle();

    expect(find.textContaining("You're offline"), findsOneWidget);
  });

  testWidgets('an initial load failure shows Retry, which re-fetches successfully',
      (tester) async {
    setTallSurface(tester);
    final repo = FlakyVehicleRepository([
      const RiderVehicleModel(
        id: 'vehicle_1',
        type: VehicleType.bike,
        registrationNumber: 'KA01AB1234',
        isActive: true,
      ),
    ]);
    await tester.pumpWidget(buildApp(vehicleRepository: repo));
    await tester.pumpAndSettle();

    expect(find.text('Could not load your vehicle'), findsOneWidget);

    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    expect(find.text('Registered Vehicle'), findsOneWidget);
    expect(repo.listCalls, 2);
  });

  testWidgets(
      'navigation after Continue is backend-driven: an already-active account goes to the dashboard',
      (tester) async {
    setTallSurface(tester);
    final repo = FakeVehicleRepository([
      const RiderVehicleModel(
        id: 'vehicle_1',
        type: VehicleType.bike,
        registrationNumber: 'KA01AB1234',
        rcDocumentUrl: 'rider-vehicle-documents/rc.jpg',
        insuranceDocumentUrl: 'rider-vehicle-documents/insurance.jpg',
        isActive: true,
      ),
    ]);
    final onboardingStatusRepo = FakeOnboardingStatusRepository(
      status: const OnboardingStatusModel(
        accountStatus: RiderAccountStatus.active,
        onboardingStatus: RiderOnboardingStatus.approved,
      ),
    );
    await tester.pumpWidget(buildApp(
      vehicleRepository: repo,
      onboardingStatusRepository: onboardingStatusRepo,
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(find.text('Dashboard Screen'), findsOneWidget);
  });
}
