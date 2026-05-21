import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Telegram uslubidagi chat ranglari.
class TelegramChatColors {
  TelegramChatColors._(this.isDark);

  factory TelegramChatColors.of(BuildContext context) {
    return TelegramChatColors._(
      Theme.of(context).brightness == Brightness.dark,
    );
  }

  final bool isDark;

  Color get wallpaper => isDark
      ? const Color(0xFF0E1621)
      : const Color(0xFFD6E4EE);

  Color get outgoingBubble => isDark
      ? const Color(0xFF2B5278)
      : const Color(0xFFEFFFDE);

  Color get incomingBubble =>
      isDark ? const Color(0xFF182533) : Colors.white;

  Color get outgoingText =>
      isDark ? const Color(0xFFF5F5F5) : const Color(0xFF000000);

  Color get incomingText =>
      isDark ? const Color(0xFFF5F5F5) : const Color(0xFF000000);

  Color get inputBar => isDark ? const Color(0xFF17212B) : Colors.white;

  Color get inputField =>
      isDark ? const Color(0xFF242F3D) : const Color(0xFFF0F2F5);

  Color get sendButton => isDark ? AppColors.teal : AppColors.primary;

  Color get datePill => isDark
      ? Colors.black.withValues(alpha: 0.35)
      : Colors.black.withValues(alpha: 0.22);

  Color senderColor(String memberId) {
    const palette = [
      Color(0xFFCC5049),
      Color(0xFFD67736),
      Color(0xFF955CDB),
      Color(0xFF40A920),
      Color(0xFF3095C7),
      Color(0xFFC7508E),
      Color(0xFF6C9EEC),
    ];
    return palette[memberId.hashCode.abs() % palette.length];
  }
}
