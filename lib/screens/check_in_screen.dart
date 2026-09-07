import 'dart:async';
import 'package:flutter/material.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../config/checkin_config.dart';
import '../models/situation_data.dart';
import 'situation_summary_screen.dart';

/// PERSON B — the "Are you okay?" check-in screen.
///
/// This is the Flutter equivalent of the document's CheckInActivity
/// contract:
///   var onTimeout: (() -> Unit)?
///   var onConfirmSafe: (() -> Unit)?
///
/// Person B does NOT know how escalation or "safe" handling works
/// internally — it only calls these two callbacks. Person A's
/// FallDetector calls INTO this screen (by pushing it); Person C's
/// EscalationManager equivalent is called FROM [onTimeout].
class CheckInScreen extends StatefulWidget {
  const CheckInScreen({
    super.key,
    this.countdownSeconds = CheckInConfig.countdownSeconds,
    this.situationData = const SituationData(),
    this.onTimeout,
    this.onConfirmSafe,
  });

  /// How many seconds the user has to respond. Defaults to the shared
  /// config value so every caller stays in sync automatically.
  final int countdownSeconds;

  /// Data shown on the situation card once the countdown expires.
  final SituationData situationData;

  /// Fired exactly once, when the countdown reaches zero without a
  /// response. This is the "user did not respond" signal — Person C
  /// wires their real escalation logic here.
  final VoidCallback? onTimeout;

  /// Fired exactly once, when the user taps "I'm okay" in time.
  final VoidCallback? onConfirmSafe;

  @override
  State<CheckInScreen> createState() => _CheckInScreenState();
}

class _CheckInScreenState extends State<CheckInScreen> {
  late int _secondsRemaining;
  Timer? _timer;

  // Guards against onTimeout/onConfirmSafe firing more than once
  // (rapid taps, or a tap that races the timer's last tick).
  bool _hasResponded = false;

  @override
  void initState() {
    super.initState();
    _secondsRemaining = widget.countdownSeconds;
    // Keep the screen awake while the prompt is up — see README notes
    // on why this needs a plugin rather than a pure-Dart API.
    WakelockPlus.enable();
    _startCountdown();
  }

  void _startCountdown() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining <= 1) {
        timer.cancel();
        _handleTimeout();
      } else {
        setState(() => _secondsRemaining--);
      }
    });
  }

  void _handleTimeout() {
    if (_hasResponded) return;
    _hasResponded = true;

    // Notify the integration layer first, so escalation can start
    // immediately rather than waiting on navigation/animation.
    widget.onTimeout?.call();

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => SituationSummaryScreen(data: widget.situationData),
      ),
    );
  }

  void _handleConfirmSafe() {
    if (_hasResponded) return; // rapid-tap guard
    _hasResponded = true;
    _timer?.cancel();

    widget.onConfirmSafe?.call();

    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    // Always cancel the timer here — if the screen is popped/replaced
    // mid-countdown (e.g. back gesture, hot reload), this is the one
    // place that guarantees no orphaned timer keeps running.
    _timer?.cancel();
    WakelockPlus.disable();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // Block the back gesture/button so the countdown can't be
      // silently dismissed without either callback firing.
      canPop: false,
      child: Scaffold(
        backgroundColor: const Color(0xFFB00020),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 72),
                const SizedBox(height: 16),
                const Text(
                  'Are you okay?',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                const Text(
                  "We detected a possible fall.\nIf you're okay, confirm below. "
                  "If you don't respond, an emergency alert will be triggered.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, fontSize: 16, height: 1.4),
                ),
                const SizedBox(height: 40),
                Text(
                  '$_secondsRemaining',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 96,
                    fontWeight: FontWeight.w900,
                    height: 1.0,
                  ),
                ),
                const Text('seconds remaining', style: TextStyle(color: Colors.white70, fontSize: 14)),
                const SizedBox(height: 48),
                SizedBox(
                  width: double.infinity,
                  height: 64,
                  child: ElevatedButton(
                    onPressed: _handleConfirmSafe,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFFB00020),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 4,
                    ),
                    child: const Text(
                      "I'M OKAY",
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
