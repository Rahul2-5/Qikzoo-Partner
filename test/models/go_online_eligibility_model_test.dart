import 'package:flutter_test/flutter_test.dart';
import 'package:delivery_partner_app/models/dashboard/go_online_eligibility_model.dart';

void main() {
  test('parses backend-controlled selfie decision', () {
    final eligibility = GoOnlineEligibilityModel.fromJson(const {
      'eligible': true,
      'blockers': <String>[],
      'selfieRequired': false,
      'selfieMissing': false,
      'livenessRequired': false,
    });

    expect(eligibility.eligible, isTrue);
    expect(eligibility.selfieRequired, isFalse);
    expect(eligibility.message, 'Your account is ready to go online.');
  });

  test('turns backend blockers into an actionable rider message', () {
    final eligibility = GoOnlineEligibilityModel.fromJson(const {
      'eligible': false,
      'blockers': ['KYC_NOT_APPROVED', 'ACTIVE_VEHICLE_NOT_APPROVED'],
      'selfieRequired': false,
      'selfieMissing': false,
      'livenessRequired': false,
    });

    expect(eligibility.message, contains('KYC documents'));
    expect(eligibility.message, contains('approved active vehicle'));
  });
}
