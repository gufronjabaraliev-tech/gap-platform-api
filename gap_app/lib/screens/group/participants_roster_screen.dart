import 'package:flutter/material.dart';

import 'member_list_screen.dart';

/// Eski yo'nalish — bitta [MemberListScreen] ga birlashtirildi.
@Deprecated('MemberListScreen ishlating')
class ParticipantsRosterScreen extends StatelessWidget {
  const ParticipantsRosterScreen({super.key});

  @override
  Widget build(BuildContext context) => const MemberListScreen();
}
