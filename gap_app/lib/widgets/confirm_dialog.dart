import 'package:flutter/material.dart';

import '../theme/gap_theme_extension.dart';

Future<bool?> showGapConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Tasdiqlash',
  bool isDanger = true,
}) {
  final gap = context.gap;
  return showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      icon: Icon(
        isDanger ? Icons.warning_amber_rounded : Icons.help_outline_rounded,
        color: isDanger ? gap.danger : Theme.of(ctx).colorScheme.primary,
        size: 32,
      ),
      title: Text(title),
      content: Text(message, style: const TextStyle(height: 1.45)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Bekor qilish'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: FilledButton.styleFrom(
            backgroundColor: isDanger ? gap.danger : null,
          ),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
}

/// Tasodifiy bosishdan himoya: matnni aniq yozish kerak.
Future<bool> showGapTypedConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  required String typeLabel,
  required String expectedText,
}) async {
  final gap = context.gap;
  final ctrl = TextEditingController();
  var matches = false;

  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setLocal) => AlertDialog(
        icon: Icon(Icons.warning_amber_rounded, color: gap.danger, size: 32),
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(message, style: const TextStyle(height: 1.45)),
            const SizedBox(height: 16),
            Text(
              'Davom etish uchun «$expectedText» deb yozing:',
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(ctx).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: ctrl,
              decoration: InputDecoration(labelText: typeLabel),
              onChanged: (v) => setLocal(
                () => matches = v.trim() == expectedText,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Bekor qilish'),
          ),
          FilledButton(
            onPressed: matches ? () => Navigator.pop(ctx, true) : null,
            style: FilledButton.styleFrom(backgroundColor: gap.danger),
            child: const Text('O\'chirish'),
          ),
        ],
      ),
    ),
  );
  ctrl.dispose();
  return result == true;
}

void showGapSnackBar(
  BuildContext context,
  String message, {
  bool isError = false,
}) {
  if (!isError) return;
  if (!context.mounted) return;
  final gap = context.gap;
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null) return;
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: gap.danger,
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 4),
    ),
  );
}
