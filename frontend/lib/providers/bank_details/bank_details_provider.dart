import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../repositories/bank_details/bank_details_repository.dart';
import '../../models/bank_details/bank_details_model.dart';

class BankDetailsNotifier extends AsyncNotifier<BankDetailsModel?> {
  @override
  Future<BankDetailsModel?> build() => ref.watch(bankDetailsRepositoryProvider).getBankDetails();

  Future<void> save(BankDetailsModel details) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(bankDetailsRepositoryProvider).saveBankDetails(details);
      return details;
    });
  }
}

final bankDetailsProvider = AsyncNotifierProvider<BankDetailsNotifier, BankDetailsModel?>(
  BankDetailsNotifier.new,
);
