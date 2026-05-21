import 'package:flutter/material.dart';

/// Uzun matn sig‘masa, gorizontal slayd (marquee) — overflow xatosiz.
class GapSlidingText extends StatefulWidget {
  const GapSlidingText({
    super.key,
    required this.text,
    this.style,
    this.textAlign = TextAlign.start,
    this.velocity = 32,
    this.pauseDuration = const Duration(milliseconds: 1400),
  });

  final String text;
  final TextStyle? style;
  final TextAlign textAlign;
  final double velocity;
  final Duration pauseDuration;

  @override
  State<GapSlidingText> createState() => _GapSlidingTextState();
}

class _GapSlidingTextState extends State<GapSlidingText>
    with SingleTickerProviderStateMixin {
  AnimationController? _ctrl;
  double _distance = 0;
  bool _slides = false;
  double? _cachedWidth;
  String? _cachedText;

  @override
  void didUpdateWidget(GapSlidingText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      _cachedWidth = null;
      _cachedText = null;
    }
  }

  @override
  void dispose() {
    _ctrl?.dispose();
    super.dispose();
  }

  void _configure(double maxWidth, TextStyle style) {
    if (_cachedWidth == maxWidth && _cachedText == widget.text) return;
    _cachedWidth = maxWidth;
    _cachedText = widget.text;

    final painter = TextPainter(
      text: TextSpan(text: widget.text, style: style),
      maxLines: 1,
      textDirection: Directionality.of(context),
    )..layout(maxWidth: double.infinity);

    final gap = 20.0;
    final overflow = painter.width > maxWidth + 0.5;
    final distance = overflow ? painter.width - maxWidth + gap : 0.0;

    _ctrl?.dispose();
    _ctrl = null;
    _slides = overflow && distance > 0;
    _distance = distance;

    if (_slides) {
      final scrollMs =
          (distance / widget.velocity * 1000).round().clamp(600, 9000);
      final totalMs = scrollMs + widget.pauseDuration.inMilliseconds * 2;
      _ctrl = AnimationController(
        vsync: this,
        duration: Duration(milliseconds: totalMs),
      )..repeat();
    }

    if (mounted) setState(() {});
  }

  double _offsetFor(double t) {
    const pause = 0.14;
    const forwardEnd = 0.46;
    const holdEnd = 0.58;

    if (t < pause) return 0;
    if (t < forwardEnd) {
      final p = (t - pause) / (forwardEnd - pause);
      return _distance * Curves.easeInOut.transform(p);
    }
    if (t < holdEnd) return _distance;
    final p = (t - holdEnd) / (1 - holdEnd);
    return _distance * (1 - Curves.easeInOut.transform(p));
  }

  @override
  Widget build(BuildContext context) {
    final style = widget.style ?? DefaultTextStyle.of(context).style;

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxW = constraints.maxWidth;
        if (maxW.isFinite && maxW > 0) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _configure(maxW, style);
          });
        }

        if (!maxW.isFinite || maxW <= 0 || !_slides || _ctrl == null) {
          return Text(
            widget.text,
            style: style,
            textAlign: widget.textAlign,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          );
        }

        return ClipRect(
          child: SizedBox(
            width: maxW,
            child: AnimatedBuilder(
              animation: _ctrl!,
              builder: (context, _) {
                return Transform.translate(
                  offset: Offset(-_offsetFor(_ctrl!.value), 0),
                  child: Align(
                    alignment: _alignmentFor(widget.textAlign),
                    widthFactor: 1,
                    child: Text(
                      widget.text,
                      style: style,
                      maxLines: 1,
                      softWrap: false,
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Alignment _alignmentFor(TextAlign align) {
    switch (align) {
      case TextAlign.center:
        return Alignment.center;
      case TextAlign.end:
      case TextAlign.right:
        return Alignment.centerRight;
      default:
        return Alignment.centerLeft;
    }
  }
}
