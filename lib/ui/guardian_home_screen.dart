import 'dart:async';

import 'package:flutter/material.dart';

import '../sensors/fall_detection_state.dart';
import '../sensors/fall_detector.dart';
import '../sensors/sensor_debug_screen.dart';
import '../shared/trigger_listener.dart';
import 'fall_alert_screen.dart';
import 'motion_wave_painter.dart';
import 'pulse_ring.dart';

/// The real, user-facing screen — what actually ships, instead of a
/// SIMULATE FALL debug button. It runs the genuine accelerometer/
/// gyroscope pipeline and reacts to a real `onFallDetected` callback by
/// opening [FallAlertScreen]. A raw-data diagnostics view is still
/// reachable (for tuning thresholds on the demo phone, Section 8/16 of
/// the build plan) but is no longer the primary interface.
class GuardianHomeScreen extends StatefulWidget {
  const GuardianHomeScreen({super.key});

  @override
  State<GuardianHomeScreen> createState() => _GuardianHomeScreenState();
}

class _GuardianHomeScreenState extends State<GuardianHomeScreen> {
  static const _navy = Color(0xFF121A2B);
  static const _amber = Color(0xFFF2A93B);
  static const _paper = Color(0xFFF5F1E8);
  static const _muted = Color(0xFF8792A6);

  late final FallDetector _detector;
  Timer? _uiTicker;
  bool _monitoring = false;
  bool _alertShowing = false;

  @override
  void initState() {
    super.initState();
    _detector = FallDetector(
      listener: _HomeTriggerListener(
        onFall: _handleFallDetected,
        onGesture: () {},
      ),
    );
  }

  @override
  void dispose() {
    _uiTicker?.cancel();
    _detector.stop();
    super.dispose();
  }

  void _handleFallDetected(double confidence) {
    if (!mounted || _alertShowing) return;
    _alertShowing = true;
    Navigator.of(context)
        .push(MaterialPageRoute(
          builder: (_) => FallAlertScreen(
            confidence: confidence,
            detectedAt: DateTime.now(),
            onDismiss: () => Navigator.of(context).pop(),
          ),
        ))
        .then((_) => _alertShowing = false);
  }

  void _toggleMonitoring() {
    setState(() {
      _monitoring = !_monitoring;
      if (_monitoring) {
        _detector.start();
        _uiTicker ??= Timer.periodic(const Duration(milliseconds: 150), (_) {
          if (mounted) setState(() {});
        });
      } else {
        _detector.stop();
      }
    });
  }

  _StatusInfo get _status {
    if (!_monitoring) {
      return const _StatusInfo(
        label: 'Monitoring is paused',
        subtitle: 'Turn it on before you head out.',
        intensity: 0.08,
      );
    }
    switch (_detector.state) {
      case FallDetectionState.normal:
        return const _StatusInfo(
          label: 'Watching for falls',
          subtitle: 'Everything looks normal.',
          intensity: 0.15,
        );
      case FallDetectionState.freeFall:
        return const _StatusInfo(
          label: 'Noticed a sudden drop in motion',
          subtitle: 'Checking what happens next.',
          intensity: 0.45,
        );
      case FallDetectionState.impact:
        return const _StatusInfo(
          label: 'Checking a sharp impact',
          subtitle: 'Looking for a change in orientation.',
          intensity: 0.6,
        );
      case FallDetectionState.orientationChanged:
        return const _StatusInfo(
          label: 'Confirming what happened',
          subtitle: 'Waiting to see if you move again.',
          intensity: 0.75,
        );
      case FallDetectionState.stillness:
        return const _StatusInfo(
          label: 'Waiting to see if you move',
          subtitle: 'Almost done checking.',
          intensity: 0.9,
        );
      case FallDetectionState.confirmedFall:
        return const _StatusInfo(
          label: 'Fall detected',
          subtitle: 'Opening the alert…',
          intensity: 1.0,
        );
      case FallDetectionState.debounce:
        return const _StatusInfo(
          label: 'Just checked in',
          subtitle: 'Resuming normal watch shortly.',
          intensity: 0.25,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = _status;
    final magnitudes =
        _detector.buffer.samples.map((s) => s.accMagnitude).toList();

    return Scaffold(
      backgroundColor: _navy,
      appBar: AppBar(
        backgroundColor: _navy,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'RakshaSense',
          style: TextStyle(
              color: _paper, fontWeight: FontWeight.w600, fontSize: 20),
        ),
        actions: [
          IconButton(
            tooltip: 'Diagnostics (for tuning on this device)',
            icon: const Icon(Icons.tune_rounded, color: _muted),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => SensorDebugScreen(detector: _detector),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            children: [
              const Spacer(flex: 3),
              PulseRing(color: _amber, intensity: status.intensity),
              const SizedBox(height: 36),
              Text(
                status.label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: _paper,
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                status.subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(color: _muted, fontSize: 14),
              ),
              const Spacer(flex: 2),
              SizedBox(
                height: 56,
                width: double.infinity,
                child: CustomPaint(
                  painter: MotionWavePainter(
                    magnitudes: magnitudes,
                    color: _amber.withOpacity(_monitoring ? 0.8 : 0.25),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _toggleMonitoring,
                  style: FilledButton.styleFrom(
                    backgroundColor: _monitoring ? _paper : _amber,
                    foregroundColor: _navy,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    _monitoring ? 'Pause monitoring' : 'Start monitoring',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(height: 28),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusInfo {
  final String label;
  final String subtitle;
  final double intensity;

  const _StatusInfo({
    required this.label,
    required this.subtitle,
    required this.intensity,
  });
}

/// Bridges the frozen [TriggerListener] contract to simple callbacks so
/// this screen can react to a *real* detection without touching
/// `lib/shared/` (build plan, Section 12: don't change shared/ unless
/// the team agrees).
class _HomeTriggerListener implements TriggerListener {
  final void Function(double confidence) onFall;
  final VoidCallback onGesture;

  _HomeTriggerListener({required this.onFall, required this.onGesture});

  @override
  void onFallDetected(double confidence) => onFall(confidence);

  @override
  void onGestureTriggered() => onGesture();
}
