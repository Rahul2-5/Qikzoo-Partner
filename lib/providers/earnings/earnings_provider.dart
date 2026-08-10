import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/earnings/earnings_models.dart';
import '../../repositories/earnings/earnings_repository.dart';

class EarningsSummaryNotifier extends AsyncNotifier<EarningsSummaryModel> {
  @override
  Future<EarningsSummaryModel> build() =>
      ref.watch(earningsRepositoryProvider).getSummary();

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(earningsRepositoryProvider).getSummary(),
    );
  }
}

final earningsSummaryProvider =
    AsyncNotifierProvider<EarningsSummaryNotifier, EarningsSummaryModel>(
  EarningsSummaryNotifier.new,
);

class EarningsHistoryNotifier extends AsyncNotifier<EarningsHistoryPage> {
  @override
  Future<EarningsHistoryPage> build() =>
      ref.watch(earningsRepositoryProvider).getHistory();

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(earningsRepositoryProvider).getHistory(),
    );
  }
}

final earningsHistoryProvider =
    AsyncNotifierProvider<EarningsHistoryNotifier, EarningsHistoryPage>(
  EarningsHistoryNotifier.new,
);
