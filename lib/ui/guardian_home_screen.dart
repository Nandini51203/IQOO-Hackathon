import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../config/checkin_config.dart';
import '../escalation/escalation_manager.dart';
import '../models/situation_data.dart';
import '../screens/check_in_screen.dart';
import '../sensors/fall_detection_state.dart';
import '../sensors/fall_detector.dart';
import '../sensors/sensor_debug_screen.dart';
import '../services/native_sms_service.dart';
import '../shared/trigger_listener.dart';
import 'motion_wave_painter.dart';
import 'pulse_ring.dart';

/// Main user-facing RakshaSense screen.
///
/// Integration flow:
///
/// FallDetector
///      ↓
/// CONFIRMED_FALL
///      ↓
/// CheckInScreen
///      ↓
/// ┌─────────────┬──────────────┐
/// │ I'M OKAY    │ TIMEOUT      │
/// │             │              │
/// │ Resume      │ Escalation   │
/// │ monitoring │ Manager      │
/// └─────────────┴──────────────┘
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
  bool _checkInShowing = false;

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

  // ------------------------------------------------------------
  // FALL DETECTED → CHECK-IN
  // ------------------------------------------------------------

  void _handleFallDetected(double confidence) {
    if (!mounted || _checkInShowing) {
      return;
    }

    _checkInShowing = true;

    final confidencePercent = (confidence * 100).round();

    Navigator.of(context)
        .push(
      MaterialPageRoute(
        builder: (_) => CheckInScreen(
          countdownSeconds: CheckInConfig.countdownSeconds,
          situationData: SituationData(
            situation: 'Possible fall detected',
            confidence: '$confidencePercent%',
            time: DateTime.now(),
            triggerType: 'Automatic fall detection',
          ),

          // ------------------------------------------------
          // USER DID NOT RESPOND
          // ------------------------------------------------

          onTimeout: () async {
            EscalationManager.trigger(context);
          },

          // ------------------------------------------------
          // USER CONFIRMED SAFE
          // ------------------------------------------------

          onConfirmSafe: () {
            if (!_monitoring) {
              _startMonitoring();
            }
          },
        ),
      ),
    )
        .then((_) {
      _checkInShowing = false;
    });
  }

  // ------------------------------------------------------------
  // MONITORING
  // ------------------------------------------------------------
  Future<void> _startMonitoring() async {
    if (_monitoring) return;

    // Request SMS permission before monitoring starts.
    // This is important because the user may be unconscious
    // when an emergency escalation happens.
    final smsPermission =
    await NativeSmsService.requestPermission();

    if (!mounted) return;

    if (!smsPermission) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'SMS permission is required for automatic emergency alerts.',
          ),
        ),
      );
      return;
    }

    // Request location permission before monitoring starts.
    LocationPermission locationPermission =
    await Geolocator.checkPermission();

    if (locationPermission == LocationPermission.denied) {
      locationPermission =
      await Geolocator.requestPermission();
    }

    if (!mounted) return;

    if (locationPermission == LocationPermission.denied ||
        locationPermission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Location permission is required for emergency location sharing.',
          ),
        ),
      );
      return;
    }

    // All required permissions are available.
    setState(() {
      _monitoring = true;
    });

    _detector.start();

    _uiTicker?.cancel();

    _uiTicker = Timer.periodic(
      const Duration(milliseconds: 120),
          (_) {
        if (!mounted) return;

        setState(() {});
      },
    );
  }

  void _stopMonitoring() {
    if (!_monitoring) {
      return;
    }

    setState(() {
      _monitoring = false;
    });

    _detector.stop();
  }

  void _toggleMonitoring() {
    if (_monitoring) {
      _stopMonitoring();
    } else {
      _startMonitoring();
    }
  }

  // ------------------------------------------------------------
  // STATUS
  // ------------------------------------------------------------

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
          subtitle: 'Opening safety check-in.',
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
            color: _paper,
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Diagnostics',
            icon: const Icon(
              Icons.tune_rounded,
              color: _muted,
            ),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => SensorDebugScreen(
                    detector: _detector,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            children: [
              const Spacer(flex: 3),

              PulseRing(
                color: _amber,
                intensity: status.intensity,
              ),

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
                style: const TextStyle(
                  color: _muted,
                  fontSize: 14,
                ),
              ),

              const Spacer(flex: 2),

              SizedBox(
                height: 56,
                width: double.infinity,
                child: CustomPaint(
                  painter: MotionWavePainter(
                    magnitudes: magnitudes,
                    color: _amber.withOpacity(
                      _monitoring ? 0.8 : 0.25,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 28),

              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _toggleMonitoring,
                  style: FilledButton.styleFrom(
                    backgroundColor:
                    _monitoring ? _paper : _amber,
                    foregroundColor: _navy,
                    padding: const EdgeInsets.symmetric(
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    _monitoring
                        ? 'Pause monitoring'
                        : 'Start monitoring',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
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

/// Bridges the Member 1 sensor contract to the main UI.
class _HomeTriggerListener implements TriggerListener {
  final void Function(double confidence) onFall;
  final VoidCallback onGesture;

  _HomeTriggerListener({
    required this.onFall,
    required this.onGesture,
  });

  @override
  void onFallDetected(double confidence) {
    onFall(confidence);
  }

  @override
  void onGestureTriggered() {
    onGesture();
  }
}