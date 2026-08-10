import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api_client.dart';
import '../../core/api/api_endpoints.dart';
import '../../models/wallet/wallet_model.dart';
import '../../models/wallet/transaction_model.dart';
import '../../providers/core/api_providers.dart';

abstract class WalletRepository {
  Future<WalletModel> getWallet();
  Future<List<TransactionModel>> getTransactions();
}

/// `GET /rider/wallet` returns the rider's wallet balances in paise
/// (`availableBalancePaise`, plus a pending/locked balance under one of a few
/// possible keys). Amounts are converted to rupees for [WalletModel].
class DioWalletRepository implements WalletRepository {
  const DioWalletRepository({required ApiClient apiClient})
      : _apiClient = apiClient;

  final ApiClient _apiClient;

  @override
  Future<WalletModel> getWallet() async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      ApiEndpoints.riderWallet,
    );
    final wallet = _unwrap(response.data);
    final availablePaise = _readPaise(wallet, const [
      'availableBalancePaise',
      'balancePaise',
    ]);
    final pendingPaise = _readPaise(wallet, const [
      'pendingBalancePaise',
      'pendingPayoutPaise',
      'lockedBalancePaise',
    ]);
    return WalletModel(
      balance: availablePaise / 100.0,
      pendingAmount: pendingPaise / 100.0,
    );
  }

  /// The wallet-transactions endpoint is not yet available in this app; return
  /// an empty list rather than fabricated rows so the UI shows the real
  /// (empty) state instead of mock data.
  @override
  Future<List<TransactionModel>> getTransactions() async => const [];

  Map<String, dynamic> _unwrap(Map<String, dynamic>? body) {
    final nested = body?['data'];
    final payload = nested is Map<String, dynamic> ? nested : body;
    return payload ?? const {};
  }

  int _readPaise(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      final value = data[key];
      if (value is num) return value.toInt();
    }
    return 0;
  }
}

final walletRepositoryProvider = Provider<WalletRepository>(
  (ref) => DioWalletRepository(apiClient: ref.watch(apiClientProvider)),
);
