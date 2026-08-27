import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api_client.dart';
import '../../core/api/api_endpoints.dart';
import '../../models/referrals/referral_summary_model.dart';
import '../../providers/core/api_providers.dart';

abstract class ReferralRepository {
  Future<ReferralSummaryModel> getSummary();
  Future<ReferralSummaryModel> applyCode(String code);
}

class DioReferralRepository implements ReferralRepository {
  const DioReferralRepository(this._api);
  final ApiClient _api;
  @override
  Future<ReferralSummaryModel> getSummary() async {
    final response =
        await _api.get<Map<String, dynamic>>(ApiEndpoints.riderReferrals);
    return ReferralSummaryModel.fromJson(_unwrap(response.data));
  }

  @override
  Future<ReferralSummaryModel> applyCode(String code) async {
    final response = await _api.post<Map<String, dynamic>>(
        ApiEndpoints.riderReferralApply,
        data: {'code': code.trim().toUpperCase()});
    return ReferralSummaryModel.fromJson(_unwrap(response.data));
  }

  Map<String, dynamic> _unwrap(Map<String, dynamic>? body) {
    final nested = body?['data'];
    return nested is Map<String, dynamic> ? nested : (body ?? const {});
  }
}

final referralRepositoryProvider = Provider<ReferralRepository>(
    (ref) => DioReferralRepository(ref.watch(apiClientProvider)));
