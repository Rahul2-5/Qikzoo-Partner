import 'package:equatable/equatable.dart';

class ProfileSummary extends Equatable {
  final String name;
  final String partnerId;
  final String? photoUrl;
  final double ratingAverage;
  final String deliveriesLabel;
  final bool documentsVerified;
  final double walletBalance;
  final String bankName;
  final String maskedAccount;
  final String nextPayoutDate;
  final int notificationCount;

  const ProfileSummary({
    required this.name,
    required this.partnerId,
    this.photoUrl,
    required this.ratingAverage,
    required this.deliveriesLabel,
    required this.documentsVerified,
    required this.walletBalance,
    required this.bankName,
    required this.maskedAccount,
    required this.nextPayoutDate,
    required this.notificationCount,
  });

  factory ProfileSummary.mock() => const ProfileSummary(
        name: 'Rahul Verma',
        partnerId: 'ZP12345678',
        ratingAverage: 4.8,
        deliveriesLabel: '250+ Deliveries',
        documentsVerified: true,
        walletBalance: 2345.50,
        bankName: 'HDFC Bank',
        maskedAccount: '4321',
        nextPayoutDate: '15 May 2025',
        notificationCount: 3,
      );

  @override
  List<Object?> get props => [
        name,
        partnerId,
        photoUrl,
        ratingAverage,
        deliveriesLabel,
        documentsVerified,
        walletBalance,
        bankName,
        maskedAccount,
        nextPayoutDate,
        notificationCount,
      ];
}
