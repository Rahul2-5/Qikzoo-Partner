import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/utils/payment_failure_message.dart';
import '../../core/api/api_client.dart';
import '../../core/api/api_endpoints.dart';
import '../../models/wallet/wallet_model.dart';
import '../../models/wallet/transaction_model.dart';
import '../../providers/core/api_providers.dart';

abstract class WalletRepository {
  Future<WalletModel> getWallet();
  Future<List<TransactionModel>> getTransactions();
  Future<CashDepositModel> createCashDeposit(int amountPaise);
  Future<CashDepositModel> getCashDeposit(String depositId);
}

class CashDepositModel {
  const CashDepositModel({
    required this.id,
    required this.amountPaise,
    required this.status,
    required this.qrPayload,
    required this.expiresAt,
    this.gateway,
    this.transactionId,
    this.failureReason,
  });

  final String id;
  final int amountPaise;
  final String status;
  final String qrPayload;
  final DateTime expiresAt;
  final String? gateway;
  final String? transactionId;
  final String? failureReason;

  bool get isPaid => status == 'SUCCESS';
  bool get isTerminal =>
      const {'SUCCESS', 'FAILED', 'EXPIRED', 'CANCELLED'}.contains(status);

  factory CashDepositModel.fromJson(Map<String, dynamic> json) =>
      CashDepositModel(
        id: (json['depositId'] ?? json['id'] ?? '').toString(),
        amountPaise: _int(json['amountPaise']),
        status: (json['status'] ?? 'FAILED').toString().toUpperCase(),
        qrPayload: (json['qrPayload'] ?? '').toString(),
        expiresAt:
            DateTime.tryParse(json['expiresAt']?.toString() ?? '')?.toLocal() ??
                DateTime.fromMillisecondsSinceEpoch(0),
        gateway: json['gateway']?.toString(),
        transactionId: json['transactionId']?.toString(),
        failureReason: paymentFailureMessage(json['failureReason']),
      );
}

/// `GET /rider/wallet` returns the rider's wallet balances in paise
/// (`availableBalancePaise`, pending balance, floatingCash, cashLimit).
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
    final floatingPaise = _readPaise(wallet, const [
      'floatingCashPaise',
      'cashInHandPaise',
      'codCashPaise',
      'collectedCashPaise',
    ]);
    final limitPaise = _readPaise(wallet, const [
      'cashLimitPaise',
      'floatingCashLimitPaise',
      'availableCashLimitPaise',
    ]);

    final rawLimit = limitPaise > 0 ? (limitPaise / 100.0) : 2000.0;

    return WalletModel(
      balance: availablePaise / 100.0,
      pendingAmount: pendingPaise / 100.0,
      floatingCash: floatingPaise / 100.0,
      cashLimit: rawLimit,
      cashDepositAvailable: wallet['cashDepositAvailable'] == true,
    );
  }

  @override
  Future<List<TransactionModel>> getTransactions() async {
    final response = await _apiClient.get<dynamic>(
      ApiEndpoints.riderWalletTransactions,
    );
    final raw = response.data is Map<String, dynamic>
        ? (response.data as Map<String, dynamic>)['data'] ?? response.data
        : response.data;
    if (raw is! List) return const [];
    return raw.whereType<Map<String, dynamic>>().map((json) {
      final availableDelta = _int(json['availableDeltaPaise']);
      final floatingDelta = _int(json['floatingCashDeltaPaise']);
      final delta = availableDelta != 0 ? availableDelta : floatingDelta;
      final backendType = (json['type'] ?? '').toString();
      final type = switch (backendType) {
        'DELIVERY_EARNING' => TransactionType.earning,
        'COD_CASH_COLLECTED' => TransactionType.cashHeld,
        'COD_CASH_DEPOSITED' => TransactionType.cashDeposited,
        'PAYOUT' => TransactionType.payout,
        _ => TransactionType.adjustment,
      };
      return TransactionModel(
        id: (json['id'] ?? '').toString(),
        type: type,
        amount: delta.abs() / 100,
        description: (json['description'] ?? 'Wallet activity').toString(),
        date:
            DateTime.tryParse(json['createdAt']?.toString() ?? '')?.toLocal() ??
                DateTime.now(),
      );
    }).toList();
  }

  @override
  Future<CashDepositModel> createCashDeposit(int amountPaise) async {
    final response = await _apiClient.post<Map<String, dynamic>>(
      ApiEndpoints.riderWalletDeposits,
      data: {'amountPaise': amountPaise},
    );
    return CashDepositModel.fromJson(_unwrap(response.data));
  }

  @override
  Future<CashDepositModel> getCashDeposit(String depositId) async {
    final response = await _apiClient.get<Map<String, dynamic>>(
      ApiEndpoints.riderWalletDeposit(depositId),
    );
    return CashDepositModel.fromJson(_unwrap(response.data));
  }

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

int _int(Object? value) {
  if (value is int) return value;
  if (value is num) return value.round();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

final walletRepositoryProvider = Provider<WalletRepository>(
  (ref) => DioWalletRepository(apiClient: ref.watch(apiClientProvider)),
);
