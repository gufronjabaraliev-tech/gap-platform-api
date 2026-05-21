import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/device_contact.dart';
import '../../providers/groups_provider.dart';
import '../../services/device_contacts_service.dart';
import '../../theme/gap_theme_extension.dart';
import '../../utils/pin_util.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/gap_sliding_text.dart';

/// Kontaktlardan bir yoki bir nechta a'zo tanlash.
class PickContactsScreen extends StatefulWidget {
  const PickContactsScreen({super.key});

  @override
  State<PickContactsScreen> createState() => _PickContactsScreenState();
}

class _PickContactsScreenState extends State<PickContactsScreen> {
  final _contactsService = DeviceContactsService();
  final _searchCtrl = TextEditingController();
  final _selected = <String>{};

  List<DeviceContact> _all = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
    _searchCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final access = await _contactsService.requestAccess();
    if (!access.granted) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = access.message;
      });
      return;
    }

    try {
      final list = await _contactsService.loadUzPhoneContacts();
      if (!mounted) return;
      setState(() {
        _all = list;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  List<DeviceContact> get _filtered {
    final q = _searchCtrl.text.trim().toLowerCase();
    if (q.isEmpty) return _all;
    final digitsOnly = q.replaceAll(RegExp(r'\D'), '');
    final display = q;
    return _all.where((c) {
      final nameMatch = c.displayName.toLowerCase().contains(display);
      final phoneDigits = formatPhoneDisplay(c.normalizedPhone)
          .toLowerCase()
          .replaceAll(RegExp(r'\D'), '');
      final phoneMatch = digitsOnly.isNotEmpty &&
          (c.normalizedPhone.contains(digitsOnly) ||
              phoneDigits.contains(digitsOnly));
      final formattedMatch =
          formatPhoneDisplay(c.normalizedPhone).toLowerCase().contains(display);
      return nameMatch || phoneMatch || formattedMatch;
    }).toList();
  }

  Future<void> _addSelected() async {
    if (_selected.isEmpty) {
      showGapSnackBar(context, 'Kamida bitta kontakt tanlang', isError: true);
      return;
    }

    final groups = context.read<GroupsProvider>();
    final picks =
        _all.where((c) => _selected.contains(c.normalizedPhone)).toList();

    setState(() => _loading = true);
    var added = 0;
    final errors = <String>[];

    for (final c in picks) {
      final err = await groups.addMemberByPhone(
        c.normalizedPhone,
        displayName: c.displayName,
      );
      if (err != null) {
        errors.add('${c.displayName}: $err');
      } else {
        added++;
      }
    }

    if (!mounted) return;
    setState(() => _loading = false);

    if (added > 0) {
      showGapSnackBar(context, '$added ta a\'zo qo\'shildi');
    }
    if (errors.isNotEmpty && mounted) {
      showGapSnackBar(
        context,
        errors.length == 1 ? errors.first : '${errors.length} ta xato',
        isError: true,
      );
    }
    if (added > 0 && mounted) {
      Navigator.pop(context, added);
    }
  }

  @override
  Widget build(BuildContext context) {
    final gap = context.gap;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kontaktlar'),
        actions: [
          if (_selected.isNotEmpty)
            TextButton(
              onPressed: _loading ? null : _addSelected,
              child: Text('Qo\'shish (${_selected.length})'),
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: TextField(
              controller: _searchCtrl,
              decoration: const InputDecoration(
                hintText: 'Ism yoki telefon...',
                prefixIcon: Icon(Icons.search_rounded),
              ),
            ),
          ),
          Expanded(child: _buildBody(gap)),
        ],
      ),
    );
  }

  Widget _buildBody(GapThemeExtension gap) {
    if (_loading && _all.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.contacts_outlined, size: 48, color: gap.mutedText),
              const SizedBox(height: 12),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(onPressed: _load, child: const Text('Qayta urinish')),
            ],
          ),
        ),
      );
    }
    if (_all.isEmpty) {
      return Center(
        child: Text(
          'O\'zbek telefon raqami bo\'lgan kontaktlar topilmadi',
          style: TextStyle(color: gap.mutedText),
          textAlign: TextAlign.center,
        ),
      );
    }

    final list = _filtered;
    return ListView.builder(
      itemCount: list.length,
      itemBuilder: (context, index) {
        final c = list[index];
        final checked = _selected.contains(c.normalizedPhone);
        return CheckboxListTile(
          value: checked,
          onChanged: (v) {
            setState(() {
              if (v == true) {
                _selected.add(c.normalizedPhone);
              } else {
                _selected.remove(c.normalizedPhone);
              }
            });
          },
          secondary: CircleAvatar(
            child: Text(
              c.displayName.isNotEmpty
                  ? c.displayName[0].toUpperCase()
                  : '?',
            ),
          ),
          title: GapSlidingText(text: c.displayName),
          subtitle: Text(formatPhoneDisplay(c.normalizedPhone)),
        );
      },
    );
  }
}
