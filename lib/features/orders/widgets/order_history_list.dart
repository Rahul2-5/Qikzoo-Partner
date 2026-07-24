import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../models/orders/order_history_page_model.dart';
import '../../../providers/orders/order_history_provider.dart';
import '../../../shared/widgets/feedback/app_snack_bar.dart';
import '../../../shared/widgets/misc/empty_state.dart';
import '../../../shared/widgets/misc/error_widget_custom.dart';
import 'rider_order_list_tile.dart';

/// One tab's worth of paginated order history — infinite-scrolls by
/// calling `OrderHistoryNotifier.loadMore()` when the list nears its end.
class OrderHistoryList extends ConsumerStatefulWidget {
  final OrderHistoryFilter filter;
  final void Function(String riderOrderId) onOpen;

  const OrderHistoryList({super.key, required this.filter, required this.onOpen});

  @override
  ConsumerState<OrderHistoryList> createState() => _OrderHistoryListState();
}

class _OrderHistoryListState extends ConsumerState<OrderHistoryList> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  Future<void> _loadMore() async {
    try {
      await ref.read(orderHistoryProvider(widget.filter).notifier).loadMore();
    } on ApiException catch (e) {
      if (mounted) AppSnackBar.error(context, e.message);
    } catch (_) {
      if (mounted) {
        AppSnackBar.error(context, 'Could not load more orders. Please try again.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final stateAsync = ref.watch(orderHistoryProvider(widget.filter));

    return stateAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => ErrorWidgetCustom(
        message: error is ApiException ? error.message : 'Could not load orders.',
        onRetry: () => ref.read(orderHistoryProvider(widget.filter).notifier).refresh(),
      ),
      data: (state) {
        if (state.items.isEmpty) {
          return EmptyState(
            icon: LucideIcons.inbox,
            message: switch (widget.filter) {
              OrderHistoryFilter.active => 'No active orders right now.',
              OrderHistoryFilter.completed => 'No completed orders yet.',
              OrderHistoryFilter.cancelled => 'No cancelled orders.',
            },
          );
        }
        return RefreshIndicator(
          color: AppColors.secondary,
          onRefresh: () => ref.read(orderHistoryProvider(widget.filter).notifier).refresh(),
          child: ListView.separated(
            controller: _scrollController,
            physics:
                const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
            padding: const EdgeInsets.only(bottom: AppSpacing.lg),
            itemCount: state.items.length + (state.isLoadingMore ? 1 : 0),
            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
            itemBuilder: (context, index) {
              if (index >= state.items.length) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                  child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                );
              }
              final order = state.items[index];
              return RiderOrderListTile(
                order: order,
                onTap: () => widget.onOpen(order.id),
              );
            },
          ),
        );
      },
    );
  }
}
