import 'package:flutter/services.dart';

class NativeSmsService {
  static const MethodChannel _channel =
  MethodChannel('rakshasense/native');

  static Future<bool> requestPermission() async {
    try {
      final result =
      await _channel.invokeMethod<bool>(
        'requestSmsPermission',
      );

      return result ?? false;
    } on PlatformException catch (e) {
      print(
        'SMS permission error: '
            '${e.code} - ${e.message}',
      );

      return false;
    }
  }

  static Future<bool> sendSms({
    required String to,
    required String message,
  }) async {
    try {
      final result =
      await _channel.invokeMethod<bool>(
        'sendSms',
        {
          'to': to,
          'message': message,
        },
      );

      return result ?? false;
    } on PlatformException catch (e) {
      print(
        'SMS send error: '
            '${e.code} - ${e.message}',
      );

      return false;
    }
  }
}