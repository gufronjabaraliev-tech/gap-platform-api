import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/app_currency.dart';
import '../models/savings_group.dart';
import '../services/bank_rates_service.dart';
import '../utils/exchange_rate_format.dart';
import '../utils/money_format.dart';
import '../theme/gap_theme_extension.dart';
import '../screens/rates/bank_rates_screen.dart';

/// To'lov sahifasida valyuta tanlangach kurs kiritish bloki.
class PaymentExchangeRateCard extends StatelessWidget {
  const PaymentExchangeRateCard({
    super.key,
    required this.group,
    required this.currency,
    required this.rateController,
    required this.amountPreview,
    required this.settlementPreview,
    required this.onChanged,
    required this.onApplyBankRate,
  });

  final SavingsGroup group;
  final AppCurrency currency;
  final TextEditingController rateController;
  final int amountPreview;
  final int settlementPreview;
  final VoidCallback onChanged;
  final VoidCallback onApplyBankRate;

  @override
  Widget build(BuildContext context) {
    final gap = context.gap;
    final cs = Theme.of(context).colorScheme;
    final settlement = group.settlementCurrency;
    final bank = BankRatesService.instance;
    final bankRate = bank.rateBetween(currency, settlement);
    final bankLine = bank.rateFor(currency);

    final ratePreview = parseRateInput(rateController.text);

    return Card(
      elevation: 0,
      color: cs.primaryContainer.withValues(alpha: 0.35),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: cs.primary.withValues(alpha: 0.25)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.currency_exchange_rounded, color: cs.primary, size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Bugungi kurs',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: cs.primary,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const BankRatesScreen()),
                  ),
                  child: const Text('Bank kurslari'),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '1 ${currency.label} necha ${settlement.label} ekvivalenti — shu kurs bo\'yicha jami hisoblanadi.',
              style: TextStyle(fontSize: 12, color: gap.mutedText, height: 1.35),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: rateController,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[\d.,]')),
              ],
              onChanged: (_) => onChanged(),
              decoration: InputDecoration(
                filled: true,
                fillColor: cs.surface,
                labelText: '1 ${currency.symbol} = ? ${settlement.symbol}',
                hintText: formatRateInput(bankRate),
                prefixIcon: const Icon(Icons.edit_rounded),
                suffixIcon: IconButton(
                  tooltip: 'Bank kursidan',
                  onPressed: onApplyBankRate,
                  icon: const Icon(Icons.account_balance_rounded),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: cs.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
              ),
              child: Row(
                children: [
                  Icon(Icons.account_balance_rounded,
                      size: 20, color: gap.mutedText),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Markaziy bank (MB)',
                          style: TextStyle(
                            fontSize: 11,
                            color: gap.mutedText,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '${bankLine.nominalLabel} ${currency.code} = '
                          '${formatAmountNumber(bankLine.rateUzs.round())} so\'m'
                          ' → 1 ${currency.symbol} = ${formatRateInput(bankRate)} ${settlement.symbol}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  FilledButton.tonal(
                    onPressed: onApplyBankRate,
                    child: const Text('Qo\'llash'),
                  ),
                ],
              ),
            ),
            if (amountPreview > 0 && ratePreview != null && ratePreview > 0) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: gap.success.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: gap.success.withValues(alpha: 0.35)),
                ),
                child: Text(
                  'Hisob: ${formatMoney(amountPreview, currency)} = '
                  '${formatMoney(settlementPreview, settlement)}',
                  style: TextStyle(
                    color: gap.success,
                    fontWeight: FontWeight.w700,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
