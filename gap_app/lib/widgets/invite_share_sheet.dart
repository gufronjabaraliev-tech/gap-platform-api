import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../theme/gap_theme_extension.dart';
import '../utils/invite_link.dart';
import 'confirm_dialog.dart';

/// Masul taklif kodini ulashish va QR ko'rsatish.
class InviteShareSheet extends StatelessWidget {
  const InviteShareSheet({
    super.key,
    required this.groupName,
    required this.inviteCode,
  });

  final String groupName;
  final String inviteCode;

  static Future<void> show(
    BuildContext context, {
    required String groupName,
    required String inviteCode,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => InviteShareSheet(
        groupName: groupName,
        inviteCode: inviteCode,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final gap = context.gap;
    final cs = Theme.of(context).colorScheme;
    final code = InviteLink.normalizeCode(inviteCode);
    final qrData = InviteLink.payload(code);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        8,
        24,
        24 + MediaQuery.paddingOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'A\'zolarni taklif qiling',
            style: Theme.of(context).textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            groupName,
            textAlign: TextAlign.center,
            style: TextStyle(color: gap.mutedText, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: cs.outlineVariant),
            ),
            child: QrImageView(
              data: qrData,
              version: QrVersions.auto,
              size: 200,
              backgroundColor: Colors.white,
              eyeStyle: QrEyeStyle(
                eyeShape: QrEyeShape.square,
                color: cs.primary,
              ),
              dataModuleStyle: QrDataModuleStyle(
                dataModuleShape: QrDataModuleShape.square,
                color: cs.primary,
              ),
            ),
          ),
          const SizedBox(height: 16),
          SelectableText(
            code,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              letterSpacing: 6,
              color: cs.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Kodni kiriting yoki QR skaner qiling',
            style: TextStyle(fontSize: 13, color: gap.mutedText),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: code));
                    showGapSnackBar(context, 'Kod nusxalandi');
                  },
                  icon: const Icon(Icons.copy_rounded),
                  label: const Text('Nusxalash'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () {
                    Share.share(
                      InviteLink.shareText(
                        groupName: groupName,
                        inviteCode: code,
                      ),
                      subject: 'GAP taklif: $groupName',
                    );
                  },
                  icon: const Icon(Icons.share_rounded),
                  label: const Text('Yuborish'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Tayyor'),
            ),
          ),
        ],
      ),
    );
  }
}
