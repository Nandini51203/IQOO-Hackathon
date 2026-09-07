import 'package:flutter/material.dart';
import '../config/checkin_config.dart';
import '../models/situation_data.dart';
import 'check_in_screen.dart';

/// DEV/DEMO SCREEN — not the team's real RakshaSense home screen.
///
/// Its only job is the "Simulate Fall" button required by the doc's
/// manual-testing requirement (section 3, Person B "How to test
/// standalone"). It calls the exact same [_startCheckIn] function a
/// real integration would call from
/// `fallDetector.setOnFallDetectedListener { startCheckIn(...) }`
/// so the manual trigger and the real trigger share one code path.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _startCheckIn(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CheckInScreen(
          countdownSeconds: CheckInConfig.countdownSeconds,
          situationData: const SituationData(
            situation: 'Fall detected',
            confidence: 'High',
            triggerType: 'Manual simulate (dev)',
          ),
          onTimeout: () {
            // MOCKED — real build: EscalationManager.trigger(contact) here.
            // Waiting for Person C.
            debugPrint('[Person B] onTimeout fired -> escalation would start now (MOCKED)');
          },
          onConfirmSafe: () {
            // MOCKED — real build: resume Person A's monitoring here.
            // Waiting for Person A.
            debugPrint('[Person B] onConfirmSafe fired -> user marked safe (MOCKED)');
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('RakshaSense — Dev Home (Person B)')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.shield_outlined, size: 48, color: Colors.black38),
              const SizedBox(height: 16),
              const Text(
                "Monitoring normally...\n"
                "(In the real build, Person A's FallDetector calls this "
                "automatically — this button just stands in for that.)",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () => _startCheckIn(context),
                icon: const Icon(Icons.warning_amber_rounded),
                label: const Text('Simulate Fall'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFB00020),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
