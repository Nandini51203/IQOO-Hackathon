/// All tunable detection values live here, and nowhere else.
///
/// These are STARTER values for development, not claims of medical or
/// statistical accuracy (build plan, Section 8). Re-tune every constant
/// here using real logged movement / fall-like events captured on the
/// actual demo phone before the final demo.
class ThresholdConfig {
  // --- Acceleration magnitude thresholds (m/s^2, gravity ~9.8) ---

  /// Below this during NORMAL -> transition to FREE_FALL.
  static const double freeFallThreshold = 3.5;

  /// Above this during FREE_FALL -> transition to IMPACT.
  static const double impactThreshold = 20.0;

  // --- Gyroscope threshold (rad/s) ---

  /// Above this during IMPACT -> supports ORIENTATION_CHANGED.
  static const double gyroRotationThreshold = 2.0;

  // --- Stillness ---

  /// Acceleration-magnitude variation below this counts as "still".
  static const double stillnessThreshold = 0.5;

  /// How long stillness must hold before CONFIRMED_FALL fires.
  static const int stillnessDurationMs = 1500;

  // --- Timing windows ---

  /// FREE_FALL must be followed by an impact spike within this window,
  /// or the state machine resets to NORMAL.
  static const int maxImpactWindowMs = 1000;

  /// After IMPACT, how long we wait for rotation evidence before
  /// falling through to STILLNESS anyway (keeps the machine from
  /// getting stuck if the phone doesn't visibly reorient).
  static const int orientationWindowMs = 500;

  /// After a CONFIRMED_FALL, ignore further detections for this long.
  static const int debounceDurationMs = 3000;

  // --- Rolling buffer ---

  /// Rolling window length used for buffering + stillness checks.
  static const int bufferWindowMs = 2000;
}
