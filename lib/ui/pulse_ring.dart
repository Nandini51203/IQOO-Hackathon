import 'package:flutter/material.dart';

/// The calm, breathing ring at the centre of the real (non-debug)
/// interface. Its speed and brightness communicate the detector's
/// state without exposing any raw numbers — this is what the person
/// wearing/carrying the phone actually sees, not a developer tool.
///
/// [intensity] is 0.0 (fully at rest) to 1.0 (actively checking a
/// possible fall). Colour never changes here — only pace and
/// brightness — so the one alarm colour in the app (used in
/// `FallAlertScreen`) stays meaningful by being the only thing that's
/// ever truly red.
class PulseRing extends StatefulWidget {
  final Color color;
  final double intensity;
  final double size;
  final IconData icon;

  const PulseRing({
    super.key,
    required this.color,
    this.intensity = 0.15,
    this.size = 220,
    this.icon = Icons.shield_moon_outlined,
  });

  @override
  State<PulseRing> createState() => _PulseRingState();
}

class _PulseRingState extends State<PulseRing>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  Duration _durationFor(double intensity) => Duration(
        milliseconds: (2200 - intensity.clamp(0.0, 1.0) * 1500).round(),
      );

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: _durationFor(widget.intensity),
    )..repeat();
  }

  @override
  void didUpdateWidget(covariant PulseRing oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.intensity != widget.intensity) {
      _controller.duration = _durationFor(widget.intensity);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _ripple(double t, double phaseOffset, double baseOpacity) {
    final phase = (t + phaseOffset) % 1.0;
    final scale = 0.55 + phase * 0.45;
    final opacity = (1 - phase) * baseOpacity;
    return Opacity(
      opacity: opacity.clamp(0.0, 1.0),
      child: Transform.scale(
        scale: scale,
        child: Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: widget.color, width: 1.5),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final baseOpacity = 0.25 + widget.intensity.clamp(0.0, 1.0) * 0.45;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _controller.value;
        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              _ripple(t, 0.0, baseOpacity),
              _ripple(t, 0.33, baseOpacity),
              _ripple(t, 0.66, baseOpacity),
              Container(
                width: widget.size * 0.46,
                height: widget.size * 0.46,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.color.withOpacity(
                      0.65 + widget.intensity.clamp(0.0, 1.0) * 0.35),
                  boxShadow: [
                    BoxShadow(
                      color: widget.color.withOpacity(0.35),
                      blurRadius: 28,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Icon(
                  widget.icon,
                  color: const Color(0xFF121A2B),
                  size: widget.size * 0.2,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
