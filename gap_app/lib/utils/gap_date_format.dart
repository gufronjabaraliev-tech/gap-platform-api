const _monthsUz = [
  'yanvar',
  'fevral',
  'mart',
  'aprel',
  'may',
  'iyun',
  'iyul',
  'avgust',
  'sentyabr',
  'oktyabr',
  'noyabr',
  'dekabr',
];

const _weekdaysUz = [
  'Du',
  'Se',
  'Ch',
  'Pa',
  'Ju',
  'Sh',
  'Ya',
];

DateTime gapDateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

bool gapSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

String formatGapDate(DateTime date, {bool withWeekday = false}) {
  final d = gapDateOnly(date);
  final base = '${d.day} ${_monthsUz[d.month - 1]} ${d.year}';
  if (!withWeekday) return base;
  return '${_weekdaysUz[d.weekday - 1]}, $base';
}

String weekdayShortUz(DateTime date) => _weekdaysUz[date.weekday - 1];

String formatChatTime(DateTime date) {
  final h = date.hour.toString().padLeft(2, '0');
  final m = date.minute.toString().padLeft(2, '0');
  return '$h:$m';
}

String formatChatDateHeader(DateTime date) {
  final now = DateTime.now();
  if (gapSameDay(date, now)) return 'Bugun';
  final yesterday = now.subtract(const Duration(days: 1));
  if (gapSameDay(date, yesterday)) return 'Kecha';
  return formatGapDate(date, withWeekday: true);
}
