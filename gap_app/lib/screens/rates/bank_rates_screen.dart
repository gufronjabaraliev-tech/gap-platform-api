import 'package:flutter/material.dart';

import '../../models/app_currency.dart';
import '../../models/bank_rate.dart';
import '../../services/bank_rates_service.dart';
import '../../theme/gap_theme_extension.dart';
import '../../utils/money_format.dart';
import '../../widgets/gap_hero_header.dart';

/// Markaziy bank valyuta kurslari (referens).
class BankRatesScreen extends StatefulWidget {
  const BankRatesScreen({super.key});

  @override
  State<BankRatesScreen> createState() => _BankRatesScreenState();
}

class _BankRatesScreenState extends State<BankRatesScreen> {
  final _bank = BankRatesService.instance;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool force = false}) async {
    setState(() => _loading = true);
    if (force) {
      await _bank.refresh();
    } else {
      await _bank.ensureLoaded();
    }
    if (mounted) setState(() => _loading = false);
  }

  String _updatedLabel() {
    final dt = _bank.lastUpdated;
    if (dt == null) return 'Yangilanmagan';
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final h = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '$d.$m.${dt.year} $h:$min';
  }

  @override
  Widget build(BuildContext context) {
    final gap = context.gap;
    final cs = Theme.of(context).colorScheme;
    final rates = _bank.rates;

    return Scaffold(
      body: Column(
        children: [
          GapHeroHeader(
            title: 'Bank kurslari',
            subtitle: 'O\'zbekiston MB · $_updatedLabel',
            leading: IconButton(
              onPressed: () => Navigator.pop(context),
              style: IconButton.styleFrom(
                backgroundColor: gap.glassOverlay,
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.arrow_back_rounded),
            ),
            actions: [
              IconButton(
                onPressed: _loading ? null : () => _load(force: true),
                style: IconButton.styleFrom(
                  backgroundColor: gap.glassOverlay,
                  foregroundColor: Colors.white,
                ),
                icon: _loading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.refresh_rounded),
              ),
            ],
          ),
          Expanded(
            child: _loading && rates.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: () => _load(force: true),
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      children: [
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Row(
                              children: [
                                Icon(Icons.info_outline_rounded,
                                    color: cs.primary),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    _bank.isWebPlatform
                                        ? 'Brauzerda standart yoki saqlangan kurslar. '
                                            'Yangilangan MB kursi uchun mobil ilovadan foydalaning.'
                                        : 'Kurslar Markaziy bank ma\'lumotlaridan olinadi (cbu.uz). '
                                            'To\'lov qayd etishda shu kursni qo\'llashingiz mumkin.',
                                    style: TextStyle(
                                      color: gap.mutedText,
                                      height: 1.4,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (_bank.lastError != null &&
                            _bank.rateFor(AppCurrency.usd).source == 'default')
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              'Internet yo\'q — standart kurslar ko\'rsatilmoqda',
                              style: TextStyle(color: gap.warning, fontSize: 12),
                            ),
                          ),
                        const SizedBox(height: 12),
                        _RatesTableHeader(),
                        const SizedBox(height: 4),
                        ...rates.map((r) => _RateRow(rate: r)),
                        const SizedBox(height: 16),
                        Text(
                          'Manba: ${rates.isNotEmpty && rates.first.source == 'cbu' ? 'cbu.uz (MB)' : 'Standart kurslar'}',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 11, color: gap.mutedText),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _RatesTableHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final gap = context.gap;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text('Valyuta',
                style: TextStyle(
                    fontWeight: FontWeight.w700, color: gap.mutedText, fontSize: 12)),
          ),
          Expanded(
            child: Text('Nominal',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontWeight: FontWeight.w700, color: gap.mutedText, fontSize: 12)),
          ),
          Expanded(
            flex: 2,
            child: Text('Kurs (so\'m)',
                textAlign: TextAlign.end,
                style: TextStyle(
                    fontWeight: FontWeight.w700, color: gap.mutedText, fontSize: 12)),
          ),
        ],
      ),
    );
  }
}

class _RateRow extends StatelessWidget {
  const _RateRow({required this.rate});
  final BankRate rate;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final gap = context.gap;

    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: cs.primaryContainer,
              child: Text(
                rate.currency.code[0],
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: cs.primary,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(rate.currency.label,
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  Text(rate.currency.code,
                      style: TextStyle(fontSize: 11, color: gap.mutedText)),
                ],
              ),
            ),
            Expanded(
              child: Text(
                rate.nominalLabel,
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                formatAmountNumber(rate.rateUzs.round()),
                textAlign: TextAlign.end,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: cs.primary,
                  fontSize: 15,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
