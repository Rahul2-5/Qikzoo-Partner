import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/referrals/referral_summary_model.dart';
import '../../repositories/referrals/referral_repository.dart';

final referralSummaryProvider = FutureProvider<ReferralSummaryModel>(
    (ref) => ref.watch(referralRepositoryProvider).getSummary());
