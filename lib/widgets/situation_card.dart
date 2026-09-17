import 'package:flutter/material.dart';
import '../models/situation_data.dart';

/// PERSON B — reusable situation-summary card.
///
/// Usage:
/// ```dart
/// SituationCard(
///   data: SituationData(situation: 'Fall detected', confidence: 'High'),
/// )
/// ```
///
/// Static/template only — no backend, no database, no ML. Optional
/// fields (time/location/triggerType) render as extra rows only when
/// provided, so the same widget works today (situation + confidence
/// only) and later once other fields are wired in.
class SituationCard extends StatelessWidget {
  const SituationCard({super.key, required this.data});

  final SituationData data;

  static const _accent = Color(0xFFB00020);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.info_outline, color: _accent),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Possible situation: ${data.situation}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _confidenceBadge(data.confidence),
            if (data.time != null) ...[
              const SizedBox(height: 10),
              _detailRow(Icons.access_time, 'Time', _formatTime(data.time!)),
            ],
            if (data.location != null) ...[
              const SizedBox(height: 10),
              _detailRow(Icons.location_on_outlined, 'Location', data.location!),
            ],
            if (data.triggerType != null) ...[
              const SizedBox(height: 10),
              _detailRow(Icons.sensors, 'Trigger', data.triggerType!),
            ],
          ],
        ),
      ),
    );
  }

  Widget _confidenceBadge(String confidence) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _accent.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        'Confidence: $confidence',
        style: const TextStyle(color: _accent, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.black54),
        const SizedBox(width: 8),
        Text('$label: ', style: const TextStyle(color: Colors.black54)),
        Expanded(child: Text(value, overflow: TextOverflow.ellipsis)),
      ],
    );
  }

  String _formatTime(DateTime t) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(t.hour)}:${two(t.minute)}:${two(t.second)}';
  }
}
