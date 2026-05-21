import 'package:flutter/material.dart';

import '../screens/group/group_home_screen.dart';
import '../screens/main_shell_screen.dart';

/// Qayta yoqishdan keyin a'zolar/to'lovlar sahifalarini yopib boshqaruv paneliga qaytish.
void navigateToGroupHomeCleared(BuildContext context) {
  Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute(builder: (_) => const GroupHomeScreen()),
    (route) => route.isFirst,
  );
}

/// GAP yopilgach jamg'armalar ro'yxatiga qaytish.
void navigateToMyGroupsCleared(BuildContext context) {
  Navigator.of(context).popUntil((route) => route.isFirst);
  MainShellScreen.globalKey.currentState?.goToTab(1);
}
