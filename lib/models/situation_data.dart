/// Static/template data shown on the situation-summary card.
///
/// This round of the prototype does NOT use ML to fill this in — it's a
/// plain, immutable data holder. [situation] and [confidence] are the
/// only two fields the current scope requires; [time], [location], and
/// [triggerType] are optional extras the card already knows how to
/// display, ready for whenever a future round wires in real values
/// (e.g. Person C's location fetch) — no widget changes needed then.
class SituationData {
  final String situation;
  final String confidence;
  final DateTime? time;
  final String? location;
  final String? triggerType;

  const SituationData({
    this.situation = 'Fall detected',
    this.confidence = 'High',
    this.time,
    this.location,
    this.triggerType,
  });
}
