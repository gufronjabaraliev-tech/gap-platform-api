import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/savings_group.dart';
import '../../providers/groups_provider.dart';
import '../../theme/gap_theme_extension.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/gap_sliding_text.dart';
import '../../widgets/member_avatar.dart';

/// GAP navbat — tasodifiy tartibni 2–3 soniya animatsiya bilan ko'rsatadi.
class FixedScheduleShuffleScreen extends StatefulWidget {
  const FixedScheduleShuffleScreen({super.key, this.firstReceiverId});

  final String? firstReceiverId;

  @override
  State<FixedScheduleShuffleScreen> createState() =>
      _FixedScheduleShuffleScreenState();
}

class _FixedScheduleShuffleScreenState extends State<FixedScheduleShuffleScreen>
    with TickerProviderStateMixin {
  static const _spinMs = 2800;

  late final AnimationController _pulseCtrl;
  bool _spinning = false;
  bool _saving = false;
  int _highlightIndex = 0;
  List<String> _previewOrder = [];
  List<String>? _finalOrder;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    WidgetsBinding.instance.addPostFrameCallback((_) => _startShuffle());
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseCtrl.dispose();
    super.dispose();
  }

  List<String> _computeOrder(SavingsGroup g) {
    final random = Random.secure();
    final ordered = <String>[];

    if (widget.firstReceiverId != null) {
      final first = widget.firstReceiverId!;
      final rest = g.members.keys.where((id) => id != first).toList();
      for (var i = rest.length - 1; i > 0; i--) {
        final j = random.nextInt(i + 1);
        final t = rest[i];
        rest[i] = rest[j];
        rest[j] = t;
      }
      ordered.addAll([first, ...rest]);
    } else {
      ordered.addAll(g.members.keys);
      for (var i = ordered.length - 1; i > 0; i--) {
        final j = random.nextInt(i + 1);
        final t = ordered[i];
        ordered[i] = ordered[j];
        ordered[j] = t;
      }
    }
    return ordered;
  }

  void _startShuffle() {
    final g = context.read<GroupsProvider>().activeGroup!;
    final members = g.members.keys.toList();
    if (members.isEmpty) return;

    final finalOrder = _computeOrder(g);
    setState(() {
      _spinning = true;
      _finalOrder = null;
      _previewOrder = List<String>.from(members);
    });

    final start = DateTime.now();
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 70), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      final elapsed = DateTime.now().difference(start).inMilliseconds;
      if (elapsed >= _spinMs) {
        t.cancel();
        setState(() {
          _previewOrder = finalOrder;
          _highlightIndex = 0;
          _finalOrder = finalOrder;
          _spinning = false;
        });
        return;
      }
      final shuffled = List<String>.from(members);
      for (var i = shuffled.length - 1; i > 0; i--) {
        final j = Random.secure().nextInt(i + 1);
        final tmp = shuffled[i];
        shuffled[i] = shuffled[j];
        shuffled[j] = tmp;
      }
      setState(() {
        _previewOrder = shuffled;
        _highlightIndex = Random.secure().nextInt(shuffled.length);
      });
    });
  }

  Future<void> _save() async {
    final order = _finalOrder;
    if (order == null || _saving) return;

    setState(() => _saving = true);
    final groups = context.read<GroupsProvider>();
    final err = await groups.createFixedSchedule(
      firstReceiverId: widget.firstReceiverId,
      predeterminedOrder: order,
    );
    if (!mounted) return;
    setState(() => _saving = false);

    if (err != null) {
      showGapSnackBar(context, err, isError: true);
      return;
    }
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final g = context.watch<GroupsProvider>().activeGroup!;
    final gap = context.gap;
    final cs = Theme.of(context).colorScheme;
    final order = _previewOrder;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              cs.primary.withValues(alpha: 0.12),
              cs.surface,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: _spinning || _saving
                          ? null
                          : () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_rounded),
                    ),
                    Expanded(
                      child: Text(
                        'Tasodifiy navbat',
                        style: Theme.of(context).textTheme.titleLarge,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  _spinning
                      ? 'Ishtirokchilar aralashtirilmoqda...'
                      : 'Navbat tayyor. Tasdiqlang yoki qayta aralashtiring.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: gap.mutedText, height: 1.4),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  itemCount: order.length,
                  itemBuilder: (context, i) {
                    final id = order[i];
                    final m = g.members[id]!;
                    final isHighlight = _spinning && _highlightIndex == i;
                    return AnimatedBuilder(
                      animation: _pulseCtrl,
                      builder: (context, child) {
                        final scale = isHighlight && _spinning
                            ? 1.0 + _pulseCtrl.value * 0.04
                            : 1.0;
                        return Transform.scale(
                          scale: scale,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 140),
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: isHighlight
                                  ? cs.primary.withValues(alpha: 0.85)
                                  : cs.primaryContainer.withValues(alpha: 0.55),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isHighlight
                                    ? cs.primary
                                    : cs.outline.withValues(alpha: 0.35),
                                width: isHighlight ? 2.5 : 1,
                              ),
                            ),
                            child: child,
                          ),
                        );
                      },
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor:
                                Colors.white.withValues(alpha: 0.25),
                            child: Text(
                              '${i + 1}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          MemberAvatar(
                            displayName: m.displayName,
                            member: m,
                            phone: m.phone,
                            linkedUserId: m.linkedUserId,
                            radius: 22,
                            backgroundColor:
                                Colors.white.withValues(alpha: 0.28),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: GapSlidingText(
                              text: m.displayName,
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: cs.onPrimaryContainer,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_finalOrder != null) ...[
                      FilledButton.icon(
                        onPressed: _saving ? null : _save,
                        icon: _saving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.check_rounded),
                        label: Text(_saving ? 'Saqlanmoqda...' : 'Navbatni saqlash'),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: _spinning || _saving ? null : _startShuffle,
                        icon: const Icon(Icons.shuffle_rounded),
                        label: const Text('Qayta aralashtirish'),
                      ),
                    ] else
                      FilledButton.icon(
                        onPressed: null,
                        icon: const Icon(Icons.shuffle_rounded),
                        label: const Text('Aralashtirilmoqda...'),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
