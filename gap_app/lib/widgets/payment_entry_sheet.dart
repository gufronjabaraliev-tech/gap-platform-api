import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/app_currency.dart';
import '../models/savings_group.dart';
import '../providers/groups_provider.dart';
import '../services/bank_rates_service.dart';
import '../theme/gap_theme_extension.dart';
import '../utils/currency_quick_amounts.dart';
import '../utils/exchange_rate_format.dart';
import '../utils/money_format.dart';
import 'gap_sliding_text.dart';
import 'payment_exchange_rate_card.dart';
import 'reciprocal_payment_banner.dart';

/// Ishtirokchi uchun to'lov kiritish (pastdan modali).
Future<bool?> showPaymentEntrySheet({
  required BuildContext context,
  required SavingsGroup group,
  required String payerId,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) => PaymentEntrySheet(
      payerId: payerId,
      group: group,
    ),
  );
}

class PaymentEntrySheet extends StatefulWidget {
  const PaymentEntrySheet({
    super.key,
    required this.payerId,
    required this.group,
  });

  final String payerId;
  final SavingsGroup group;

  @override
  State<PaymentEntrySheet> createState() => _PaymentEntrySheetState();
}

class _PaymentEntrySheetState extends State<PaymentEntrySheet> {
  final _amountCtrl = TextEditingController();
  final _rateCtrl = TextEditingController();
  AppCurrency? _currency;
  bool _initialized = false;
  String? _formError;

  SavingsGroup get g => widget.group;
  String get payerId => widget.payerId;

  @override
  void initState() {
    super.initState();
    BankRatesService.instance.ensureLoaded();
    _initFields();
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _rateCtrl.dispose();
    super.dispose();
  }

  void _initFields() {
    if (_initialized) return;
    final existing = g.paymentFor(payerId);
    if (existing != null) {
      _currency = existing.currency;
      _amountCtrl.text = '${existing.amount}';
      _rateCtrl.text = existing.currency == g.settlementCurrency
          ? ''
          : formatRateInput(g.effectiveRateFor(existing));
    } else {
      final reciprocal = g.mandatoryPaymentFor(payerId);
      if (reciprocal != null) {
        _currency = reciprocal.entry.currency;
        _amountCtrl.text = '${reciprocal.entry.amount}';
        _syncRateField(reciprocal.entry.currency);
      } else {
        _currency = g.currencyForMember(payerId);
        _amountCtrl.text = '${g.recommendedAmountFor(payerId)}';
        _syncRateField(_currency!);
      }
    }
    _initialized = true;
  }

  void _syncRateField(AppCurrency currency) {
    if (currency == g.settlementCurrency) {
      _rateCtrl.clear();
      return;
    }
    final bank =
        BankRatesService.instance.rateBetween(currency, g.settlementCurrency);
    _rateCtrl.text = formatRateInput(bank);
  }

  void _applyBankRate(AppCurrency currency) {
    final rate =
        BankRatesService.instance.rateBetween(currency, g.settlementCurrency);
    _rateCtrl.text = formatRateInput(rate);
    setState(() {});
  }

  Future<void> _submit() async {
    final groups = context.read<GroupsProvider>();
    final amount = int.tryParse(_amountCtrl.text.trim());
    if (amount == null || amount < 1) {
      setState(() => _formError = 'To\'g\'ri summa kiriting');
      return;
    }
    final currency = _currency ?? g.currencyForMember(payerId);
    double? rate;
    if (currency != g.settlementCurrency) {
      rate = parseRateInput(_rateCtrl.text);
      if (rate == null || rate <= 0) {
        setState(() => _formError = 'Bugungi kursni kiriting');
        return;
      }
    }

    final err = await groups.makePayment(
      payerId,
      amount,
      currency,
      exchangeRate: rate,
    );
    if (!mounted) return;
    if (err != null) {
      setState(() => _formError = err);
      return;
    }
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final gap = context.gap;
    final name = g.displayNameFor(payerId);
    if (g.isPayerExemptFromPayingCurrentReceiver(payerId)) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.block_rounded, size: 40, color: gap.mutedText),
            const SizedBox(height: 12),
            Text(
              '$name dan pul olinmaydi',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Bu ishtirokchi oldin navbatdagi oluvchiga to\'lamagan.',
              textAlign: TextAlign.center,
              style: TextStyle(color: gap.mutedText, height: 1.4),
            ),
          ],
        ),
      );
    }
    final reciprocal = g.mandatoryPaymentFor(payerId);
    final existing = g.paymentFor(payerId);
    final currency =
        _currency ?? g.currencyForMember(payerId);
    final recommended = g.recommendedAmountFor(payerId);
    final needsRate = currency != g.settlementCurrency;
    final amountPreview = int.tryParse(_amountCtrl.text.trim()) ?? 0;
    final ratePreview = needsRate ? parseRateInput(_rateCtrl.text) : null;
    final settlementPreview = needsRate &&
            ratePreview != null &&
            amountPreview > 0
        ? (amountPreview * ratePreview).round()
        : amountPreview;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.88,
        minChildSize: 0.45,
        maxChildSize: 0.95,
        builder: (context, scrollController) {
          return ListView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            children: [
              GapSlidingText(
                text: name,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              Text(
                existing != null
                    ? 'To\'lovni yangilash'
                    : reciprocal != null
                        ? 'Majburiy to\'lov'
                        : 'Ixtiyoriy to\'lov',
                style: TextStyle(color: gap.mutedText, fontSize: 13),
              ),
              if (reciprocal != null && existing == null) ...[
                const SizedBox(height: 12),
                ReciprocalPaymentBanner(group: g, obligation: reciprocal),
              ],
              const SizedBox(height: 16),
              DropdownButtonFormField<AppCurrency>(
                value: currency,
                decoration: const InputDecoration(
                  labelText: 'To\'lov valyutasi',
                ),
                items: AppCurrency.values
                    .map(
                      (c) => DropdownMenuItem(
                        value: c,
                        child: Text('${c.label} (${c.symbol})'),
                      ),
                    )
                    .toList(),
                onChanged: (v) {
                  if (v == null) return;
                  setState(() {
                    _currency = v;
                    final recip = g.mandatoryPaymentFor(payerId);
                    if (recip != null && recip.entry.currency == v) {
                      _amountCtrl.text = '${recip.entry.amount}';
                    } else {
                      _amountCtrl.text =
                          '${g.fromSettlementAmount(g.periodAmount, v)}';
                    }
                    _syncRateField(v);
                  });
                },
              ),
              if (needsRate) ...[
                const SizedBox(height: 14),
                PaymentExchangeRateCard(
                  group: g,
                  currency: currency,
                  rateController: _rateCtrl,
                  amountPreview: amountPreview,
                  settlementPreview: settlementPreview,
                  onChanged: () => setState(() {}),
                  onApplyBankRate: () => _applyBankRate(currency),
                ),
              ],
              const SizedBox(height: 12),
              TextField(
                controller: _amountCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  labelText: 'Summa (${currency.symbol})',
                  prefixIcon: const Icon(Icons.payments_rounded),
                  helperText: reciprocal != null && existing == null
                      ? 'Majburiy: ${formatMoney(reciprocal.entry.amount, reciprocal.entry.currency)}'
                      : 'Tavsiya: ${formatMoney(recommended, currency)}',
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (reciprocal != null && existing == null)
                    ActionChip(
                      avatar: Icon(Icons.history_rounded,
                          size: 18, color: gap.warning),
                      label: Text(
                        'Qaytarish: ${formatMoney(reciprocal.entry.amount, reciprocal.entry.currency)}',
                      ),
                      onPressed: () => setState(() {
                        _currency = reciprocal.entry.currency;
                        _amountCtrl.text = '${reciprocal.entry.amount}';
                        _syncRateField(reciprocal.entry.currency);
                      }),
                    ),
                  for (final quick in paymentQuickAmounts(currency))
                    ActionChip(
                      label: Text(formatMoney(quick, currency)),
                      onPressed: () =>
                          setState(() => _amountCtrl.text = '$quick'),
                    ),
                ],
              ),
              if (_formError != null) ...[
                const SizedBox(height: 12),
                Text(
                  _formError!,
                  style: TextStyle(color: gap.danger, fontSize: 13),
                ),
              ],
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: _submit,
                style: FilledButton.styleFrom(
                  backgroundColor: gap.success,
                  minimumSize: const Size(double.infinity, 48),
                ),
                icon: const Icon(Icons.check_circle_outline),
                label: Text(
                  existing != null ? 'Saqlash' : 'To\'lov qayd etildi',
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Birinchi to'lov qilish kerak bo'lgan ishtirokchi (majburiy, keyin ixtiyoriy).
String? suggestNextPayerId(SavingsGroup g) {
  final recv = g.currentReceiverId;
  if (recv == null) return null;
  if (g.mandatoryUnpaidPayerIds.isNotEmpty) {
    return g.mandatoryUnpaidPayerIds.first;
  }
  if (g.optionalUnpaidPayerIds.isNotEmpty) {
    return g.optionalUnpaidPayerIds.first;
  }
  return null;
}
