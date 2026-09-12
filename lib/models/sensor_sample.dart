/// Internal representation of one moment of motion data, built from
/// whatever the underlying sensor package (sensors_plus) hands us.
///
/// The detector never talks to `AccelerometerEvent` / `GyroscopeEvent`
/// directly outside of `FallDetector` — everything downstream of the
/// stream subscriptions works with `SensorSample` so the detector logic
/// stays independent of the sensor package (build plan, Section 4).
class SensorSample {
  /// Milliseconds since epoch.
  final int timestamp;

  /// sqrt(ax^2 + ay^2 + az^2), in m/s^2 (includes gravity, ~9.8 at rest).
  final double accMagnitude;

  /// sqrt(gx^2 + gy^2 + gz^2), in rad/s.
  final double gyroMagnitude;

  // Raw axes are optional — kept for debugging / future tuning, not
  // required by the core state machine.
  final double? ax;
  final double? ay;
  final double? az;
  final double? gx;
  final double? gy;
  final double? gz;

  const SensorSample({
    required this.timestamp,
    required this.accMagnitude,
    required this.gyroMagnitude,
    this.ax,
    this.ay,
    this.az,
    this.gx,
    this.gy,
    this.gz,
  });

  @override
  String toString() =>
      'SensorSample(t: $timestamp, acc: ${accMagnitude.toStringAsFixed(2)}, '
      'gyro: ${gyroMagnitude.toStringAsFixed(2)})';
}
