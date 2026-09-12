import 'package:flutter/material.dart';

/// Shown the moment the detector actually confirms a fall — this is
/// the one screen in the app that uses the alarm colour, which is what
/// keeps it meaningful.
///
/// This screen only reports that the trigger callback fired; it does
/// not implement check-in, escalation, or contacting anyone. That is
/// intentionally out of scope here (build plan, Section 15) and is the
/// next module in the pipeline.
class FallAlertScreen extends StatelessWidget {
  final double confidence;
  final DateTime detectedAt;
  final VoidCallback onDismiss;

  const FallAlertScreen({
    super.key,
    required this.confidence,
    required this.detectedAt,
    required this.onDismiss,
  });

  static const _alarm = Color(0xFFD6483B);
  static const _ink = Color(0xFF121A2B);
  static const _paper = Color(0xFFF5F1E8);

  String get _levelLabel {
    if (confidence >= 0.75) return 'High confidence';
    if (confidence >= 0.5) return 'Moderate confidence';
    return 'Low confidence';
  }

  String get _timeLabel {
    final h = detectedAt.hour.toString().padLeft(2, '0');
    final m = detectedAt.minute.toString().padLeft(2, '0');
    final s = detectedAt.second.toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: _alarm,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(28, 32, 28, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: _paper,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.priority_high_rounded,
                      color: _alarm, size: 36),
                ),
                const SizedBox(height: 28),
                const Text(
                  'Possible fall detected',
                  style: TextStyle(
                    color: _paper,
                    fontSize: 30,
                    fontWeight: FontWeight.w700,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Guardian noticed a sudden impact followed by a period '
                  'of stillness at $_timeLabel.',
                  style: TextStyle(
                    color: _paper.withOpacity(0.9),
                    fontSize: 16,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: _paper.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.speed_rounded,
                          color: _paper.withOpacity(0.9), size: 20),
                      const SizedBox(width: 10),
                      Text(
                        '$_levelLabel · ${(confidence * 100).round()}%',
                        style: TextStyle(
                          color: _paper.withOpacity(0.95),
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Text(
                  "This module only raises the alert — your team's "
                  'check-in and escalation flow picks up from here.',
                  style: TextStyle(
                    color: _paper.withOpacity(0.75),
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: onDismiss,
                    style: FilledButton.styleFrom(
                      backgroundColor: _paper,
                      foregroundColor: _alarm,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Dismiss',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
