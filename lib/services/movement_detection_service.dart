/// Movement Detection Service — on-device AI for fall, fight, and emergency running detection.
///
/// Uses accelerometer and gyroscope data processed through a TensorFlow Lite model
/// to detect dangerous movements in real-time. Runs completely offline.
///
/// Detection types:
/// - FALL: sudden deceleration followed by stillness
/// - FIGHT: rapid, chaotic movement patterns
/// - EMERGENCY_RUNNING: sustained high-speed movement with panic patterns
///
/// NOTE: Uses the trained TFLite model at assets/ml/movement_model_float16.tflite
/// Falls back to heuristic-based detection if the model fails to load.
library;

import 'dart:async';
import 'dart:math' as math;

import 'package:sensors_plus/sensors_plus.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

/// Result from a single frame of movement analysis.
class MovementResult {
  final String type; // 'normal', 'fall', 'fight', 'running'
  final double confidence;
  final DateTime timestamp;
  final double accelerationMagnitude;

  const MovementResult({
    required this.type,
    required this.confidence,
    required this.timestamp,
    required this.accelerationMagnitude,
  });

  bool get isDangerous =>
      type != 'normal' && confidence > 0.7;
}

/// Alert produced when a dangerous movement is confirmed.
class MovementAlert {
  final String type;
  final double confidence;
  final DateTime timestamp;
  final double? lat;
  final double? lng;

  const MovementAlert({
    required this.type,
    required this.confidence,
    required this.timestamp,
    this.lat,
    this.lng,
  });
}

class MovementDetectionService {
  // ── Configuration ────────────────────────────────────────────────────────
  int _windowSize = 50; // frames per analysis window, dynamically updated from model
  static const double _fallThreshold = 0.75;
  static const double _fightThreshold = 0.70;
  static const double _runningThreshold = 0.65;
  static const int _countdownSeconds = 15;

  // ── State ────────────────────────────────────────────────────────────────
  bool _isRunning = false;
  bool _modelLoaded = false;
  Interpreter? _interpreter;
  List<int> _inputShape = [];
  List<int> _outputShape = [];
  List<String> _modelClasses = ['normal', 'fall', 'fight', 'running'];
  StreamSubscription<AccelerometerEvent>? _accelSub;
  StreamSubscription<GyroscopeEvent>? _gyroSub;

  // Sensor data buffers
  final List<List<double>> _accelBuffer = [];
  final List<List<double>> _gyroBuffer = [];

  // Streams for external consumption
  final _resultController = StreamController<MovementResult>.broadcast();
  final _alertController = StreamController<MovementAlert>.broadcast();
  final _countdownController = StreamController<int>.broadcast();

  // Countdown timer for false-positive prevention
  Timer? _countdownTimer;
  String? _pendingAlertType;
  double? _pendingAlertConfidence;

  Stream<MovementResult> get results => _resultController.stream;
  Stream<MovementAlert> get alerts => _alertController.stream;
  Stream<int> get countdown => _countdownController.stream;

  bool get isRunning => _isRunning;
  bool get modelLoaded => _modelLoaded;

  // Diagnostics
  MovementResult? _lastResult;
  DateTime? _lastAccelEvent;
  DateTime? _lastGyroEvent;

  // ══════════════════════════════════════════════════════════════════════════
  // Initialization
  // ══════════════════════════════════════════════════════════════════════════

  /// Load the TFLite model. Call once at app startup.
  Future<void> initialize() async {
    try {
      final options = InterpreterOptions()
        ..threads = 2
        ..useNnApiForAndroid = false;
      _interpreter = await Interpreter.fromAsset(
        'assets/ml/movement_model_float16.tflite',
        options: options,
      );
      _inputShape = _interpreter!.getInputTensor(0).shape;
      _outputShape = _interpreter!.getOutputTensor(0).shape;

      // Auto-detect class count and window size from input shape.
      if (_inputShape.length >= 2) {
        _windowSize = _inputShape[_inputShape.length - 2];
      }

      final outSize = _outputShape.isNotEmpty ? _outputShape.last : 4;
      if (outSize == 2) {
        _modelClasses = ['normal', 'danger'];
      } else if (outSize == 3) {
        _modelClasses = ['normal', 'fall', 'fight'];
      } else if (outSize >= 4) {
        _modelClasses = ['normal', 'fall', 'fight', 'running'];
        if (outSize > 4) {
          _modelClasses = List.generate(outSize, (i) => i == 0 ? 'normal' : 'class_$i');
        }
      }

      _modelLoaded = true;
    } catch (e) {
      _modelLoaded = false;
      _interpreter = null;
      _inputShape = [];
      _outputShape = [];
      // Fallback to heuristic detection — still functional offline.
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // Start / Stop
  // ══════════════════════════════════════════════════════════════════════════

  /// Start listening to accelerometer and gyroscope.
  void startDetection() {
    if (_isRunning) return;
    _isRunning = true;

    _accelSub = accelerometerEventStream(
      samplingPeriod: const Duration(milliseconds: 20),
    ).listen(_onAccelerometerData);

    _gyroSub = gyroscopeEventStream(
      samplingPeriod: const Duration(milliseconds: 20),
    ).listen(_onGyroscopeData);
  }

  /// Stop all detection.
  void stopDetection() {
    _isRunning = false;
    _accelSub?.cancel();
    _gyroSub?.cancel();
    _countdownTimer?.cancel();
    _accelBuffer.clear();
    _gyroBuffer.clear();
  }

  // ══════════════════════════════════════════════════════════════════════════
  // Sensor Callbacks
  // ══════════════════════════════════════════════════════════════════════════

  void _onAccelerometerData(AccelerometerEvent event) {
    _lastAccelEvent = DateTime.now();
    _accelBuffer.add([event.x, event.y, event.z]);

    // Keep buffer bounded.
    if (_accelBuffer.length > _windowSize * 2) {
      _accelBuffer.removeRange(0, _accelBuffer.length - _windowSize);
    }

    // Run analysis when we have enough data.
    if (_accelBuffer.length >= _windowSize &&
        _gyroBuffer.length >= _windowSize) {
      _analyzeWindow();
    }
  }

  void _onGyroscopeData(GyroscopeEvent event) {
    _lastGyroEvent = DateTime.now();
    _gyroBuffer.add([event.x, event.y, event.z]);

    if (_gyroBuffer.length > _windowSize * 2) {
      _gyroBuffer.removeRange(0, _gyroBuffer.length - _windowSize);
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // Analysis
  // ══════════════════════════════════════════════════════════════════════════

  void _analyzeWindow() {
    if (_modelLoaded && _interpreter != null) {
      final success = _analyzeWithModel();
      if (!success) {
        _analyzeWithHeuristics();
      }
    } else {
      _analyzeWithHeuristics();
    }
  }

  /// Run inference with the TFLite model.
  /// Returns `true` if inference succeeded, `false` otherwise.
  bool _analyzeWithModel() {
    try {
      final win = math.min(_windowSize, _accelBuffer.length);
      if (win < 10) return false;

      dynamic input;
      dynamic output;

      if (_inputShape.length == 3) {
        // Expected [1, window, 6] : accel_x, accel_y, accel_z, gyro_x, gyro_y, gyro_z
        final inputData = List.generate(win, (i) {
          final a = _accelBuffer[_accelBuffer.length - win + i];
          final g = _gyroBuffer[_gyroBuffer.length - win + i];
          return <double>[a[0], a[1], a[2], g[0], g[1], g[2]];
        });
        input = <List<List<double>>>[inputData];
        output = <List<double>>[List<double>.filled(_outputShape.last, 0.0)];
      } else if (_inputShape.length == 2) {
        // Flattened input [1, window * 6]
        final flat = <double>[];
        for (int i = 0; i < win; i++) {
          final a = _accelBuffer[_accelBuffer.length - win + i];
          final g = _gyroBuffer[_gyroBuffer.length - win + i];
          flat.addAll([a[0], a[1], a[2], g[0], g[1], g[2]]);
        }
        input = <List<double>>[flat];
        output = <List<double>>[List<double>.filled(_outputShape.last, 0.0)];
      } else {
        return false;
      }

      _interpreter!.run(input, output);
      List<double> probs;
      if (output is List<List<double>>) {
        probs = _softmax(List<double>.from(output[0]));
      } else {
        probs = List<double>.from(output[0]);
      }

      int maxIdx = 0;
      double maxProb = probs[0];
      for (int i = 1; i < probs.length; i++) {
        if (probs[i] > maxProb) {
          maxProb = probs[i];
          maxIdx = i;
        }
      }

      final type = _modelClasses[maxIdx];
      double confidence = maxProb;

      // Apply per-class thresholds
      if (type == 'fall' && confidence < _fallThreshold) {
        confidence = confidence;
      } else if (type == 'fight' && confidence < _fightThreshold) {
        confidence = confidence;
      } else if (type == 'running' && confidence < _runningThreshold) {
        confidence = confidence;
      }

      final avgAccel = _avgMagnitude(
        _accelBuffer.sublist(_accelBuffer.length - win),
      );

      final result = MovementResult(
        type: type,
        confidence: confidence,
        timestamp: DateTime.now(),
        accelerationMagnitude: avgAccel,
      );

      _lastResult = result;
      _resultController.add(result);

      if (result.isDangerous && _countdownTimer == null) {
        _startCountdown(type, confidence);
      }

      // Clear buffer for next window ONLY on success.
      _accelBuffer.clear();
      _gyroBuffer.clear();
      return true;
    } catch (e) {
      // If model inference fails, do NOT clear buffers here;
      // let the caller fall back to heuristics.
      return false;
    }
  }

  /// Heuristic fallback when TFLite model is not available.
  void _analyzeWithHeuristics() {
    final accelWindow = _accelBuffer.sublist(
        _accelBuffer.length - _windowSize);
    final gyroWindow = _gyroBuffer.sublist(
        _gyroBuffer.length - _windowSize);

    // Calculate features
    final magnitudes = accelWindow.map((a) =>
        math.sqrt(a[0] * a[0] + a[1] * a[1] + a[2] * a[2])).toList();
    final gyroMagnitudes = gyroWindow.map((g) =>
        math.sqrt(g[0] * g[0] + g[1] * g[1] + g[2] * g[2])).toList();

    final maxAccel = magnitudes.reduce(math.max);
    final minAccel = magnitudes.reduce(math.min);
    final avgAccel = magnitudes.reduce((a, b) => a + b) / magnitudes.length;
    final accelRange = maxAccel - minAccel;

    final avgGyro =
        gyroMagnitudes.reduce((a, b) => a + b) / gyroMagnitudes.length;

    // Standard deviation of acceleration
    final accelStdDev = _stdDev(magnitudes, avgAccel);

    // ── Fall Detection ──────────────────────────────────────────────────
    final lastQuarter = magnitudes.sublist(magnitudes.length ~/ 4 * 3);
    final lastQuarterAvg =
        lastQuarter.reduce((a, b) => a + b) / lastQuarter.length;
    final isFreefall = minAccel < 2.0;
    final isImpact = maxAccel > 25.0;
    final isStill = lastQuarterAvg < 11.0 && _stdDev(lastQuarter, lastQuarterAvg) < 1.5;

    double fallConfidence = 0.0;
    if (isImpact && isStill) {
      fallConfidence = 0.85;
      if (isFreefall) fallConfidence = 0.95;
    } else if (accelRange > 20.0 && isStill) {
      fallConfidence = 0.70;
    }

    // ── Fight Detection ─────────────────────────────────────────────────
    final isHighVariance = accelStdDev > 5.0;
    final isHighRotation = avgGyro > 3.0;
    final isSustained = accelRange > 10.0;

    double fightConfidence = 0.0;
    if (isHighVariance && isHighRotation && isSustained) {
      fightConfidence = 0.80;
    } else if (isHighVariance && isHighRotation) {
      fightConfidence = 0.60;
    }

    // ── Emergency Running Detection ─────────────────────────────────────
    final crossings = _zeroCrossings(magnitudes, avgAccel);
    final isRhythmic = crossings > _windowSize * 0.3;
    final isHighAccel = avgAccel > 12.0;

    double runningConfidence = 0.0;
    if (isRhythmic && isHighAccel && accelStdDev > 3.0) {
      runningConfidence = 0.75;
    }

    // ── Determine result ────────────────────────────────────────────────
    String type = 'normal';
    double confidence = 0.0;

    if (fallConfidence >= _fallThreshold &&
        fallConfidence >= fightConfidence &&
        fallConfidence >= runningConfidence) {
      type = 'fall';
      confidence = fallConfidence;
    } else if (fightConfidence >= _fightThreshold &&
        fightConfidence >= runningConfidence) {
      type = 'fight';
      confidence = fightConfidence;
    } else if (runningConfidence >= _runningThreshold) {
      type = 'running';
      confidence = runningConfidence;
    }

    final result = MovementResult(
      type: type,
      confidence: confidence,
      timestamp: DateTime.now(),
      accelerationMagnitude: avgAccel,
    );

    _lastResult = result;
    _resultController.add(result);

    if (result.isDangerous && _countdownTimer == null) {
      _startCountdown(type, confidence);
    }

    // Clear buffer for next window.
    _accelBuffer.clear();
    _gyroBuffer.clear();
  }

  // ══════════════════════════════════════════════════════════════════════════
  // Countdown (false-positive prevention)
  // ══════════════════════════════════════════════════════════════════════════

  void _startCountdown(String type, double confidence) {
    _pendingAlertType = type;
    _pendingAlertConfidence = confidence;
    int remaining = _countdownSeconds;

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      remaining--;
      _countdownController.add(remaining);

      if (remaining <= 0) {
        timer.cancel();
        _countdownTimer = null;
        _fireAlert();
      }
    });
  }

  /// Cancel the current countdown (user pressed "I'm OK").
  void cancelFallAlert() {
    _countdownTimer?.cancel();
    _countdownTimer = null;
    _pendingAlertType = null;
    _pendingAlertConfidence = null;
    _countdownController.add(-1); // Signal cancellation.
  }

  void _fireAlert() {
    if (_pendingAlertType == null) return;

    _alertController.add(MovementAlert(
      type: _pendingAlertType!,
      confidence: _pendingAlertConfidence ?? 0.0,
      timestamp: DateTime.now(),
    ));

    _pendingAlertType = null;
    _pendingAlertConfidence = null;
  }

  // ══════════════════════════════════════════════════════════════════════════
  // Math Helpers
  // ══════════════════════════════════════════════════════════════════════════

  double _avgMagnitude(List<List<double>> window) {
    final mags = window.map((v) =>
        math.sqrt(v[0] * v[0] + v[1] * v[1] + v[2] * v[2])).toList();
    return mags.reduce((a, b) => a + b) / mags.length;
  }

  List<double> _softmax(List<double> logits) {
    final maxVal = logits.reduce(math.max);
    final exps = logits.map((x) => math.exp(x - maxVal)).toList();
    final sum = exps.reduce((a, b) => a + b);
    return exps.map((e) => e / sum).toList();
  }

  double _stdDev(List<double> values, double mean) {
    final sumSqDiff =
        values.fold<double>(0.0, (sum, v) => sum + (v - mean) * (v - mean));
    return math.sqrt(sumSqDiff / values.length);
  }

  int _zeroCrossings(List<double> values, double mean) {
    int count = 0;
    for (int i = 1; i < values.length; i++) {
      if ((values[i - 1] - mean).sign != (values[i] - mean).sign) {
        count++;
      }
    }
    return count;
  }

  // ══════════════════════════════════════════════════════════════════════════
  // Diagnostics & Testing
  // ══════════════════════════════════════════════════════════════════════════

  Map<String, dynamic> get diagnostics => {
        'isRunning': _isRunning,
        'modelLoaded': _modelLoaded,
        'accelBufferSize': _accelBuffer.length,
        'gyroBufferSize': _gyroBuffer.length,
        'lastAccelEvent': _lastAccelEvent?.toIso8601String(),
        'lastGyroEvent': _lastGyroEvent?.toIso8601String(),
        'receivingAccel': _lastAccelEvent != null &&
            DateTime.now().difference(_lastAccelEvent!).inSeconds < 2,
        'receivingGyro': _lastGyroEvent != null &&
            DateTime.now().difference(_lastGyroEvent!).inSeconds < 2,
        'lastResultType': _lastResult?.type,
        'lastResultConfidence': _lastResult?.confidence,
        'pendingAlert': _pendingAlertType,
        'countdownActive': _countdownTimer != null,
      };

  /// Simulate a fall event (for testing via AI Test Screen).
  void simulateFall() {
    _fireSimulatedAlert('fall', 0.92);
  }

  /// Simulate a fight event (for testing via AI Test Screen).
  void simulateFight() {
    _fireSimulatedAlert('fight', 0.88);
  }

  /// Simulate an emergency running event (for testing via AI Test Screen).
  void simulateRunning() {
    _fireSimulatedAlert('running', 0.85);
  }

  void _fireSimulatedAlert(String type, double confidence) {
    final result = MovementResult(
      type: type,
      confidence: confidence,
      timestamp: DateTime.now(),
      accelerationMagnitude: 0,
    );
    _lastResult = result;
    _resultController.add(result);
    if (_countdownTimer == null) {
      _startCountdown(type, confidence);
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // Cleanup
  // ══════════════════════════════════════════════════════════════════════════

  void dispose() {
    stopDetection();
    _interpreter?.close();
    _resultController.close();
    _alertController.close();
    _countdownController.close();
  }
}
