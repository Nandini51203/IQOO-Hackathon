/// Central place for Person B's tunable values.
///
/// Change the countdown length here ONLY — nothing else in this module
/// hardcodes the number of seconds, so tuning it for the demo (15 vs 20
/// vs 30) never means hunting through multiple files.
class CheckInConfig {
  CheckInConfig._(); // not meant to be instantiated

  /// How long the user has to confirm they're okay before [CheckInScreen]
  /// fires onTimeout(). 15s is fine for development; raise to 20-30 for
  /// the real demo once the team agrees on a value (see doc section 5).
  static const int countdownSeconds = 15;
}
