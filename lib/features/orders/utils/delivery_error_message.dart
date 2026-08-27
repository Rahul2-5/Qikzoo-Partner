import '../../../core/api/api_exception.dart';

String riderMessageForDeliveryAction(ApiException error) {
  final technicalMessage = error.message.toLowerCase();
  if (technicalMessage.contains('payment') ||
      technicalMessage.contains('collect')) {
    return 'Payment is not confirmed yet. Check the payment status and try again.';
  }
  if (technicalMessage.contains('location is outdated') ||
      technicalMessage.contains('fresh location')) {
    return 'Waiting for a fresh GPS location. Keep location enabled and try again.';
  }
  if (technicalMessage.contains('too far')) {
    return 'Move closer to the customer’s delivery location and try again.';
  }
  if (technicalMessage.contains('already completed') ||
      technicalMessage.contains('already delivered')) {
    return 'This delivery was already completed. Refreshing your active orders.';
  }
  if (error.statusCode == 404 || technicalMessage.contains('assignment')) {
    return 'This delivery assignment is no longer available to your account.';
  }
  if (error.statusCode == 409 ||
      technicalMessage.contains('cannot transition') ||
      technicalMessage.contains('already picked')) {
    return 'This order was just updated. Please review the next delivery step.';
  }
  if (error.statusCode == 400 || error.statusCode == 422) {
    return 'We could not complete that step. Refresh the order and try again.';
  }
  if (error.statusCode == 403) {
    return 'This action is not available for your current delivery step.';
  }
  return 'We could not update this order. Please try again.';
}
