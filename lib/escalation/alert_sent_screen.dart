import 'package:flutter/material.dart';

import 'escalation_manager.dart';

class AlertSentScreen extends StatefulWidget {
  final String contact;

  const AlertSentScreen({
    super.key,
    required this.contact,
  });

  @override
  State<AlertSentScreen> createState() =>
      _AlertSentScreenState();
}

class _AlertSentScreenState
    extends State<AlertSentScreen> {

  String _status = 'Preparing emergency alert...';
  String _locationText = 'Getting current location...';

  bool _loading = true;
  bool _smsSent = false;

  @override
  void initState() {
    super.initState();
    _startEscalation();
  }

  Future<void> _startEscalation() async {
    setState(() {
      _status = 'Getting your location...';
    });

    final result =
    await EscalationManager.execute(
      widget.contact,
    );

    if (!mounted) return;

    setState(() {
      _locationText = result.locationText;
      _smsSent = result.smsSent;
      _loading = false;

      if (result.smsSent) {
        _status = 'Emergency SMS sent';
      } else {
        _status = 'Emergency SMS could not be sent';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: const Color(0xFFD32F2F),
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisAlignment:
                MainAxisAlignment.center,
                children: [

                  // Icon
                  Icon(
                    _loading
                        ? Icons.warning_amber_rounded
                        : _smsSent
                        ? Icons.check_circle_rounded
                        : Icons.error_rounded,
                    color: Colors.white,
                    size: 92,
                  ),

                  const SizedBox(height: 28),

                  // Main status
                  Text(
                    _status,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Progress indicator
                  if (_loading)
                    const Padding(
                      padding: EdgeInsets.symmetric(
                        vertical: 20,
                      ),
                      child: CircularProgressIndicator(
                        color: Colors.white,
                      ),
                    ),

                  const SizedBox(height: 12),

                  // SMS status
                  Row(
                    mainAxisAlignment:
                    MainAxisAlignment.center,
                    children: [
                      Icon(
                        _loading
                            ? Icons.hourglass_top
                            : _smsSent
                            ? Icons.check_circle
                            : Icons.cancel,
                        color: Colors.white,
                        size: 22,
                      ),
                      const SizedBox(width: 10),
                      Flexible(
                        child: Text(
                          _loading
                              ? 'Sending emergency SMS...'
                              : _smsSent
                              ? 'SMS sent to ${widget.contact}'
                              : 'SMS could not be sent',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Location
                  Row(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.location_on,
                        color: Colors.white,
                        size: 24,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Location:\n$_locationText',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 35),

                  if (!_loading)
                    const Text(
                      'RakshaSense emergency escalation is active.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}