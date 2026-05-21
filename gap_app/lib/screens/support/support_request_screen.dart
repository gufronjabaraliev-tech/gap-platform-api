import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../services/platform_api_service.dart';
import '../../theme/gap_theme_extension.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/gap_hero_header.dart';

class SupportRequestScreen extends StatefulWidget {
  const SupportRequestScreen({super.key});

  @override
  State<SupportRequestScreen> createState() => _SupportRequestScreenState();
}

class _SupportRequestScreenState extends State<SupportRequestScreen> {
  final _subjectCtrl = TextEditingController();
  final _messageCtrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _subjectCtrl.dispose();
    _messageCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final subject = _subjectCtrl.text.trim();
    final message = _messageCtrl.text.trim();
    if (subject.isEmpty || message.isEmpty) {
      showGapSnackBar(context, 'Mavzu va xabar to\'ldiring', isError: true);
      return;
    }

    setState(() => _loading = true);
    final user = context.read<AuthProvider>().user;
    final ok = await PlatformApiService.instance.submitSupport(
      subject: subject,
      message: message,
      name: user?.name,
      phone: user?.phone,
      userId: user?.id,
    );
    if (!mounted) return;
    setState(() => _loading = false);

    if (ok) {
      Navigator.pop(context);
    } else {
      showGapSnackBar(
        context,
        'Yuborib bo\'lmadi. Internet va serverni tekshiring.',
        isError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final gap = context.gap;

    return Scaffold(
      body: Column(
        children: [
          GapHeroHeader(
            title: 'Murojaat',
            subtitle: 'Savol yoki taklifingizni yuboring',
            leading: IconButton(
              onPressed: () => Navigator.pop(context),
              style: IconButton.styleFrom(
                backgroundColor: gap.glassOverlay,
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.arrow_back_rounded),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text(
                  'Admin panel orqali javob beriladi.',
                  style: TextStyle(color: gap.mutedText, height: 1.4),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _subjectCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Mavzu',
                  ),
                ),
                TextField(
                  controller: _messageCtrl,
                  minLines: 5,
                  maxLines: 8,
                  decoration: const InputDecoration(
                    labelText: 'Xabar',
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _loading ? null : _submit,
                  child: Text(_loading ? 'Yuborilmoqda...' : 'Yuborish'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
