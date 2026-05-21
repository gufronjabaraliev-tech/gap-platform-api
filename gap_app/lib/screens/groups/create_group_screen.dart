import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../config/gap_pricing.dart';
import '../../models/app_currency.dart';
import '../../models/cycle_type.dart';
import '../../models/schedule_mode.dart';
import '../../models/gap_creation_eligibility.dart';
import '../../providers/auth_provider.dart';
import '../../providers/groups_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/invite_share_sheet.dart';
import '../../widgets/pay_gap_creation_sheet.dart';
import '../main_shell_screen.dart';

class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final _nameCtrl = TextEditingController();
  final _nameFieldKey = GlobalKey();
  final _nameFocus = FocusNode();
  CycleType _cycle = CycleType.weekly;
  final _amountCtrl = TextEditingController(text: '500000');
  AppCurrency _settlement = AppCurrency.uzs;
  ScheduleMode _scheduleMode = ScheduleMode.fixedRandom;
  bool _loading = false;
  GapCreationEligibility? _eligibility;
  String? _nameError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadEligibility());
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _nameFocus.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  void _scrollNameIntoViewAndFocus() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final ctx = _nameFieldKey.currentContext;
      if (ctx != null) {
        Scrollable.ensureVisible(
          ctx,
          duration: const Duration(milliseconds: 380),
          curve: Curves.easeOutCubic,
          alignment: 0.12,
          alignmentPolicy: ScrollPositionAlignmentPolicy.explicit,
        );
      }
      _nameFocus.requestFocus();
    });
  }

  Future<void> _loadEligibility() async {
    final auth = context.read<AuthProvider>().user;
    if (auth == null) return;
    final e = await context.read<GroupsProvider>().creationEligibility(auth.id);
    if (mounted) setState(() => _eligibility = e);
  }

  void _onSettlementChanged(AppCurrency? v) {
    if (v == null) return;
    setState(() {
      _settlement = v;
      if (v == AppCurrency.uzs && _amountCtrl.text == '100') {
        _amountCtrl.text = '500000';
      } else if (v == AppCurrency.usd && _amountCtrl.text == '500000') {
        _amountCtrl.text = '100';
      }
    });
  }

  Future<bool> _ensureCanCreate() async {
    final auth = context.read<AuthProvider>().user!;
    final groups = context.read<GroupsProvider>();
    var e = await groups.creationEligibility(auth.id);
    if (mounted) setState(() => _eligibility = e);

    if (e.canCreate) return true;

    final paid = await PayGapCreationSheet.show(context);
    if (paid != true || !mounted) return false;

    setState(() => _loading = true);
    final err = await groups.purchaseGapCreationSlot(auth.id);
    if (!mounted) return false;
    await context.read<AuthProvider>().refreshUser();
    if (!mounted) return false;
    setState(() => _loading = false);

    if (err != null) {
      showGapSnackBar(context, err, isError: true);
      return false;
    }

    e = await groups.creationEligibility(auth.id);
    if (!mounted) return false;
    setState(() => _eligibility = e);
    if (!e.canCreate) {
      showGapSnackBar(context, 'To\'lov qayd etilmadi', isError: true);
      return false;
    }
    showGapSnackBar(context, 'To\'lov qabul qilindi. Endi GAP yaratishingiz mumkin.');
    return true;
  }

  Future<void> _create() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      setState(() => _nameError = 'Jamg\'arma nomini kiriting');
      _scrollNameIntoViewAndFocus();
      return;
    }
    if (name.length < 2) {
      setState(() => _nameError = 'Kamida 2 ta belgi kiriting');
      _scrollNameIntoViewAndFocus();
      return;
    }
    setState(() => _nameError = null);
    final amount = int.tryParse(_amountCtrl.text);
    if (amount == null || amount < 1) {
      showGapSnackBar(context, 'Summani kiriting', isError: true);
      return;
    }

    if (!await _ensureCanCreate() || !mounted) return;

    final auth = context.read<AuthProvider>().user!;
    setState(() => _loading = true);
    final groups = context.read<GroupsProvider>();
    final err = await groups.createGroup(
          userId: auth.id,
          userName: auth.name,
          userPhone: auth.phone,
          name: name,
          cycleType: _cycle,
          periodAmount: amount,
          settlementCurrency: _settlement,
          scheduleMode: _scheduleMode,
        );
    if (!mounted) return;
    setState(() => _loading = false);

    if (err == 'payment_required') {
      if (!mounted) return;
      final ok = await _ensureCanCreate();
      if (ok && mounted) return _create();
      return;
    }

    if (err != null) {
      showGapSnackBar(context, err, isError: true);
      return;
    }

    await _loadEligibility();
    if (!mounted) return;
    final created = context.read<GroupsProvider>().activeGroup!;
    showGapSnackBar(context, 'GAP yaratildi. A\'zolarni taklif qiling!');
    await InviteShareSheet.show(
      context,
      groupName: created.name,
      inviteCode: created.inviteCode,
    );
    if (!mounted) return;

    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop(true);
    } else {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => MainShellScreen(
            key: MainShellScreen.globalKey,
            initialIndex: 1,
          ),
        ),
        (route) => false,
      );
    }
  }

  String get _createButtonLabel {
    final e = _eligibility;
    if (e == null) return 'Yaratish...';
    if (e.kind == GapCreationKind.free) return 'Bepul yaratish';
    if (e.kind == GapCreationKind.paidCredit) {
      return 'GAP yaratish (kredit)';
    }
    return 'To\'lov va yaratish — ${GapPricing.extraGapPriceLabel}';
  }

  @override
  Widget build(BuildContext context) {
    final gap = context.gap;
    final e = _eligibility;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Yangi GAP'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (e != null) _PricingBanner(eligibility: e),
          const SizedBox(height: 16),
          Text(
            'Siz ushbu jamg\'armaning masuli bo\'lasiz. A\'zolar turli valyutada to\'lashi mumkin.',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            key: _nameFieldKey,
            controller: _nameCtrl,
            focusNode: _nameFocus,
            onChanged: (_) {
              if (_nameError != null) setState(() => _nameError = null);
            },
            decoration: InputDecoration(
              labelText: 'Jamg\'arma nomi',
              hintText: 'Masalan: Do\'stlar guruhi',
              errorText: _nameError,
            ),
          ),
          const SizedBox(height: 20),
          const Text('Davr turi', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          ...CycleType.values.map(
            (t) => RadioListTile<CycleType>(
              title: Text(t.label),
              subtitle: Text('Har ${t.periodLabel} bitta kishi pul oladi'),
              value: t,
              groupValue: _cycle,
              onChanged: (v) => setState(() => _cycle = v!),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Navbat turi',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            'Majburiy tanlov. GAP shu uslubda ishlaydi. '
            'Keyinchalik faqat Sozlamalar bo\'limidan o\'zgartirish mumkin.',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 13,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 10),
          ...ScheduleMode.values.map(
            (m) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: _scheduleMode == m
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.outlineVariant,
                  width: _scheduleMode == m ? 2 : 1,
                ),
              ),
              child: RadioListTile<ScheduleMode>(
                value: m,
                groupValue: _scheduleMode,
                onChanged: (v) => setState(() => _scheduleMode = v!),
                title: Row(
                  children: [
                    Icon(m.icon, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        m.label,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(left: 32),
                  child: Text(m.description),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<AppCurrency>(
            value: _settlement,
            decoration: const InputDecoration(
              labelText: 'Asosiy valyuta (pul oluvchi oladi)',
            ),
            items: AppCurrency.values
                .map(
                  (c) => DropdownMenuItem(
                    value: c,
                    child: Text('${c.label} (${c.symbol})'),
                  ),
                )
                .toList(),
            onChanged: _onSettlementChanged,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _amountCtrl,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              labelText:
                  '${_cycle.label} tavsiya summasi (${_settlement.symbol})',
            ),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _loading ? null : _create,
            child: _loading
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(_createButtonLabel),
          ),
          if (e?.needsPayment == true) ...[
            const SizedBox(height: 12),
            Text(
              'Birinchi GAP bepul. Qo\'shimcha har biri ${GapPricing.extraGapPriceLabel}.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: gap.mutedText),
            ),
          ],
        ],
      ),
    );
  }
}

class _PricingBanner extends StatelessWidget {
  const _PricingBanner({required this.eligibility});
  final GapCreationEligibility eligibility;

  @override
  Widget build(BuildContext context) {
    final gap = context.gap;
    final cs = Theme.of(context).colorScheme;

    final (Color bg, Color fg, IconData icon) = switch (eligibility.kind) {
      GapCreationKind.free => (
          AppColors.teal.withValues(alpha: 0.12),
          AppColors.teal,
          Icons.celebration_rounded,
        ),
      GapCreationKind.paidCredit => (
          cs.primaryContainer,
          cs.primary,
          Icons.verified_rounded,
        ),
      GapCreationKind.paymentRequired => (
          gap.warning.withValues(alpha: 0.12),
          gap.warning,
          Icons.payment_rounded,
        ),
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: fg.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: fg, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  switch (eligibility.kind) {
                    GapCreationKind.free => 'Birinchi GAP — bepul',
                    GapCreationKind.paidCredit => 'Kredit mavjud',
                    GapCreationKind.paymentRequired => 'Qo\'shimcha GAP — pullik',
                  },
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: fg,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  eligibility.subtitle,
                  style: TextStyle(
                    color: cs.onSurface.withValues(alpha: 0.75),
                    height: 1.35,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
