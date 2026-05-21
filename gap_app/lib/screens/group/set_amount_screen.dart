import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../models/cycle_type.dart';
import '../../providers/groups_provider.dart';
import '../../utils/money_format.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/gap_group_scroll_body.dart';
import '../../widgets/group_header.dart';
import 'exchange_rates_screen.dart';

class SetAmountScreen extends StatefulWidget {
  const SetAmountScreen({super.key});

  @override
  State<SetAmountScreen> createState() => _SetAmountScreenState();
}

class _SetAmountScreenState extends State<SetAmountScreen> {
  final _amountCtrl = TextEditingController();
  late CycleType _cycle;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final g = context.read<GroupsProvider>().activeGroup!;
    _cycle = g.cycleType;
    if (_amountCtrl.text.isEmpty) {
      _amountCtrl.text = '${g.periodAmount}';
    }
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final amount = int.tryParse(_amountCtrl.text);
    if (amount == null) {
      showGapSnackBar(context, 'Summani kiriting', isError: true);
      return;
    }
    final groups = context.read<GroupsProvider>();
    var err = await groups.setPeriodAmount(amount);
    if (err != null && mounted) {
      showGapSnackBar(context, err, isError: true);
      return;
    }
    err = await groups.setCycleType(_cycle);
    if (!mounted) return;
    if (err != null) {
      showGapSnackBar(context, err, isError: true);
    } else {
      showGapSnackBar(context, 'Saqlandi');
    }
  }

  @override
  Widget build(BuildContext context) {
    final g = context.watch<GroupsProvider>().activeGroup!;
    final members = g.memberCount == 0 ? 10 : g.memberCount;
    final payers = members - 1;
    final amount = int.tryParse(_amountCtrl.text) ?? g.periodAmount;
    final total = payers * amount;
    final cur = g.settlementCurrency;

    return Scaffold(
      body: GapGroupScrollBody(
        header: const GroupHeader(),
        padding: const EdgeInsets.all(20),
        children: [
                const Text('Davr turi', style: TextStyle(fontWeight: FontWeight.w600)),
                ...CycleType.values.map(
                  (t) => RadioListTile<CycleType>(
                    title: Text(t.label),
                    value: t,
                    groupValue: _cycle,
                    onChanged: (v) => setState(() => _cycle = v!),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Asosiy valyuta: ${cur.label} (${cur.symbol})',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _amountCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    labelText: '${_cycle.label} tavsiya (${cur.symbol})',
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ExchangeRatesScreen(),
                    ),
                  ),
                  icon: const Icon(Icons.currency_exchange_rounded),
                  label: const Text('Valyuta kurslari'),
                ),
                const SizedBox(height: 16),
                FilledButton(onPressed: _save, child: const Text('Saqlash')),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF3CD),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$members kishi, $payers to\'laydi × '
                    '${formatMoney(amount, cur)} = ${formatMoney(total, cur)}\n'
                    '1 kishi oladi: ${formatMoney(total, cur)}\n\n'
                    'A\'zolar dollar, so\'m yoki boshqa valyutada to\'lashi mumkin — '
                    'jami ${cur.label} da hisoblanadi.',
                  ),
                ),
        ],
      ),
    );
  }
}
