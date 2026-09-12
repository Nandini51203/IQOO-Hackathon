import 'dart:async';

import 'package:flutter/material.dart';

import 'fall_detection_state.dart';
import 'fall_detector.dart';

/// Raw-data diagnostics view (build plan, Section 10), reached from a
/// small icon on the real interface rather than shown by default.
///
///   RAKSHASENSE — SENSOR DEBUG
///   Accelerometer: X / Y / Z
///   Acceleration magnitude
///   Gyroscope: X / Y / Z
///   Current state: NORMAL / FREE_FALL / IMPACT / ...
///   Current confidence
///   Last event timestamp
///
/// There is no SIMULATE FALL button here anymore — detection now runs
/// only on real accelerometer/gyroscope data. This screen exists so
/// the actual thresholds in `ThresholdConfig` can be tuned against real
/// device readings (Section 8, Section 16 Day 2), by reading the same
/// live [FallDetector] instance the main screen is running.
class SensorDebugScreen extends StatefulWidget {
  final FallDetector detector;

  const SensorDebugScreen({super.key, required this.detector});

  @override
  State<SensorDebugScreen> createState() => _SensorDebugScreenState();
}

class _SensorDebugScreenState extends State<SensorDebugScreen> {
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    if (!widget.detector.isRunning) {
      widget.detector.start();
    }
    // The detector doesn't emit a UI-facing stream on purpose (it only
    // talks to TriggerListener) — poll lightly to refresh the readout.
    _refreshTimer =
        Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  String _axisText(double? v) => v == null ? '--' : v.toStringAsFixed(2);

  String _stateLabel(FallDetectionState s) {
    switch (s) {
      case FallDetectionState.normal:
        return 'NORMAL';
      case FallDetectionState.freeFall:
        return 'FREE_FALL';
      case FallDetectionState.impact:
        return 'IMPACT';
      case FallDetectionState.orientationChanged:
        return 'ORIENTATION_CHANGED';
      case FallDetectionState.stillness:
        return 'STILLNESS';
      case FallDetectionState.confirmedFall:
        return 'CONFIRMED_FALL';
      case FallDetectionState.debounce:
        return 'DEBOUNCE';
    }
  }

  @override
  Widget build(BuildContext context) {
    final detector = widget.detector;
    final accel = detector.latestAccel;
    final gyro = detector.latestGyro;
    final lastTs = detector.lastEventTimestamp;

    return Scaffold(
      appBar: AppBar(title: const Text('RAKSHASENSE — SENSOR DEBUG')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionLabel('Accelerometer (X / Y / Z)'),
            Text(
              '${_axisText(accel?.x)}   ${_axisText(accel?.y)}   ${_axisText(accel?.z)}',
              style: _monoStyle,
            ),
            const SizedBox(height: 12),
            _sectionLabel('Acceleration magnitude'),
            Text(detector.latestAccMagnitude.toStringAsFixed(2),
                style: _monoStyle),
            const SizedBox(height: 12),
            _sectionLabel('Gyroscope (X / Y / Z)'),
            Text(
              '${_axisText(gyro?.x)}   ${_axisText(gyro?.y)}   ${_axisText(gyro?.z)}',
              style: _monoStyle,
            ),
            const SizedBox(height: 12),
            _sectionLabel('Current state'),
            Text(_stateLabel(detector.state), style: _monoStyle),
            const SizedBox(height: 12),
            _sectionLabel('Current confidence'),
            Text(detector.lastConfidence.toStringAsFixed(2),
                style: _monoStyle),
            const SizedBox(height: 12),
            _sectionLabel('Last event timestamp'),
            Text(lastTs?.toString() ?? '--', style: _monoStyle),
            const Spacer(),
            Text(
              'Live data only — walk, sit, climb stairs and log a safe '
              'simulated drop here while tuning ThresholdConfig.',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) => Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.grey,
          fontSize: 12,
        ),
      );

  static const _monoStyle = TextStyle(fontFamily: 'monospace', fontSize: 18);
}
