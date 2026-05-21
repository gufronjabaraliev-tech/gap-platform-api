import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/groups_provider.dart';
import '../../services/device_contacts_service.dart';
import '../../theme/gap_theme_extension.dart';
import '../../utils/pin_util.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/gap_group_scroll_body.dart';
import '../../widgets/group_header.dart';
import 'pick_contacts_screen.dart';

class AddMemberScreen extends StatefulWidget {
  const AddMemberScreen({super.key});

  @override
  State<AddMemberScreen> createState() => _AddMemberScreenState();
}

class _AddMemberScreenState extends State<AddMemberScreen> {
  final _phoneCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _contactsService = DeviceContactsService();
  bool _loading = false;
  bool _lookupDone = false;
  bool _isRegistered = false;
  String? _lookupName;

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _openContacts() async {
    if (!_contactsService.isSupported) {
      showGapSnackBar(
        context,
        'Kontaktlar faqat telefonda (Android/iOS) ishlaydi',
        isError: true,
      );
      return;
    }
    final added = await Navigator.push<int>(
      context,
      MaterialPageRoute(builder: (_) => const PickContactsScreen()),
    );
    if (added != null && added > 0 && mounted) {
      Navigator.pop(context);
    }
  }

  Future<void> _lookup() async {
    final phone = _phoneCtrl.text.trim();
    if (!isValidPhone(phone)) {
      showGapSnackBar(context, 'Telefon raqamni to\'g\'ri kiriting', isError: true);
      return;
    }

    setState(() => _loading = true);
    try {
      final result = await context.read<GroupsProvider>().lookupPhone(phone);
      if (!mounted) return;
      setState(() {
        _loading = false;
        _lookupDone = true;
        _isRegistered = result.isRegistered;
        _lookupName = result.displayName;
        if (_isRegistered && result.displayName != null) {
          _nameCtrl.text = result.displayName!;
        } else if (!_isRegistered && _nameCtrl.text.trim().isEmpty) {
          _nameCtrl.clear();
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      showGapSnackBar(context, e.toString().replaceFirst('Exception: ', ''),
          isError: true);
    }
  }

  Future<void> _submit() async {
    if (!_lookupDone) {
      await _lookup();
      return;
    }

    setState(() => _loading = true);
    final err = await context.read<GroupsProvider>().addMemberByPhone(
          _phoneCtrl.text.trim(),
          displayName: _isRegistered ? null : _nameCtrl.text.trim(),
        );
    if (!mounted) return;
    setState(() => _loading = false);

    if (err != null) {
      showGapSnackBar(context, err, isError: true);
      return;
    }
    showGapSnackBar(context, 'A\'zo qo\'shildi');
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final gap = context.gap;
    final contactsAvailable = _contactsService.isSupported;

    return Scaffold(
      body: GapGroupScrollBody(
        header: const GroupHeader(),
        padding: const EdgeInsets.all(20),
        children: [
                Text(
                  'Telefon raqamini kiriting yoki kontaktlardan tanlang.',
                  style: TextStyle(color: gap.mutedText, height: 1.4),
                ),
                const SizedBox(height: 16),
                if (contactsAvailable) ...[
                  OutlinedButton.icon(
                    onPressed: _loading ? null : _openContacts,
                    icon: const Icon(Icons.contacts_rounded),
                    label: const Text('Kontaktlardan tanlash'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: Divider(color: gap.mutedText.withValues(alpha: 0.3))),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text('yoki', style: TextStyle(color: gap.mutedText)),
                      ),
                      Expanded(child: Divider(color: gap.mutedText.withValues(alpha: 0.3))),
                    ],
                  ),
                  const SizedBox(height: 16),
                ] else if (!kIsWeb) ...[
                  Text(
                    'Kontaktlar bu qurilmada mavjud emas',
                    style: TextStyle(color: gap.mutedText, fontSize: 12),
                  ),
                  const SizedBox(height: 12),
                ],
                TextField(
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                  enabled: !_lookupDone,
                  decoration: const InputDecoration(
                    labelText: 'Telefon raqam',
                    prefixText: '+998 ',
                    prefixIcon: Icon(Icons.phone_rounded),
                  ),
                  onSubmitted: (_) => _lookup(),
                ),
                if (!_lookupDone) ...[
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: _loading ? null : _lookup,
                    child: _loading
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Tekshirish'),
                  ),
                ],
                if (_lookupDone) ...[
                  const SizedBox(height: 20),
                  if (_isRegistered)
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: gap.success.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: gap.success.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.verified_user_rounded, color: gap.success),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Ro\'yxatdan o\'tgan',
                                    style: TextStyle(fontWeight: FontWeight.w600)),
                                Text(
                                  _lookupName ?? '',
                                  style: const TextStyle(fontSize: 18),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    )
                  else ...[
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: gap.warning.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.person_add_alt_1_rounded, color: gap.warning),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'Hali ro\'yxatdan o\'tmagan. Ism familiyasini kiriting.',
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _nameCtrl,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Ism familiya',
                        prefixIcon: Icon(Icons.person_rounded),
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: _loading ? null : _submit,
                    child: const Text('Qo\'shish'),
                  ),
                  TextButton(
                    onPressed: () => setState(() {
                      _lookupDone = false;
                      _nameCtrl.clear();
                    }),
                    child: const Text('Boshqa raqam'),
                  ),
                ],
        ],
      ),
    );
  }
}
