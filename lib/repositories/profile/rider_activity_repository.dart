import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api_client.dart';
import '../../core/api/api_endpoints.dart';
import '../../models/profile/rider_activity_model.dart';
import '../../providers/core/api_providers.dart';

class RiderActivityRepository {
  final ApiClient api;
  const RiderActivityRepository(this.api);
  Future<RiderActivity> get() async {
    final r = await api.get<Map<String, dynamic>>(ApiEndpoints.riderActivity);
    final payload = r.data ?? <String, dynamic>{};
    final raw = payload['data'] is Map ? payload['data'] : payload;
    return RiderActivity.fromJson(Map<String, dynamic>.from(raw));
  }
}

final riderActivityRepositoryProvider =
    Provider((ref) => RiderActivityRepository(ref.watch(apiClientProvider)));
final riderActivityProvider = FutureProvider.autoDispose(
    (ref) => ref.watch(riderActivityRepositoryProvider).get());
