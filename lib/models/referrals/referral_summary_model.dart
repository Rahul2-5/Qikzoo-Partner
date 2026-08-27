class ReferralSummaryModel {
  const ReferralSummaryModel(
      {required this.referralCode,
      required this.rewardPaise,
      required this.successfulDeliveries,
      required this.requiredSuccessfulDeliveries,
      required this.deliveriesRemaining,
      required this.lockedRewardPaise});
  final String referralCode;
  final int rewardPaise;
  final int successfulDeliveries;
  final int requiredSuccessfulDeliveries;
  final int deliveriesRemaining;
  final int lockedRewardPaise;
  double get rewardRupees => rewardPaise / 100;
  double get lockedRewardRupees => lockedRewardPaise / 100;
  bool get isUnlocked => deliveriesRemaining == 0;
  factory ReferralSummaryModel.fromJson(Map<String, dynamic> json) =>
      ReferralSummaryModel(
          referralCode: json['referralCode'] as String? ?? '',
          rewardPaise: (json['rewardPaise'] as num?)?.toInt() ?? 20000,
          successfulDeliveries:
              (json['successfulDeliveries'] as num?)?.toInt() ?? 0,
          requiredSuccessfulDeliveries:
              (json['requiredSuccessfulDeliveries'] as num?)?.toInt() ?? 10,
          deliveriesRemaining:
              (json['deliveriesRemaining'] as num?)?.toInt() ?? 10,
          lockedRewardPaise: (json['lockedRewardPaise'] as num?)?.toInt() ?? 0);
}
