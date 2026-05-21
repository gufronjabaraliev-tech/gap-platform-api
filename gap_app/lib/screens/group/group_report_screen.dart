import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/savings_group.dart';
import '../../providers/groups_provider.dart';
import '../../services/group_report_export.dart';
import '../../theme/gap_theme_extension.dart';
import '../../utils/money_format.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/gap_card.dart';
import '../../widgets/gap_sliding_text.dart';
import '../../widgets/gap_group_scroll_body.dart';
import '../../widgets/gap_hero_header.dart';

/// Yopilgan jamg'arma hisoboti (faqat ko'rish).
class GroupReportScreen extends StatefulWidget {
  const GroupReportScreen({super.key});

  @override
  State<GroupReportScreen> createState() => _GroupReportScreenState();
}

class _GroupReportScreenState extends State<GroupReportScreen> {
  bool _exporting = false;

  Future<void> _exportPdf() async {
    final g = context.read<GroupsProvider>().activeGroup;
    if (g == null) return;
    setState(() => _exporting = true);
    try {
      await GroupReportExportService.sharePdf(g);
      if (mounted) {
        showGapSnackBar(
          context,
          'PDF tayyor — «Saqlash» yoki ulashish ilovasini tanlang',
        );
      }
    } catch (e) {
      if (mounted) {
        showGapSnackBar(
          context,
          'PDF yuklab bo\'lmadi: $e',
          isError: true,
        );
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final g = context.watch<GroupsProvider>().activeGroup!;
    final gap = context.gap;
    final cs = Theme.of(context).colorScheme;
    final periods = g.reportPeriodIndexes;

    return Scaffold(
      body: GapGroupScrollBody(
        header: GapHeroHeader(
          title: g.name,
          subtitle: g.isClosed
              ? 'Yopilgan · ${_formatDate(g.closedAt ?? DateTime.now())}'
              : 'Hisobot',
          leading: IconButton(
            onPressed: () => Navigator.of(context).pop(),
            style: IconButton.styleFrom(
              backgroundColor: gap.glassOverlay,
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          bottom: Row(
            children: [
              GapHeroChip(
                icon: Icons.archive_rounded,
                label: g.isClosed ? 'YOPILGAN' : 'HISOBOT',
              ),
              const SizedBox(width: 8),
              GapHeroChip(
                icon: Icons.people_rounded,
                label: '${g.memberCount} a\'zo',
              ),
            ],
          ),
        ),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        children: [
                GapCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Umumiy', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      _InfoRow('Davr', g.cycleType.label),
                      _InfoRow(
                        'Summa',
                        formatMoney(g.periodAmount, g.settlementCurrency),
                      ),
                      _InfoRow('Navbat', g.scheduleMode.label),
                      _InfoRow('Valyuta', g.settlementCurrency.label),
                      if (g.isClosed && g.closedAt != null)
                        _InfoRow('Yopilgan', _formatDate(g.closedAt!)),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                ...periods.map((p) => _PeriodCard(group: g, period: p)),
                const SizedBox(height: 12),
                Text('A\'zolar', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                ...g.members.entries.map(
                  (e) => _MemberSummaryTile(group: g, memberId: e.key),
                ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _exporting ? null : _exportPdf,
        icon: _exporting
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.picture_as_pdf_rounded),
        label: Text(_exporting ? 'Tayyorlanmoqda...' : 'PDF yuklab olish'),
        backgroundColor: cs.primary,
      ),
    );
  }

  static String _formatDate(DateTime dt) {
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    return '$d.$m.${dt.year}';
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final gap = context.gap;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(label, style: TextStyle(color: gap.mutedText, fontSize: 13)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

class _PeriodCard extends StatelessWidget {
  const _PeriodCard({required this.group, required this.period});
  final SavingsGroup group;
  final int period;

  @override
  Widget build(BuildContext context) {
    final gap = context.gap;
    final receiver = group.receiverForPeriod(period);
    final pmap = group.payments['$period'] ?? {};
    final collected = pmap.values.fold<int>(
      0,
      (s, e) => s + group.settlementAmountFor(e),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GapCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              group.periodLabelFor(period),
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
            Text(
              'Oluvchi: ${receiver != null ? group.displayNameFor(receiver) : '—'}',
              style: TextStyle(color: gap.mutedText),
            ),
            const SizedBox(height: 4),
            Text(
              'Yig\'ildi: ${formatMoney(collected, group.settlementCurrency)}',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const Divider(height: 20),
            ...group.members.entries.where((e) => e.key != receiver).map((e) {
              final pay = pmap[e.key];
              return ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  pay != null ? Icons.check_circle : Icons.circle_outlined,
                  color: pay != null ? gap.success : Colors.grey,
                  size: 22,
                ),
                title: GapSlidingText(text: e.value.displayName),
                trailing: Text(
                  pay != null
                      ? formatPaymentWithSettlement(group, pay)
                      : formatMoney(
                          group.recommendedAmountFor(e.key),
                          group.currencyForMember(e.key),
                        ),
                  style: TextStyle(
                    fontSize: 12,
                    color: pay != null ? gap.success : gap.mutedText,
                    fontWeight: pay != null ? FontWeight.w700 : FontWeight.normal,
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _MemberSummaryTile extends StatelessWidget {
  const _MemberSummaryTile({required this.group, required this.memberId});
  final SavingsGroup group;
  final String memberId;

  @override
  Widget build(BuildContext context) {
    final gap = context.gap;
    var paid = 0;
    for (final periodMap in group.payments.values) {
      final entry = periodMap[memberId];
      if (entry != null) paid += group.settlementAmountFor(entry);
    }
    final received = group.hasReceivedFund(memberId);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GapCard(
        child: ListTile(
          contentPadding: EdgeInsets.zero,
          title: GapSlidingText(text: group.displayNameFor(memberId)),
          subtitle: Text(
            'To\'lagan: ${formatMoney(paid, group.settlementCurrency)}'
            '${received ? ' · Pul olgan' : ''}',
            style: TextStyle(color: gap.mutedText, fontSize: 12),
          ),
        ),
      ),
    );
  }
}
