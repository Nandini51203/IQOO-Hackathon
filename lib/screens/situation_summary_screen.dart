import 'package:flutter/material.dart';
import '../models/situation_data.dart';
import '../widgets/situation_card.dart';

/// PERSON B — shown immediately after a timeout, at the exact point
/// where escalation begins (per the doc's flow: countdown -> no
/// response -> situation summary -> Person C escalation).
///
/// This screen only DISPLAYS the summary. It never fetches location or
/// sends SMS — that is entirely Person C's EscalationManager, called
/// from CheckInScreen's onTimeout before this screen even appears.
class SituationSummaryScreen extends StatelessWidget {
  const SituationSummaryScreen({super.key, required this.data});

  final SituationData data;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF3F3),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.report_rounded, color: Color(0xFFB00020), size: 56),
              const SizedBox(height: 12),
              const Text(
                'Emergency alert triggered',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              SituationCard(data: data),
              const SizedBox(height: 32),
              // PERSON C — FUTURE SCOPE: once EscalationManager exists,
              // its live status ("Sending SMS...", "Location found",
              // "Alert sent to <contact>") replaces this placeholder line.
              const Text(

                'Emergency escalation has been initiated.',

                textAlign: TextAlign.center,

                style: TextStyle(

                  color: Colors.black54,

                  fontSize: 14,

                ),

              ),
              const SizedBox(height: 24),
              TextButton(
                onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
                child: const Text('Back to home (demo only)'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
