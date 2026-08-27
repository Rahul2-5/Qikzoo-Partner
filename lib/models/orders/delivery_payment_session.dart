import 'package:equatable/equatable.dart';

import '../../core/utils/payment_failure_message.dart';

enum DeliveryPaymentStatus {
  initial,
  creatingSession,
  pending,
  success,
  failed,
  expired,
  cancelled,
  connectionError,
}

enum DeliveryQrFormat { payload, imageUrl, encodedImage }

class DeliveryPaymentSession extends Equatable {
  const DeliveryPaymentSession({
    required this.sessionId,
    required this.riderOrderId,
    required this.qrData,
    required this.qrFormat,
    required this.amountPaise,
    required this.status,
    required this.expiresAt,
    required this.paidAt,
    required this.transactionId,
    required this.failureReason,
    required this.gateway,
    required this.backendStatus,
  });

  final String sessionId;
  final String riderOrderId;
  final String qrData;
  final DeliveryQrFormat qrFormat;
  final int amountPaise;
  final DeliveryPaymentStatus status;
  final DateTime expiresAt;
  final DateTime? paidAt;
  final String? transactionId;
  final String? failureReason;
  final String? gateway;
  final String? backendStatus;

  double get amountRupees => amountPaise / 100;
  bool get hasExpired => !expiresAt.isAfter(DateTime.now());

  factory DeliveryPaymentSession.fromJson(
    Map<String, dynamic> json, {
    required String riderOrderId,
  }) {
    final orderPaymentStatus =
        _string(json['orderPaymentStatus'] ?? json['order_payment_status'])
            ?.toUpperCase();
    final rawStatus = _string(json['status'])?.toUpperCase();
    final status = orderPaymentStatus == 'PAID'
        ? DeliveryPaymentStatus.success
        : _statusFromBackend(rawStatus);

    final qrImageUrl =
        _string(json['qrImageUrl'] ?? json['qr_image_url'] ?? json['qrUrl']);
    final encodedImage =
        _string(json['qrImage'] ?? json['qr_image'] ?? json['qrBase64']);
    final payload = _string(
      json['qrPayload'] ?? json['qr_payload'] ?? json['qrData'],
    );

    return DeliveryPaymentSession(
      sessionId: _string(json['sessionId'] ?? json['id']) ?? '',
      riderOrderId: riderOrderId,
      qrData: qrImageUrl ?? encodedImage ?? payload ?? '',
      qrFormat: qrImageUrl != null
          ? DeliveryQrFormat.imageUrl
          : encodedImage != null
              ? DeliveryQrFormat.encodedImage
              : DeliveryQrFormat.payload,
      amountPaise: _integer(json['amountPaise'] ?? json['amount_paise']),
      status: status,
      expiresAt: _date(json['expiresAt'] ?? json['expires_at']) ??
          DateTime.fromMillisecondsSinceEpoch(0),
      paidAt: _date(json['paidAt'] ?? json['paid_at']),
      transactionId: _string(
        json['transactionId'] ??
            json['gatewayPaymentId'] ??
            json['referenceId'] ??
            json['paymentReference'],
      ),
      failureReason: paymentFailureMessage(
        json['failureReason'] ?? json['failure_reason'] ?? json['message'],
      ),
      gateway: _string(json['gateway']),
      backendStatus: rawStatus,
    );
  }

  @override
  List<Object?> get props => [
        sessionId,
        riderOrderId,
        qrData,
        qrFormat,
        amountPaise,
        status,
        expiresAt,
        paidAt,
        transactionId,
        failureReason,
        gateway,
        backendStatus,
      ];
}

DeliveryPaymentStatus _statusFromBackend(String? value) => switch (value) {
      'CREATED' || 'PENDING' => DeliveryPaymentStatus.pending,
      'SUCCESS' || 'PAID' => DeliveryPaymentStatus.success,
      'FAILED' => DeliveryPaymentStatus.failed,
      'EXPIRED' => DeliveryPaymentStatus.expired,
      'CANCELLED' || 'CANCELED' => DeliveryPaymentStatus.cancelled,
      _ => DeliveryPaymentStatus.connectionError,
    };

String? _string(Object? value) {
  if (value is! String || value.trim().isEmpty) return null;
  return value.trim();
}

int _integer(Object? value) {
  if (value is int) return value;
  if (value is num) return value.round();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

DateTime? _date(Object? value) {
  if (value is DateTime) return value;
  if (value is! String) return null;
  return DateTime.tryParse(value)?.toLocal();
}
