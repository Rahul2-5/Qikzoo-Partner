import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:delivery_partner_app/models/document_verification/document_model.dart';

void main() {
  group('DocumentTypeDisplay', () {
    test('labels match the document upload screen copy', () {
      expect(DocumentType.aadhaar.label, 'Aadhaar Card');
      expect(DocumentType.drivingLicense.label, 'Driving License');
      expect(DocumentType.vehicleRc.label, 'Vehicle RC');
      expect(DocumentType.vehicleInsurance.label, 'Insurance');
      expect(DocumentType.pan.label, 'PAN Card');
    });

    test('only PAN is optional', () {
      expect(DocumentType.pan.isOptional, isTrue);
      expect(DocumentType.aadhaar.isOptional, isFalse);
      expect(DocumentType.drivingLicense.isOptional, isFalse);
      expect(DocumentType.vehicleRc.isOptional, isFalse);
      expect(DocumentType.vehicleInsurance.isOptional, isFalse);
    });

    test('each displayed type has an icon assigned', () {
      expect(DocumentType.aadhaar.icon, LucideIcons.fingerprint);
      expect(DocumentType.drivingLicense.icon, LucideIcons.creditCard);
      expect(DocumentType.vehicleRc.icon, LucideIcons.car);
      expect(DocumentType.vehicleInsurance.icon, LucideIcons.shieldCheck);
      expect(DocumentType.pan.icon, LucideIcons.contact);
    });
  });
}
