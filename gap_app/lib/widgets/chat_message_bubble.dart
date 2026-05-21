import 'package:flutter/material.dart';

import '../models/group_message.dart';
import '../models/savings_group.dart';
import '../utils/gap_date_format.dart';
import 'member_avatar.dart';
import 'telegram_chat_theme.dart';

/// Telegram uslubidagi xabar qatori.
class TelegramChatMessageRow extends StatelessWidget {
  const TelegramChatMessageRow({
    super.key,
    required this.message,
    required this.group,
    required this.isMine,
    required this.showAvatar,
    required this.showSenderName,
    required this.showTail,
    required this.isClusterTop,
    required this.isClusterBottom,
  });

  final GroupMessage message;
  final SavingsGroup group;
  final bool isMine;
  final bool showAvatar;
  final bool showSenderName;
  final bool showTail;
  final bool isClusterTop;
  final bool isClusterBottom;

  @override
  Widget build(BuildContext context) {
    final tg = TelegramChatColors.of(context);
    final senderName = group.displayNameFor(message.senderMemberId);
    final member = group.members[message.senderMemberId];

    final topPad = isClusterTop ? 6.0 : 1.0;
    final bottomPad = isClusterBottom ? 6.0 : 1.0;

    if (isMine) {
      return Padding(
        padding: EdgeInsets.only(top: topPad, bottom: bottomPad),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const SizedBox(width: 56),
            Flexible(
              child: _Bubble(
                message: message,
                isMine: true,
                showTail: showTail,
                isClusterTop: isClusterTop,
                isClusterBottom: isClusterBottom,
                colors: tg,
              ),
            ),
            const SizedBox(width: 8),
          ],
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.only(top: topPad, bottom: bottomPad),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          SizedBox(
            width: 40,
            child: showAvatar
                ? Padding(
                    padding: const EdgeInsets.only(left: 6, bottom: 2),
                    child: MemberAvatar(
                      displayName: senderName,
                      member: member,
                      phone: member?.phone,
                      linkedUserId: member?.linkedUserId,
                      radius: 18,
                    ),
                  )
                : const SizedBox(width: 36),
          ),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (showSenderName)
                  Padding(
                    padding: const EdgeInsets.only(left: 6, bottom: 2),
                    child: Text(
                      senderName,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: tg.senderColor(message.senderMemberId),
                      ),
                    ),
                  ),
                _Bubble(
                  message: message,
                  isMine: false,
                  showTail: showTail,
                  isClusterTop: isClusterTop,
                  isClusterBottom: isClusterBottom,
                  colors: tg,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({
    required this.message,
    required this.isMine,
    required this.showTail,
    required this.isClusterTop,
    required this.isClusterBottom,
    required this.colors,
  });

  final GroupMessage message;
  final bool isMine;
  final bool showTail;
  final bool isClusterTop;
  final bool isClusterBottom;
  final TelegramChatColors colors;

  @override
  Widget build(BuildContext context) {
    final bg = isMine ? colors.outgoingBubble : colors.incomingBubble;
    final fg = isMine ? colors.outgoingText : colors.incomingText;

    const r = 18.0;
    const small = 4.0;

    BorderRadius radius;
    if (isMine) {
      radius = BorderRadius.only(
        topLeft: const Radius.circular(r),
        topRight: Radius.circular(isClusterTop ? r : small),
        bottomLeft: const Radius.circular(r),
        bottomRight: Radius.circular(
          showTail && isClusterBottom ? small : (isClusterBottom ? r : small),
        ),
      );
    } else {
      radius = BorderRadius.only(
        topLeft: Radius.circular(isClusterTop ? r : small),
        topRight: const Radius.circular(r),
        bottomLeft: Radius.circular(
          showTail && isClusterBottom ? small : (isClusterBottom ? r : small),
        ),
        bottomRight: const Radius.circular(r),
      );
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(10, 6, 8, 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: radius,
        boxShadow: [
          if (!isMine)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 1,
              offset: const Offset(0, 1),
            ),
        ],
      ),
      child: _MessageBody(
        text: message.text,
        time: formatChatTime(message.createdAt),
        isMine: isMine,
        textColor: fg,
        timeColor: fg.withValues(alpha: 0.55),
      ),
    );
  }
}

/// Matn va vaqt pastki o'ngda (Telegram uslubi).
class _MessageBody extends StatelessWidget {
  const _MessageBody({
    required this.text,
    required this.time,
    required this.isMine,
    required this.textColor,
    required this.timeColor,
  });

  final String text;
  final String time;
  final bool isMine;
  final Color textColor;
  final Color timeColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          text,
          style: TextStyle(
            color: textColor,
            fontSize: 16,
            height: 1.28,
          ),
        ),
        const SizedBox(height: 2),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              time,
              style: TextStyle(
                color: timeColor,
                fontSize: 11,
              ),
            ),
            if (isMine) ...[
              const SizedBox(width: 4),
              Icon(
                Icons.done_all_rounded,
                size: 14,
                color: timeColor,
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class TelegramDateSeparator extends StatelessWidget {
  const TelegramDateSeparator({super.key, required this.date});

  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final tg = TelegramChatColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: tg.datePill,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(
            formatChatDateHeader(date),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
