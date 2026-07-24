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
  final List<String> completedSections;
  final List<String> incompleteSections;
  final String? clarificationReason;
  final List<String> clarificationSections;
  final List<String> editableSections;
  final bool isSubmittable;
  final bool hasExpiredMandatoryDocuments;
  final String? rejectionReason;
  final bool reapplyAllowed;
  final DateTime? submittedAt;
  final DateTime? reviewedAt;

  const OnboardingStatusModel({
    required this.accountStatus,
    required this.onboardingStatus,
    this.currentStep,
    this.completedSections = const [],
    this.incompleteSections = const [],
    this.clarificationReason,
    this.clarificationSections = const [],
    this.editableSections = const [],
    this.isSubmittable = false,
    this.hasExpiredMandatoryDocuments = false,
    this.rejectionReason,
    this.reapplyAllowed = false,
    this.submittedAt,
    this.reviewedAt,
  });

  /// A rider whose account is fully active can go straight into the app.
  /// Anything else still needs to land on the onboarding/verification
  /// status flow rather than the dashboard.
  bool get isActive => accountStatus == RiderAccountStatus.active;

  /// Mirrors the backend's own `isEditable` rule
  /// (`RiderOnboardingService.getProgress`) exactly: a rider may keep
  /// editing sections before ever submitting, or if an admin has reopened
  /// specific sections for clarification. Once SUBMITTED/UNDER_REVIEW/
  /// APPROVED/REJECTED (without clarification), nothing is editable.
  bool get isEditable =>
      onboardingStatus == RiderOnboardingStatus.notStarted ||
      onboardingStatus == RiderOnboardingStatus.inProgress ||
      onboardingStatus == RiderOnboardingStatus.clarificationRequired;

  factory OnboardingStatusModel.fromJson(Map<String, dynamic> json) {
    return OnboardingStatusModel(
      accountStatus: _accountStatusFrom(json['accountStatus']),
      onboardingStatus: _onboardingStatusFrom(json['onboardingStatus']),
      currentStep: json['currentStep'] is String
          ? json['currentStep'] as String
          : null,
      completedSections: _stringList(json['completedSections']),
      incompleteSections: _stringList(json['incompleteSections']),
      clarificationReason: json['clarificationReason'] is String
          ? json['clarificationReason'] as String
          : null,
      clarificationSections: _stringList(json['clarificationSections']),
      editableSections: _stringList(json['editableSections']),
      isSubmittable: json['isSubmittable'] == true,
      hasExpiredMandatoryDocuments:
          json['hasExpiredMandatoryDocuments'] == true,
      rejectionReason: json['rejectionReason'] is String
          ? json['rejectionReason'] as String
          : null,
      reapplyAllowed: json['reapplyAllowed'] == true,
      submittedAt: _date(json['submittedAt']),
      reviewedAt: _date(json['reviewedAt']),
    );
  }

  static List<String> _stringList(Object? value) =>
      value is List ? value.whereType<String>().toList() : const [];

  static DateTime? _date(Object? value) =>
      value is String ? DateTime.tryParse(value) : null;

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
  List<Object?> get props => [
        accountStatus,
        onboardingStatus,
        currentStep,
        completedSections,
        incompleteSections,
        clarificationReason,
        clarificationSections,
        editableSections,
        isSubmittable,
        hasExpiredMandatoryDocuments,
        rejectionReason,
        reapplyAllowed,
        submittedAt,
        reviewedAt,
      ];
}
