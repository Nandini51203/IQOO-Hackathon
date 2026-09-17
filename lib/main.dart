import 'package:flutter/material.dart';

import 'ui/guardian_home_screen.dart';

void main() {
  runApp(const RakshaSenseApp());
}

class RakshaSenseApp extends StatelessWidget {
  const RakshaSenseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'RakshaSense',
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