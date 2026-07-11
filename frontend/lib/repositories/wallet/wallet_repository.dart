import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import '../../models/wallet/wallet_model.dart';
import '../../models/wallet/transaction_model.dart';

abstract class WalletRepository {
  Future<WalletModel> getWallet();
  Future<List<TransactionModel>> getTransactions();
}

class MockWalletRepository implements WalletRepository {
  @override
  Future<WalletModel> getWallet() async {
    await Future.delayed(AppConstants.mockNetworkDelay);
    return const WalletModel(balance: 3120, pendingAmount: 240);
  }

  @override
  Future<List<TransactionModel>> getTransactions() async {
    await Future.delayed(AppConstants.mockNetworkDelay);
    return [
      TransactionModel(
        id: 'txn_1',
        type: TransactionType.credit,
        amount: 96,
        description: 'Order #order_1 payout',
        date: DateTime.now().subtract(const Duration(hours: 2)),
      ),
    ];
  }
}

final walletRepositoryProvider = Provider<WalletRepository>((ref) => MockWalletRepository());
