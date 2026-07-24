import 'package:equatable/equatable.dart';

/// View-model for the profile screen, assembled from several backend
/// sources (profile, rating, wallet, bank details, verification steps and
/// notifications) by `profileSummaryProvider`. Every field maps to real
/// API data — there is no static/mock content behind it in production.
class ProfileSummary extends Equatable {
  final String name;
  final String partnerId;
  final String? photoUrl;
  final double ratingAverage;
  final String deliveriesLabel;
  final bool documentsVerified;
  final double walletBalance;
  final double pendingAmount;

  /// e.g. "HDFC ····1234" derived from the rider's bank account on file, or
  /// `null` when no bank account has been added yet.
  final String? bankLabel;
  final int notificationCount;

  const ProfileSummary({
    required this.name,
    required this.partnerId,
    this.photoUrl,
    required this.ratingAverage,
    required this.deliveriesLabel,
    required this.documentsVerified,
    required this.walletBalance,
    required this.pendingAmount,
    this.bankLabel,
    required this.notificationCount,
  });

  @override
  List<Object?> get props => [
        name,
        partnerId,
        photoUrl,
        ratingAverage,
        deliveriesLabel,
        documentsVerified,
        walletBalance,
        pendingAmount,
        bankLabel,
        notificationCount,
      ];
}