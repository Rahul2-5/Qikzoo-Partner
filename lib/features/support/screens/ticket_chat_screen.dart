import 'package:flutter/material.dart';
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

  @override
  void initState() {
    super.initState();
    final args = Get.arguments as Map<String, dynamic>? ?? {};
    _ticketTitle = args['title'] ?? 'Support Inquiry';
    _ticketStatus = args['status'] ?? 'Pending';

    if (_ticketStatus == 'Resolved' || _ticketStatus == 'Closed') {
      _messages.addAll([
        ChatMessage(
          sender: 'Agent',
          text:
              'Hello Partner, we have received your query. We will get back to you shortly via call or chat. You can revisit your ticket anytime to check status.',
          time: 'Jul 28, 10:01 PM',
        ),
        ChatMessage(
          sender: 'User',
          text: '?',
          time: 'Jul 28, 10:04 PM',
        ),
        ChatMessage(
          sender: 'System',
          text: 'Support agent is assigned to your ticket',
          time: '',
        ),
        ChatMessage(
          sender: 'Agent',
          text:
              'Namaste, this is your Support Agent and I will be assisting you to resolve your concern. Let us quickly check this for you. Kindly stay online.',
          time: 'Jul 29, 01:07 AM',
        ),
        ChatMessage(
          sender: 'Agent',
          text:
              'After checking your issue regarding "$_ticketTitle", we have updated the details in your delivery ledger accordingly. Thanks for your understanding!',
          time: 'Jul 29, 01:14 AM',
        ),
        ChatMessage(
          sender: 'Agent',
          text:
              'Thank you for raising your query with Qikzoo Partner Support. If you are satisfied with this resolution, you can close this ticket.',
          time: 'Jul 29, 01:14 AM',
        ),
      ]);
    } else {
      _messages.addAll([
        ChatMessage(
          sender: 'System',
          text: 'Support agent is assigned to your live chat',
          time: '',
        ),
        ChatMessage(
          sender: 'Agent',
          text:
              'Namaste! Welcome to Qikzoo Live Support. How can we assist you with "$_ticketTitle" today?',
          time: 'Just now',
        ),
      ]);
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add(
        ChatMessage(
          sender: 'User',
          text: text,
          time: 'Just now',
        ),
      );
      _textController.clear();
    });

    _scrollToBottom();

    // Mock auto-reply
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          _messages.add(
            ChatMessage(
              sender: 'Agent',
              text:
                  'Thanks for your response. Our team has recorded this update.',
              time: 'Just now',
            ),
          );
        });
        _scrollToBottom();
      }
    });
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
    final isClosed = _ticketStatus == 'Resolved' || _ticketStatus == 'Closed';

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
