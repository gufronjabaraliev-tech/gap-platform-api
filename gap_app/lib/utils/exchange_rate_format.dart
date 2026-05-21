/// Kursni kiritish / ko'rsatish uchun matn.
String formatRateInput(double rate) {
  if (rate >= 100) return rate.round().toString();
  if (rate >= 1) return rate.toStringAsFixed(2).replaceAll(RegExp(r'\.?0+$'), '');
  return rate.toStringAsFixed(6).replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
}

double? parseRateInput(String text) {
  final t = text.trim().replaceAll(',', '.').replaceAll(' ', '');
  if (t.isEmpty) return null;
  return double.tryParse(t);
}
