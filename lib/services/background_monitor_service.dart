import 'package:flutter_background/flutter_background.dart';

class BackgroundMonitorService {
  static bool _initialized = false;

  static Future<bool> initialize() async {
    if (_initialized) {
      return true;
    }

    const androidConfig = FlutterBackgroundAndroidConfig(
      notificationTitle: 'RakshaSense Active',
      notificationText: 'Fall detection is running in the background',
      notificationImportance: AndroidNotificationImportance.normal,
      notificationIcon: AndroidResource(
        name: 'ic_launcher',
        defType: 'mipmap',
      ),
      enableWifiLock: false,
      shouldRequestBatteryOptimizationsOff: false,
    );

    final success = await FlutterBackground.initialize(
      androidConfig: androidConfig,
    );

    _initialized = success;
    return success;
  }

  static Future<bool> start() async {
    final initialized = await initialize();

    if (!initialized) {
      return false;
    }

    if (FlutterBackground.isBackgroundExecutionEnabled) {
      return true;
    }

    return FlutterBackground.enableBackgroundExecution();
  }

  static Future<void> stop() async {
    if (!FlutterBackground.isBackgroundExecutionEnabled) {
      return;
    }

    await FlutterBackground.disableBackgroundExecution();
  }

  static bool get isRunning =>
      FlutterBackground.isBackgroundExecutionEnabled;
}
