import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../services/native_sms_service.dart';
import 'alert_sent_screen.dart';

class EscalationResult {
  final String locationText;
  final bool smsSent;

  const EscalationResult({
    required this.locationText,
    required this.smsSent,
  });
}

class EscalationManager {
  static const String emergencyContact = '+91 8623086410';

  /// Replaces the Check-In screen with the emergency status screen.
  static void trigger(
      BuildContext context, {
        String contact = emergencyContact,
      }) {
    if (!context.mounted) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => AlertSentScreen(
          contact: contact,
        ),
      ),
    );
  }

  /// Performs the actual emergency escalation.
  static Future<EscalationResult> execute(
      String contact,
      ) async {
    // 1. Get location.
    final locationText = await _getLocationText();

    // 2. Build emergency message.
    final message =
        'RakshaSense Alert: Possible fall detected. '
        'Location: $locationText';

    // 3. Send SMS directly through Android SmsManager.
    final smsSent = await NativeSmsService.sendSms(
      to: contact,
      message: message,
    );

    debugPrint(
      'RakshaSense: SMS result = $smsSent',
    );

    debugPrint(
      'RakshaSense: Location = $locationText',
    );

    return EscalationResult(
      locationText: locationText,
      smsSent: smsSent,
    );
  }

  static Future<String> _getLocationText() async {
    try {
      LocationPermission permission =
      await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission =
        await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        debugPrint(
          'RakshaSense: Location permission unavailable',
        );

        return 'location unavailable';
      }

      // Try the most recent known location first.
      final lastKnown =
      await Geolocator.getLastKnownPosition();

      if (lastKnown != null) {
        return _mapsLink(
          lastKnown.latitude,
          lastKnown.longitude,
        );
      }

      // Otherwise get a fresh GPS position.
      final position =
      await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
        ),
      ).timeout(
        const Duration(seconds: 5),
      );

      return _mapsLink(
        position.latitude,
        position.longitude,
      );
    } catch (e) {
      debugPrint(
        'RakshaSense: Location failed: $e',
      );

      return 'location unavailable';
    }
  }

  static String _mapsLink(
      double latitude,
      double longitude,
      ) {
    return 'https://maps.google.com/?q='
        '$latitude,$longitude';
  }
}