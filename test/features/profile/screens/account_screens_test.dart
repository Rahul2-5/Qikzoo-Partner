import 'package:delivery_partner_app/core/theme/app_theme.dart';
import 'package:delivery_partner_app/features/bank_details/screens/bank_details_screen.dart';
import 'package:delivery_partner_app/features/documents/screens/manage_documents_screen.dart';
import 'package:delivery_partner_app/features/settings/screens/settings_screen.dart';
import 'package:delivery_partner_app/features/support/screens/help_support_screen.dart';
import 'dart:io';

import 'package:delivery_partner_app/features/vehicle_details/screens/manage_vehicle_details_screen.dart';
import 'package:delivery_partner_app/models/document_verification/document_model.dart';
import 'package:delivery_partner_app/models/vehicle/rider_vehicle_model.dart';
import 'package:delivery_partner_app/repositories/document_verification/document_repository.dart';
import 'package:delivery_partner_app/repositories/vehicle/vehicle_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:url_launcher_platform_interface/link.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

/// HelpSupportScreen's "Call us"/"Live chat" buttons now attempt a real
/// tel:/https: launch via url_launcher before falling back to "$channel
/// support is not available yet." — the platform channel behind
/// canLaunchUrl has no test-environment implementation and would otherwise
/// throw MissingPluginException uncaught from the button's async onTap.
/// Forcing canLaunch to return false deterministically exercises the real,
/// honest fallback path (matching what actually happens on a real device
/// too, when no phone/chat app can handle the intent).
class _FakeUrlLauncher extends UrlLauncherPlatform {
  @override
  LinkDelegate? get linkDelegate => null;

  @override
  Future<bool> canLaunch(String url) async => false;
}

class _FakeDocumentRepository implements DocumentRepository {
  @override
  Future<List<DocumentModel>> getDocuments() async => DocumentType.values
      .map((type) => DocumentModel(type: type, status: DocumentStatus.notUploaded))
      .toList();

  @override
  Future<DocumentModel> uploadDocument(DocumentType type, String filePath) async =>
      DocumentModel(type: type, status: DocumentStatus.pendingVerification, fileUrl: filePath);
}

class _FakeVehicleRepository implements VehicleRepository {
  _FakeVehicleRepository(this.vehicles);

  final List<RiderVehicleModel> vehicles;

  @override
  Future<List<RiderVehicleModel>> listVehicles() async => vehicles;

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
  Future<RiderVehicleModel> uploadInsuranceDocument(
    String vehicleId,
    File file, {
    void Function(int sent, int total)? onSendProgress,
    CancelToken? cancelToken,
  }) =>
      throw UnimplementedError();

  @override
  Future<RiderVehicleModel> uploadRcDocument(
    String vehicleId,
    File file, {
    void Function(int sent, int total)? onSendProgress,
    CancelToken? cancelToken,
  }) =>
      throw UnimplementedError();
}

Widget _buildScreen(Widget screen, {List<Override> overrides = const []}) {
  return ProviderScope(
    overrides: overrides,
    child: GetMaterialApp(
      theme: AppTheme.light,
      home: screen,
    ),
  );
}

Future<void> _loadScreen(
  WidgetTester tester,
  Widget screen, {
  List<Override> overrides = const [],
}) async {
  tester.view.physicalSize = const Size(390, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(_buildScreen(screen, overrides: overrides));
  await tester.pump(const Duration(milliseconds: 450));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    UrlLauncherPlatform.instance = _FakeUrlLauncher();
  });

  testWidgets('bank details screen loads the saved payout account',
      (tester) async {
    await _loadScreen(tester, const BankDetailsScreen());

    expect(find.text('Account information'), findsOneWidget);
    expect(find.text('Bank name'), findsOneWidget);
    expect(find.text('Save bank details'), findsOneWidget);
  });

  testWidgets('vehicle details screen loads the real active vehicle',
      (tester) async {
    await _loadScreen(
      tester,
      const ManageVehicleDetailsScreen(),
      overrides: [
        vehicleRepositoryProvider.overrideWithValue(
          _FakeVehicleRepository([
            const RiderVehicleModel(
              id: 'v1',
              type: VehicleType.scooter,
              registrationNumber: 'KA01AB1234',
              isActive: true,
              status: VehicleDocumentStatus.approved,
            ),
          ]),
        ),
      ],
    );

    expect(find.text('Vehicle information'), findsOneWidget);
    expect(find.text('Scooter'), findsOneWidget);
    expect(find.text('KA01AB1234'), findsOneWidget);
    expect(find.text('Approved'), findsOneWidget);
    // No update-in-place endpoint exists for an approved vehicle — the
    // create form (and its Save button) must stay hidden until the rider
    // explicitly asks to register a different one.
    expect(find.text('Save vehicle details'), findsNothing);
  });

  testWidgets('vehicle details screen offers registration when none is on file',
      (tester) async {
    await _loadScreen(
      tester,
      const ManageVehicleDetailsScreen(),
      overrides: [
        vehicleRepositoryProvider.overrideWithValue(_FakeVehicleRepository(const [])),
      ],
    );

    expect(find.text('No vehicle on file'), findsOneWidget);
    expect(find.text('Save vehicle details'), findsOneWidget);
  });

  testWidgets('documents screen groups identity and vehicle documents',
      (tester) async {
    await _loadScreen(
      tester,
      const ManageDocumentsScreen(),
      overrides: [
        documentRepositoryProvider.overrideWithValue(_FakeDocumentRepository()),
      ],
    );

    expect(find.text('Identity documents'), findsOneWidget);
    expect(find.textContaining('Government ID'), findsOneWidget);
    expect(find.text('Vehicle documents'), findsOneWidget);
  });

  testWidgets(
      'support screen shows real FAQ content, no fabricated tickets',
      (tester) async {
    await _loadScreen(tester, const HelpSupportScreen());

    expect(find.text('Frequently asked questions'), findsOneWidget);
    expect(find.text('No open tickets'), findsNothing);
    expect(find.text('Raise a support ticket'), findsNothing);

    await tester.tap(find.text('Call us'));
    await tester.pump();
    expect(find.text('Phone support is not available yet.'), findsOneWidget);

    // Regression guard: "Live chat" used to navigate to a screen that
    // fabricated a scripted conversation with a fake "Agent" persona
    // (invented resolution history, invented timestamps). It must now be
    // as honest as "Call us" instead of pretending a live agent exists.
    await tester.tap(find.text('Live chat'));
    await tester.pump();
    expect(find.text('Live chat support is not available yet.'), findsOneWidget);
  });

  testWidgets('settings screen does not offer language selection',
      (tester) async {
    await _loadScreen(tester, const SettingsScreen());

    expect(find.text('App language'), findsNothing);
    expect(find.text('Choose app language'), findsNothing);
    expect(find.text('Push notifications'), findsOneWidget);
    expect(find.text('Security & privacy'), findsOneWidget);
  });
}
