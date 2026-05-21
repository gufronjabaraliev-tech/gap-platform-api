import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/payment_entry.dart';
import '../models/schedule_mode.dart';
import '../models/savings_group.dart';
import '../utils/money_format.dart';

/// Jamg'arma holati hisobotini PDF qilib yaratish va ulashish.
class GroupReportPdfService {
  static pw.Font? _cachedFont;

  static Future<pw.Font> _loadFont() async {
    if (_cachedFont != null) return _cachedFont!;
    final data = await rootBundle.load('assets/fonts/NotoSans-Regular.ttf');
    _cachedFont = pw.Font.ttf(data);
    return _cachedFont!;
  }

  static Future<List<int>> buildBytes(SavingsGroup group) async {
    final font = await _loadFont();
    final doc = pw.Document();
    final style = pw.TextStyle(font: font, fontSize: 10);
    final titleStyle = pw.TextStyle(font: font, fontSize: 18, fontWeight: pw.FontWeight.bold);
    final hStyle = pw.TextStyle(font: font, fontSize: 12, fontWeight: pw.FontWeight.bold);

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          pw.Text('GAP — Jamg\'arma hisoboti', style: titleStyle),
          pw.SizedBox(height: 6),
          pw.Text(group.name, style: hStyle),
          pw.SizedBox(height: 12),
          _infoBlock(group, style),
          pw.SizedBox(height: 16),
          pw.Text('Davrlar bo\'yicha', style: hStyle),
          pw.SizedBox(height: 8),
          ..._periodSections(group, style, hStyle),
          pw.SizedBox(height: 16),
          pw.Text('A\'zolar jami', style: hStyle),
          pw.SizedBox(height: 8),
          _memberTable(group, style),
        ],
      ),
    );
    return doc.save();
  }

  static pw.Widget _infoBlock(SavingsGroup g, pw.TextStyle style) {
    final closed = g.isClosed && g.closedAt != null
        ? _formatDate(g.closedAt!)
        : 'Faol';
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _line('Holat', g.isClosed ? 'Yopilgan ($closed)' : 'Faol', style),
        _line('Davr turi', g.cycleType.label, style),
        _line('Navbat rejimi', g.scheduleMode.label, style),
        _line(
          'Tavsiya summasi',
          formatMoney(g.periodAmount, g.settlementCurrency),
          style,
        ),
        _line('Hisob-kitob valyutasi', g.settlementCurrency.label, style),
        _line('A\'zolar soni', '${g.memberCount}', style),
        if (g.scheduleMode == ScheduleMode.fixedRandom && g.schedule.isNotEmpty)
          _line('GAP navbat', _scheduleLine(g), style),
      ],
    );
  }

  static String _scheduleLine(SavingsGroup g) {
    return g.schedule
        .asMap()
        .entries
        .map((e) => '${e.key + 1}. ${g.displayNameFor(e.value)}')
        .join(' → ');
  }

  static List<pw.Widget> _periodSections(
    SavingsGroup g,
    pw.TextStyle style,
    pw.TextStyle hStyle,
  ) {
    final periods = g.reportPeriodIndexes;
    if (periods.isEmpty) {
      return [pw.Text('To\'lovlar qayd etilmagan', style: style)];
    }

    return periods.map((p) {
      final receiver = g.receiverForPeriod(p);
      final receiverName =
          receiver != null ? g.displayNameFor(receiver) : '—';
      final pmap = g.payments['$p'] ?? {};
      final collected = pmap.values.fold<int>(
        0,
        (s, e) => s + g.settlementAmountFor(e),
      );

      return pw.Container(
        margin: const pw.EdgeInsets.only(bottom: 12),
        padding: const pw.EdgeInsets.all(10),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.grey300),
          borderRadius: pw.BorderRadius.circular(6),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              '${g.periodLabelFor(p)} — Oluvchi: $receiverName',
              style: hStyle,
            ),
            pw.Text(
              'Yig\'ildi: ${formatMoney(collected, g.settlementCurrency)}',
              style: style,
            ),
            pw.SizedBox(height: 6),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
              columnWidths: {
                0: const pw.FlexColumnWidth(2),
                1: const pw.FlexColumnWidth(2),
                2: const pw.FlexColumnWidth(1.5),
              },
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                  children: [
                    _cell('A\'zo', style, bold: true),
                    _cell('To\'lov', style, bold: true),
                    _cell('Holat', style, bold: true),
                  ],
                ),
                ...g.members.entries.where((e) => e.key != receiver).map((e) {
                  final pay = pmap[e.key];
                  return pw.TableRow(
                    children: [
                      _cell(e.value.displayName, style),
                      _cell(
                        pay != null ? _paymentText(g, pay) : '—',
                        style,
                      ),
                      _cell(pay != null ? 'To\'langan' : 'Kutilmoqda', style),
                    ],
                  );
                }),
              ],
            ),
          ],
        ),
      );
    }).toList();
  }

  static pw.Widget _memberTable(SavingsGroup g, pw.TextStyle style) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
      columnWidths: {
        0: const pw.FlexColumnWidth(2),
        1: const pw.FlexColumnWidth(1.5),
        2: const pw.FlexColumnWidth(1.5),
        3: const pw.FlexColumnWidth(1),
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey200),
          children: [
            _cell('A\'zo', style, bold: true),
            _cell('Jami to\'lagan', style, bold: true),
            _cell('Pul olgan', style, bold: true),
            _cell('Navbat', style, bold: true),
          ],
        ),
        ...g.members.entries.map((e) {
          final paid = _memberTotalPaid(g, e.key);
          final received = _memberHasReceived(g, e.key);
          final pos = g.schedulePositionForMember(e.key);
          return pw.TableRow(
            children: [
              _cell(e.value.displayName, style),
              _cell(formatMoney(paid, g.settlementCurrency), style),
              _cell(received ? 'Ha' : 'Yo\'q', style),
              _cell(pos != null ? SavingsGroup.queueNumber(pos) : '—', style),
            ],
          );
        }),
      ],
    );
  }

  static int _memberTotalPaid(SavingsGroup g, String memberId) {
    var sum = 0;
    for (final periodMap in g.payments.values) {
      final entry = periodMap[memberId];
      if (entry != null) sum += g.settlementAmountFor(entry);
    }
    return sum;
  }

  static bool _memberHasReceived(SavingsGroup g, String memberId) =>
      g.hasReceivedFund(memberId);

  static String _paymentText(SavingsGroup g, PaymentEntry pay) {
    final native = formatMoney(pay.amount, pay.currency);
    if (pay.currency == g.settlementCurrency) return native;
    final eq = g.settlementAmountFor(pay);
    return '$native (${formatMoney(eq, g.settlementCurrency)})';
  }

  static pw.Widget _line(String label, String value, pw.TextStyle style) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.RichText(
        text: pw.TextSpan(
          children: [
            pw.TextSpan(
              text: '$label: ',
              style: style.copyWith(fontWeight: pw.FontWeight.bold),
            ),
            pw.TextSpan(text: value, style: style),
          ],
        ),
      ),
    );
  }

  static pw.Widget _cell(String text, pw.TextStyle style, {bool bold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(4),
      child: pw.Text(
        text,
        style: bold ? style.copyWith(fontWeight: pw.FontWeight.bold) : style,
      ),
    );
  }

  static String _formatDate(DateTime dt) {
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    return '$d.$m.${dt.year}';
  }

  static String fileNameFor(SavingsGroup group) {
    final safe = group.name.replaceAll(RegExp(r'[^\w\s-]'), '').trim();
    final slug = safe.isEmpty ? 'gap' : safe.replaceAll(' ', '_');
    return 'GAP_${slug}_hisobot.pdf';
  }

}
