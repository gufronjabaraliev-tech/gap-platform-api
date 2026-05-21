import '../models/app_currency.dart';

/// Tanlangan valyuta uchun tez tanlash summalari (+ ixtiyoriy tavsiya).
List<int> paymentQuickAmounts(
  AppCurrency currency, {
  int? recommended,
  bool includeRecommended = true,
}) {
  final amounts = <int>[...currency.quickPaymentAmounts];
  if (includeRecommended &&
      recommended != null &&
      recommended > 0 &&
      !amounts.contains(recommended)) {
    amounts.insert(0, recommended);
  }
  return amounts;
}
