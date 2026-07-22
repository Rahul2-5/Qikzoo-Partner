import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:delivery_partner_app/core/api/api_exception.dart';
import 'package:delivery_partner_app/core/routes/app_routes.dart';
import 'package:delivery_partner_app/features/partner_registration/screens/kyc_screen.dart';
import 'package:delivery_partner_app/models/authentication/auth_session_model.dart';
import 'package:delivery_partner_app/models/authentication/otp_model.dart';
import 'package:delivery_partner_app/models/kyc/rider_kyc_model.dart';
import 'package:delivery_partner_app/models/onboarding_status/onboarding_status_model.dart';
import 'package:delivery_partner_app/models/partner_registration/personal_info_model.dart';
import 'package:delivery_partner_app/models/profile/partner_profile_model.dart';
import 'package:delivery_partner_app/models/profile/rating_model.dart';
import 'package:delivery_partner_app/repositories/authentication/auth_repository.dart';
import 'package:delivery_partner_app/repositories/document_verification/document_image_picker.dart';
import 'package:delivery_partner_app/repositories/kyc/kyc_repository.dart';
import 'package:delivery_partner_app/repositories/onboarding_status/onboarding_status_repository.dart';
import 'package:delivery_partner_app/repositories/profile/profile_repository.dart';
import 'package:delivery_partner_app/shared/widgets/buttons/primary_cta_button.dart';

class FakeKycRepository implements KycRepository {
  FakeKycRepository(this._current);
  RiderKycModel? _current;

  Object? submitError;
  Object? uploadGovIdError;
  Object? uploadDlError;
  int submitCalls = 0;
  int uploadGovIdCalls = 0;
  int uploadDlCalls = 0;

  /// Last arguments passed to [submit] — asserted on to prove unchanged
  /// fields aren't re-sent.
  String? lastBankAccountNumber;

  /// When true, [uploadGovernmentIdDocument] never completes on its own —
  /// it waits on the real Dio [CancelToken.whenCancel] future, so a test
  /// can deterministically exercise the Cancel button without a timing
  /// race.
  bool holdGovIdUpload = false;

  @override
  Future<RiderKycModel?> getKyc() async => _current;

  @override
  Future<RiderKycModel> submit({
    GovernmentIdType? governmentIdType,
    String? governmentIdNumber,
    String? drivingLicenseNumber,
    DateTime? drivingLicenseExpiry,
    String? bankAccountHolderName,
    String? bankAccountNumber,
    String? confirmBankAccountNumber,
    String? bankIfsc,
    String? bankName,
  }) async {
    submitCalls++;
    lastBankAccountNumber = bankAccountNumber;
    if (submitError != null) throw submitError!;
    final c = _current;
    _current = RiderKycModel(
      governmentIdType: governmentIdType ?? c?.governmentIdType,
      governmentIdNumber: governmentIdNumber ?? c?.governmentIdNumber,
      governmentIdDocumentUrl: c?.governmentIdDocumentUrl,
      drivingLicenseNumber: drivingLicenseNumber ?? c?.drivingLicenseNumber,
      drivingLicenseExpiry: drivingLicenseExpiry ?? c?.drivingLicenseExpiry,
      drivingLicenseDocumentUrl: c?.drivingLicenseDocumentUrl,
      bankAccountHolderName:
          bankAccountHolderName ?? c?.bankAccountHolderName,
      bankAccountNumberMasked: bankAccountNumber != null
          ? '•••• ${bankAccountNumber.substring(bankAccountNumber.length - 4)}'
          : c?.bankAccountNumberMasked,
      bankIfsc: bankIfsc ?? c?.bankIfsc,
      bankName: bankName ?? c?.bankName,
      status: KycDocumentStatus.pending,
    );
    return _current!;
  }

  @override
  Future<RiderKycModel> uploadGovernmentIdDocument(
    File file, {
    void Function(int sent, int total)? onSendProgress,
    CancelToken? cancelToken,
  }) async {
    uploadGovIdCalls++;
    onSendProgress?.call(1, 1);
    if (holdGovIdUpload && cancelToken != null) {
      await cancelToken.whenCancel;
      throw const ApiException(
        message: 'Request was cancelled.',
        code: 'cancel',
      );
    }
    if (uploadGovIdError != null) throw uploadGovIdError!;
    final c = _current;
    _current = RiderKycModel(
      governmentIdType: c?.governmentIdType,
      governmentIdNumber: c?.governmentIdNumber,
      governmentIdDocumentUrl: file.path,
      drivingLicenseNumber: c?.drivingLicenseNumber,
      drivingLicenseExpiry: c?.drivingLicenseExpiry,
      drivingLicenseDocumentUrl: c?.drivingLicenseDocumentUrl,
      bankAccountHolderName: c?.bankAccountHolderName,
      bankAccountNumberMasked: c?.bankAccountNumberMasked,
      bankIfsc: c?.bankIfsc,
      bankName: c?.bankName,
      status: KycDocumentStatus.pending,
    );
    return _current!;
  }

  @override
  Future<RiderKycModel> uploadDrivingLicenseDocument(
    File file, {
    void Function(int sent, int total)? onSendProgress,
    CancelToken? cancelToken,
  }) async {
    uploadDlCalls++;
    onSendProgress?.call(1, 1);
    if (uploadDlError != null) throw uploadDlError!;
    final c = _current;
    _current = RiderKycModel(
      governmentIdType: c?.governmentIdType,
      governmentIdNumber: c?.governmentIdNumber,
      governmentIdDocumentUrl: c?.governmentIdDocumentUrl,
      drivingLicenseNumber: c?.drivingLicenseNumber,
      drivingLicenseExpiry: c?.drivingLicenseExpiry,
      drivingLicenseDocumentUrl: file.path,
      bankAccountHolderName: c?.bankAccountHolderName,
      bankAccountNumberMasked: c?.bankAccountNumberMasked,
      bankIfsc: c?.bankIfsc,
      bankName: c?.bankName,
      status: KycDocumentStatus.pending,
    );
    return _current!;
  }
}

/// Fails the first [getKyc] call then succeeds, so Retry can be exercised.
class FlakyKycRepository implements KycRepository {
  FlakyKycRepository(this._current);
  final RiderKycModel? _current;
  int getKycCalls = 0;

  @override
  Future<RiderKycModel?> getKyc() async {
    getKycCalls++;
    if (getKycCalls == 1) {
      throw const ApiException(
        message: 'Unable to connect. Check your internet connection.',
      );
    }
    return _current;
  }

  @override
  Future<RiderKycModel> submit({
    GovernmentIdType? governmentIdType,
    String? governmentIdNumber,
    String? drivingLicenseNumber,
    DateTime? drivingLicenseExpiry,
    String? bankAccountHolderName,
    String? bankAccountNumber,
    String? confirmBankAccountNumber,
    String? bankIfsc,
    String? bankName,
  }) =>
      throw UnimplementedError();

  @override
  Future<RiderKycModel> uploadGovernmentIdDocument(
    File file, {
    void Function(int sent, int total)? onSendProgress,
    CancelToken? cancelToken,
  }) =>
      throw UnimplementedError();

  @override
  Future<RiderKycModel> uploadDrivingLicenseDocument(
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

class FakeOnboardingStatusRepository implements OnboardingStatusRepository {
  FakeOnboardingStatusRepository({this.status, this.error});
  final OnboardingStatusModel? status;
  final Object? error;

  @override
  Future<OnboardingStatusModel> getStatus() async {
    if (error != null) throw error!;
    return status!;
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

RiderKycModel mockKyc({
  GovernmentIdType? governmentIdType,
  String? governmentIdNumber,
  String? governmentIdDocumentUrl,
  String? drivingLicenseNumber,
  DateTime? drivingLicenseExpiry,
  String? drivingLicenseDocumentUrl,
  String? bankAccountHolderName,
  String? bankAccountNumberMasked,
  String? bankIfsc,
  String? bankName,
  KycDocumentStatus status = KycDocumentStatus.pending,
  String? rejectionReason,
}) =>
    RiderKycModel(
      governmentIdType: governmentIdType,
      governmentIdNumber: governmentIdNumber,
      governmentIdDocumentUrl: governmentIdDocumentUrl,
      drivingLicenseNumber: drivingLicenseNumber,
      drivingLicenseExpiry: drivingLicenseExpiry,
      drivingLicenseDocumentUrl: drivingLicenseDocumentUrl,
      bankAccountHolderName: bankAccountHolderName,
      bankAccountNumberMasked: bankAccountNumberMasked,
      bankIfsc: bankIfsc,
      bankName: bankName,
      status: status,
      rejectionReason: rejectionReason,
    );

final completeKyc = mockKyc(
  governmentIdType: GovernmentIdType.aadhaar,
  governmentIdNumber: '123456789012',
  governmentIdDocumentUrl: 'rider-kyc-documents/aadhaar.jpg',
  drivingLicenseNumber: 'DL0420110149646',
  drivingLicenseExpiry: DateTime.now().add(const Duration(days: 365)),
  drivingLicenseDocumentUrl: 'rider-kyc-documents/dl.jpg',
  bankAccountHolderName: 'Ravi Kumar',
  bankAccountNumberMasked: '•••• 9012',
  bankIfsc: 'HDFC0001234',
  bankName: 'HDFC Bank',
);

/// A real, valid 1x1 transparent PNG written to a fresh temp file — unlike
/// reusing a text file (e.g. pubspec.yaml), this decodes successfully when
/// the document preview renders it via `Image.file`, avoiding a spurious
/// "Invalid image data" async exception during the test.
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
    '${Directory.systemTemp.path}/kyc_test_${DateTime.now().microsecondsSinceEpoch}.png',
  );
  file.writeAsBytesSync(_testPngBytes);
  return file;
}

void setTallSurface(WidgetTester tester) {
  tester.view.physicalSize = const Size(400, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Widget buildApp({
  required KycRepository kycRepository,
  FakeAuthRepository? authRepository,
  FakeDocumentImagePicker? imagePicker,
  FakeOnboardingStatusRepository? onboardingStatusRepository,
}) {
  return ProviderScope(
    overrides: [
      kycRepositoryProvider.overrideWithValue(kycRepository),
      profileRepositoryProvider.overrideWithValue(FakeProfileRepository(mockProfile())),
      if (authRepository != null)
        authRepositoryProvider.overrideWithValue(authRepository),
      if (imagePicker != null)
        documentImagePickerProvider.overrideWithValue(imagePicker),
      if (onboardingStatusRepository != null)
        onboardingStatusRepositoryProvider
            .overrideWithValue(onboardingStatusRepository),
    ],
    child: GetMaterialApp(
      initialRoute: AppRoutes.kyc,
      getPages: [
        GetPage(name: AppRoutes.kyc, page: () => const KycScreen()),
        GetPage(
          name: AppRoutes.vehicleSelection,
          page: () => const Scaffold(body: Text('Vehicle Selection Screen')),
        ),
        GetPage(
          name: AppRoutes.dashboard,
          page: () => const Scaffold(body: Text('Dashboard Screen')),
        ),
        GetPage(
          name: AppRoutes.welcome,
          page: () => const Scaffold(body: Text('Welcome Screen')),
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

  testWidgets(
      'auto-loads a fully complete KYC submission and enables Continue without edits',
      (tester) async {
    setTallSurface(tester);
    final repo = FakeKycRepository(completeKyc);
    await tester.pumpWidget(buildApp(kycRepository: repo));
    await tester.pumpAndSettle();

    expect(find.text('123456789012'), findsOneWidget);
    expect(find.text('DL0420110149646'), findsOneWidget);
    expect(find.text('Ravi Kumar'), findsOneWidget);
    expect(find.textContaining('•••• 9012'), findsOneWidget);

    final button =
        tester.widget<PrimaryCtaButton>(find.byType(PrimaryCtaButton));
    expect(button.onPressed, isNotNull);
  });

  testWidgets('a brand-new, empty KYC keeps Continue disabled', (tester) async {
    setTallSurface(tester);
    final repo = FakeKycRepository(null);
    await tester.pumpWidget(buildApp(kycRepository: repo));
    await tester.pumpAndSettle();

    final button =
        tester.widget<PrimaryCtaButton>(find.byType(PrimaryCtaButton));
    expect(button.onPressed, isNull);
  });

  testWidgets('an invalid Aadhaar number shows an inline error and disables Continue',
      (tester) async {
    setTallSurface(tester);
    final repo = FakeKycRepository(completeKyc);
    await tester.pumpWidget(buildApp(kycRepository: repo));
    await tester.pumpAndSettle();

    final idField = find.byWidgetPredicate(
      (w) => w is TextField && w.controller?.text == '123456789012',
    );
    await tester.enterText(idField, '12345');
    await tester.pump();

    expect(find.text('Enter a valid 12-digit Aadhaar number'), findsOneWidget);
    final button =
        tester.widget<PrimaryCtaButton>(find.byType(PrimaryCtaButton));
    expect(button.onPressed, isNull);
  });

  testWidgets('tapping a different ID type chip changes the selected chip',
      (tester) async {
    setTallSurface(tester);
    final repo = FakeKycRepository(completeKyc);
    await tester.pumpWidget(buildApp(kycRepository: repo));
    await tester.pumpAndSettle();

    await tester.tap(find.text('PAN Card'));
    await tester.pumpAndSettle();

    // Aadhaar-specific formatting (12-digit hint) is gone once PAN is
    // selected instead.
    expect(find.text('12-digit Aadhaar number'), findsNothing);
  });

  testWidgets(
      'a PAN-type submission validates against the PAN format, not Aadhaar',
      (tester) async {
    setTallSurface(tester);
    final repo = FakeKycRepository(mockKyc(
      governmentIdType: GovernmentIdType.pan,
      governmentIdNumber: 'ABCDE1234F',
      governmentIdDocumentUrl: 'rider-kyc-documents/pan.jpg',
      drivingLicenseNumber: 'DL0420110149646',
      drivingLicenseExpiry: DateTime.now().add(const Duration(days: 365)),
      drivingLicenseDocumentUrl: 'rider-kyc-documents/dl.jpg',
      bankAccountHolderName: 'Ravi Kumar',
      bankAccountNumberMasked: '•••• 9012',
      bankIfsc: 'HDFC0001234',
      bankName: 'HDFC Bank',
    ));
    await tester.pumpWidget(buildApp(kycRepository: repo));
    await tester.pumpAndSettle();

    final idField = find.byWidgetPredicate(
      (w) => w is TextField && w.controller?.text == 'ABCDE1234F',
    );
    await tester.enterText(idField, 'INVALIDPAN');
    await tester.pump();
    expect(find.text('Enter a valid PAN (e.g. ABCDE1234F)'), findsOneWidget);

    final button =
        tester.widget<PrimaryCtaButton>(find.byType(PrimaryCtaButton));
    expect(button.onPressed, isNull);
  });

  testWidgets('a driving licence expiry in the past is flagged as invalid',
      (tester) async {
    setTallSurface(tester);
    final repo = FakeKycRepository(mockKyc(
      governmentIdType: GovernmentIdType.aadhaar,
      governmentIdNumber: '123456789012',
      governmentIdDocumentUrl: 'rider-kyc-documents/aadhaar.jpg',
      drivingLicenseNumber: 'DL0420110149646',
      drivingLicenseExpiry: DateTime.now().subtract(const Duration(days: 10)),
      drivingLicenseDocumentUrl: 'rider-kyc-documents/dl.jpg',
      bankAccountHolderName: 'Ravi Kumar',
      bankAccountNumberMasked: '•••• 9012',
      bankIfsc: 'HDFC0001234',
      bankName: 'HDFC Bank',
    ));
    await tester.pumpWidget(buildApp(kycRepository: repo));
    await tester.pumpAndSettle();

    expect(find.text('Expiry date must be in the future'), findsOneWidget);
    final button =
        tester.widget<PrimaryCtaButton>(find.byType(PrimaryCtaButton));
    expect(button.onPressed, isNull);
  });

  testWidgets('a mismatched account number confirmation shows an inline error',
      (tester) async {
    setTallSurface(tester);
    final repo = FakeKycRepository(completeKyc);
    await tester.pumpWidget(buildApp(kycRepository: repo));
    await tester.pumpAndSettle();

    final accountField = find.byWidgetPredicate(
      (w) => w is TextField && w.controller?.text == '',
    );
    await tester.enterText(accountField.first, '123456789');
    await tester.pump();

    expect(find.text('Account numbers do not match'), findsWidgets);
  });

  testWidgets('an invalid IFSC code shows an inline error', (tester) async {
    setTallSurface(tester);
    final repo = FakeKycRepository(completeKyc);
    await tester.pumpWidget(buildApp(kycRepository: repo));
    await tester.pumpAndSettle();

    final ifscField = find.byWidgetPredicate(
      (w) => w is TextField && w.controller?.text == 'HDFC0001234',
    );
    await tester.enterText(ifscField, 'BADIFSC');
    await tester.pump();

    expect(find.text('Enter a valid 11-character IFSC code'), findsOneWidget);
  });

  testWidgets(
      'leaving the bank account fields blank keeps the on-file account valid '
      'and does not re-send it on Continue', (tester) async {
    setTallSurface(tester);
    final repo = FakeKycRepository(completeKyc);
    await tester.pumpWidget(buildApp(kycRepository: repo));
    await tester.pumpAndSettle();

    expect(find.textContaining('On file: •••• 9012'), findsOneWidget);

    final dlField = find.byWidgetPredicate(
      (w) => w is TextField && w.controller?.text == 'DL0420110149646',
    );
    await tester.enterText(dlField, 'DL0420110149647');
    await tester.pump();

    final button =
        tester.widget<PrimaryCtaButton>(find.byType(PrimaryCtaButton));
    expect(button.onPressed, isNotNull);

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(repo.submitCalls, 1);
    expect(repo.lastBankAccountNumber, isNull);
  });

  testWidgets(
      'Continue on an already-complete, unedited KYC does not re-submit '
      '(would otherwise reset an APPROVED/REJECTED status back to PENDING)',
      (tester) async {
    setTallSurface(tester);
    final repo = FakeKycRepository(completeKyc);
    await tester.pumpWidget(buildApp(kycRepository: repo));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(repo.submitCalls, 0);
    expect(find.text('Vehicle Selection Screen'), findsOneWidget);
  });

  testWidgets('picking a government ID document uploads it and marks it uploaded',
      (tester) async {
    setTallSurface(tester);
    final existingFile = writeTestPngFile();

    final repo = FakeKycRepository(mockKyc(
      governmentIdType: GovernmentIdType.aadhaar,
      governmentIdNumber: '123456789012',
      drivingLicenseNumber: 'DL0420110149646',
      drivingLicenseExpiry: DateTime.now().add(const Duration(days: 365)),
      drivingLicenseDocumentUrl: 'rider-kyc-documents/dl.jpg',
      bankAccountHolderName: 'Ravi Kumar',
      bankAccountNumberMasked: '•••• 9012',
      bankIfsc: 'HDFC0001234',
      bankName: 'HDFC Bank',
    ));
    await tester.pumpWidget(buildApp(
      kycRepository: repo,
      imagePicker: FakeDocumentImagePicker(existingFile.path),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Not uploaded'), findsOneWidget);

    await tester.runAsync(() async {
      await tester.tap(find.text('Upload'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Choose from Gallery'));
      await Future<void>.delayed(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));
    });
    await tester.pumpAndSettle();

    expect(repo.uploadGovIdCalls, 1);
    // The Driving Licence document was already on file in this fixture, so
    // both tiles now read "Uploaded".
    expect(find.text('Uploaded'), findsNWidgets(2));
    final button =
        tester.widget<PrimaryCtaButton>(find.byType(PrimaryCtaButton));
    expect(button.onPressed, isNotNull);
  });

  testWidgets('a failed document upload shows Retry, which succeeds on retry',
      (tester) async {
    setTallSurface(tester);
    final existingFile = writeTestPngFile();

    final repo = FakeKycRepository(completeKyc)
      ..uploadGovIdError = const ApiException(
        message: 'Verification failed due to a server issue. Please try again later.',
        statusCode: 500,
      );
    await tester.pumpWidget(buildApp(
      kycRepository: repo,
      imagePicker: FakeDocumentImagePicker(existingFile.path),
    ));
    await tester.pumpAndSettle();

    await tester.runAsync(() async {
      // Both documents are already uploaded in this fixture, so both tiles
      // show "Replace" — the Government ID one comes first.
      await tester.tap(find.text('Replace').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Choose from Gallery'));
      await Future<void>.delayed(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));
    });
    await tester.pumpAndSettle();

    expect(find.text('Upload failed'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);

    repo.uploadGovIdError = null;
    await tester.runAsync(() async {
      await tester.tap(find.text('Retry'));
      await Future<void>.delayed(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));
    });
    await tester.pumpAndSettle();

    expect(repo.uploadGovIdCalls, 2);
    // Both the Government ID and Driving Licence tiles are uploaded now.
    expect(find.text('Uploaded'), findsNWidgets(2));
  });

  testWidgets('cancelling an in-flight document upload leaves it not uploaded',
      (tester) async {
    setTallSurface(tester);
    final existingFile = writeTestPngFile();

    final repo = FakeKycRepository(mockKyc(
      governmentIdType: GovernmentIdType.aadhaar,
      governmentIdNumber: '123456789012',
      drivingLicenseNumber: 'DL0420110149646',
      drivingLicenseExpiry: DateTime.now().add(const Duration(days: 365)),
      drivingLicenseDocumentUrl: 'rider-kyc-documents/dl.jpg',
      bankAccountHolderName: 'Ravi Kumar',
      bankAccountNumberMasked: '•••• 9012',
      bankIfsc: 'HDFC0001234',
      bankName: 'HDFC Bank',
    ))
      ..holdGovIdUpload = true;
    await tester.pumpWidget(buildApp(
      kycRepository: repo,
      imagePicker: FakeDocumentImagePicker(existingFile.path),
    ));
    await tester.pumpAndSettle();

    await tester.runAsync(() async {
      await tester.tap(find.text('Upload'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Choose from Gallery'));
      await Future<void>.delayed(const Duration(milliseconds: 50));
      await tester.pump(const Duration(milliseconds: 50));
    });
    await tester.pump();

    expect(find.text('Cancel'), findsOneWidget);
    await tester.runAsync(() async {
      await tester.tap(find.text('Cancel'));
      await Future<void>.delayed(const Duration(milliseconds: 50));
      await tester.pump(const Duration(milliseconds: 50));
    });
    await tester.pumpAndSettle();

    expect(find.text('Not uploaded'), findsOneWidget);
  });

  testWidgets('a locked (403) section on submit shows a banner and does not navigate',
      (tester) async {
    setTallSurface(tester);
    final repo = FakeKycRepository(completeKyc)
      ..submitError = const ApiException(
        message:
            'Onboarding has already been submitted — this section can no longer be edited.',
        statusCode: 403,
      );
    await tester.pumpWidget(buildApp(kycRepository: repo));
    await tester.pumpAndSettle();

    final dlField = find.byWidgetPredicate(
      (w) => w is TextField && w.controller?.text == 'DL0420110149646',
    );
    await tester.enterText(dlField, 'DL0420110149647');
    await tester.pump();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(find.textContaining('can no longer be edited'), findsWidgets);
    expect(find.text('Vehicle Selection Screen'), findsNothing);
  });

  testWidgets('a hard 401 on submit logs the rider out and navigates to welcome',
      (tester) async {
    setTallSurface(tester);
    final repo = FakeKycRepository(completeKyc)
      ..submitError = const ApiException(message: 'Unauthorized', statusCode: 401);
    final authRepo = FakeAuthRepository();
    await tester.pumpWidget(
      buildApp(kycRepository: repo, authRepository: authRepo),
    );
    await tester.pumpAndSettle();

    final dlField = find.byWidgetPredicate(
      (w) => w is TextField && w.controller?.text == 'DL0420110149646',
    );
    await tester.enterText(dlField, 'DL0420110149647');
    await tester.pump();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(authRepo.loggedOut, isTrue);
    expect(find.text('Welcome Screen'), findsOneWidget);
  });

  testWidgets(
      'an offline failure on submit shows a persistent offline banner with Retry',
      (tester) async {
    setTallSurface(tester);
    final repo = FakeKycRepository(completeKyc)
      ..submitError = const ApiException(
        message: 'Unable to connect. Check your internet connection.',
        code: 'connectionError',
      );
    await tester.pumpWidget(buildApp(kycRepository: repo));
    await tester.pumpAndSettle();

    final dlField = find.byWidgetPredicate(
      (w) => w is TextField && w.controller?.text == 'DL0420110149646',
    );
    await tester.enterText(dlField, 'DL0420110149647');
    await tester.pump();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(find.textContaining("You're offline"), findsOneWidget);
  });

  testWidgets('an initial load failure shows Retry, which re-fetches successfully',
      (tester) async {
    setTallSurface(tester);
    final repo = FlakyKycRepository(completeKyc);
    await tester.pumpWidget(buildApp(kycRepository: repo));
    await tester.pumpAndSettle();

    expect(find.text('Could not load your KYC details'), findsOneWidget);

    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    expect(find.text('123456789012'), findsOneWidget);
    expect(repo.getKycCalls, 2);
  });

  testWidgets(
      'tapping the back arrow with no changes pops immediately, no dialog',
      (tester) async {
    setTallSurface(tester);
    final repo = FakeKycRepository(completeKyc);
    await tester.pumpWidget(buildApp(kycRepository: repo));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(LucideIcons.arrowLeft));
    await tester.pumpAndSettle();

    expect(find.text('Discard changes?'), findsNothing);
    expect(repo.submitCalls, 0);
  });

  testWidgets(
      'tapping the back arrow with unsaved changes warns first; Keep Editing stays',
      (tester) async {
    setTallSurface(tester);
    final repo = FakeKycRepository(completeKyc);
    await tester.pumpWidget(buildApp(kycRepository: repo));
    await tester.pumpAndSettle();

    final dlField = find.byWidgetPredicate(
      (w) => w is TextField && w.controller?.text == 'DL0420110149646',
    );
    await tester.enterText(dlField, 'DL0420110149647');
    await tester.pump();

    await tester.tap(find.byIcon(LucideIcons.arrowLeft));
    await tester.pumpAndSettle();

    expect(find.text('Discard changes?'), findsOneWidget);
    await tester.tap(find.text('Keep Editing'));
    await tester.pumpAndSettle();

    expect(find.byType(KycScreen), findsOneWidget);
    expect(repo.submitCalls, 0);
  });

  testWidgets(
      'tapping the back arrow with unsaved changes: Discard actually leaves the screen',
      (tester) async {
    setTallSurface(tester);
    final repo = FakeKycRepository(completeKyc);
    // KYC needs a real previous route to pop back to for this assertion —
    // the other back-navigation tests don't need one since they only
    // assert no save call happened, not that navigation occurred.
    await tester.pumpWidget(ProviderScope(
      overrides: [
        kycRepositoryProvider.overrideWithValue(repo),
        profileRepositoryProvider.overrideWithValue(FakeProfileRepository(mockProfile())),
      ],
      child: GetMaterialApp(
        initialRoute: AppRoutes.vehicleSelection,
        getPages: [
          GetPage(
            name: AppRoutes.vehicleSelection,
            page: () => const Scaffold(body: Text('Vehicle Selection Screen')),
          ),
          GetPage(name: AppRoutes.kyc, page: () => const KycScreen()),
        ],
      ),
    ));
    await tester.pumpAndSettle();
    Get.toNamed(AppRoutes.kyc);
    await tester.pumpAndSettle();

    final dlField = find.byWidgetPredicate(
      (w) => w is TextField && w.controller?.text == 'DL0420110149646',
    );
    await tester.enterText(dlField, 'DL0420110149647');
    await tester.pump();

    await tester.tap(find.byIcon(LucideIcons.arrowLeft));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Discard'));
    await tester.pumpAndSettle();

    expect(find.byType(KycScreen), findsNothing);
    expect(find.text('Vehicle Selection Screen'), findsOneWidget);
    expect(repo.submitCalls, 0);
  });

  testWidgets(
      'navigation after Continue is backend-driven: an already-active account goes to the dashboard',
      (tester) async {
    setTallSurface(tester);
    final repo = FakeKycRepository(completeKyc);
    final onboardingStatusRepo = FakeOnboardingStatusRepository(
      status: const OnboardingStatusModel(
        accountStatus: RiderAccountStatus.active,
        onboardingStatus: RiderOnboardingStatus.approved,
      ),
    );
    await tester.pumpWidget(buildApp(
      kycRepository: repo,
      onboardingStatusRepository: onboardingStatusRepo,
    ));
    await tester.pumpAndSettle();

    final dlField = find.byWidgetPredicate(
      (w) => w is TextField && w.controller?.text == 'DL0420110149646',
    );
    await tester.enterText(dlField, 'DL0420110149647');
    await tester.pump();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(find.text('Dashboard Screen'), findsOneWidget);
  });
}
