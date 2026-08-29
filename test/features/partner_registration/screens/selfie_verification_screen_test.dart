import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:delivery_partner_app/core/routes/app_routes.dart';
import 'package:delivery_partner_app/features/partner_registration/screens/selfie_verification_screen.dart';
import 'package:delivery_partner_app/models/partner_registration/personal_info_model.dart';
import 'package:delivery_partner_app/models/profile/partner_profile_model.dart';
import 'package:delivery_partner_app/models/profile/rating_model.dart';
import 'package:delivery_partner_app/repositories/document_verification/document_image_picker.dart';
import 'package:delivery_partner_app/repositories/profile/profile_repository.dart';

class FakeProfileRepository implements ProfileRepository {
  FakeProfileRepository({String? selfieUrl}) : _selfieUrl = selfieUrl;
  String? _selfieUrl;
  int uploadSelfieCalls = 0;

  PartnerProfileModel _profile() => PartnerProfileModel(
        id: 'rider-1',
        name: 'Test Rider',
        phone: '9876543210',
        joinedDate: DateTime(2026, 1, 1),
        selfieUrl: _selfieUrl,
      );

  @override
  Future<PartnerProfileModel> getProfile() async => _profile();

  @override
  Future<PartnerProfileModel> uploadSelfie(
    File file, {
    void Function(int sent, int total)? onSendProgress,
    CancelToken? cancelToken,
  }) async {
    uploadSelfieCalls++;
    _selfieUrl = file.path;
    return _profile();
  }

  @override
  Future<RatingModel> getRating() => throw UnimplementedError();

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

class FakeDocumentImagePicker implements DocumentImagePicker {
  @override
  Future<String?> pickImage(ImageSource source) async => '/tmp/selfie.jpg';
}

void setTallSurface(WidgetTester tester) {
  tester.view.physicalSize = const Size(400, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Widget buildApp(FakeProfileRepository profileRepository) {
  return ProviderScope(
    overrides: [
      profileRepositoryProvider.overrideWithValue(profileRepository),
      documentImagePickerProvider.overrideWithValue(FakeDocumentImagePicker()),
    ],
    child: GetMaterialApp(
      initialRoute: AppRoutes.selfieVerification,
      getPages: [
        GetPage(
          name: AppRoutes.selfieVerification,
          page: () => const SelfieVerificationScreen(),
        ),
        GetPage(
          name: AppRoutes.welcomeKit,
          page: () => const Scaffold(body: Text('Welcome Kit Screen')),
        ),
      ],
    ),
  );
}

/// Opening a modal bottom sheet from this screen (image-source picker,
/// selfie confirm sheet) leaves a frame scheduled indefinitely — confirmed
/// the sheet and its content render and are tappable within a couple of
/// pumps, so this is a pumpAndSettle-convergence quirk of the modal-route
/// transition in this environment, not a stuck app state (the same class
/// of issue already worked around by dashboard_home_screen_test.dart's
/// pumpBounded() helper for its own modal flows). Bounded pumps sidestep it
/// without weakening what's actually being verified.
Future<void> pumpBounded(WidgetTester tester) async {
  await tester.pump();
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  testWidgets('shows Take selfie now initially and the do/don\'t guide',
      (tester) async {
    setTallSurface(tester);
    await tester.pumpWidget(buildApp(FakeProfileRepository()));
    await tester.pumpAndSettle();

    // The button label is now "Take selfie now" (SelfieVerificationScreen's
    // PrimaryCtaButton, isUploaded == false), and the old bullet-point tips
    // list ("Make sure your face is clearly visible" / "Good lighting" /
    // "No sunglasses or filters") was replaced by a do/don't icon grid
    // (_SelfieDoDontGrid) with short labels instead of sentences.
    expect(find.text('Take selfie now'), findsOneWidget);
    expect(find.text('Center your face in good light.'), findsOneWidget);
    expect(find.text('Correct'), findsOneWidget);
    expect(find.text('Blurry'), findsOneWidget);
    expect(find.text('Helmet'), findsOneWidget);
  });

  testWidgets('capturing and using a photo uploads it and switches the CTA to Continue',
      (tester) async {
    setTallSurface(tester);
    final repo = FakeProfileRepository();
    await tester.pumpWidget(buildApp(repo));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Take selfie now'));
    await pumpBounded(tester);
    await tester.tap(find.text('Take Photo'));
    await pumpBounded(tester);
    await tester.tap(find.text('Use Photo'));
    await pumpBounded(tester);

    expect(repo.uploadSelfieCalls, 1);
    expect(find.text('Continue'), findsOneWidget);
  });

  testWidgets(
      'Continue navigates to Welcome Kit once the selfie is uploaded',
      (tester) async {
    setTallSurface(tester);
    await tester.pumpWidget(
        buildApp(FakeProfileRepository(selfieUrl: '/tmp/existing.jpg')));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(find.text('Welcome Kit Screen'), findsOneWidget);
  });
}
