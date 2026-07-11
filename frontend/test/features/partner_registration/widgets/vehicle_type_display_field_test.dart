import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:delivery_partner_app/features/partner_registration/widgets/vehicle_type_display_field.dart';
import 'package:delivery_partner_app/models/partner_registration/vehicle_model.dart';

void main() {
  testWidgets('shows the label for the given vehicle type', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: VehicleTypeDisplayField(vehicleType: VehicleType.electricVehicle),
        ),
      ),
    );

    expect(find.text('E-Bike Partner'), findsOneWidget);
  });

  testWidgets('renders the vehicle type image asset', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: VehicleTypeDisplayField(vehicleType: VehicleType.bicycle),
        ),
      ),
    );

    final image = tester.widget<Image>(find.byType(Image));
    expect(
      (image.image as AssetImage).assetName,
      'assets/images/cycle_3d.png',
    );
  });
}
