import 'package:flutter_test/flutter_test.dart';
import 'package:rakshasense_sensor_module/sensors/fall_detector.dart';
import 'package:rakshasense_sensor_module/sensors/fall_detection_state.dart';
import 'package:rakshasense_sensor_module/shared/trigger_listener.dart';

class _RecordingListener implements TriggerListener {
  int fallCount = 0;
  double? lastConfidence;

  @override
  void onFallDetected(double confidence) {
    fallCount++;
    lastConfidence = confidence;
  }

  @override
  void onGestureTriggered() {}
}

void main() {
  group('FallDetector.simulateFall', () {
    test('fires exactly one callback and matches the real event shape', () {
      final listener = _RecordingListener();
      final detector = FallDetector(listener: listener);

      detector.simulateFall();

      expect(listener.fallCount, 1);
      expect(listener.lastConfidence, isNotNull);
      expect(listener.lastConfidence, inInclusiveRange(0.0, 1.0));
      expect(detector.state, FallDetectionState.debounce);
    });

    test('debounces a second simulated fall while in DEBOUNCE', () {
      final listener = _RecordingListener();
      final detector = FallDetector(listener: listener);

      detector.simulateFall();
      detector.simulateFall(); // should be ignored (still debouncing)

      expect(listener.fallCount, 1);
    });
  });
}
