import 'package:delivery_partner_app/core/validators/validators.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Validators.isValidPhone', () {
    test('accepts a valid Indian mobile number', () {
      expect(Validators.isValidPhone('9876543210'), isTrue);
    });

    test('rejects repeated-digit placeholder numbers', () {
      expect(Validators.isValidPhone('9999999999'), isFalse);
      expect(Validators.isValidPhone('7777777777'), isFalse);
    });

    test('rejects numbers outside Indian mobile-number prefixes', () {
      expect(Validators.isValidPhone('1234567890'), isFalse);
      expect(Validators.isValidPhone('5234567890'), isFalse);
    });
  });
}
