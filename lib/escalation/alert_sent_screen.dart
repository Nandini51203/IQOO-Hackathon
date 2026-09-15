import 'package:flutter/material.dart';

/// Shown at the moment of escalation, whether SMS actually sent or not.
/// Doesn't know or care how it got here — just displays what EscalationManager passes it.
class AlertSentScreen extends StatelessWidget {
  final String contact;
  final String locationText;
  final bool smsSent;

  const AlertSentScreen({
    super.key,
    required this.contact,
    required this.locationText,
    required this.smsSent,
  });

  @override
  Widget build(BuildContext context) {
    final statusText = smsSent
        ? "Alert sent to $contact"
        : "Alert sent to $contact (on-screen alert — SMS unavailable)";

    return Scaffold(
      backgroundColor: const Color(0xFFD32F2F),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                color: Colors.white,
                size: 96,
              ),
              const SizedBox(height: 24),
              Text(
                statusText,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                "Location shared: $locationText",
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
