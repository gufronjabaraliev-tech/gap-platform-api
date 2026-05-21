import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/groups_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/gap_theme_extension.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/gap_sliding_text.dart';
import '../../widgets/member_avatar.dart';

/// Har bir ishtirokchi uchun barqaror rang (qayta chizilganda o'zgarmaydi).
class _PickCardStyle {
  const _PickCardStyle(this.top, this.bottom);

  final Color top;
  final Color bottom;

  LinearGradient gradient({double brighten = 0}) {
    if (brighten <= 0) {
      return LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [top, bottom],
      );
    }
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color.lerp(top, Colors.white, brighten)!,
        Color.lerp(bottom, Colors.white, brighten)!,
      ],
    );
  }

  static final List<_PickCardStyle> _light = [
    const _PickCardStyle(Color(0xFF047857), Color(0xFF064E3B)),
    const _PickCardStyle(Color(0xFF0D9488), Color(0xFF0F766E)),
    const _PickCardStyle(Color(0xFF2563EB), Color(0xFF1E40AF)),
    const _PickCardStyle(Color(0xFF7C3AED), Color(0xFF5B21B6)),
    const _PickCardStyle(Color(0xFFDB2777), Color(0xFF9D174D)),
    const _PickCardStyle(Color(0xFFEA580C), Color(0xFFC2410C)),
    const _PickCardStyle(Color(0xFFCA8A04), Color(0xFF92400E)),
    const _PickCardStyle(Color(0xFF16A34A), Color(0xFF166534)),
    const _PickCardStyle(Color(0xFF0891B2), Color(0xFF155E75)),
    const _PickCardStyle(Color(0xFF4F46E5), Color(0xFF3730A3)),
  ];

  static final List<_PickCardStyle> _dark = [
    const _PickCardStyle(Color(0xFF10B981), Color(0xFF047857)),
    const _PickCardStyle(Color(0xFF2DD4BF), Color(0xFF0F766E)),
    const _PickCardStyle(Color(0xFF60A5FA), Color(0xFF1D4ED8)),
    const _PickCardStyle(Color(0xFFA78BFA), Color(0xFF6D28D9)),
    const _PickCardStyle(Color(0xFFF472B6), Color(0xFFBE185D)),
    const _PickCardStyle(Color(0xFFFB923C), Color(0xFFC2410C)),
    const _PickCardStyle(Color(0xFFFBBF24), Color(0xFFB45309)),
    const _PickCardStyle(Color(0xFF4ADE80), Color(0xFF15803D)),
    const _PickCardStyle(Color(0xFF22D3EE), Color(0xFF0E7490)),
    const _PickCardStyle(Color(0xFF818CF8), Color(0xFF4338CA)),
  ];

  static _PickCardStyle forMember(String memberId, bool isDark) {
    final palette = isDark ? _dark : _light;
    final i = memberId.hashCode.abs() % palette.length;
    return palette[i];
  }
}

/// Har gal tasodifiy — animatsiyali tanlash ekrani.
class RandomPickScreen extends StatefulWidget {
  const RandomPickScreen({super.key});

  @override
  State<RandomPickScreen> createState() => _RandomPickScreenState();
}

class _RandomPickScreenState extends State<RandomPickScreen>
    with TickerProviderStateMixin {
  static const _spinMs = 2800;

  late final AnimationController _pulseCtrl;
  late final AnimationController _celebrateCtrl;
  bool _spinning = false;
  int _highlightIndex = 0;
  String? _winnerId;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _celebrateCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseCtrl.dispose();
    _celebrateCtrl.dispose();
    super.dispose();
  }

  Future<void> _spin(List<String> eligible) async {
    if (_spinning || eligible.isEmpty) return;
    setState(() {
      _spinning = true;
      _winnerId = null;
    });

    final winnerIndex = Random.secure().nextInt(eligible.length);
    final winner = eligible[winnerIndex];
    final start = DateTime.now();

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 65), (t) async {
      if (!mounted) {
        t.cancel();
        return;
      }
      final elapsed = DateTime.now().difference(start).inMilliseconds;
      if (elapsed < _spinMs) {
        setState(() {
          _highlightIndex = Random.secure().nextInt(eligible.length);
        });
        return;
      }

      t.cancel();
      final groups = context.read<GroupsProvider>();
      final err = await groups.pickRandomReceiver(memberId: winner);
      if (!mounted) return;
      if (err != null) {
        setState(() => _spinning = false);
        showGapSnackBar(context, err, isError: true);
        return;
      }

      setState(() {
        _highlightIndex = winnerIndex;
        _winnerId = winner;
        _spinning = false;
      });
      _celebrateCtrl.forward(from: 0);
    });
  }

  @override
  Widget build(BuildContext context) {
    final g = context.watch<GroupsProvider>().activeGroup!;
    final gap = context.gap;
    final cs = Theme.of(context).colorScheme;
    final eligible = g.eligibleReceiverIds;

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
                      onPressed: _spinning ? null : () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_rounded),
                    ),
                    Expanded(
                      child: Text(
                        'Tasodifiy tanlash',
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
                  'Hali pul olmagan ishtirokchilardan bittasi tasodifiy tanlanadi.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: gap.mutedText, height: 1.4),
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: eligible.isEmpty
                    ? Center(
                        child: Text(
                          'Barcha ishtirokchilar allaqachon pul olgan.',
                          style: TextStyle(color: gap.mutedText),
                        ),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                          childAspectRatio: eligible.length <= 3 ? 0.78 : 0.72,
                        ),
                        itemCount: eligible.length,
                        itemBuilder: (context, i) {
                          final id = eligible[i];
                          final m = g.members[id]!;
                          final isHighlight = _highlightIndex == i;
                          final isWinner = _winnerId == id;
                          final isDark =
                              Theme.of(context).brightness == Brightness.dark;
                          final cardStyle = _PickCardStyle.forMember(id, isDark);

                          return AnimatedBuilder(
                            animation: Listenable.merge([
                              _pulseCtrl,
                              _celebrateCtrl,
                            ]),
                            builder: (context, child) {
                              var scale = 1.0;
                              if (isWinner && _celebrateCtrl.isAnimating) {
                                scale = 1.0 +
                                    Curves.elasticOut.transform(
                                      _celebrateCtrl.value,
                                    ) *
                                    0.12;
                              } else if (isHighlight && _spinning) {
                                scale = 1.0 + _pulseCtrl.value * 0.08;
                              }

                              final glow = isWinner || isHighlight;
                              final brighten =
                                  isWinner ? 0.18 : (isHighlight ? 0.12 : 0.0);

                              return Transform.scale(
                                scale: scale,
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 140),
                                  curve: Curves.easeOutCubic,
                                  decoration: BoxDecoration(
                                    gradient: cardStyle.gradient(
                                      brighten: brighten,
                                    ),
                                    borderRadius: BorderRadius.circular(22),
                                    border: Border.all(
                                      color: isWinner
                                          ? AppColors.gold
                                          : isHighlight
                                              ? Colors.white
                                              : Colors.white.withValues(
                                                  alpha: 0.22,
                                                ),
                                      width: isWinner
                                          ? 3.5
                                          : isHighlight
                                              ? 2.5
                                              : 1,
                                    ),
                                    boxShadow: glow
                                        ? [
                                            BoxShadow(
                                              color: (isWinner
                                                      ? AppColors.gold
                                                      : cardStyle.top)
                                                  .withValues(alpha: 0.55),
                                              blurRadius: isWinner ? 22 : 14,
                                              spreadRadius: isWinner ? 1 : 0,
                                              offset: const Offset(0, 8),
                                            ),
                                          ]
                                        : [
                                            BoxShadow(
                                              color: cardStyle.bottom
                                                  .withValues(alpha: 0.35),
                                              blurRadius: 10,
                                              offset: const Offset(0, 5),
                                            ),
                                          ],
                                  ),
                                  child: child,
                                ),
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 16,
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  DecoratedBox(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white.withValues(
                                          alpha: 0.85,
                                        ),
                                        width: 2.5,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(
                                            alpha: 0.2,
                                          ),
                                          blurRadius: 8,
                                          offset: const Offset(0, 3),
                                        ),
                                      ],
                                    ),
                                    child: MemberAvatar(
                                      displayName: m.displayName,
                                      member: m,
                                      phone: m.phone,
                                      linkedUserId: m.linkedUserId,
                                      radius: eligible.length <= 3 ? 36 : 32,
                                      backgroundColor:
                                          Colors.white.withValues(alpha: 0.28),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  GapSlidingText(
                                    text: m.displayName,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 15,
                                      color: Colors.white,
                                      letterSpacing: -0.2,
                                    ),
                                  ),
                                  if (isWinner) ...[
                                    const SizedBox(height: 8),
                                    Icon(
                                      Icons.emoji_events_rounded,
                                      color: AppColors.gold,
                                      size: 30,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
              if (_winnerId != null) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                  child: Text(
                    'Tanlandi: ${g.displayNameFor(_winnerId!)}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: cs.primary,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                child: FilledButton.icon(
                  onPressed: eligible.isEmpty || _spinning
                      ? null
                      : _winnerId != null
                          ? () => Navigator.pop(context, true)
                          : () => _spin(eligible),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(double.infinity, 52),
                  ),
                  icon: Icon(
                    _winnerId != null
                        ? Icons.check_rounded
                        : Icons.casino_rounded,
                  ),
                  label: Text(
                    _spinning
                        ? 'Tanlanmoqda...'
                        : _winnerId != null
                            ? 'Tayyor'
                            : 'Tasodifiy tanlash',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
