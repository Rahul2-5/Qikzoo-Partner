import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../models/support/support_ticket_model.dart';
import '../../../providers/support/support_provider.dart';
import '../../../shared/widgets/buttons/primary_cta_button.dart';
import '../../../shared/widgets/feedback/app_snack_bar.dart';
import '../../../shared/widgets/layout/responsive_frame.dart';
import '../../profile/widgets/account_screen_components.dart';

class HelpSupportScreen extends ConsumerStatefulWidget {
  const HelpSupportScreen({super.key});

  @override
  ConsumerState<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends ConsumerState<HelpSupportScreen> {
  bool _isCreatingTicket = false;

  Future<String?> _showTicketSheet() {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.sheet),
        ),
      ),
      builder: (sheetContext) => const _CreateTicketSheet(),
    );
  }

  Future<void> _createTicket() async {
    final subject = await _showTicketSheet();
    if (subject == null || !mounted) return;
    setState(() => _isCreatingTicket = true);
    try {
      await ref.read(supportTicketsProvider.notifier).createTicket(subject);
      if (mounted) AppSnackBar.success(context, 'Support ticket created');
    } catch (_) {
      if (mounted) {
        AppSnackBar.error(context, 'Could not create the ticket. Try again.');
      }
    } finally {
      if (mounted) setState(() => _isCreatingTicket = false);
    }
  }

  void _showChannelMessage(String channel) {
    AppSnackBar.info(context, '$channel support will connect you shortly');
  }

  @override
  Widget build(BuildContext context) {
    final ticketsAsync = ref.watch(supportTicketsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ResponsiveFrame(
          maxWidth: 520,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AccountScreenHeader(
                title: 'Help & Support',
                subtitle:
                    'Get quick help with deliveries, payouts, or your account.',
              ),
              const SizedBox(height: AppSpacing.lg),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(AppRadius.sheet),
                        ),
                        child: Column(
                          children: [
                            Container(
                              width: 54,
                              height: 54,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.12),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                LucideIcons.headphones,
                                color: Colors.white,
                                size: 27,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            Text(
                              'How can we help?',
                              style: AppTypography.h2
                                  .copyWith(color: Colors.white),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              'Partner support is available 24 × 7',
                              textAlign: TextAlign.center,
                              style: AppTypography.caption.copyWith(
                                color: Colors.white.withValues(alpha: 0.72),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            Row(
                              children: [
                                Expanded(
                                  child: _SupportChannelButton(
                                    icon: LucideIcons.phone,
                                    label: 'Call us',
                                    onTap: () => _showChannelMessage('Phone'),
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                Expanded(
                                  child: _SupportChannelButton(
                                    icon: LucideIcons.messageCircle,
                                    label: 'Live chat',
                                    onTap: () => _showChannelMessage('Chat'),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Text('Your tickets', style: AppTypography.bodyMedium),
                      const SizedBox(height: AppSpacing.sm),
                      ticketsAsync.when(
                        loading: () => const AccountSectionCard(
                          child: Center(
                            child: Padding(
                              padding: EdgeInsets.all(AppSpacing.md),
                              child: CircularProgressIndicator(),
                            ),
                          ),
                        ),
                        error: (error, _) => AccountSectionCard(
                          child: Row(
                            children: [
                              const Icon(
                                LucideIcons.alertCircle,
                                color: AppColors.warning,
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: Text(
                                  'Could not load support tickets',
                                  style: AppTypography.body,
                                ),
                              ),
                              TextButton(
                                onPressed: () =>
                                    ref.invalidate(supportTicketsProvider),
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        ),
                        data: (tickets) => tickets.isEmpty
                            ? const AccountSectionCard(
                                child: _EmptyTickets(),
                              )
                            : Column(
                                children: [
                                  for (var index = 0;
                                      index < tickets.length;
                                      index++) ...[
                                    _SupportTicketCard(ticket: tickets[index]),
                                    if (index < tickets.length - 1)
                                      const SizedBox(height: AppSpacing.sm),
                                  ],
                                ],
                              ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Text('Frequently asked questions',
                          style: AppTypography.bodyMedium),
                      const SizedBox(height: AppSpacing.sm),
                      const AccountSectionCard(
                        padding: EdgeInsets.zero,
                        child: Column(
                          children: [
                            _FaqTile(
                              question: 'When will I receive my payout?',
                              answer:
                                  'Completed delivery earnings are included in your next scheduled payout after verification.',
                            ),
                            Divider(height: 1),
                            _FaqTile(
                              question: 'How do I update a document?',
                              answer:
                                  'Open Documents from your profile, select the document, and choose Replace.',
                            ),
                            Divider(height: 1),
                            _FaqTile(
                              question: 'What if an order has an issue?',
                              answer:
                                  'Use call or chat support from the active order screen for the fastest assistance.',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                    ],
                  ),
                ),
              ),
              PrimaryCtaButton(
                label: 'Raise a support ticket',
                trailingIcon: LucideIcons.plus,
                isLoading: _isCreatingTicket,
                onPressed: _isCreatingTicket ? null : _createTicket,
              ),
              const SizedBox(height: AppSpacing.md),
            ],
          ),
        ),
      ),
    );
  }
}

class _CreateTicketSheet extends StatefulWidget {
  const _CreateTicketSheet();

  @override
  State<_CreateTicketSheet> createState() => _CreateTicketSheetState();
}

class _CreateTicketSheetState extends State<_CreateTicketSheet> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Raise a support ticket', style: AppTypography.h2),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Briefly describe what you need help with.',
              style:
                  AppTypography.body.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.lg),
            TextField(
              controller: _controller,
              autofocus: true,
              maxLength: 100,
              textCapitalization: TextCapitalization.sentences,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                labelText: 'Issue summary',
                hintText: 'e.g. Payout not received',
                prefixIcon: Icon(
                  LucideIcons.fileText,
                  color: AppColors.secondary,
                  size: 20,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            PrimaryCtaButton(
              label: 'Submit ticket',
              trailingIcon: LucideIcons.send,
              onPressed: _controller.text.trim().length >= 4
                  ? () => Navigator.of(context).pop(_controller.text.trim())
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _SupportChannelButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _SupportChannelButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(AppRadius.control),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.control),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 52),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 19),
              const SizedBox(width: AppSpacing.sm),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodyMedium.copyWith(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyTickets extends StatelessWidget {
  const _EmptyTickets();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: AppColors.primarySoft,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            LucideIcons.checkCircle2,
            color: AppColors.primary,
            size: 21,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('No open tickets', style: AppTypography.bodyMedium),
              const SizedBox(height: 2),
              Text('You are all caught up', style: AppTypography.caption),
            ],
          ),
        ),
      ],
    );
  }
}

class _SupportTicketCard extends StatelessWidget {
  final SupportTicketModel ticket;

  const _SupportTicketCard({required this.ticket});

  String get _statusLabel => switch (ticket.status) {
        SupportTicketStatus.open => 'Open',
        SupportTicketStatus.inProgress => 'In progress',
        SupportTicketStatus.resolved => 'Resolved',
      };

  Color get _statusColor => switch (ticket.status) {
        SupportTicketStatus.open => AppColors.warning,
        SupportTicketStatus.inProgress => AppColors.secondary,
        SupportTicketStatus.resolved => AppColors.success,
      };

  @override
  Widget build(BuildContext context) {
    return AccountSectionCard(
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppRadius.control),
            ),
            child: Icon(
              LucideIcons.fileText,
              color: _statusColor,
              size: 20,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(ticket.subject, style: AppTypography.bodyMedium),
                const SizedBox(height: 2),
                Text(
                  '${ticket.id.toUpperCase()} • ${DateFormat('d MMM yyyy').format(ticket.createdAt)}',
                  style: AppTypography.caption,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            decoration: BoxDecoration(
              color: _statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppRadius.chip),
            ),
            child: Text(
              _statusLabel,
              style: AppTypography.caption.copyWith(color: _statusColor),
            ),
          ),
        ],
      ),
    );
  }
}

class _FaqTile extends StatelessWidget {
  final String question;
  final String answer;

  const _FaqTile({required this.question, required this.answer});

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        childrenPadding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          0,
          AppSpacing.md,
          AppSpacing.md,
        ),
        title: Text(question, style: AppTypography.bodyMedium),
        iconColor: AppColors.secondary,
        collapsedIconColor: AppColors.textSecondary,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(answer, style: AppTypography.body),
          ),
        ],
      ),
    );
  }
}
