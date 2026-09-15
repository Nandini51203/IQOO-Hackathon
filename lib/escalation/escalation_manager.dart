import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:telephony/telephony.dart';

import 'alert_sent_screen.dart';

/// Person C's module — single public entry point: EscalationManager.trigger().
/// Nobody else in the app needs to know how location/SMS/fallback work internally.
class EscalationManager {
  // Hardcoded emergency contact for the prototype demo.
  static const String emergencyContact =
      "+91 9172948074"; // TODO: replace with real demo number

  static final Telephony _telephony = Telephony.instance;

  /// Call this when the check-in countdown expires.
  /// Fetches location, tries SMS, and always shows the on-screen
  /// confirmation/fallback state at the point of escalation.
  static Future<void> trigger(
    BuildContext context, {
    String contact = emergencyContact,
  }) async {
    final locationText = await _getLocationText();
    final smsSent = await _trySendSms(contact, locationText);

    if (!context.mounted) return;
    _launchAlertSentScreen(context, contact, locationText, smsSent);
  }

  static Future<String> _getLocationText() async {
    try {
      final hasPermission = await _ensureLocationPermission();
      if (!hasPermission) return "location unavailable";

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      ).timeout(const Duration(seconds: 8));

      return "https://maps.google.com/?q=${position.latitude},${position.longitude}";
    } catch (e) {
      debugPrint("EscalationManager: location fetch failed: $e");
      return "location unavailable";
    }
  }

  static Future<bool> _ensureLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  static Future<bool> _trySendSms(String contact, String locationText) async {
    try {
      final granted = await _telephony.requestPhoneAndSmsPermissions;
      if (granted != true) {
        debugPrint(
            "EscalationManager: SMS permission not granted — using fallback only");
        return false;
      }
      final message =
          "RakshaSense Alert: Possible fall detected. Location: $locationText";
      await _telephony.sendSms(to: contact, message: message);
      debugPrint("EscalationManager: SMS sent to $contact");
      return true;
    } catch (e) {
      debugPrint("EscalationManager: SMS send failed: $e");
      return false;
    }
  }

  static void _launchAlertSentScreen(
    BuildContext context,
    String contact,
    String locationText,
    bool smsSent,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AlertSentScreen(
          contact: contact,
          locationText: locationText,
          smsSent: smsSent,
        ),
      ),
    );
  }
}
