import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../repositories/wallet/wallet_repository.dart';
import '../../models/wallet/wallet_model.dart';
import '../../models/wallet/transaction_model.dart';

final walletProvider = FutureProvider<WalletModel>(
  (ref) => ref.watch(walletRepositoryProvider).getWallet(),
);

final transactionsProvider = FutureProvider<List<TransactionModel>>(
  (ref) => ref.watch(walletRepositoryProvider).getTransactions(),
);
