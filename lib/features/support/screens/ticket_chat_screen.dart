import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/core/api_providers.dart';
import '../../../repositories/support/support_repository.dart';
import '../../../models/support/support_models.dart';
import '../../../core/api/api_exception.dart';
import '../../../shared/widgets/feedback/app_snack_bar.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/layout/responsive_frame.dart';

class ChatMessage {
  final String sender; // 'Agent', 'User', or 'System'
  final String text;
  final String time;

  ChatMessage({
    required this.sender,
    required this.text,
    required this.time,
  });
}

class TicketChatScreen extends StatefulWidget {
  const TicketChatScreen({super.key});

  @override
  State<TicketChatScreen> createState() => _TicketChatScreenState();
}

class _TicketChatScreenState extends State<TicketChatScreen> {
  final _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  late String _ticketTitle;
  late String _ticketStatus;
  String? _ticketId;

  @override
  void initState() {
    super.initState();
    final args = Get.arguments as Map<String, dynamic>? ?? {};
    _ticketTitle = args['title'] ?? 'Support Inquiry';
    _ticketStatus = args['status'] ?? 'OPEN';
    _ticketId = args['id']?.toString();
    _messages.add(ChatMessage(sender: 'Agent', text: 'Namaste! Welcome to Qikzoo Partner Support. How can we help you today?', time: 'Just now'));
    _loadTicket();
  }

  Future<void> _loadTicket() async {
    try {
      final repo = SupportRepository(ProviderScope.containerOf(context, listen: false).read(apiClientProvider));
      SupportTicketModel? ticket;
      if (_ticketId != null && _ticketId!.isNotEmpty) { ticket = await repo.get(_ticketId!); }
      else { final tickets = await repo.list(); final active = tickets.where((x) => !['RESOLVED', 'CLOSED'].contains(x.status)).toList(); if (active.isNotEmpty) { ticket = active.first; _ticketId = ticket.id; } }
      if (!mounted || ticket == null) return;
      setState(() { _ticketStatus = ticket!.status; _messages..clear()..addAll(ticket.messages.map((m) => ChatMessage(sender: m.senderId.startsWith('QIKZOO') ? 'Agent' : 'User', text: m.body, time: m.createdAt.toLocal().toString().substring(11, 16)))); });
      _scrollToBottom();
    } catch (_) {}
  }

  Future<void> _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    _textController.clear();
    try {
      final repo = SupportRepository(ProviderScope.containerOf(context, listen: false).read(apiClientProvider));
      if (_ticketId == null || _ticketId!.isEmpty) {
        final ticket = await repo.create('GENERAL', text);
        if (!mounted) return;
        setState(() { _ticketId = ticket.id; _ticketStatus = ticket.status; _messages..clear()..addAll(ticket.messages.map((m) => ChatMessage(sender: m.senderId.startsWith('QIKZOO') ? 'Agent' : 'User', text: m.body, time: m.createdAt.toLocal().toString().substring(11, 16)))); });
      } else {
        await repo.send(_ticketId!, text);
        if (mounted) setState(() => _messages.add(ChatMessage(sender: 'User', text: text, time: 'Just now')));
      }
      _scrollToBottom();
    } catch (error) {
      if (mounted) AppSnackBar.error(context, error is ApiException ? error.message : 'Unable to send your message. Please try again.');
    }
  }
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final normalizedStatus = _ticketStatus.toUpperCase();
    final isClosed = normalizedStatus == 'RESOLVED' || normalizedStatus == 'CLOSED';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        toolbarHeight: 72,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft,
              color: Color(0xFF0F172A), size: 24),
          onPressed: () => Get.back(),
        ),
        titleSpacing: 0,
        title: _SupportAppBarTitle(
          title: _ticketTitle,
          isClosed: isClosed,
        ),
      ),
      body: SafeArea(
        child: ResponsiveFrame(
          maxWidth: 520,
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              // Divider under AppBar
              const Divider(height: 1, color: Color(0xFFF1F5F9)),

              // Chat Messages
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
                  physics: const BouncingScrollPhysics(),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final message = _messages[index];

                    if (message.sender == 'System') {
                      return _buildSystemDivider(message.text);
                    }

                    final isUser = message.sender == 'User';
                    final isNextSame = index + 1 < _messages.length &&
                        _messages[index + 1].sender == message.sender;

                    return _buildMessageRow(
                      message: message,
                      isUser: isUser,
                      showAvatar: !isUser &&
                          (!isNextSame || index == _messages.length - 1),
                    );
                  },
                ),
              ),

              // Bottom control area (Closed banner or Active input)
              isClosed ? _buildClosedFooter() : _buildInputArea(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSystemDivider(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
      child: Row(
        children: [
          const Expanded(child: Divider(color: Color(0xFFE2E8F0))),
          Flexible(
            flex: 4,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                text,
                textAlign: TextAlign.center,
                softWrap: true,
                style: AppTypography.caption.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                  height: 1.35,
                ),
              ),
            ),
          ),
          const Expanded(child: Divider(color: Color(0xFFE2E8F0))),
        ],
      ),
    );
  }

  Widget _buildMessageRow({
    required ChatMessage message,
    required bool isUser,
    required bool showAvatar,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Agent Avatar on left
          if (!isUser) ...[
            if (showAvatar)
              Container(
                margin: const EdgeInsets.only(right: 8, bottom: 2),
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.border),
                  boxShadow: AppShadows.control,
                ),
                child: const Icon(LucideIcons.headphones,
                    size: 18, color: AppColors.primary),
              )
            else
              const SizedBox(width: 44),
          ],

          // Message Bubble
          Flexible(
            child: Container(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
              constraints: BoxConstraints(
                maxWidth: MediaQuery.sizeOf(context).width * 0.72,
              ),
              decoration: BoxDecoration(
                color: isUser ? AppColors.primary : AppColors.surface,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: isUser
                      ? const Radius.circular(16)
                      : const Radius.circular(4),
                  bottomRight: isUser
                      ? const Radius.circular(4)
                      : const Radius.circular(16),
                ),
                border: isUser ? null : Border.all(color: AppColors.border),
                boxShadow: isUser ? null : AppShadows.control,
              ),
              child: Column(
                crossAxisAlignment:
                    isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  Text(
                    message.text,
                    softWrap: true,
                    style: AppTypography.body.copyWith(
                      color: isUser ? Colors.white : AppColors.textPrimary,
                      height: 1.45,
                    ),
                  ),
                  if (message.time.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      message.time,
                      style: AppTypography.caption.copyWith(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: isUser
                            ? const Color(0xFFE0E7FF)
                            : const Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClosedFooter() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.surfaceMuted,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Ticket Closed',
            style: AppTypography.caption.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'This conversation has been marked as closed.',
            textAlign: TextAlign.center,
            softWrap: true,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: EdgeInsets.fromLTRB(
        14,
        10,
        8,
        10 + MediaQuery.viewPaddingOf(context).bottom,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Color(0xFFF1F5F9)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: AppColors.surfaceMuted,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.border),
              ),
              child: TextField(
                controller: _textController,
                style: AppTypography.body,
                decoration: const InputDecoration(
                  hintText: 'Type your message...',
                  hintStyle: TextStyle(
                    fontFamily: 'PlusJakartaSans',
                    fontSize: 13.5,
                    color: Color(0xFF94A3B8),
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 10),
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Material(
            color: AppColors.primary,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: _sendMessage,
              child: const SizedBox(
                width: 42,
                height: 42,
                child: Center(
                  child: Icon(
                    LucideIcons.send,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SupportAppBarTitle extends StatelessWidget {
  const _SupportAppBarTitle({
    required this.title,
    required this.isClosed,
  });

  final String title;
  final bool isClosed;

  @override
  Widget build(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.bodyMedium.copyWith(
              fontWeight: FontWeight.w800,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            isClosed ? 'Conversation closed' : 'Support agent online',
            style: AppTypography.caption.copyWith(
              color: AppColors.textSecondary,
              fontSize: 10.5,
            ),
          ),
        ],
      );
}
