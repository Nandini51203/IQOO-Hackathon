/// Callback interface implemented by the coordinator / GuardianService.
///
/// Member 1's detector calls these two methods and nothing else. It must
/// never reach into UI, SMS, GPS, or emergency-contact code directly
/// (build plan, Section 3 and Section 15).
abstract class TriggerListener {
  /// Fired once per confirmed fall event, after debounce logic has
  /// already guaranteed "one physical event -> one callback".
  void onFallDetected(double confidence);

  /// Fired for the optional/stretch active silent gesture trigger.
  /// Not required for the MVP (build plan, Section 2 and Section 15).
  void onGestureTriggered();
}
