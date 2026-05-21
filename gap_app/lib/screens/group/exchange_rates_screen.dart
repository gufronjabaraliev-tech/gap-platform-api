import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../models/app_currency.dart';
import '../../providers/groups_provider.dart';
import '../../utils/money_format.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/gap_group_scroll_body.dart';
import '../../widgets/group_header.dart';

/// Masul valyuta kurslarini sozlaydi (1 dollar = necha so'm).
class ExchangeRatesScreen extends StatefulWidget {
  const ExchangeRatesScreen({super.key});

  @override
  State<ExchangeRatesScreen> createState() => _ExchangeRatesScreenState();
}

class _ExchangeRatesScreenState extends State<ExchangeRatesScreen> {
  final _controllers = <AppCurrency, TextEditingController>{};

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _init(GroupsProvider groups) {
    final g = groups.activeGroup!;
    for (final c in AppCurrency.values) {
      if (c == g.settlementCurrency) continue;
      _controllers.putIfAbsent(c, () {
        final rate = g.rateFor(c);
        final text = rate >= 1
            ? rate.round().toString()
            : rate.toStringAsFixed(6);
        return TextEditingController(text: text);
      });
    }
  }

  Future<void> _save() async {
    final rates = <String, double>{};
    for (final entry in _controllers.entries) {
      final v = double.tryParse(entry.value.text.replaceAll(',', '.'));
      if (v == null || v <= 0) {
        showGapSnackBar(
          context,
          '${entry.key.label} uchun to\'g\'ri kurs kiriting',
          isError: true,
        );
        return;
      }
      rates[entry.key.code] = v;
    }
    final err = await context.read<GroupsProvider>().setExchangeRates(rates);
    if (!mounted) return;
    if (err != null) {
      showGapSnackBar(context, err, isError: true);
    } else {
      showGapSnackBar(context, 'Kurslar saqlandi');
    }
  }

  @override
  Widget build(BuildContext context) {
    final groups = context.watch<GroupsProvider>();
    final g = groups.activeGroup!;
    _init(groups);

    return Scaffold(
      body: GapGroupScrollBody(
        header: const GroupHeader(),
        padding: const EdgeInsets.all(20),
        children: [
                Text(
                  'Asosiy valyuta (pul oluvchi oladi): ${g.settlementCurrency.label}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Har bir valyuta uchun: 1 birlik = necha ${g.settlementCurrency.label}. '
                  'Masalan, 15 kishidan yarmi dollarda, yarmi so\'mda to\'lasa — ilova jami summani '
                  '${g.settlementCurrency.label} da hisoblaydi.',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 20),
                ...AppCurrency.values.where((c) => c != g.settlementCurrency).map(
                  (c) {
                    final ctrl = _controllers[c]!;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: TextField(
                        controller: ctrl,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'[\d.,]'),
                          ),
                        ],
                        decoration: InputDecoration(
                          labelText: '1 ${c.label} = ? ${g.settlementCurrency.symbol}',
                          helperText:
                              'Standart: ${AppCurrency.rateBetween(c, g.settlementCurrency).toStringAsFixed(AppCurrency.rateBetween(c, g.settlementCurrency) < 1 ? 6 : 0)}',
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _save,
                  child: const Text('Kurslarni saqlash'),
                ),
                const SizedBox(height: 24),
                if (g.collectedByCurrency.isNotEmpty) ...[
                  const Text(
                    'Joriy davr (asl summalar)',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  ...g.collectedByCurrency.entries.map(
                    (e) => ListTile(
                      dense: true,
                      title: Text(e.key.label),
                      trailing: Text(formatMoney(e.value, e.key)),
                    ),
                  ),
                  ListTile(
                    dense: true,
                    title: const Text('Jami (asosiy valyuta)'),
                    trailing: Text(
                      formatMoney(g.collectedTotal, g.settlementCurrency),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
        ],
      ),
    );
  }
}
