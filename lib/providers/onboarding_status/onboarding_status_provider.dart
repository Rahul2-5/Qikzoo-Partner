import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/onboarding_status/onboarding_status_model.dart';
import '../../repositories/onboarding_status/onboarding_status_repository.dart';

final onboardingStatusProvider = FutureProvider<OnboardingStatusModel>(
  (ref) => ref.watch(onboardingStatusRepositoryProvider).getStatus(),
);
