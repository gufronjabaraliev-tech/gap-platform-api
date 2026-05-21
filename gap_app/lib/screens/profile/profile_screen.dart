import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../models/app_user.dart';
import '../../providers/auth_provider.dart';
import '../../providers/groups_provider.dart';
import '../../providers/theme_provider.dart';
import '../auth/login_screen.dart';
import '../../services/local_avatar_storage.dart';
import '../../utils/pin_util.dart';
import '../../widgets/confirm_dialog.dart';
import '../../theme/gap_theme_extension.dart';
import '../../widgets/gap_hero_header.dart';
import '../../widgets/member_avatar.dart';
import '../../widgets/theme_toggle_button.dart';
import 'participant_statistics_screen.dart';
import '../support/support_request_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, this.embeddedInShell = false});

  /// Asosiy qobiqdagi Profil bo'limi.
  final bool embeddedInShell;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final TextEditingController _nameCtrl;
  final _extraPhoneCtrl = TextEditingController();
  final _picker = ImagePicker();
  bool _loading = false;
  File? _avatarFile;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user!;
    _nameCtrl = TextEditingController(text: user.name);
    _loadAvatar();
  }

  Future<void> _loadAvatar() async {
    final user = context.read<AuthProvider>().user;
    if (user == null) return;
    final file = await LocalAvatarStorage.instance.fileForUser(
      user.id,
      user.localAvatarFileName,
    );
    if (mounted) setState(() => _avatarFile = file);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _extraPhoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    if (kIsWeb) {
      showGapSnackBar(
        context,
        'Rasm tanlash mobil ilovada to\'liq ishlaydi',
        isError: true,
      );
      return;
    }
    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      if (picked == null || !mounted) return;

      setState(() => _loading = true);
      final err = await context.read<AuthProvider>().setAvatarFromFile(
            File(picked.path),
          );
      if (!mounted) return;
      setState(() => _loading = false);

      if (err != null) {
        showGapSnackBar(context, err, isError: true);
      } else {
        await _loadAvatar();
        showGapSnackBar(context, 'Rasm saqlandi (faqat shu qurilmada)');
      }
    } catch (e) {
      if (mounted) {
        showGapSnackBar(context, 'Rasm tanlanmadi: $e', isError: true);
      }
    }
  }

  Future<void> _removeAvatar() async {
    setState(() => _loading = true);
    final err = await context.read<AuthProvider>().removeAvatar();
    if (!mounted) return;
    setState(() {
      _loading = false;
      _avatarFile = null;
    });
    if (err != null) {
      showGapSnackBar(context, err, isError: true);
    } else {
      showGapSnackBar(context, 'Rasm o\'chirildi');
    }
  }

  Future<void> _save() async {
    setState(() => _loading = true);
    final err = await context.read<AuthProvider>().updateName(_nameCtrl.text);
    if (!mounted) return;
    setState(() => _loading = false);
    if (err != null) {
      showGapSnackBar(context, err, isError: true);
    } else {
      showGapSnackBar(context, 'Profil yangilandi');
    }
  }

  void _showChangePinSheet() {
    final user = context.read<AuthProvider>().user!;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetCtx) => _ChangePinSheet(
        user: user,
        onSuccess: () {
          if (mounted) {
            showGapSnackBar(context, 'Kirish paroli yangilandi');
          }
        },
      ),
    );
  }

  Future<void> _logout() async {
    final ok = await showGapConfirmDialog(
      context,
      title: 'Chiqish',
      message: 'Hisobdan chiqasizmi?',
      isDanger: false,
      confirmLabel: 'Chiqish',
    );
    if (ok != true || !mounted) return;

    final navigator = Navigator.of(context);
    final groups = context.read<GroupsProvider>();
    final auth = context.read<AuthProvider>();
    groups.clearActive();

    // Avval navigatsiya — IndexedStack dagi tablar user=null bilan qayta chizilmasin.
    navigator.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
    await auth.logout();
  }

  Future<void> _addPhone() async {
    final err = await context.read<AuthProvider>().addExtraPhone(
          _extraPhoneCtrl.text,
        );
    if (!mounted) return;
    if (err != null) {
      showGapSnackBar(context, err, isError: true);
    } else {
      _extraPhoneCtrl.clear();
      showGapSnackBar(
        context,
        'Raqam biriktirildi — shu raqam bilan ham kirishingiz mumkin',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    if (user == null) {
      return const SizedBox.shrink();
    }
    context.watch<ThemeProvider>();
    final gap = context.gap;
    final hasUnsavedNameChanges =
        _nameCtrl.text.trim() != user.name.trim();

    return Scaffold(
      body: Column(
        children: [
          GapHeroHeader(
            title: 'Profil',
            subtitle: formatPhoneDisplay(user.phone),
            leading: widget.embeddedInShell
                ? null
                : IconButton(
                    onPressed: () => Navigator.pop(context),
                    style: IconButton.styleFrom(
                      backgroundColor: gap.glassOverlay,
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
            actions: const [
              ThemeToggleButton(iconColor: Colors.white),
            ],
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Center(
                  child: ProfileAvatarPicker(
                    name: user.name,
                    photoFile: _avatarFile,
                    onPickCamera: () => _pickImage(ImageSource.camera),
                    onPickGallery: () => _pickImage(ImageSource.gallery),
                    onRemove: _removeAvatar,
                  ),
                ),
                const SizedBox(height: 20),
                Card(
                  clipBehavior: Clip.antiAlias,
                  child: ListTile(
                    leading: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: gap.primaryGradient,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.analytics_rounded,
                        color: Colors.white,
                      ),
                    ),
                    title: const Text(
                      'Statistika',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text(
                      'GAPlar va balans',
                      style: TextStyle(
                        fontSize: 12,
                        color: gap.mutedText,
                      ),
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: _loading
                        ? null
                        : () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    const ParticipantStatisticsScreen(),
                              ),
                            ),
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _nameCtrl,
                  textCapitalization: TextCapitalization.words,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    labelText: 'Ism familiya',
                    prefixIcon: Icon(Icons.person_rounded),
                  ),
                ),
                const SizedBox(height: 24),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.lock_rounded),
                    title: const Text('Kirish paroli'),
                    subtitle: Text('${user.pinLength} raqamli parol'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: _loading ? null : _showChangePinSheet,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Telefon raqamlar',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.phone_android_rounded),
                    title: Text(formatPhoneDisplay(user.phone)),
                    subtitle: const Text('Asosiy (kirish)'),
                    trailing: Chip(
                      label: const Text('Asosiy'),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ),
                ...user.extraPhones.map(
                  (p) => Card(
                    margin: const EdgeInsets.only(top: 8),
                    child: ListTile(
                      leading: const Icon(Icons.add_ic_call_rounded),
                      title: Text(formatPhoneDisplay(p)),
                      trailing: IconButton(
                        icon: Icon(Icons.close_rounded, color: gap.danger),
                        onPressed: () async {
                          final ok = await showGapConfirmDialog(
                            context,
                            title: 'Raqamni olib tashlash',
                            message: formatPhoneDisplay(p),
                          );
                          if (ok == true && mounted) {
                            final err = await context
                                .read<AuthProvider>()
                                .removeExtraPhone(p);
                            if (mounted && err != null) {
                              showGapSnackBar(context, err, isError: true);
                            }
                          }
                        },
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    'Qo\'shimcha raqam ham asosiy parol bilan ilovaga kirish uchun ishlatiladi.',
                    style: TextStyle(fontSize: 12, color: gap.mutedText, height: 1.35),
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _extraPhoneCtrl,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'Qo\'shimcha raqam',
                          hintText: '+998 90 123 45 67',
                          prefixIcon: Icon(Icons.add_rounded),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton.tonal(
                      onPressed: _loading ? null : _addPhone,
                      child: const Text('Qo\'shish'),
                    ),
                  ],
                ),
                if (hasUnsavedNameChanges) ...[
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _loading ? null : _save,
                    child: _loading
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Saqlash'),
                  ),
                ],
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.support_agent_rounded),
                  title: const Text('Murojaat yuborish'),
                  subtitle: const Text('Savol va takliflar'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const SupportRequestScreen(),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: _loading ? null : _logout,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: gap.danger,
                    side: BorderSide(color: gap.danger.withValues(alpha: 0.5)),
                    minimumSize: const Size(double.infinity, 48),
                  ),
                  icon: const Icon(Icons.logout_rounded),
                  label: const Text('Hisobdan chiqish'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Parol o'zgartirish — controllerlar faqat shu widget [dispose] da yopiladi.
class _ChangePinSheet extends StatefulWidget {
  const _ChangePinSheet({
    required this.user,
    required this.onSuccess,
  });

  final AppUser user;
  final VoidCallback onSuccess;

  @override
  State<_ChangePinSheet> createState() => _ChangePinSheetState();
}

class _ChangePinSheetState extends State<_ChangePinSheet> {
  late final TextEditingController _currentCtrl;
  late final TextEditingController _newCtrl;
  late final TextEditingController _confirmCtrl;
  late int _pinLength;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _pinLength = widget.user.pinLength;
    _currentCtrl = TextEditingController();
    _newCtrl = TextEditingController();
    _confirmCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _currentCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final user = widget.user;
    if (_currentCtrl.text.length != user.pinLength) {
      showGapSnackBar(
        context,
        'Joriy parolni ${user.pinLength} raqam bilan kiriting',
        isError: true,
      );
      return;
    }
    if (!isValidPin(_newCtrl.text, _pinLength)) {
      showGapSnackBar(
        context,
        'Yangi parol $_pinLength raqamdan iborat bo\'lishi kerak',
        isError: true,
      );
      return;
    }
    if (_newCtrl.text != _confirmCtrl.text) {
      showGapSnackBar(
        context,
        'Yangi parollar mos kelmaydi',
        isError: true,
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final err = await context.read<AuthProvider>().changePin(
            currentPin: _currentCtrl.text,
            newPin: _newCtrl.text,
            newPinLength: _pinLength,
          );
      if (!mounted) return;
      setState(() => _saving = false);
      if (err != null) {
        showGapSnackBar(context, err, isError: true);
        return;
      }
      Navigator.pop(context);
      widget.onSuccess();
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      showGapSnackBar(
        context,
        'Parol saqlanmadi. Qayta urinib ko\'ring.',
        isError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.user;
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 8,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Kirish parolini o\'zgartirish',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 4),
            Text(
              'Hozirgi parolni kiriting, keyin yangisini belgilang.',
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _currentCtrl,
              obscureText: true,
              keyboardType: TextInputType.number,
              maxLength: user.pinLength,
              enabled: !_saving,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                labelText: 'Joriy parol (${user.pinLength} raqam)',
                prefixIcon: const Icon(Icons.lock_outline_rounded),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Yangi parol uzunligi',
              style: Theme.of(context).textTheme.labelMedium,
            ),
            const SizedBox(height: 8),
            SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 4, label: Text('4 raqam')),
                ButtonSegment(value: 6, label: Text('6 raqam')),
              ],
              selected: {_pinLength},
              onSelectionChanged: _saving
                  ? null
                  : (s) => setState(() => _pinLength = s.first),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _newCtrl,
              obscureText: true,
              keyboardType: TextInputType.number,
              maxLength: _pinLength,
              enabled: !_saving,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                labelText: 'Yangi parol ($_pinLength raqam)',
                prefixIcon: const Icon(Icons.lock_rounded),
              ),
            ),
            TextField(
              controller: _confirmCtrl,
              obscureText: true,
              keyboardType: TextInputType.number,
              maxLength: _pinLength,
              enabled: !_saving,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: 'Yangi parolni tasdiqlang',
                prefixIcon: Icon(Icons.lock_rounded),
              ),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _saving ? null : _submit,
              child: _saving
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Parolni saqlash'),
            ),
          ],
        ),
      ),
    );
  }
}
