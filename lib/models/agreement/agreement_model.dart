import 'package:equatable/equatable.dart';

class AgreementModel extends Equatable {
  final bool termsAccepted;
  final bool privacyAccepted;
  final bool partnerAgreementAccepted;
  final DateTime? acceptedAt;

  const AgreementModel({
    required this.termsAccepted,
    required this.privacyAccepted,
    required this.partnerAgreementAccepted,
    this.acceptedAt,
  });

  bool get allAccepted => termsAccepted && privacyAccepted && partnerAgreementAccepted;

  @override
  List<Object?> get props =>
      [termsAccepted, privacyAccepted, partnerAgreementAccepted, acceptedAt];
}
