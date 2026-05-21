import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/groups_provider.dart';
import '../../services/group_report_export.dart';
import '../../utils/money_format.dart';
import '../../theme/gap_theme_extension.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/gap_sliding_text.dart';
import '../../widgets/gap_group_scroll_body.dart';
import '../../widgets/group_header.dart';

class StatusScreen extends StatefulWidget {
  const StatusScreen({super.key});

  @override
  State<StatusScreen> createState() => _StatusScreenState();
}

class _StatusScreenState extends State<StatusScreen> {
  bool _exporting = false;

  Future<void> _exportPdf() async {
    final g = context.read<GroupsProvider>().activeGroup!;
    setState(() => _exporting = true);
    try {
      await GroupReportExportService.sharePdf(g);
      if (mounted) {
        showGapSnackBar(context, 'PDF tayyor — ulashish oynasini tanlang');
      }
    } catch (e) {
      if (mounted) {
        showGapSnackBar(context, 'PDF xatolik: $e', isError: true);
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final g = context.watch<GroupsProvider>().activeGroup!;
    final gap = context.gap;

    if (!g.isScheduleConfigured) {
      return Scaffold(
        body: GapGroupScrollBodyFill(
          header: const GroupHeader(),
          padding: const EdgeInsets.all(16),
          child: const Center(child: Text('Navbat yaratilmagan')),
        ),
      );
    }

    final receiverId = g.currentReceiverId;
    if (receiverId == null || !g.gapSessionActive) {
      return Scaffold(
        body: GapGroupScrollBody(
          header: const GroupHeader(),
          padding: const EdgeInsets.all(16),
          children: [
                  OutlinedButton.icon(
                    onPressed: _exporting ? null : _exportPdf,
                    icon: _exporting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.picture_as_pdf_outlined),
                    label: Text(
                      _exporting
                          ? 'PDF tayyorlanmoqda...'
                          : 'Hisobotni PDF yuklab olish',
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Jamg\'arma olganlar: ${g.membersWhoReceivedFund.length} / ${g.memberCount}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  ...g.membersWhoReceivedFund.map(
                    (id) => ListTile(
                      leading: const Icon(Icons.check_circle_rounded),
                      title: GapSlidingText(text: g.displayNameFor(id)),
                      subtitle: const Text('Jamg\'arma olgan'),
                    ),
                  ),
          ],
        ),
      );
    }

    final pct = (g.paymentProgress * 100).round();

    return Scaffold(
      body: GapGroupScrollBody(
        header: const GroupHeader(),
        padding: const EdgeInsets.all(16),
        children: [
                OutlinedButton.icon(
                  onPressed: _exporting ? null : _exportPdf,
                  icon: _exporting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.picture_as_pdf_outlined),
                  label: Text(
                    _exporting ? 'PDF tayyorlanmoqda...' : 'Hisobotni PDF yuklab olish',
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: gap.primaryGradient,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        g.currentPeriodLabel,
                        style: const TextStyle(color: Colors.white70),
                        softWrap: true,
                      ),
                      Text(
                        g.currentReceiverName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                        softWrap: true,
                      ),
                      const SizedBox(height: 16),
                      if (g.collectedRawText != null) ...[
                        Text(
                          'Asl: ${g.collectedRawText}',
                          style: const TextStyle(color: Colors.white, fontSize: 15),
                          softWrap: true,
                        ),
                        const SizedBox(height: 8),
                      ],
                      Text(
                        'Jami (${g.settlementCurrency.label}): '
                        '${formatMoney(g.collectedTotal, g.settlementCurrency)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        softWrap: true,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Maqsad (${g.currentReceiverReceiveCurrency.label}): '
                        '${formatMoney(g.expectedTotalForCurrentReceiver, g.currentReceiverReceiveCurrency)}',
                        style: const TextStyle(color: Colors.white70, fontSize: 16),
                        softWrap: true,
                      ),
                    ],
                  ),
                ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('To\'lov (${g.paidCount}/${g.payersCount})',
                            style: const TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        LinearProgressIndicator(value: g.paymentProgress),
                        Text('$pct%', textAlign: TextAlign.center),
                        const Divider(),
                          ...g.members.entries
                            .where((e) => e.key != receiverId)
                            .map((e) {
                          final pay = g.paymentFor(e.key);
                          return ListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            leading: Icon(
                              pay != null
                                  ? Icons.check_circle
                                  : Icons.circle_outlined,
                              color: pay != null ? gap.success : Colors.grey,
                            ),
                            title: GapSlidingText(text: e.value.displayName),
                            subtitle: Text(
                              g.currencyForMember(e.key).label,
                              style: const TextStyle(fontSize: 11),
                            ),
                            trailing: pay != null
                                ? Text(
                                    formatPaymentWithSettlement(g, pay),
                                    style: TextStyle(
                                      color: gap.success,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  )
                                : Text(
                                    formatMoney(
                                      g.recommendedAmountFor(e.key),
                                      g.currencyForMember(e.key),
                                    ),
                                    style: const TextStyle(fontSize: 12),
                                  ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),
        ],
      ),
    );
  }
}
