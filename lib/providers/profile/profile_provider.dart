import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../models/bank_details/bank_details_model.dart';
import '../../models/partner_registration/personal_info_model.dart';
import '../../models/profile/partner_profile_model.dart';
import '../../models/profile/profile_summary.dart';
import '../../models/profile/rating_model.dart';
import '../../models/verification_status/verification_step_model.dart';
import '../../features/profile/widgets/personal_information_sheet.dart';
import '../bank_details/bank_details_provider.dart';
import '../notifications/notifications_provider.dart';
import '../verification_status/verification_status_provider.dart';
import '../wallet/wallet_provider.dart';
import '../../repositories/profile/profile_repository.dart';

final profileProvider = FutureProvider<PartnerProfileModel>(
  (ref) => ref.watch(profileRepositoryProvider).getProfile(),
);

final ratingProvider = FutureProvider<RatingModel>(
  (ref) => ref.watch(profileRepositoryProvider).getRating(),
);

/// The profile-screen view-model, combining the rider's profile with rating,
/// wallet, bank, verification and notification data. The core [profileProvider]
/// drives the loading/error state; the auxiliary sources are read
/// opportunistically so a slow or failed wallet/bank call still lets the
/// profile render (those fields simply fall back to zero/empty).
final profileSummaryProvider = Provider<AsyncValue<ProfileSummary>>((ref) {
  final profileAsync = ref.watch(profileProvider);
  final rating = ref.watch(ratingProvider).valueOrNull;
  final wallet = ref.watch(walletProvider).valueOrNull;
  final bank = ref.watch(bankDetailsProvider).valueOrNull;
  final steps = ref.watch(verificationStepsProvider).valueOrNull;
  final unreadCount = ref
          .watch(notificationsProvider)
          .valueOrNull
          ?.where((n) => !n.isRead)
          .length ??
      0;

  return profileAsync.whenData(
    (profile) => ProfileSummary(
      name: profile.name,
      // Permanent, backend-issued QRIDxxxxx — never the internal UUID
      // (profile.id), which must never reach the rider-facing UI.
      partnerId: profile.publicRiderId ?? '',
      photoUrl: profile.photoUrl,
      ratingAverage: rating?.average ?? 0,
      deliveriesLabel: _deliveriesLabel(rating?.totalRatings ?? 0),
      documentsVerified: _allStepsCompleted(steps),
      walletBalance: wallet?.balance ?? 0,
      pendingAmount: wallet?.pendingAmount ?? 0,
      bankLabel: _bankLabel(bank),
      notificationCount: unreadCount,
    ),
  );
});

/// The rider's details formatted for the Personal Information sheet, or
/// `null` while the profile is still loading / failed to load.
final personalInformationProvider = Provider<PersonalInformationData?>((ref) {
  final profile = ref.watch(profileProvider).valueOrNull;
  if (profile == null) return null;
  return PersonalInformationData(
    fullName: profile.name,
    partnerId: profile.publicRiderId ?? '',
    phone: profile.phone,
    email: profile.email ?? '',
    dateOfBirth: profile.dateOfBirth != null
        ? DateFormat('d MMMM yyyy').format(profile.dateOfBirth!)
        : '',
    gender: _genderLabel(profile.gender),
    emergencyContactName: profile.emergencyContactName ?? '',
    emergencyContactPhone: profile.emergencyContactPhone ?? '',
    photoUrl: profile.photoUrl,
    vehicleType: profile.vehicleType,
  );
});

String _deliveriesLabel(int total) =>
    total > 0 ? '$total Deliveries' : 'New Partner';

bool _allStepsCompleted(List<VerificationStepModel>? steps) =>
    steps != null &&
    steps.isNotEmpty &&
    steps.every((s) => s.state == VerificationStepState.completed);

/// "HDFC ····1234" — the IFSC's first four characters are the bank code and
/// the last four account digits are shown; `null` when no bank is on file.
String? _bankLabel(BankDetailsModel? bank) {
  if (bank == null) return null;
  final account = bank.accountNumber.trim();
  final last4 =
      account.length >= 4 ? account.substring(account.length - 4) : account;
  final ifsc = bank.ifsc.trim().toUpperCase();
  final bankCode = ifsc.length >= 4 ? ifsc.substring(0, 4) : ifsc;
  if (bankCode.isEmpty) return '····$last4';
  return '$bankCode ····$last4';
}

String _genderLabel(Gender? gender) => switch (gender) {
      Gender.male => 'Male',
      Gender.female => 'Female',
      Gender.other => 'Other',
      null => '',
    };
