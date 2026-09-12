# RakshaSense — Sensor & Trigger Engine (Member 1, Flutter)

Standalone prototype of the Member 1 scope from
`RakshaSense_Member1_Flutter_Prototype_Build_Plan.docx`:

```
REAL PHONE -> ACCELEROMETER/GYROSCOPE -> SENSOR BUFFER -> FALL STATE MACHINE
           -> CONFIDENCE -> onFallDetected(confidence) -> GuardianService -> ...
```

This module ends at the trigger callback, on purpose. It does not contain
check-in UI, SMS, GPS, or escalation logic — those belong to the rest of
the team (see "What this does NOT include" below).

## Project layout

```
lib/
  sensors/
    fall_detector.dart        # state machine + sensor subscriptions + confidence
    threshold_config.dart     # every tunable constant, in one place
    sensor_data_buffer.dart   # rolling ~2s window of SensorSample
    fall_detection_state.dart # NORMAL..DEBOUNCE enum
    sensor_debug_screen.dart  # raw-data diagnostics view (for tuning only)
  models/
    sensor_sample.dart        # internal sample shape (timestamp, magnitudes, raw axes)
  shared/
    trigger_event.dart        # TriggerEvent + TriggerType (frozen contract)
    trigger_listener.dart     # TriggerListener interface (frozen contract)
  ui/
    guardian_home_screen.dart # the real interface — what actually ships
    fall_alert_screen.dart    # full-screen alert on a real confirmed fall
    pulse_ring.dart           # breathing/ripple presence indicator
    motion_wave_painter.dart  # live motion trace (no raw numbers on the main screen)
  main.dart                   # standalone runner: launches GuardianHomeScreen
test/
  fall_detector_test.dart     # simulateFall() callback + debounce smoke tests
pubspec.yaml
analysis_options.yaml
```

`lib/ui/` is this module's own presentation layer for demoing/testing the
detector end to end. It still ends at the trigger callback — no check-in
countdown, escalation, or messaging lives here (Section 15); that's the
next module in the pipeline. The doc's own `decision/`, `escalation/`,
and top-level `ui/` folders (Section 3) belong to other members and
aren't part of this drop.

## The real interface (replaces SIMULATE FALL)

**`GuardianHomeScreen`** is what a person actually sees:

- A breathing amber ring shows Guardian is watching. It speeds up and
  brightens as the detector moves through FREE_FALL → IMPACT →
  ORIENTATION_CHANGED → STILLNESS — feedback in plain language
  ("Checking a sharp impact", "Waiting to see if you move"), never raw
  numbers.
- A thin live motion trace along the bottom is the only "raw" signal
  kept on the main screen, so it's visibly reading real motion.
- **Start monitoring / Pause monitoring** replaces any simulate control
  — this only turns the real accelerometer/gyroscope pipeline on or off.
- The moment a real `CONFIRMED_FALL` fires the shared `onFallDetected`
  callback, the app opens **`FallAlertScreen`** — the one place the
  alarm colour is used — showing a plain-language confidence level, the
  time, and a note that check-in/escalation is the next team's module.

**`SensorDebugScreen`** still exists (reachable via the tune icon in the
app bar) for the real work of tuning `ThresholdConfig` against a live
device — but its SIMULATE FALL button is gone. Every value on it now
comes from the same live `FallDetector` instance the home screen is
running.

`FallDetector.simulateFall()` itself is still in the code (it's what
`test/fall_detector_test.dart` uses to check the debounce logic and that
a fall reaches the same callback path), but nothing in the UI calls it
anymore — the shipped app only reacts to genuine sensor data.

## Running it

```bash
flutter pub get
flutter run   # on a real device — sensors_plus needs physical hardware
              # to produce meaningful accelerometer/gyroscope data
```

`flutter test` runs the two unit tests for the SIMULATE FALL path.

> This environment couldn't run `flutter pub get` / `flutter analyze`
> against pub.dev (no network egress to it), so the code hasn't been
> compiled here. Everything is written directly against the documented
> `sensors_plus` stream API (`accelerometerEventStream()` /
> `gyroscopeEventStream()`, stable since sensors_plus 4.x). Run
> `flutter pub get` first thing and fix any version-specific API drift
> if a much newer/older major version resolves.

## What's implemented (mapped to the build plan's phases)

| Phase | Section | Status |
|---|---|---|
| 1 — sensor proof | 6 | `FallDetector.start()` subscribes to real accel/gyro streams, computes magnitude |
| 2 — sample model + rolling buffer | 6 | `SensorSample` + `SensorDataBuffer` (2s window, oldest evicted) |
| 3 — fall state machine | 6, 7 | `NORMAL -> FREE_FALL -> IMPACT -> ORIENTATION_CHANGED -> STILLNESS -> CONFIRMED_FALL` in `_evaluate()` |
| 4 — confidence scoring | 6, 9 | Weighted 0.25/0.30/0.20/0.25 formula, clamped 0.0–1.0, no Low/Med/High mapping |
| 5 — debounce + reset | 6 | `DEBOUNCE` state + timer, `_resetToNormal()` |
| 6 — debug screen + manual trigger | 6, 10 | Superseded by the real interface: `GuardianHomeScreen` + `FallAlertScreen` react to genuine detections; `SensorDebugScreen` is kept as a raw-data tuning view only, with SIMULATE FALL removed |
| 7 — continuous monitoring | 6 | **Not implemented** — intentionally left to the team's chosen background-monitoring strategy per platform |
| 8 — integration | 6 | `TriggerListener`/`TriggerEvent` are ready to hand to a real `GuardianService`; `main.dart`'s console listener is a placeholder |

Threshold starting values are copied verbatim from Section 8 of the plan
and must be re-tuned on the real demo phone (Section 8, Section 16 Day 2).

One prototype simplification not spelled out in the source doc: after
`IMPACT`, if no rotation evidence shows up within
`ThresholdConfig.orientationWindowMs`, the state machine falls through to
`ORIENTATION_CHANGED` anyway (with zero rotation evidence) rather than
getting stuck — otherwise a fall with little phone rotation would never
reach `STILLNESS`/`CONFIRMED_FALL`. Tune or replace this once real device
data is available.

## What this does NOT include (Section 15)

- SMS sending
- GPS/location packaging
- Check-in UI
- Situation-summary card
- Office Kit dashboard
- On-device LLM
- Ambient sound classification / active silent gesture (stretch-only, Section 2)

## Testing checklist (Section 11)

Use the debug screen to manually walk through:

- [ ] Walking — no trigger
- [ ] Jogging — no trigger
- [ ] Sitting down — no trigger
- [ ] Climbing stairs — no trigger
- [ ] Phone placed on table — no trigger
- [ ] Safe drop onto bed/cushion — trigger
- [ ] Impact in a different orientation — trigger
- [ ] Phone shake — ideally no trigger
- [ ] Repeated motion after a trigger — no duplicate callback (debounce)

## Git workflow (Section 12–13)

- Branch: `feature/sensors`
- Primary ownership: `lib/sensors/`
- Don't push directly to `main`; open a PR once the module works standalone
- Don't change `lib/shared/` unless the team agrees — it's the frozen contract
- Suggested commit sequence is in Section 13 of the original build plan;
  this prototype was generated as a single drop, so split it into that
  sequence of commits before opening a PR if you want the history to
  match.
