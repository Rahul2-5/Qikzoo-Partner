class Validators {
  Validators._();

  static final _phoneRegex = RegExp(r'^[6-9]\d{9}$');
  static final _emailRegex = RegExp(r'^[\w\.\-]+@[\w\-]+\.[a-zA-Z]{2,}$');
  static final _ifscRegex = RegExp(r'^[A-Z]{4}0[A-Z0-9]{6}$');
  static final _panRegex = RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]$');
  static final _aadhaarRegex = RegExp(r'^\d{12}$');

  static bool isValidPhone(String value) => _phoneRegex.hasMatch(value.trim());

  static bool isValidOtp(String value, {int length = 6}) =>
      RegExp('^\\d{$length}\$').hasMatch(value.trim());

  static bool isValidEmail(String value) => _emailRegex.hasMatch(value.trim());

  static bool isValidIfsc(String value) =>
      _ifscRegex.hasMatch(value.trim().toUpperCase());

  static bool isValidPan(String value) =>
      _panRegex.hasMatch(value.trim().toUpperCase());

  static bool isValidAadhaar(String value) =>
      _aadhaarRegex.hasMatch(value.trim());

  static final _specialCharRegex =
      RegExp(r'[!@#$%^&*(),.?":{}|<>_\-\[\]\\/;+=~`]');

  static bool passwordHasMinLength(String value) => value.length >= 8;
  static bool passwordHasUppercase(String value) =>
      value.contains(RegExp(r'[A-Z]'));
  static bool passwordHasNumber(String value) =>
      value.contains(RegExp(r'[0-9]'));
  static bool passwordHasSpecialChar(String value) =>
      _specialCharRegex.hasMatch(value);

  /// Count of the 4 password requirements met (0-4).
  static int passwordStrength(String value) => [
        passwordHasMinLength(value),
        passwordHasUppercase(value),
        passwordHasNumber(value),
        passwordHasSpecialChar(value),
      ].where((met) => met).length;

  static bool isStrongPassword(String value) => passwordStrength(value) == 4;
}
