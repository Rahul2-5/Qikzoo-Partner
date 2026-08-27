class GoOnlineEligibilityModel {
  const GoOnlineEligibilityModel({
    required this.eligible,
    required this.blockers,
    required this.selfieRequired,
    required this.selfieMissing,
    required this.livenessRequired,
  });

  final bool eligible;
  final List<String> blockers;
  final bool selfieRequired;
  final bool selfieMissing;
  final bool livenessRequired;

  factory GoOnlineEligibilityModel.fromJson(Map<String, dynamic> json) {
    final rawBlockers = json['blockers'];
    return GoOnlineEligibilityModel(
      eligible: json['eligible'] == true,
      blockers: rawBlockers is List
          ? rawBlockers.whereType<String>().toList(growable: false)
          : const [],
      selfieRequired: json['selfieRequired'] == true,
      selfieMissing: json['selfieMissing'] == true,
      livenessRequired: json['livenessRequired'] == true,
    );
  }

  String get message {
    if (blockers.isEmpty) return 'Your account is ready to go online.';
    return blockers.map(_labelFor).join(' ');
  }

  static String _labelFor(String blocker) => switch (blocker) {
        'ACCOUNT_NOT_ACTIVE' =>
          'Your rider account is not active. Please contact support.',
        'ONBOARDING_NOT_APPROVED' =>
          'Your onboarding must be approved before you can go online.',
        'KYC_NOT_APPROVED' =>
          'Your KYC documents must be approved before you can go online.',
        'DRIVING_LICENSE_EXPIRED' =>
          'Your driving licence has expired. Please update it.',
        'ACTIVE_VEHICLE_NOT_APPROVED' =>
          'Select an approved active vehicle before you go online.',
        'VEHICLE_INSURANCE_EXPIRED' =>
          'Your active vehicle insurance has expired. Please update it.',
        _ => 'Your rider account is not currently eligible to go online.',
      };
}
