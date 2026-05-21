import 'package:flutter/material.dart';

import 'telegram_chat_theme.dart';

class TelegramChatInputBar extends StatefulWidget {
  const TelegramChatInputBar({
    super.key,
    required this.controller,
    required this.enabled,
    required this.onSend,
    this.hintText = 'Xabar',
  });

  final TextEditingController controller;
  final bool enabled;
  final VoidCallback onSend;
  final String hintText;

  @override
  State<TelegramChatInputBar> createState() => _TelegramChatInputBarState();
}

class _TelegramChatInputBarState extends State<TelegramChatInputBar> {
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
    _hasText = widget.controller.text.trim().isNotEmpty;
  }

  @override
  void didUpdateWidget(TelegramChatInputBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onTextChanged);
      widget.controller.addListener(_onTextChanged);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() {
    final next = widget.controller.text.trim().isNotEmpty;
    if (next != _hasText) setState(() => _hasText = next);
  }

  @override
  Widget build(BuildContext context) {
    final tg = TelegramChatColors.of(context);

    return Material(
      color: tg.inputBar,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(6, 6, 6, 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              IconButton(
                onPressed: widget.enabled ? () {} : null,
                icon: Icon(
                  Icons.attach_file_rounded,
                  color: tg.sendButton.withValues(alpha: 0.85),
                ),
                tooltip: 'Tez orada',
              ),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: tg.inputField,
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: TextField(
                    controller: widget.controller,
                    enabled: widget.enabled,
                    minLines: 1,
                    maxLines: 6,
                    textCapitalization: TextCapitalization.sentences,
                    style: const TextStyle(fontSize: 16),
                    decoration: InputDecoration(
                      hintText: widget.hintText,
                      hintStyle: TextStyle(
                        color: Colors.grey.withValues(alpha: 0.7),
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                    ),
                    onSubmitted: widget.enabled && _hasText
                        ? (_) => widget.onSend()
                        : null,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Material(
                color: _hasText && widget.enabled
                    ? tg.sendButton
                    : tg.sendButton.withValues(alpha: 0.35),
                shape: const CircleBorder(),
                child: InkWell(
                  onTap: widget.enabled && _hasText ? widget.onSend : null,
                  customBorder: const CircleBorder(),
                  child: SizedBox(
                    width: 46,
                    height: 46,
                    child: Icon(
                      _hasText ? Icons.send_rounded : Icons.mic_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
