import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/group_message.dart';
import '../../providers/auth_provider.dart';
import '../../providers/groups_provider.dart';
import '../../services/group_chat_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/gap_card.dart';
import '../../widgets/gap_hero_header.dart';
import '../../widgets/remote_ad_banner.dart';
import '../../widgets/theme_toggle_button.dart';
import '../group/group_chat_screen.dart';
import '../group/group_home_screen.dart';
import '../group/group_report_screen.dart';
import '../group/participant_group_screen.dart';

enum _ChatHubTab { chatlar, yangiliklar }

/// Umumiy chat va yangiliklar — guruh chatlari ro'yxati.
class ChatHubScreen extends StatefulWidget {
  const ChatHubScreen({super.key});

  @override
  State<ChatHubScreen> createState() => _ChatHubScreenState();
}

class _ChatHubScreenState extends State<ChatHubScreen> {
  _ChatHubTab _tab = _ChatHubTab.chatlar;
  final Map<String, GroupMessage?> _lastMessages = {};
  late final PageController _tabPageController;

  @override
  void initState() {
    super.initState();
    _tabPageController = PageController(initialPage: _tab.index);
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _tabPageController.dispose();
    super.dispose();
  }

  void _selectTab(_ChatHubTab tab) {
    if (_tab == tab) return;
    setState(() => _tab = tab);
    if (!_tabPageController.hasClients) return;
    _tabPageController.animateToPage(
      tab.index,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _load() async {
    final auth = context.read<AuthProvider>().user;
    if (auth == null) return;
    final groups = context.read<GroupsProvider>();
    await groups.loadMyGroups(auth.id, phone: auth.phone);
    if (!mounted) return;
    await _loadLastMessages(groups);
  }

  Future<void> _loadLastMessages(GroupsProvider groups) async {
    final chat = context.read<GroupChatService>();
    final map = <String, GroupMessage?>{};
    for (final item in groups.myGroups) {
      final msgs = await chat.getMessages(item.group.id);
      map[item.group.id] = msgs.isNotEmpty ? msgs.last : null;
    }
    if (mounted) setState(() => _lastMessages.addAll(map));
  }

  Future<void> _openGroupChat(GroupListItem item) async {
    final auth = context.read<AuthProvider>().user!;
    final groups = context.read<GroupsProvider>();
    await groups.selectGroup(item.group.id, auth.id, phone: auth.phone);
    if (!mounted) return;

    if (item.group.isClosed) {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const GroupReportScreen()),
      );
    } else {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => item.isResponsible
              ? const GroupHomeScreen()
              : const ParticipantGroupScreen(),
        ),
      );
    }
    if (!mounted) return;
    await _load();
  }

  Future<void> _openChat(GroupListItem item) async {
    final auth = context.read<AuthProvider>().user!;
    final groups = context.read<GroupsProvider>();
    await groups.selectGroup(item.group.id, auth.id, phone: auth.phone);
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const GroupChatScreen()),
    );
    if (!mounted) return;
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    if (user == null) {
      return const SizedBox.shrink();
    }
    final groups = context.watch<GroupsProvider>();
    final gap = context.gap;
    final cs = Theme.of(context).colorScheme;
    final chatGroups = List<GroupListItem>.from(groups.myGroups)
      ..sort((a, b) => a.group.name.compareTo(b.group.name));

    return Scaffold(
      body: Column(
        children: [
          GapHeroHeader(
            title: 'Chat',
            subtitle: user.name,
            actions: const [
              ThemeToggleButton(iconColor: Colors.white),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: SegmentedButton<_ChatHubTab>(
              segments: const [
                ButtonSegment(
                  value: _ChatHubTab.chatlar,
                  label: Text('Guruh chatlari'),
                  icon: Icon(Icons.forum_rounded, size: 18),
                ),
                ButtonSegment(
                  value: _ChatHubTab.yangiliklar,
                  label: Text('Yangiliklar'),
                  icon: Icon(Icons.newspaper_rounded, size: 18),
                ),
              ],
              selected: {_tab},
              onSelectionChanged: (s) => _selectTab(s.first),
            ),
          ),
          Expanded(
            child: PageView(
              controller: _tabPageController,
              onPageChanged: (i) =>
                  setState(() => _tab = _ChatHubTab.values[i]),
              children: [
                _ChatListTab(
                  groups: groups,
                  chatGroups: chatGroups,
                  lastMessages: _lastMessages,
                  gap: gap,
                  cs: cs,
                  onRefresh: _load,
                  onOpenChat: _openChat,
                  onOpenGroup: _openGroupChat,
                ),
                _NewsTab(gap: gap, cs: cs),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatListTab extends StatelessWidget {
  const _ChatListTab({
    required this.groups,
    required this.chatGroups,
    required this.lastMessages,
    required this.gap,
    required this.cs,
    required this.onRefresh,
    required this.onOpenChat,
    required this.onOpenGroup,
  });

  final GroupsProvider groups;
  final List<GroupListItem> chatGroups;
  final Map<String, GroupMessage?> lastMessages;
  final GapThemeExtension gap;
  final ColorScheme cs;
  final Future<void> Function() onRefresh;
  final Future<void> Function(GroupListItem) onOpenChat;
  final Future<void> Function(GroupListItem) onOpenGroup;

  @override
  Widget build(BuildContext context) {
    if (groups.isLoading && chatGroups.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (chatGroups.isEmpty) {
      return RefreshIndicator(
        onRefresh: onRefresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24),
          children: [
            Icon(Icons.forum_outlined, size: 64, color: gap.mutedText),
            const SizedBox(height: 16),
            Text(
              'Hali guruh chatlari yo\'q',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Jamg\'arma qo\'shganingizdan keyin shu yerda guruh chatlari ko\'rinadi.',
              textAlign: TextAlign.center,
              style: TextStyle(color: gap.mutedText, height: 1.4),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        itemCount: chatGroups.length,
        itemBuilder: (context, i) {
          final item = chatGroups[i];
          final last = lastMessages[item.group.id];
          final closed = item.group.isClosed;

          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: GapCard(
              onTap: () => onOpenChat(item),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 4,
                  vertical: 2,
                ),
                leading: CircleAvatar(
                  backgroundColor: closed
                      ? gap.mutedText.withValues(alpha: 0.2)
                      : cs.primary.withValues(alpha: 0.15),
                  child: Icon(
                    closed ? Icons.archive_rounded : Icons.groups_rounded,
                    color: closed ? gap.mutedText : cs.primary,
                  ),
                ),
                title: Text(
                  item.group.name,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: Text(
                  last?.text ??
                      (closed
                          ? 'GAP yakunlangan'
                          : 'Xabarlar — chatni oching'),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: gap.mutedText, fontSize: 13),
                ),
                trailing: PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert_rounded),
                  onSelected: (v) {
                    if (v == 'chat') {
                      onOpenChat(item);
                    } else if (v == 'gap') {
                      onOpenGroup(item);
                    }
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                      value: 'chat',
                      child: ListTile(
                        leading: Icon(Icons.chat_rounded),
                        title: Text('Chat'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'gap',
                      child: ListTile(
                        leading: Icon(Icons.groups_rounded),
                        title: Text('GAP sahifasi'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _NewsTab extends StatelessWidget {
  const _NewsTab({required this.gap, required this.cs});

  final GapThemeExtension gap;
  final ColorScheme cs;

  static const _items = [
    _NewsItem(
      title: 'GAP ilovasiga xush kelibsiz',
      summary:
          'Navbatli jamg\'armalarni boshqaring, to\'lovlarni kuzating va guruh chatida muloqot qiling.',
      dateLabel: 'Platforma',
      icon: Icons.rocket_launch_rounded,
    ),
    _NewsItem(
      title: 'Guruh chatlari',
      summary:
          'Har bir jamg\'arma uchun alohida chat. Chat bo\'limida barcha guruhlaringiz bir joyda.',
      dateLabel: 'Yangilik',
      icon: Icons.forum_rounded,
    ),
    _NewsItem(
      title: 'Dashboard statistikasi',
      summary:
          'To\'lovlar, qarzlar va kutilayotgan jamg\'armalarni Dashboard bo\'limida ko\'ring.',
      dateLabel: 'Yangilik',
      icon: Icons.dashboard_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        const RemoteAdBanner(),
        ..._items.map(
          (n) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: GapCard(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: cs.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(n.icon, color: cs.primary),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            n.dateLabel,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: cs.primary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            n.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            n.summary,
                            style: TextStyle(
                              color: gap.mutedText,
                              height: 1.45,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _NewsItem {
  const _NewsItem({
    required this.title,
    required this.summary,
    required this.dateLabel,
    required this.icon,
  });

  final String title;
  final String summary;
  final String dateLabel;
  final IconData icon;
}
