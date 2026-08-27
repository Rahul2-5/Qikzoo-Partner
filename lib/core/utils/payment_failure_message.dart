/// Converts backend payment failure codes into safe, provider-neutral copy.
///
/// Gateway identifiers and raw diagnostic payloads are intentionally never
/// rendered in the rider app. This also protects old provider-coded sessions.
String? paymentFailureMessage(Object? value) {
  if (value is! String || value.trim().isEmpty) return null;
  final reason = value.trim();
  if (reason.length > 160) return null;

  final code = reason.toUpperCase();
  if (code.endsWith('QR_GENERATION_FAILED')) {
    return 'Payment QR could not be generated. Please try again.';
  }
  if (code == 'PAYMENT_FAILED') {
    return 'The payment was not completed. Please try again.';
  }
  if (code == 'GATEWAY_AMOUNT_MISMATCH' ||
      code == 'GATEWAY_AMOUNT_UNAVAILABLE') {
    return 'Payment confirmation needs verification. Please contact support.';
  }

  final normalized = reason.toLowerCase();
  if (normalized.contains('payu') ||
      normalized.contains('pinelabs') ||
      normalized.contains('paytm') ||
      normalized.contains('phonepe') ||
      normalized.contains('exception') ||
      normalized.contains('stack') ||
      normalized.contains('gatewayresponse') ||
      reason.contains('{') ||
      reason.contains('}')) {
    return 'The payment could not be completed. Please try again.';
  }

  if (RegExp(r'^[A-Z0-9_]+$').hasMatch(reason)) {
    return 'The payment could not be completed. Please try again.';
  }
  return reason;
}
