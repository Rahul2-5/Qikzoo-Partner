import 'package:equatable/equatable.dart';

class OtpModel extends Equatable {
  final String phoneNumber;
  final bool isVerified;
  final DateTime expiresAt;

  const OtpModel({required this.phoneNumber, required this.isVerified, required this.expiresAt});

  OtpModel copyWith({String? phoneNumber, bool? isVerified, DateTime? expiresAt}) => OtpModel(
        phoneNumber: phoneNumber ?? this.phoneNumber,
        isVerified: isVerified ?? this.isVerified,
        expiresAt: expiresAt ?? this.expiresAt,
      );

  @override
  List<Object?> get props => [phoneNumber, isVerified, expiresAt];
}
