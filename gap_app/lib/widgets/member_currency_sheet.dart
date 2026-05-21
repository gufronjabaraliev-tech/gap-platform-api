import 'package:flutter/material.dart';

import '../models/app_currency.dart';

/// A'zo uchun to'lov va qabul valyutasi tanlash.
Future<void> showMemberCurrencyPrefsSheet({
  required BuildContext context,
  required String memberName,
  required AppCurrency? currentPayment,
  required AppCurrency? currentReceive,
  required Future<void> Function(AppCurrency? payment) onPayment,
  required Future<void> Function(AppCurrency? receive) onReceive,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => SafeArea(
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.55,
        minChildSize: 0.4,
        maxChildSize: 0.85,
        builder: (context, scrollController) => ListView(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            Text(
              memberName,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            Text(
              'To\'lov va qabul valyutasini alohida belgilang',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            _sectionTitle(context, 'To\'lov qilganda'),
            _option(
              ctx,
              label: 'Farqi yo\'q',
              selected: currentPayment == null,
              onTap: () async {
                Navigator.pop(ctx);
                await onPayment(null);
              },
            ),
            ...AppCurrency.values.map(
              (c) => _option(
                ctx,
                label: '${c.label} (${c.symbol})',
                selected: currentPayment == c,
                onTap: () async {
                  Navigator.pop(ctx);
                  await onPayment(c);
                },
              ),
            ),
            const Divider(height: 28),
            _sectionTitle(context, 'Navbatda pul olganda'),
            _option(
              ctx,
              label: 'Farqi yo\'q',
              selected: currentReceive == null,
              onTap: () async {
                Navigator.pop(ctx);
                await onReceive(null);
              },
            ),
            ...AppCurrency.values.map(
              (c) => _option(
                ctx,
                label: '${c.label} (${c.symbol})',
                selected: currentReceive == c,
                onTap: () async {
                  Navigator.pop(ctx);
                  await onReceive(c);
                },
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

Widget _sectionTitle(BuildContext context, String text) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      text,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
    ),
  );
}

Widget _option(
  BuildContext ctx, {
  required String label,
  required bool selected,
  required VoidCallback onTap,
}) {
  return ListTile(
    dense: true,
    leading: Icon(
      selected ? Icons.radio_button_checked : Icons.radio_button_off,
      size: 20,
    ),
    title: Text(label),
    onTap: onTap,
  );
}
