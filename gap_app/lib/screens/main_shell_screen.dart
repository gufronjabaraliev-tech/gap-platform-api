import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/groups_provider.dart';
import '../utils/route_observer.dart';
import '../widgets/gap_bottom_nav_bar.dart';
import 'groups/my_groups_screen.dart';
import 'home/chat_hub_screen.dart';
import 'profile/profile_screen.dart';
import 'home/dashboard_screen.dart';

/// Asosiy ilova qobig'i — pastki navigatsiya bilan 4 ta bo'lim.
class MainShellScreen extends StatefulWidget {
  const MainShellScreen({super.key, this.initialIndex = 0});

  static final globalKey = GlobalKey<MainShellScreenState>();

  /// 0 — Dashboard, 1 — Jamg'armalar, 2 — Chat, 3 — Profil
  final int initialIndex;

  @override
  State<MainShellScreen> createState() => MainShellScreenState();
}

class MainShellScreenState extends State<MainShellScreen> with RouteAware {
  late int _index;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex.clamp(0, 3);
    WidgetsBinding.instance.addPostFrameCallback((_) => _reloadGroups());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute) {
      gapRouteObserver.subscribe(this, route);
    }
  }

  @override
  void dispose() {
    gapRouteObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPopNext() {
    _reloadGroups();
  }

  Future<void> _reloadGroups() async {
    final auth = context.read<AuthProvider>().user;
    if (auth == null) return;
    await context.read<GroupsProvider>().loadMyGroups(
          auth.id,
          phone: auth.phone,
        );
  }

  void goToTab(int index) {
    if (index < 0 || index > 3 || index == _index) return;
    setState(() => _index = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: const [
          DashboardScreen(),
          MyGroupsScreen(embeddedInShell: true),
          ChatHubScreen(),
          ProfileScreen(embeddedInShell: true),
        ],
      ),
      bottomNavigationBar: GapBottomNavBar(
        selectedIndex: _index,
        onSelected: goToTab,
      ),
    );
  }
}
