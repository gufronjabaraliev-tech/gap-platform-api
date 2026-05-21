import '../models/app_currency.dart';
import '../models/payment_entry.dart';
import '../models/savings_group.dart';

/// Raqamni o'qish oson ko'rinishda (1 250 000).
String formatAmountNumber(int amount) {
  final s = amount.abs().toString();
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write(' ');
    buf.write(s[i]);
  }
  return buf.toString();
}

String formatMoney(int amount, AppCurrency currency) {
  return '${formatAmountNumber(amount)} ${currency.symbol}';
}

String formatMoneyWithLabel(int amount, AppCurrency currency) {
  return '${formatAmountNumber(amount)} ${currency.label}';
}

/// To'lovni qisqa ko'rinishda (masalan: 50 $ yoki 500 000 so'm).
String formatPayment(PaymentEntry entry) => formatMoney(entry.amount, entry.currency);

/// Asl summa + asosiy valyutadagi ekvivalent (to'lov kursi bilan).
String formatPaymentWithSettlement(SavingsGroup group, PaymentEntry entry) {
  final native = formatPayment(entry);
  if (entry.currency == group.settlementCurrency) return native;
  final eq = group.settlementAmountFor(entry);
  final rate = group.effectiveRateFor(entry);
  final rateStr = rate >= 1 ? rate.round().toString() : rate.toStringAsFixed(4);
  return '$native → ${formatMoney(eq, group.settlementCurrency)} (kurs: $rateStr)';
}

/// Jami yig'ilgan — asl + asosiy valyuta.
String formatCollectedSummary(SavingsGroup group) {
  final total = formatMoney(group.collectedTotal, group.settlementCurrency);
  final raw = group.collectedRawText;
  if (raw == null || !group.showDualTotals) return total;
  return 'Asl: $raw\nJami: $total';
}
