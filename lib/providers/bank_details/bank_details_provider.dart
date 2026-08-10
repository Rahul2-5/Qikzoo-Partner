import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../repositories/bank_details/bank_details_repository.dart';
import '../../models/bank_details/bank_details_model.dart';

class BankDetailsNotifier extends AsyncNotifier<BankDetailsModel?> {
  @override
  Future<BankDetailsModel?> build() => ref.watch(bankDetailsRepositoryProvider).getBankDetails();

  Future<void> save(BankDetailsModel details, {required String accountNumber}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref
          .read(bankDetailsRepositoryProvider)
          .saveBankDetails(details, accountNumber: accountNumber);
      return ref.read(bankDetailsRepositoryProvider).getBankDetails();
    });
  }
}

final bankDetailsProvider = AsyncNotifierProvider<BankDetailsNotifier, BankDetailsModel?>(
  BankDetailsNotifier.new,
);
