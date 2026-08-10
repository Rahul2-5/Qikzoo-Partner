import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api_client.dart';
import '../../core/api/api_endpoints.dart';
import '../../models/earnings/earnings_models.dart';
import '../../providers/core/api_providers.dart';

abstract class EarningsRepository {
  /// `GET /rider/earnings/summary` — real today/this-week/lifetime totals
  /// (`RiderEarningsService.summary`). No category breakdown or daily
  /// chart-bar series exists on the backend — this is the full real shape.
  Future<EarningsSummaryModel> getSummary();

  /// `GET /rider/earnings/history` — paginated, most-recent-delivery-first.
  Future<EarningsHistoryPage> getHistory({int page = 1, int pageSize = 20});
}

class DioEarningsRepository implements EarningsRepository {
  const DioEarningsRepository({required ApiClient apiClient})
      : _apiClient = apiClient;

  final ApiClient _apiClient;

  @override
  Future<EarningsSummaryModel> getSummary() async {
    final response = await _apiClient
        .get<Map<String, dynamic>>(ApiEndpoints.riderEarningsSummary);
    return EarningsSummaryModel.fromJson(_unwrap(response.data));
  }

  @override
  Future<EarningsHistoryPage> getHistory({int page = 1, int pageSize = 20}) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      ApiEndpoints.riderEarningsHistory,
      queryParameters: {'page': page, 'pageSize': pageSize},
    );
    return EarningsHistoryPage.fromJson(_unwrap(response.data));
  }

  Map<String, dynamic> _unwrap(Map<String, dynamic>? body) {
    final nested = body?['data'];
    final payload = nested is Map<String, dynamic> ? nested : body;
    return payload ?? const {};
  }
}

final earningsRepositoryProvider = Provider<EarningsRepository>(
  (ref) => DioEarningsRepository(apiClient: ref.watch(apiClientProvider)),
);
