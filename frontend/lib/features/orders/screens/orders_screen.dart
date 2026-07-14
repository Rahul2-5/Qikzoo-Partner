import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../models/orders/order_list_entry.dart';
import '../../../shared/widgets/layout/responsive_frame.dart';
import '../../../shared/widgets/misc/empty_state.dart';
import '../../../shared/widgets/navigation/app_bottom_nav.dart';
import '../widgets/date_group_header.dart';
import '../widgets/order_filter_sheet.dart';
import '../widgets/order_list_card.dart';
import '../widgets/orders_header.dart';
import '../widgets/orders_support_banner.dart';
import '../widgets/orders_tab_bar.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  final _all = OrderListEntry.mockList();
  OrdersTab _tab = OrdersTab.all;
  String _query = '';
  bool _searchOpen = false;
  OrdersSort _sort = OrdersSort.newest;
  OrdersDateFilter _dateFilter = OrdersDateFilter.all;

  void _toggleSearch() {
    setState(() {
      _searchOpen = !_searchOpen;
      if (!_searchOpen) _query = '';
    });
  }

  Future<void> _openFilter() async {
    final result = await OrderFilterSheet.show(
      context,
      sort: _sort,
      dateFilter: _dateFilter,
    );
    if (result != null) {
      setState(() {
        _sort = result.sort;
        _dateFilter = result.dateFilter;
      });
    }
  }

  void _openDetails(OrderListEntry entry) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Order details coming soon')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = filterEntries(
      all: _all,
      tab: _tab,
      query: _query,
      dateFilter: _dateFilter,
    );
    final sorted = sortEntries(filtered, _sort);
    final groups = groupByDate(sorted);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ResponsiveFrame(
          maxWidth: 520,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              OrdersHeader(
                searchOpen: _searchOpen,
                query: _query,
                onToggleSearch: _toggleSearch,
                onQueryChanged: (q) => setState(() => _query = q),
                onOpenFilter: _openFilter,
              ),
              const SizedBox(height: AppSpacing.md),
              OrdersTabBar(
                current: _tab,
                onChanged: (t) => setState(() => _tab = t),
              ),
              const SizedBox(height: AppSpacing.md),
              Expanded(
                child: sorted.isEmpty
                    ? const EmptyState(
                        icon: LucideIcons.inbox,
                        message: 'No orders here yet',
                      )
                    : ListView(
                        physics: const BouncingScrollPhysics(),
                        children: [
                          for (final entry in groups.entries) ...[
                            DateGroupHeader(label: entry.key),
                            for (final order in entry.value)
                              OrderListCard(
                                entry: order,
                                onTap: () => _openDetails(order),
                              ),
                          ],
                          const SizedBox(height: AppSpacing.sm),
                          OrdersSupportBanner(onGetSupport: () {}),
                          const SizedBox(height: AppSpacing.md),
                        ],
                      ),
              ),
              const AppBottomNav(currentIndex: 2),
            ],
          ),
        ),
      ),
    );
  }
}
