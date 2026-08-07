import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../data/order_preview_data.dart';
import '../../../models/orders/order_history_page_model.dart';
import '../../../models/orders/rider_order_model.dart';
import '../../../providers/orders/order_history_provider.dart';
import '../../../shared/widgets/feedback/app_snack_bar.dart';
import '../../../shared/widgets/misc/empty_state.dart';
import '../../../shared/widgets/misc/error_widget_custom.dart';
import '../../../shared/widgets/misc/loading_skeleton.dart';
import 'rider_order_list_tile.dart';

/// One tab's worth of paginated order history — infinite-scrolls by
/// calling `OrderHistoryNotifier.loadMore()` when the list nears its end.
class OrderHistoryList extends ConsumerStatefulWidget {
  final OrderHistoryFilter filter;
  final void Function(String riderOrderId) onOpen;
  final int? maxItems;

  const OrderHistoryList({
    super.key,
    required this.filter,
    required this.onOpen,
    this.maxItems,
  });

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
    if (widget.maxItems != null) return;
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
        AppSnackBar.error(
            context, 'Could not load more orders. Please try again.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final stateAsync = ref.watch(orderHistoryProvider(widget.filter));
    final showOrderPreviews = ref.watch(showOrderPreviewProvider);

    return stateAsync.when(
      loading: () => const PageLoadingShimmer(
        padding: EdgeInsets.zero,
        itemCount: 3,
      ),
      error: (error, _) => ErrorWidgetCustom(
        message:
            error is ApiException ? error.message : 'Could not load orders.',
        onRetry: () =>
            ref.read(orderHistoryProvider(widget.filter).notifier).refresh(),
      ),
      data: (state) {
        final previewItems = showOrderPreviews && state.items.isEmpty
            ? orderPreviewsFor(widget.filter)
            : const <RiderOrderModel>[];
        final allItems = state.items.isEmpty ? previewItems : state.items;
        final displayedItems = widget.maxItems == null
            ? allItems
            : allItems.take(widget.maxItems!).toList(growable: false);

        if (displayedItems.isEmpty) {
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
          onRefresh: () =>
              ref.read(orderHistoryProvider(widget.filter).notifier).refresh(),
          child: ListView.separated(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics()),
            padding: const EdgeInsets.only(bottom: AppSpacing.lg),
            // A capped list deliberately cannot request more pages: the
            // active Orders view represents one current assignment only.
            itemCount: displayedItems.length +
                (widget.maxItems == null &&
                        state.isLoadingMore &&
                        previewItems.isEmpty
                    ? 1
                    : 0),
            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
            itemBuilder: (context, index) {
              if (index >= displayedItems.length) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                  child: LoadingSkeleton(height: 56),
                );
              }
              final order = displayedItems[index];
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
