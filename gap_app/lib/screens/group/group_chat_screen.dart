import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/group_message.dart';
import '../../providers/auth_provider.dart';
import '../../providers/group_chat_provider.dart';
import '../../providers/groups_provider.dart';
import '../../theme/gap_theme_extension.dart';
import '../../utils/gap_date_format.dart';
import '../../widgets/chat_message_bubble.dart';
import '../../widgets/gap_sliding_text.dart';
import '../../widgets/telegram_chat_input_bar.dart';
import '../../widgets/telegram_chat_theme.dart';

class GroupChatScreen extends StatefulWidget {
  const GroupChatScreen({super.key});

  @override
  State<GroupChatScreen> createState() => _GroupChatScreenState();
}

class _GroupChatScreenState extends State<GroupChatScreen> {
  final _inputCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  String? _sendError;

  static const _clusterGap = Duration(minutes: 5);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadChat());
  }

  Future<void> _loadChat() async {
    final g = context.read<GroupsProvider>().activeGroup;
    if (g == null) return;
    await context.read<GroupChatProvider>().load(g.id);
    _scrollToBottom(animated: false);
  }

  @override
  void dispose() {
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _scrollToBottom({bool animated = true}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollCtrl.hasClients) return;
      final target = _scrollCtrl.position.maxScrollExtent;
      if (animated) {
        _scrollCtrl.animateTo(
          target,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
        );
      } else {
        _scrollCtrl.jumpTo(target);
      }
    });
  }

  Future<void> _send() async {
    final text = _inputCtrl.text.trim();
    if (text.isEmpty) return;

    final groups = context.read<GroupsProvider>();
    final auth = context.read<AuthProvider>();
    final chat = context.read<GroupChatProvider>();
    final g = groups.activeGroup;
    final memberId = groups.activeMemberId;
    final user = auth.user;

    if (g == null || memberId == null || user == null) return;

    final err = await chat.send(
      group: g,
      senderMemberId: memberId,
      senderUserId: user.id,
      text: text,
    );
    if (!mounted) return;
    if (err != null) {
      setState(() => _sendError = err);
      return;
    }
    _inputCtrl.clear();
    setState(() => _sendError = null);
    _scrollToBottom();
  }

  bool _sameCluster(GroupMessage a, GroupMessage b) {
    if (a.senderMemberId != b.senderMemberId) return false;
    return b.createdAt.difference(a.createdAt).abs() < _clusterGap;
  }

  bool _showDateHeader(int index, List<GroupMessage> messages) {
    if (index == 0) return true;
    return !gapSameDay(messages[index - 1].createdAt, messages[index].createdAt);
  }

  bool _isClusterTop(int index, List<GroupMessage> messages) {
    if (index == 0) return true;
    return !_sameCluster(messages[index - 1], messages[index]);
  }

  bool _isClusterBottom(int index, List<GroupMessage> messages) {
    if (index == messages.length - 1) return true;
    return !_sameCluster(messages[index], messages[index + 1]);
  }

  bool _showSenderName(int index, List<GroupMessage> messages, bool isMine) {
    if (isMine) return false;
    return _isClusterTop(index, messages);
  }

  bool _showAvatar(int index, List<GroupMessage> messages, bool isMine) {
    if (isMine) return false;
    return _isClusterBottom(index, messages);
  }

  bool _showTail(int index, List<GroupMessage> messages, bool isMine) {
    return _isClusterBottom(index, messages);
  }

  @override
  Widget build(BuildContext context) {
    final groups = context.watch<GroupsProvider>();
    final chat = context.watch<GroupChatProvider>();
    final g = groups.activeGroup!;
    final memberId = groups.activeMemberId;
    final gap = context.gap;
    final tg = TelegramChatColors.of(context);
    final messages = chat.messages;

    return Scaffold(
      backgroundColor: tg.wallpaper,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: tg.inputBar,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: gap.primaryGradient.colors.first,
              child: Text(
                g.name.isNotEmpty ? g.name[0].toUpperCase() : 'G',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GapSlidingText(
                    text: g.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '${g.memberCount} a\'zo',
                    style: TextStyle(
                      fontSize: 13,
                      color: gap.mutedText,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () async {
              await chat.refresh();
              _scrollToBottom();
            },
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Yangilash',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: chat.isLoading
                ? const Center(child: CircularProgressIndicator())
                : messages.isEmpty
                    ? _EmptyChat(colors: tg)
                    : ListView.builder(
                        controller: _scrollCtrl,
                        padding: const EdgeInsets.only(top: 8, bottom: 8),
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final msg = messages[index];
                          final isMine = msg.senderMemberId == memberId;
                          return Column(
                            children: [
                              if (_showDateHeader(index, messages))
                                TelegramDateSeparator(date: msg.createdAt),
                              TelegramChatMessageRow(
                                message: msg,
                                group: g,
                                isMine: isMine,
                                showAvatar: _showAvatar(
                                  index,
                                  messages,
                                  isMine,
                                ),
                                showSenderName: _showSenderName(
                                  index,
                                  messages,
                                  isMine,
                                ),
                                showTail: _showTail(index, messages, isMine),
                                isClusterTop: _isClusterTop(index, messages),
                                isClusterBottom:
                                    _isClusterBottom(index, messages),
                              ),
                            ],
                          );
                        },
                      ),
          ),
          if (_sendError != null)
            Material(
              color: tg.inputBar,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: Text(
                  _sendError!,
                  style: TextStyle(color: gap.danger, fontSize: 13),
                ),
              ),
            ),
          TelegramChatInputBar(
            controller: _inputCtrl,
            enabled: memberId != null,
            onSend: _send,
            hintText: memberId != null ? 'Xabar' : 'Chat uchun a\'zo bo\'ling',
          ),
        ],
      ),
    );
  }
}

class _EmptyChat extends StatelessWidget {
  const _EmptyChat({required this.colors});

  final TelegramChatColors colors;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.chat_bubble_outline_rounded,
              size: 64,
              color: Colors.black.withValues(alpha: 0.2),
            ),
            const SizedBox(height: 16),
            Text(
              'Xabarlar yo\'q',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black.withValues(alpha: 0.45),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Birinchi xabarni yozing',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.black.withValues(alpha: 0.35),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
