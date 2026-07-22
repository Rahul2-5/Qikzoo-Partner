import 'package:equatable/equatable.dart';

/// Mirrors the backend's `RiderAccountStatus` enum
/// (`prisma/schema.prisma`) — the rider's overall account standing.
enum RiderAccountStatus { pendingKyc, active, suspended, blocked, unknown }

/// Mirrors the backend's `RiderOnboardingStatus` enum.
enum RiderOnboardingStatus {
  notStarted,
  inProgress,
  submitted,
  underReview,
  clarificationRequired,
  approved,
  rejected,
  unknown,
}

/// The rider's onboarding/verification progress, as returned by the
/// backend-driven `GET /rider/onboarding` endpoint. The backend is the
/// source of truth for this state — the app should route off it rather
/// than infer progress locally.
class OnboardingStatusModel extends Equatable {
  final RiderAccountStatus accountStatus;
  final RiderOnboardingStatus onboardingStatus;
  final String? currentStep;

  const OnboardingStatusModel({
    required this.accountStatus,
    required this.onboardingStatus,
    this.currentStep,
  });

  /// A rider whose account is fully active can go straight into the app.
  /// Anything else still needs to land on the onboarding/verification
  /// status flow rather than the dashboard.
  bool get isActive => accountStatus == RiderAccountStatus.active;

  factory OnboardingStatusModel.fromJson(Map<String, dynamic> json) {
    return OnboardingStatusModel(
      accountStatus: _accountStatusFrom(json['accountStatus']),
      onboardingStatus: _onboardingStatusFrom(json['onboardingStatus']),
      currentStep: json['currentStep'] is String
          ? json['currentStep'] as String
          : null,
    );
  }

  static RiderAccountStatus _accountStatusFrom(Object? value) {
    if (value is! String) return RiderAccountStatus.unknown;
    return switch (value) {
      'PENDING_KYC' => RiderAccountStatus.pendingKyc,
      'ACTIVE' => RiderAccountStatus.active,
      'SUSPENDED' => RiderAccountStatus.suspended,
      'BLOCKED' => RiderAccountStatus.blocked,
      _ => RiderAccountStatus.unknown,
    };
  }

  static RiderOnboardingStatus _onboardingStatusFrom(Object? value) {
    if (value is! String) return RiderOnboardingStatus.unknown;
    return switch (value) {
      'NOT_STARTED' => RiderOnboardingStatus.notStarted,
      'IN_PROGRESS' => RiderOnboardingStatus.inProgress,
      'SUBMITTED' => RiderOnboardingStatus.submitted,
      'UNDER_REVIEW' => RiderOnboardingStatus.underReview,
      'CLARIFICATION_REQUIRED' => RiderOnboardingStatus.clarificationRequired,
      'APPROVED' => RiderOnboardingStatus.approved,
      'REJECTED' => RiderOnboardingStatus.rejected,
      _ => RiderOnboardingStatus.unknown,
    };
  }

  @override
  List<Object?> get props => [accountStatus, onboardingStatus, currentStep];
}
