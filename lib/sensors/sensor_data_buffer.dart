import 'dart:collection';
import 'dart:math' as math;

import '../models/sensor_sample.dart';
import 'threshold_config.dart';

/// Rolling window of the most recent ~1-2 seconds of sensor samples.
///
/// The detector should never make a decision off a single sample —
/// everything (impact spikes, stillness, debugging) reads from this
/// buffer instead (build plan, Section 6, Phase 2).
class SensorDataBuffer {
  final int windowMs;
  final Queue<SensorSample> _samples = Queue<SensorSample>();

  SensorDataBuffer({this.windowMs = ThresholdConfig.bufferWindowMs});

  /// Adds a sample and evicts anything older than [windowMs].
  void add(SensorSample sample) {
    _samples.addLast(sample);
    _evictOlderThan(sample.timestamp);
  }

  void _evictOlderThan(int now) {
    while (_samples.isNotEmpty &&
        now - _samples.first.timestamp > windowMs) {
      _samples.removeFirst();
    }
  }

  /// Read-only snapshot of the current window, oldest first.
  List<SensorSample> get samples => List.unmodifiable(_samples);

  bool get isEmpty => _samples.isEmpty;

  SensorSample? get latest => _samples.isEmpty ? null : _samples.last;

  double get averageAccMagnitude {
    if (_samples.isEmpty) return 0;
    return _samples.map((s) => s.accMagnitude).reduce((a, b) => a + b) /
        _samples.length;
  }

  double get maxAccMagnitude {
    if (_samples.isEmpty) return 0;
    return _samples.map((s) => s.accMagnitude).reduce(math.max);
  }

  /// Simple spread (max - min) of acceleration magnitude over the
  /// window, used as a cheap stand-in for variance when deciding
  /// whether the phone has gone still after an impact.
  double accMagnitudeSpread({int? withinMs}) {
    final relevant = withinMs == null
        ? _samples
        : _samples.where((s) =>
            (_samples.last.timestamp - s.timestamp) <= withinMs);
    if (relevant.isEmpty) return 0;
    final mags = relevant.map((s) => s.accMagnitude);
    return mags.reduce(math.max) - mags.reduce(math.min);
  }

  void clear() => _samples.clear();
}
