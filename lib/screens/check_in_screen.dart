import 'dart:async';

import 'package:flutter/material.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../config/checkin_config.dart';
import '../models/situation_data.dart';

/// RakshaSense emergency check-in screen.
///
/// A fall detection event opens this screen and gives the user a limited
/// amount of time to confirm that they are safe.
///
/// If the countdown expires, [onTimeout] is awaited so the escalation
/// process can complete before this screen is removed.
class CheckInScreen extends StatefulWidget {
  const CheckInScreen({
    super.key,
    this.countdownSeconds = CheckInConfig.countdownSeconds,
    this.situationData = const SituationData(),
    this.onTimeout,
    this.onConfirmSafe,
  });

  final int countdownSeconds;
  final SituationData situationData;

  /// Called when the countdown reaches zero.
  ///
  /// This can be asynchronous because escalation may need to obtain
  /// GPS location and open the SMS composer.
  final Future<void> Function()? onTimeout;

  /// Called when the user confirms that they are safe.
  final VoidCallback? onConfirmSafe;

  @override
  State<CheckInScreen> createState() => _CheckInScreenState();
}

class _CheckInScreenState extends State<CheckInScreen> {
  late int _secondsRemaining;

  Timer? _timer;

  bool _hasResponded = false;
  bool _escalating = false;

  @override
  void initState() {
    super.initState();

    _secondsRemaining = widget.countdownSeconds;

    WakelockPlus.enable();

    _startCountdown();
  }

  void _startCountdown() {
    _timer = Timer.periodic(
      const Duration(seconds: 1),
          (timer) {
        if (_secondsRemaining <= 1) {
          timer.cancel();
          _handleTimeout();
        } else {
          setState(() {
            _secondsRemaining--;
          });
        }
      },
    );
  }

  Future<void> _handleTimeout() async {
    if (_hasResponded) return;

    _hasResponded = true;
    _escalating = true;
    _timer?.cancel();

    if (mounted) {
      setState(() {});
    }

    // The timeout callback owns the navigation.
    // Do NOT pop this screen here.
    await widget.onTimeout?.call();
  }

  void _handleConfirmSafe() {
    if (_hasResponded) return;

    _hasResponded = true;

    _timer?.cancel();

    widget.onConfirmSafe?.call();

    if (!mounted) return;

    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _timer?.cancel();
    WakelockPlus.disable();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: const Color(0xFFB00020),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.white,
                  size: 72,
                ),

                const SizedBox(height: 16),

                const Text(
                  'Are you okay?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 34,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 12),

                const Text(
                  'We detected a possible fall.\n'
                      "If you're okay, confirm below. "
                      "If you don't respond, an emergency alert will be triggered.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                    height: 1.4,
                  ),
                ),

                const SizedBox(height: 40),

                if (_escalating) ...[
                  const CircularProgressIndicator(
                    color: Colors.white,
                  ),

                  const SizedBox(height: 24),

                  const Text(
                    'Preparing emergency alert...',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 10),

                  const Text(
                    'Getting your location and opening the emergency message.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ] else ...[
                  Text(
                    '$_secondsRemaining',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 96,
                      fontWeight: FontWeight.w900,
                      height: 1.0,
                    ),
                  ),

                  const Text(
                    'seconds remaining',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),

                  const SizedBox(height: 48),

                  SizedBox(
                    width: double.infinity,
                    height: 64,
                    child: ElevatedButton(
                      onPressed: _handleConfirmSafe,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFFB00020),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 4,
                      ),
                      child: const Text(
                        "I'M OKAY",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}