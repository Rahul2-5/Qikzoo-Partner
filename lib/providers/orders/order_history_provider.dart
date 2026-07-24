import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/orders/order_history_page_model.dart';
import '../../models/orders/rider_order_model.dart';
import '../../repositories/orders/rider_orders_repository.dart';

const _pageSize = 20;

class OrderHistoryState extends Equatable {
  final List<RiderOrderModel> items;
  final int page;
  final int total;
  final bool isLoadingMore;

  const OrderHistoryState({
    required this.items,
    required this.page,
    required this.total,
    this.isLoadingMore = false,
  });

  bool get hasMore => items.length < total;

  OrderHistoryState copyWith({
    List<RiderOrderModel>? items,
    int? page,
    int? total,
    bool? isLoadingMore,
  }) =>
      OrderHistoryState(
        items: items ?? this.items,
        page: page ?? this.page,
        total: total ?? this.total,
        isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      );

  @override
  List<Object?> get props => [items, page, total, isLoadingMore];
}

/// One paginated, infinite-scrollable order-history list per
/// [OrderHistoryFilter] tab — kept as a family so switching tabs doesn't
/// discard the other tabs' already-loaded pages.
class OrderHistoryNotifier
    extends FamilyAsyncNotifier<OrderHistoryState, OrderHistoryFilter> {
  @override
  Future<OrderHistoryState> build(OrderHistoryFilter arg) => _fetchFirstPage();

  Future<OrderHistoryState> _fetchFirstPage() async {
    final page = await ref.read(riderOrdersRepositoryProvider).getHistory(
          filter: arg,
          page: 1,
          pageSize: _pageSize,
        );
    return OrderHistoryState(items: page.items, page: page.page, total: page.total);
  }

  Future<void> refresh() async {
    state = await AsyncValue.guard(_fetchFirstPage);
  }

  /// Deliberately does NOT go through AsyncValue.guard — a failed "load
  /// more" page must not replace the already-visible list with a
  /// full-screen error; the exception propagates to the caller (the
  /// screen), which shows a snackbar and leaves the current page intact.
  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || current.isLoadingMore || !current.hasMore) return;

    state = AsyncData(current.copyWith(isLoadingMore: true));
    try {
      final nextPage = current.page + 1;
      final OrderHistoryPageModel page =
          await ref.read(riderOrdersRepositoryProvider).getHistory(
                filter: arg,
                page: nextPage,
                pageSize: _pageSize,
              );
      state = AsyncData(
        current.copyWith(
          items: [...current.items, ...page.items],
          page: page.page,
          total: page.total,
          isLoadingMore: false,
        ),
      );
    } catch (_) {
      state = AsyncData(current.copyWith(isLoadingMore: false));
      rethrow;
    }
  }
}

final orderHistoryProvider = AsyncNotifierProvider.family<OrderHistoryNotifier,
    OrderHistoryState, OrderHistoryFilter>(OrderHistoryNotifier.new);
