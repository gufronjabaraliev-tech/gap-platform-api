import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/groups_provider.dart';
import '../../theme/gap_theme_extension.dart';
import '../../utils/invite_link.dart';
import '../../widgets/confirm_dialog.dart';
import '../group/participant_group_screen.dart';
import 'qr_scanner_screen.dart';

class JoinGroupScreen extends StatefulWidget {
  const JoinGroupScreen({super.key});

  @override
  State<JoinGroupScreen> createState() => _JoinGroupScreenState();
}

class _JoinGroupScreenState extends State<JoinGroupScreen> {
  final _codeCtrl = TextEditingController();
  bool _loading = false;
  int _tabIndex = 0;

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _joinWithCode(String code) async {
    final normalized = InviteLink.normalizeCode(code);
    if (normalized.length < 4) {
      showGapSnackBar(context, 'Taklif kodini kiriting', isError: true);
      return;
    }

    final auth = context.read<AuthProvider>().user!;
    setState(() => _loading = true);
    final err = await context.read<GroupsProvider>().joinGroup(
          userId: auth.id,
          userName: auth.name,
          userPhone: auth.phone,
          inviteCode: normalized,
        );
    if (!mounted) return;
    setState(() => _loading = false);

    if (err != null) {
      showGapSnackBar(context, err, isError: true);
      return;
    }

    showGapSnackBar(context, 'Jamg\'armaga qo\'shildingiz');
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const ParticipantGroupScreen()),
    );
  }

  Future<void> _join() => _joinWithCode(_codeCtrl.text);

  Future<void> _scanQr() async {
    final code = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const QrScannerScreen()),
    );
    if (code == null || !mounted) return;
    _codeCtrl.text = code;
    setState(() => _tabIndex = 0);
    await _joinWithCode(code);
  }

  @override
  Widget build(BuildContext context) {
    final gap = context.gap;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Jamg\'armaga qo\'shilish'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          SegmentedButton<int>(
            segments: const [
              ButtonSegment(
                value: 0,
                icon: Icon(Icons.vpn_key_outlined),
                label: Text('Kod'),
              ),
              ButtonSegment(
                value: 1,
                icon: Icon(Icons.qr_code_scanner_rounded),
                label: Text('QR skaner'),
              ),
            ],
            selected: {_tabIndex},
            onSelectionChanged: (s) => setState(() => _tabIndex = s.first),
          ),
          const SizedBox(height: 20),
          if (_tabIndex == 0) ...[
            Text(
              'Masul bergan 6 belgili taklif kodini kiriting.',
              style: TextStyle(color: gap.mutedText, height: 1.4),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _codeCtrl,
              textCapitalization: TextCapitalization.characters,
              autocorrect: false,
              decoration: const InputDecoration(
                labelText: 'Taklif kodi',
                hintText: 'ABC123',
                prefixIcon: Icon(Icons.vpn_key_rounded),
              ),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _loading ? null : _join,
              child: _loading
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Qo\'shilish'),
            ),
          ] else ...[
            Icon(
              Icons.qr_code_scanner_rounded,
              size: 72,
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.7),
            ),
            const SizedBox(height: 16),
            Text(
              kIsWeb
                  ? 'QR skaner mobil ilovada ishlaydi. Kompyuterdan kodni qo\'lda kiriting.'
                  : 'Masul ko\'rsatgan QR kodni skaner qiling — taklif kodi avtomatik olinadi.',
              textAlign: TextAlign.center,
              style: TextStyle(color: gap.mutedText, height: 1.45),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: kIsWeb || _loading ? null : _scanQr,
              icon: const Icon(Icons.qr_code_scanner_rounded),
              label: Text(kIsWeb ? 'Faqat telefonda' : 'Skanerlashni boshlash'),
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 52),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
