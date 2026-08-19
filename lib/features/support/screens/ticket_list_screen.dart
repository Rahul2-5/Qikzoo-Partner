import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/layout/responsive_frame.dart';

class SupportTicket {
  final String id;
  final String title;
  final String date;
  final String outletName;
  final String status; // 'Pending' or 'Resolved'

  SupportTicket({
    required this.id,
    required this.title,
    required this.date,
    required this.outletName,
    required this.status,
  });
}

class TicketListScreen extends StatefulWidget {
  const TicketListScreen({super.key});

  @override
  State<TicketListScreen> createState() => _TicketListScreenState();
}

class _TicketListScreenState extends State<TicketListScreen> {
  String _activeFilter = 'All';

  final List<SupportTicket> _tickets = [
    SupportTicket(
      id: 'TCK-1002',
      title: 'Payout delay issue',
      date: '18 Aug 2026',
      outletName: 'Noodle House, Mumbai',
      status: 'Pending',
    ),
    SupportTicket(
      id: 'TCK-0985',
      title: 'Wrong cash collection',
      date: '15 Aug 2026',
      outletName: 'Pizza Point',
      status: 'Resolved',
    ),
    SupportTicket(
      id: 'TCK-0961',
      title: 'Customer not reachable',
      date: '12 Aug 2026',
      outletName: 'Burger Bistro',
      status: 'Resolved',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final filteredTickets = _tickets.where((ticket) {
      if (_activeFilter == 'All') return true;
      return ticket.status == _activeFilter;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Support Tickets'),
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => Get.back(),
        ),
      ),
      body: SafeArea(
        child: ResponsiveFrame(
          maxWidth: 520,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              // Filter Chips
              Row(
                children: [
                  _buildFilterChip('All'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Pending'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Resolved'),
                ],
              ),
              const SizedBox(height: 16),

              // Ticket List
              Expanded(
                child: filteredTickets.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        itemCount: filteredTickets.length,
                        itemBuilder: (context, index) {
                          final ticket = filteredTickets[index];
                          return _buildTicketCard(ticket);
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final selected = _activeFilter == label;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (val) {
        if (val) setState(() => _activeFilter = label);
      },
      selectedColor: AppColors.primarySoft,
      labelStyle: TextStyle(
        color: selected ? AppColors.primary : AppColors.textSecondary,
        fontWeight: FontWeight.bold,
        fontSize: 13,
      ),
      side: BorderSide(
        color: selected ? AppColors.primary : AppColors.border,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
    );
  }

  Widget _buildTicketCard(SupportTicket ticket) {
    final isPending = ticket.status == 'Pending';
    final statusColor = isPending ? AppColors.warning : AppColors.success;
    final statusBg = isPending ? AppColors.warningBg : AppColors.successBg;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.border),
      ),
      child: InkWell(
        onTap: () => Get.toNamed(
          AppRoutes.ticketChat,
          arguments: {
            'id': ticket.id,
            'title': ticket.title,
            'status': ticket.status,
            'outlet': ticket.outletName,
            'date': ticket.date,
          },
        ),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    ticket.id,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusBg,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      ticket.status,
                      style: AppTypography.caption.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.w800,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                ticket.title,
                style: AppTypography.bodyMedium.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(LucideIcons.store, size: 12, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      ticket.outletName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Icon(LucideIcons.calendar, size: 12, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    ticket.date,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(LucideIcons.helpCircle, size: 48, color: AppColors.textDisabled),
          const SizedBox(height: 12),
          Text(
            'No tickets found',
            style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          const Text('You do not have any tickets in this category.'),
        ],
      ),
    );
  }
}
