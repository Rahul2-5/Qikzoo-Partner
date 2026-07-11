import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../repositories/profile/profile_repository.dart';
import '../../models/profile/partner_profile_model.dart';
import '../../models/profile/rating_model.dart';

final profileProvider = FutureProvider<PartnerProfileModel>(
  (ref) => ref.watch(profileRepositoryProvider).getProfile(),
);

final ratingProvider = FutureProvider<RatingModel>(
  (ref) => ref.watch(profileRepositoryProvider).getRating(),
);
