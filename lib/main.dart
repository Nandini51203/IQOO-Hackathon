import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

/// STANDALONE TESTING ENTRY POINT — Person B's branch only.
///
/// This file exists purely so Person B can `flutter run` and exercise
/// the check-in module before Person A/C's code exists. It is NOT the
/// team's shared wiring file (the Flutter equivalent of MainActivity.kt
/// in the original doc).
///
/// DO NOT merge this file as-is into the team's real entry point. The
/// coordinator's real main.dart/app.dart will import HomeScreen or
/// CheckInScreen directly and wire the callbacks to Person A's
/// FallDetector and Person C's EscalationManager instead of the
/// debugPrint() mocks used here. See the integration notes in the
/// chat response for the exact wiring.
void main() {
  runApp(const RakshaSenseDevApp());
}

class RakshaSenseDevApp extends StatelessWidget {
  const RakshaSenseDevApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RakshaSense — Person B Dev',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFFB00020),
      ),
      home: const HomeScreen(),
    );
  }
}
