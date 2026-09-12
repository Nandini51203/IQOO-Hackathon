import 'package:flutter/material.dart';

import 'ui/guardian_home_screen.dart';

/// Standalone entry point for running the Sensor & Trigger Engine on
/// its own. `GuardianHomeScreen` owns the real `FallDetector` and
/// reacts to genuine accelerometer/gyroscope data — there is no
/// simulated-fall path in the shipped app anymore.
///
/// When this module is merged into the full RakshaSense app, the
/// coordinator/GuardianService should implement `TriggerListener`
/// the same way `GuardianHomeScreen`'s internal listener does (build
/// plan, Section 6 Phase 8), then take over from the fall-detected
/// callback with real check-in/escalation logic.
void main() {
  runApp(const RakshaSenseSensorApp());
}

class RakshaSenseSensorApp extends StatelessWidget {
  const RakshaSenseSensorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RakshaSense — Guardian',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFFF2A93B),
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF121A2B),
      ),
      home: const GuardianHomeScreen(),
    );
  }
}
