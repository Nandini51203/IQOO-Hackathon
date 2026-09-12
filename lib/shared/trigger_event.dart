/// Shared contract between Member 1 (Sensor & Trigger Engine) and the
/// rest of RakshaSense (Member 2 / decision layer, Member 3 / UI).
///
/// FREEZE THIS FILE before building on top of it. If the contract needs
/// to change, coordinate with the team first (see build plan, Section 5
/// and Section 12).
library;

/// The kind of trigger raised by the sensor layer.
enum TriggerType { fall, gesture }

/// Immutable event handed off from the sensor layer to the rest of the
/// app. Member 1 only ever *creates* these; downstream code consumes
/// them without needing to know how detection works internally.
class TriggerEvent {
  final TriggerType type;

  /// Confidence in the range 0.0–1.0. The original Kotlin plan used a
  /// `Float`; in Dart we use `double` while preserving the same meaning
  /// and range.
  final double confidence;

  /// Milliseconds since epoch (`DateTime.now().millisecondsSinceEpoch`).
  final int timestamp;

  const TriggerEvent({
    required this.type,
    required this.confidence,
    required this.timestamp,
  }) : assert(confidence >= 0.0 && confidence <= 1.0,
            'confidence must be clamped to 0.0-1.0 before creating a TriggerEvent');

  @override
  String toString() =>
      'TriggerEvent(type: $type, confidence: ${confidence.toStringAsFixed(2)}, '
      'timestamp: $timestamp)';
}
