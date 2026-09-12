/// The prototype fall-detection state machine (build plan, Section 7).
///
/// NORMAL -> FREE_FALL -> IMPACT -> ORIENTATION_CHANGED -> STILLNESS
/// -> CONFIRMED_FALL -> DEBOUNCE -> NORMAL
///
/// This is a conceptual state machine for the prototype, not a
/// medically validated model.
enum FallDetectionState {
  normal,
  freeFall,
  impact,
  orientationChanged,
  stillness,
  confirmedFall,
  debounce,
}
