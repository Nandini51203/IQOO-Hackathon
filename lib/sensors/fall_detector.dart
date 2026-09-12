import 'dart:async';
import 'dart:math' as math;

import 'package:sensors_plus/sensors_plus.dart';

import '../models/sensor_sample.dart';
import '../shared/trigger_event.dart';
import '../shared/trigger_listener.dart';
import 'fall_detection_state.dart';
import 'sensor_data_buffer.dart';
import 'threshold_config.dart';

/// Owns the accelerometer/gyroscope subscriptions, the rolling buffer,
/// and the fall-detection state machine. Exposes exactly one thing to
/// the rest of the app: [TriggerListener.onFallDetected] /
/// [TriggerListener.onGestureTriggered] via [listener].
///
/// Nothing outside `lib/sensors/` should need to know how any of this
/// works internally (build plan, Section 3, Section 8, Section 15).
class FallDetector {
  final TriggerListener listener;
  final SensorDataBuffer buffer;

  FallDetector({required this.listener, SensorDataBuffer? buffer})
      : buffer = buffer ?? SensorDataBuffer();

  StreamSubscription<AccelerometerEvent>? _accelSub;
  StreamSubscription<GyroscopeEvent>? _gyroSub;
  Timer? _watchdogTimer;
  Timer? _debounceTimer;

  FallDetectionState _state = FallDetectionState.normal;
  FallDetectionState get state => _state;

  // Latest raw readings, kept only for the debug screen.
  AccelerometerEvent? latestAccel;
  GyroscopeEvent? latestGyro;
  double _latestAccMagnitude = 0;
  double _latestGyroMagnitude = 0;
  double get latestAccMagnitude => _latestAccMagnitude;
  double get latestGyroMagnitude => _latestGyroMagnitude;

  // Evidence accumulated across the current attempt, used for
  // confidence scoring once/if we reach CONFIRMED_FALL.
  double _freeFallEvidence = 0.0;
  double _impactEvidence = 0.0;
  double _rotationEvidence = 0.0;
  double _stillnessEvidence = 0.0;

  int? _freeFallStartedAt;
  int? _impactAt;
  int? _orientationChangedAt;
  int? _stillSince;

  double _lastConfidence = 0.0;
  double get lastConfidence => _lastConfidence;

  int? _lastEventTimestamp;
  int? get lastEventTimestamp => _lastEventTimestamp;

  bool _running = false;
  bool get isRunning => _running;

  /// Phase 1: subscribe to real device sensor streams.
  void start() {
    if (_running) return;
    _running = true;

    _accelSub = accelerometerEventStream().listen(_onAccelerometerEvent);
    _gyroSub = gyroscopeEventStream().listen(_onGyroscopeEvent);
  }

  void stop() {
    _running = false;
    _accelSub?.cancel();
    _gyroSub?.cancel();
    _watchdogTimer?.cancel();
    _debounceTimer?.cancel();
  }

  void _onAccelerometerEvent(AccelerometerEvent event) {
    latestAccel = event;
    _latestAccMagnitude = _magnitude(event.x, event.y, event.z);
    _pushSample();
    _evaluate();
  }

  void _onGyroscopeEvent(GyroscopeEvent event) {
    latestGyro = event;
    _latestGyroMagnitude = _magnitude(event.x, event.y, event.z);
    // Gyro doesn't drive its own sample push; it just updates the value
    // used the next time an accelerometer sample arrives, and it is
    // still checked live during IMPACT (see _evaluate).
  }

  double _magnitude(double x, double y, double z) =>
      math.sqrt(x * x + y * y + z * z);

  void _pushSample() {
    final now = DateTime.now().millisecondsSinceEpoch;
    buffer.add(SensorSample(
      timestamp: now,
      accMagnitude: _latestAccMagnitude,
      gyroMagnitude: _latestGyroMagnitude,
      ax: latestAccel?.x,
      ay: latestAccel?.y,
      az: latestAccel?.z,
      gx: latestGyro?.x,
      gy: latestGyro?.y,
      gz: latestGyro?.z,
    ));
  }

  /// Phase 3/4/5: the actual state machine. Runs once per accelerometer
  /// sample. Kept intentionally simple/explainable (Section 9).
  void _evaluate() {
    final now = DateTime.now().millisecondsSinceEpoch;

    switch (_state) {
      case FallDetectionState.normal:
        if (_latestAccMagnitude < ThresholdConfig.freeFallThreshold) {
          _state = FallDetectionState.freeFall;
          _freeFallStartedAt = now;
          _freeFallEvidence = _normalize(
            ThresholdConfig.freeFallThreshold - _latestAccMagnitude,
            0,
            ThresholdConfig.freeFallThreshold,
          );
        }
        break;

      case FallDetectionState.freeFall:
        final elapsed = now - (_freeFallStartedAt ?? now);
        if (elapsed > ThresholdConfig.maxImpactWindowMs) {
          _resetToNormal();
          break;
        }
        if (_latestAccMagnitude > ThresholdConfig.impactThreshold) {
          _state = FallDetectionState.impact;
          _impactAt = now;
          _impactEvidence = _normalize(
            _latestAccMagnitude - ThresholdConfig.impactThreshold,
            0,
            ThresholdConfig.impactThreshold, // rough scale
          );
        }
        break;

      case FallDetectionState.impact:
        final sinceImpact = now - (_impactAt ?? now);
        if (_latestGyroMagnitude > ThresholdConfig.gyroRotationThreshold) {
          _state = FallDetectionState.orientationChanged;
          _orientationChangedAt = now;
          _rotationEvidence = _normalize(
            _latestGyroMagnitude - ThresholdConfig.gyroRotationThreshold,
            0,
            ThresholdConfig.gyroRotationThreshold * 2,
          );
        } else if (sinceImpact > ThresholdConfig.orientationWindowMs) {
          // No clear rotation evidence within the window — fall through
          // to stillness anyway rather than getting stuck (documented
          // as a prototype simplification, not in the source plan).
          _rotationEvidence = 0.0;
          _state = FallDetectionState.orientationChanged;
          _orientationChangedAt = now;
        }
        break;

      case FallDetectionState.orientationChanged:
        _stillSince ??= now;
        final spread =
            buffer.accMagnitudeSpread(withinMs: now - (_stillSince ?? now) + 1);
        if (spread > ThresholdConfig.stillnessThreshold) {
          // Still moving — keep waiting, reset the still-since clock.
          _stillSince = now;
          break;
        }
        _state = FallDetectionState.stillness;
        break;

      case FallDetectionState.stillness:
        final spread = buffer.accMagnitudeSpread(
            withinMs: ThresholdConfig.stillnessDurationMs);
        if (spread > ThresholdConfig.stillnessThreshold) {
          // Movement resumed before stillness duration elapsed.
          _stillSince = now;
          _state = FallDetectionState.orientationChanged;
          break;
        }
        final stillFor = now - (_stillSince ?? now);
        if (stillFor >= ThresholdConfig.stillnessDurationMs) {
          _stillnessEvidence = 1.0 -
              _normalize(spread, 0, ThresholdConfig.stillnessThreshold);
          _confirmFall(simulated: false);
        }
        break;

      case FallDetectionState.confirmedFall:
        // Transitional only — _confirmFall() moves straight to debounce.
        break;

      case FallDetectionState.debounce:
        // Ignore everything until the debounce timer fires.
        break;
    }
  }

  double _normalize(double value, double min, double max) {
    if (max <= min) return 0.0;
    return ((value - min) / (max - min)).clamp(0.0, 1.0);
  }

  /// Phase 4: confidence scoring (Section 9). Weighted, explainable,
  /// and clamped to 0.0-1.0. No Low/Medium/High mapping here — that
  /// belongs to the decision/UI layer.
  double _computeConfidence() {
    final raw = 0.25 * _freeFallEvidence +
        0.30 * _impactEvidence +
        0.20 * _rotationEvidence +
        0.25 * _stillnessEvidence;
    return raw.clamp(0.0, 1.0);
  }

  /// Fires the single downstream callback for a confirmed fall, then
  /// moves into DEBOUNCE. Used by both the real state machine and
  /// [simulateFall], so a manual trigger exercises exactly the same
  /// path a real detection would (build plan, Section 6 Phase 6 and
  /// Section 10).
  void _confirmFall({required bool simulated}) {
    final now = DateTime.now().millisecondsSinceEpoch;
    _lastConfidence = simulated ? 0.9 : _computeConfidence();
    _lastEventTimestamp = now;
    _state = FallDetectionState.confirmedFall;

    listener.onFallDetected(_lastConfidence);
    // ignore: unused_local_variable
    final event = TriggerEvent(
      type: TriggerType.fall,
      confidence: _lastConfidence,
      timestamp: now,
    );
    // `event` is what the coordinator/GuardianService builds from the
    // callback above; kept here only to show the shape of the handoff.

    _state = FallDetectionState.debounce;
    _debounceTimer?.cancel();
    _debounceTimer = Timer(
      Duration(milliseconds: ThresholdConfig.debounceDurationMs),
      _resetToNormal,
    );
  }

  void _resetToNormal() {
    _state = FallDetectionState.normal;
    _freeFallStartedAt = null;
    _impactAt = null;
    _orientationChangedAt = null;
    _stillSince = null;
    _freeFallEvidence = 0.0;
    _impactEvidence = 0.0;
    _rotationEvidence = 0.0;
    _stillnessEvidence = 0.0;
  }

  /// Phase 6: manual trigger for the debug screen's SIMULATE FALL
  /// button. Must produce the same callback path as a real detection —
  /// so it reuses [_confirmFall] rather than a separate code path.
  void simulateFall() {
    if (_state == FallDetectionState.debounce) return;
    _confirmFall(simulated: true);
  }
}
