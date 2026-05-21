import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../providers/groups_provider.dart';
import '../../services/group_report_export.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/gap_group_scroll_body.dart';
import '../../widgets/group_header.dart';
import '../../widgets/invite_share_sheet.dart';
import '../../providers/theme_provider.dart';
import 'group_report_screen.dart';
import '../../widgets/schedule_mode_settings_sheet.dart';
import '../../widgets/transfer_responsibility_sheet.dart';
import 'schedule_screen.dart';

class GroupSettingsScreen extends StatefulWidget {
  const GroupSettingsScreen({super.key});

  @override
  State<GroupSettingsScreen> createState() => _GroupSettingsScreenState();
}

class _GroupSettingsScreenState extends State<GroupSettingsScreen> {
  bool _exportingPdf = false;
  bool _exportingImage = false;

  Future<void> _exportPdf() async {
    final g = context.read<GroupsProvider>().activeGroup!;
    setState(() => _exportingPdf = true);
    try {
      await GroupReportExportService.sharePdf(g);
      if (mounted) {
        showGapSnackBar(context, 'PDF tayyor — saqlash yoki ulashing');
      }
    } catch (e) {
      if (mounted) {
        showGapSnackBar(
          context,
          'PDF yuklab bo\'lmadi. Qayta urinib ko\'ring.',
          isError: true,
        );
      }
    } finally {
      if (mounted) setState(() => _exportingPdf = false);
    }
  }

  Future<void> _exportImage() async {
    final g = context.read<GroupsProvider>().activeGroup!;
    setState(() => _exportingImage = true);
    try {
      await GroupReportExportService.shareImage(g);
      if (mounted) {
        showGapSnackBar(
          context,
          'Rasm tayyor — saqlash yoki ulashishni tanlang',
        );
      }
    } catch (e) {
      if (mounted) {
        showGapSnackBar(
          context,
          'Rasm yuklab bo\'lmadi. Qayta urinib ko\'ring.',
          isError: true,
        );
      }
    } finally {
      if (mounted) setState(() => _exportingImage = false);
    }
  }

  void _openReport() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const GroupReportScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final groups = context.watch<GroupsProvider>();
    final g = groups.activeGroup!;
    final busy = _exportingPdf || _exportingImage;

    return Scaffold(
      body: GapGroupScrollBody(
        header: const GroupHeader(),
        padding: const EdgeInsets.all(20),
        children: [
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.vpn_key),
                    title: const Text('Taklif kodi'),
                    subtitle: Text(
                      g.inviteCode,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.copy),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: g.inviteCode));
                        showGapSnackBar(context, 'Kod nusxalandi');
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => InviteShareSheet.show(
                          context,
                          groupName: g.name,
                          inviteCode: g.inviteCode,
                        ),
                        icon: const Icon(Icons.qr_code_2_rounded),
                        label: const Text('QR ko\'rsatish'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () => InviteShareSheet.show(
                          context,
                          groupName: g.name,
                          inviteCode: g.inviteCode,
                        ),
                        icon: const Icon(Icons.share_rounded),
                        label: const Text('Yuborish'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'A\'zolar kod yoki QR orqali qo\'shiladi (kuzatuvchi).',
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 20),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(Icons.summarize_rounded),
                          title: Text('Hisobot'),
                          subtitle: Text(
                            'To\'lovlar, davrlar va a\'zolar bo\'yicha joriy holat',
                          ),
                        ),
                        FilledButton.icon(
                          onPressed: busy ? null : _openReport,
                          icon: const Icon(Icons.visibility_rounded),
                          label: const Text('Hisobotni ko\'rish'),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: busy || _exportingPdf
                                    ? null
                                    : _exportPdf,
                                icon: _exportingPdf
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Icon(
                                        Icons.picture_as_pdf_outlined,
                                      ),
                                label: Text(
                                  _exportingPdf ? 'PDF...' : 'PDF',
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: busy || _exportingImage
                                    ? null
                                    : _exportImage,
                                icon: _exportingImage
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Icon(Icons.image_outlined),
                                label: Text(
                                  _exportingImage ? 'Rasm...' : 'Rasm',
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'PDF yoki rasmni telefonga saqlash yoki Telegram, WhatsApp orqali yuborish mumkin.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                if (groups.isResponsibleActive)
                  Card(
                    child: Column(
                      children: [
                        ListTile(
                          leading: Icon(Icons.swap_horiz_rounded,
                              color: Theme.of(context).colorScheme.primary),
                          title: const Text('Masullikni topshirish'),
                          subtitle: const Text(
                            'Boshqaruvni boshqa ishtirokchiga berish',
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () async {
                            final ok =
                                await showTransferResponsibilitySheet(context);
                            if (!context.mounted) return;
                            if (ok && !context.read<GroupsProvider>().isResponsibleActive) {
                              Navigator.pop(context);
                            }
                          },
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: Icon(g.scheduleMode.icon),
                          title: const Text('Navbat turi (GAP uslubi)'),
                          subtitle: Text(
                            '${g.scheduleMode.label}\n'
                            'Yaratilganda tanlangan. Bu yerdan o\'zgartirish mumkin.',
                          ),
                          isThreeLine: true,
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () =>
                              ScheduleModeSettingsSheet.show(context),
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(Icons.format_list_numbered_rounded),
                          title: const Text('Navbat boshqaruvi'),
                          subtitle: const Text(
                            'Joriy navbat, pul oluvchi va davrlar',
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ScheduleScreen(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (groups.isResponsibleActive) const SizedBox(height: 12),
                Builder(
                  builder: (context) {
                    final theme = context.watch<ThemeProvider>();
                    return SwitchListTile(
                      secondary: Icon(
                        theme.isDark
                            ? Icons.dark_mode_rounded
                            : Icons.light_mode_rounded,
                      ),
                      title: const Text('Tungi rejim'),
                      subtitle: Text(
                        theme.isDark ? 'Yoqilgan' : 'Kunduzgi rejim',
                      ),
                      value: theme.isDark,
                      onChanged: (_) => theme.toggleDayNight(),
                    );
                  },
                ),
                const SizedBox(height: 24),
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Murojaat uchun tel: 998937300206',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
        ],
      ),
    );
  }
}
