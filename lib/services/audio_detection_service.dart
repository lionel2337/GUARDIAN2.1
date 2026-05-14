/// Audio Detection Service — on-device keyword and scream detection.
///
/// Operates in two alternating phases to avoid microphone conflicts:
///   1. **Keyword Phase** (continuous) — Uses `speech_to_text` to listen for
///      emergency keywords like "au secours". Restarts automatically after
///      each session.
///   2. **Amplitude Phase** (burst) — When speech recognition pauses, briefly
///      records audio to check dB levels for screams. Runs the TFLite model
///      if available.
///
/// Both engines run 100 % on-device. Zero internet required when offline
/// speech packs are installed.
library;

import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:fftea/fftea.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// Data classes
// ═══════════════════════════════════════════════════════════════════════════════

class AudioResult {
  final String type; // 'normal', 'scream', 'keyword'
  final double confidence;
  final DateTime timestamp;
  final double amplitude; // dB value
  final double? frequency;
  final String? detectedWord;

  const AudioResult({
    required this.type,
    required this.confidence,
    required this.timestamp,
    required this.amplitude,
    this.frequency,
    this.detectedWord,
  });

  bool get isDangerous => type != 'normal' && confidence > 0.65;
}

class AudioAlert {
  final String type;
  final double confidence;
  final DateTime timestamp;
  final String? detectedWord;

  const AudioAlert({
    required this.type,
    required this.confidence,
    required this.timestamp,
    this.detectedWord,
  });
}

// ═══════════════════════════════════════════════════════════════════════════════
// Service
// ═══════════════════════════════════════════════════════════════════════════════

class AudioDetectionService {
  // ── Configuration ─────────────────────────────────────────────────────────
  static const double _screamThreshold = 0.65;
  static const int _keywordPhaseSeconds = 12;
  static const int _amplitudePhaseSeconds = 3;

  /// Minimum dB that qualifies as a possible scream.
  static const double _screamDbFloor = -12.0;

  /// Cooldown between alerts to avoid spamming (seconds).
  static const int _alertCooldownSeconds = 8;

  // ── TFLite ────────────────────────────────────────────────────────────────
  Interpreter? _interpreter;
  bool _modelLoaded = false;
  List<int> _inputShape = [];
  List<int> _outputShape = [];
  List<String> _modelClasses = ['normal', 'scream', 'keyword'];

  // ── Emergency Keywords (French + English) ─────────────────────────────────
  static const List<String> emergencyKeywordsFr = [
    'au secours',
    'secours',
    'à l aide',
    'a l aide',
    'aidez moi',
    'aidez-moi',
    'aide moi',
    'aide-moi',
    'arretez',
    'arreter',
    'arrete',
    'arrêtez',
    'arrêter',
    'arrête',
    'laissez moi',
    'laissez-moi',
    'laisse moi',
    'laisse-moi',
    'lachez moi',
    'lachez-moi',
    'lache moi',
    'lache-moi',
    'lâchez moi',
    'lâchez-moi',
    'lâche moi',
    'lâche-moi',
    'non non',
    'police',
    'danger',
    'appelez la police',
    'appeler la police',
    'j ai peur',
    'j ai mal',
    'ne me touche pas',
    'ne me touchez pas',
    'sauvez moi',
    'sauvez-moi',
    'sauve moi',
    'sauve-moi',
  ];

  static const List<String> emergencyKeywordsEn = [
    'help',
    'help me',
    'somebody help',
    'stop',
    'stop it',
    'leave me alone',
    'let me go',
    'let go of me',
    'don t touch me',
    'do not touch me',
    'call the police',
    'police',
    'danger',
    'save me',
    'i m scared',
    'no no',
  ];

  // ── State ─────────────────────────────────────────────────────────────────
  bool _isListening = false;
  bool _recorderReady = false;
  bool _speechReady = false;
  bool _hasMicPermission = false;

  // Recorder (amplitude monitoring)
  final AudioRecorder _recorder = AudioRecorder();
  String? _pcmPath;

  // Speech recognition (keyword detection)
  final stt.SpeechToText _speech = stt.SpeechToText();
  String _currentLocaleId = 'fr_FR';
  bool _speechActive = false;

  // Phase control
  Timer? _phaseTimer;
  String _currentPhase = 'idle';

  // Amplitude buffer for trend analysis
  final List<double> _amplitudeBuffer = [];
  static const int _amplitudeBufferSize = 20;

  // Cooldown tracking
  DateTime? _lastAlertTime;

  // Diagnostics
  String _lastRecognizedText = '';
  String _lastSpeechError = '';
  double _lastAmplitudeDb = -160;

  // Streams
  final _resultController = StreamController<AudioResult>.broadcast();
  final _alertController = StreamController<AudioAlert>.broadcast();

  Stream<AudioResult> get results => _resultController.stream;
  Stream<AudioAlert> get alerts => _alertController.stream;
  bool get isListening => _isListening;

  // ═══════════════════════════════════════════════════════════════════════════
  // Initialization
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> initialize() async {
    await _requestPermissions();
    await _initRecorder();
    await _initSpeechRecognition();
    await _initTfliteModel();
  }

  Future<void> _requestPermissions() async {
    final status = await Permission.microphone.request();
    _hasMicPermission = status.isGranted;
  }

  Future<void> _initRecorder() async {
    try {
      if (!_hasMicPermission) {
        _recorderReady = false;
        return;
      }
      _recorderReady = await _recorder.hasPermission();
    } catch (e) {
      _recorderReady = false;
    }
  }

  Future<void> _initSpeechRecognition() async {
    try {
      if (!_hasMicPermission) {
        _speechReady = false;
        return;
      }
      _speechReady = await _speech.initialize(
        onError: _onSpeechError,
        onStatus: _onSpeechStatus,
        debugLogging: false,
      );

      if (_speechReady) {
        try {
          final locales = await _speech.locales();
          if (locales.isNotEmpty) {
            final targetLocale = locales.firstWhere(
              (l) => l.localeId.startsWith('fr'),
              orElse: () => locales.firstWhere(
                (l) => l.localeId.startsWith('en'),
                orElse: () => locales.first,
              ),
            );
            _currentLocaleId = targetLocale.localeId;
          }
        } catch (e) {
          _lastSpeechError = 'Locale error: $e';
        }
      } else {
        _lastSpeechError = 'Speech init returned false';
      }
    } catch (e) {
      _speechReady = false;
      _lastSpeechError = 'Init error: $e';
    }
  }

  Future<void> _initTfliteModel() async {
    try {
      final options = InterpreterOptions()
        ..threads = 2
        ..useNnApiForAndroid = false;
      _interpreter = await Interpreter.fromAsset(
        'assets/ml/audio_model_float16.tflite',
        options: options,
      );
      _inputShape = _interpreter!.getInputTensor(0).shape;
      _outputShape = _interpreter!.getOutputTensor(0).shape;

      // Auto-detect class count from output shape.
      final outSize = _outputShape.isNotEmpty ? _outputShape.last : 0;
      if (outSize == 2) {
        _modelClasses = ['normal', 'danger'];
      } else if (outSize == 3) {
        _modelClasses = ['normal', 'scream', 'keyword'];
      } else if (outSize >= 4) {
        _modelClasses = List.generate(outSize, (i) => i == 0 ? 'normal' : 'class_$i');
      }

      _modelLoaded = true;
    } catch (e) {
      _modelLoaded = false;
      _interpreter = null;
      _inputShape = [];
      _outputShape = [];
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Start / Stop
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> startListening() async {
    if (_isListening) return;
    if (!_speechReady && !_recorderReady) {
      // Try to re-initialize if permissions were denied earlier.
      await initialize();
    }
    _isListening = true;
    _amplitudeBuffer.clear();

    // Begin with keyword detection phase.
    _startKeywordPhase();
  }

  void stopListening() {
    _isListening = false;
    _phaseTimer?.cancel();
    _phaseTimer = null;
    _stopRecorder();
    _speech.stop();
    _speechActive = false;
    _currentPhase = 'idle';
    _amplitudeBuffer.clear();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Phase Management (prevents microphone conflict)
  // ═══════════════════════════════════════════════════════════════════════════

  void _startKeywordPhase() {
    if (!_isListening || _currentPhase == 'keyword') return;
    _currentPhase = 'keyword';
    _stopRecorder();

    // Only start speech recognition if it is actually available.
    // Otherwise stay briefly in keyword phase and move to amplitude.
    if (_speechReady) {
      _startSpeechRecognitionListening();
    }

    // Switch to amplitude phase after keyword phase duration.
    _phaseTimer?.cancel();
    _phaseTimer = Timer(
      const Duration(seconds: _keywordPhaseSeconds),
      () => _startAmplitudePhase(),
    );
  }

  Future<void> _startAmplitudePhase() async {
    if (!_isListening || _currentPhase == 'amplitude') return;
    _currentPhase = 'amplitude';

    // CRITICAL: Await speech stop to free the microphone before
    // starting the recorder. Without this the recorder fails to
    // obtain the mic on many Android devices.
    if (_speechActive) {
      try {
        await _speech.stop();
      } catch (_) {}
      _speechActive = false;
    }

    // Small safety delay to ensure the OS has released the mic.
    await Future.delayed(const Duration(milliseconds: 300));

    await _startAmplitudeRecording();

    _phaseTimer?.cancel();
    _phaseTimer = Timer(
      const Duration(seconds: _amplitudePhaseSeconds),
      () async {
        await _runTfliteInference();
        await _stopRecorder();
        _cleanupOldPcmFiles();
        if (_isListening) _startKeywordPhase();
      },
    );
  }

  Future<void> _cleanupOldPcmFiles() async {
    try {
      final tempDir = await getTemporaryDirectory();
      final files = tempDir
          .listSync()
          .whereType<File>()
          .where((f) => f.path.contains('guardians_amplitude_'));
      for (final file in files) {
        try {
          file.deleteSync();
        } catch (_) {}
      }
    } catch (_) {}
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ENGINE 1: Speech Recognition (Keyword Detection)
  // ═══════════════════════════════════════════════════════════════════════════

  void _startSpeechRecognitionListening() {
    if (!_speechReady || _speechActive || !_isListening) return;
    _speechActive = true;

    try {
      _speech.listen(
        onResult: _onSpeechResult,
        localeId: _currentLocaleId,
        listenOptions: stt.SpeechListenOptions(
          listenMode: stt.ListenMode.dictation,
          cancelOnError: false,
          partialResults: true,
          onDevice: true,
        ),
        listenFor: const Duration(seconds: _keywordPhaseSeconds + 2),
        pauseFor: const Duration(seconds: 3),
      );
    } catch (e) {
      _speechActive = false;
      _lastSpeechError = 'Listen error: $e';
    }
  }

  void _onSpeechResult(SpeechRecognitionResult result) {
    if (!_isListening) return;

    final recognizedText = result.recognizedWords.toLowerCase().trim();
    if (recognizedText.isEmpty) return;

    _lastRecognizedText = recognizedText;

    // Check recognized text against emergency keywords.
    final matchedKeyword = _matchKeyword(recognizedText);

    if (matchedKeyword != null) {
      final audioResult = AudioResult(
        type: 'keyword',
        confidence: result.confidence > 0 ? result.confidence : 0.90,
        timestamp: DateTime.now(),
        amplitude: 0,
        detectedWord: matchedKeyword,
      );

      _resultController.add(audioResult);

      if (_canFireAlert()) {
        _fireAlert('keyword', audioResult.confidence,
            detectedWord: matchedKeyword);
      }
    }
  }

  String? _matchKeyword(String text) {
    // Remove accents for more robust matching.
    final normalizedText = _removeAccents(text);

    for (final keyword in emergencyKeywordsFr) {
      if (normalizedText.contains(_removeAccents(keyword))) return keyword;
    }

    for (final keyword in emergencyKeywordsEn) {
      if (normalizedText.contains(_removeAccents(keyword))) return keyword;
    }

    // Check for repeated "non" / "no" / "stop".
    final nonCount = RegExp(r'\bnon\b').allMatches(normalizedText).length;
    if (nonCount >= 2) return 'non non';

    final noCount = RegExp(r'\bno\b').allMatches(normalizedText).length;
    if (noCount >= 2) return 'no no';

    final stopCount = RegExp(r'\bstop\b').allMatches(normalizedText).length;
    if (stopCount >= 2) return 'stop stop';

    return null;
  }

  String _removeAccents(String input) {
    const accents = 'àáâãäåèéêëìíîïòóôõöùúûüýÿçñ';
    const without = 'aaaaaaeeeeiiiiooooouuuuyycn';
    String result = input;
    for (int i = 0; i < accents.length; i++) {
      result = result.replaceAll(accents[i], without[i]);
    }
    return result;
  }

  void _onSpeechError(SpeechRecognitionError error) {
    _lastSpeechError = '${error.errorMsg} (${error.permanent})';
    _speechActive = false;
    if (_isListening &&
        _currentPhase == 'keyword' &&
        error.errorMsg != 'error_busy') {
      Future.delayed(const Duration(milliseconds: 800), () {
        if (_isListening && _currentPhase == 'keyword') {
          _startSpeechRecognitionListening();
        }
      });
    }
  }

  void _onSpeechStatus(String status) {
    if (status == 'done' || status == 'notListening') {
      _speechActive = false;
      // If we are still in keyword phase and listening is on, restart.
      if (_isListening && _currentPhase == 'keyword') {
        Future.delayed(const Duration(milliseconds: 300), () {
          if (_isListening && _currentPhase == 'keyword') {
            _startSpeechRecognitionListening();
          }
        });
      }
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ENGINE 2: Amplitude Monitor (Scream Detection)
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> _startAmplitudeRecording() async {
    if (!_recorderReady || !_isListening) return;

    try {
      // Make absolutely sure we are not already recording.
      if (await _recorder.isRecording()) {
        await _recorder.stop();
        await Future.delayed(const Duration(milliseconds: 100));
      }

      final tempDir = await getTemporaryDirectory();
      _pcmPath = '${tempDir.path}/guardians_amplitude_${DateTime.now().millisecondsSinceEpoch}.pcm';

      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.pcm16bits,
          sampleRate: 16000,
          numChannels: 1,
          autoGain: false,
          echoCancel: false,
          noiseSuppress: false,
        ),
        path: _pcmPath!,
      );

      // Poll amplitude every 400ms during the amplitude phase.
      _pollAmplitudeDuringPhase();
    } catch (e) {
      _lastSpeechError = 'Recorder start error: $e';
      _recorderReady = false;
    }
  }

  void _pollAmplitudeDuringPhase() {
    if (!_isListening || _currentPhase != 'amplitude') return;

    Future.delayed(const Duration(milliseconds: 400), () async {
      if (!_isListening || _currentPhase != 'amplitude') return;

      try {
        final amp = await _recorder.getAmplitude();
        final currentDb = amp.current;
        _lastAmplitudeDb = currentDb;

        _amplitudeBuffer.add(currentDb);
        if (_amplitudeBuffer.length > _amplitudeBufferSize) {
          _amplitudeBuffer.removeAt(0);
        }

        final result = _analyzeAmplitude(currentDb);
        _resultController.add(result);

        if (result.isDangerous && _canFireAlert()) {
          _fireAlert(result.type, result.confidence, detectedWord: null);
        }
      } catch (e) {
        // Skip frame but keep polling.
        _lastSpeechError = 'Amp poll error: $e';
      }

      // Continue polling if still in amplitude phase.
      if (_isListening && _currentPhase == 'amplitude') {
        _pollAmplitudeDuringPhase();
      }
    });
  }

  Future<void> _stopRecorder() async {
    try {
      if (await _recorder.isRecording()) {
        await _recorder.stop();
      }
    } catch (e) {
      _lastSpeechError = 'Recorder stop error: $e';
    }
    _pcmPath = null;
  }

  AudioResult _analyzeAmplitude(double currentDb) {
    double variance = 0.0;
    double avgDb = currentDb;

    if (_amplitudeBuffer.length >= 4) {
      final recent = _amplitudeBuffer.sublist(_amplitudeBuffer.length - 4);
      avgDb = recent.reduce((a, b) => a + b) / recent.length;
      variance = recent.fold<double>(
              0.0, (sum, v) => sum + (v - avgDb) * (v - avgDb)) /
          recent.length;
    }

    double rateOfChange = 0.0;
    if (_amplitudeBuffer.length >= 2) {
      final older = _amplitudeBuffer[_amplitudeBuffer.length - 2];
      rateOfChange = currentDb - older;
    }

    double screamConfidence = 0.0;

    if (currentDb > -5.0) {
      screamConfidence = 0.95;
    } else if (currentDb > -8.0 && rateOfChange > 12.0) {
      screamConfidence = 0.90;
    } else if (currentDb > -10.0 && rateOfChange > 8.0 && variance > 25.0) {
      screamConfidence = 0.85;
    } else if (currentDb > -12.0 && rateOfChange > 6.0) {
      final loudReadings = _amplitudeBuffer.where((db) => db > -15.0).length;
      if (loudReadings >= 2) {
        screamConfidence = 0.80;
      }
    } else if (currentDb > _screamDbFloor && variance > 60.0) {
      screamConfidence = 0.70;
    }

    if (screamConfidence >= _screamThreshold) {
      return AudioResult(
        type: 'scream',
        confidence: screamConfidence,
        timestamp: DateTime.now(),
        amplitude: currentDb,
      );
    }

    return AudioResult(
      type: 'normal',
      confidence: 1.0 - ((currentDb + 160) / 160).clamp(0.0, 1.0),
      timestamp: DateTime.now(),
      amplitude: currentDb,
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TFLite Model (runs during amplitude phase if model is loaded)
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> _runTfliteInference() async {
    if (!_modelLoaded || _interpreter == null || _pcmPath == null) return;

    try {
      final file = File(_pcmPath!);
      if (!file.existsSync()) return;

      final bytes = await file.readAsBytes();
      if (bytes.length < 2048) return;

      final byteData = ByteData.view(bytes.buffer);
      final samples = <double>[];
      for (int i = 0; i < bytes.length - 1; i += 2) {
        final sample = byteData.getInt16(i, Endian.little);
        samples.add(sample / 32768.0);
      }

      dynamic input;
      dynamic output;

      // Build input dynamically based on model shape.
      if (_inputShape.length == 3) {
        // Expected [1, frames, features]
        final targetFrames = _inputShape[1];
        final targetFeatures = _inputShape[2];

        // Compute needed samples: each frame is 512 samples, step 256.
        final neededSamples = (targetFrames - 1) * 256 + 512;
        if (samples.length < neededSamples) return;

        final recentSamples = samples.sublist(samples.length - neededSamples);
        final mfcc = computeMfcc(recentSamples, targetFeatures: targetFeatures);

        final inputFrames = List.generate(targetFrames, (i) {
          if (i < mfcc.length) {
            return mfcc[mfcc.length - targetFrames + i];
          }
          return List.filled(targetFeatures, 0.0);
        });

        input = <List<List<double>>>[inputFrames];
        output = <List<double>>[List<double>.filled(_outputShape.last, 0.0)];
      } else if (_inputShape.length == 2) {
        // Expected [1, samples]
        final targetSamples = _inputShape[1];
        if (samples.length < targetSamples) return;
        input = <List<double>>[samples.sublist(samples.length - targetSamples)];
        output = <List<double>>[List<double>.filled(_outputShape.last, 0.0)];
      } else {
        // Unsupported shape — skip inference.
        return;
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
      if (type != 'normal' && maxProb > 0.65 && _canFireAlert()) {
        _fireAlert(type, maxProb,
            detectedWord: type == 'keyword' ? 'keyword' : null);
      }
    } catch (e) {
      // Model inference failed — heuristics are still running.
      // Do not crash; amplitude monitoring continues.
    }
  }

  List<double> _softmax(List<double> logits) {
    final maxVal = logits.reduce(math.max);
    final exps = logits.map((x) => math.exp(x - maxVal)).toList();
    final sum = exps.reduce((a, b) => a + b);
    return exps.map((e) => e / sum).toList();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Alert Management
  // ═══════════════════════════════════════════════════════════════════════════

  bool _canFireAlert() {
    if (_lastAlertTime == null) return true;
    return DateTime.now().difference(_lastAlertTime!).inSeconds >=
        _alertCooldownSeconds;
  }

  void _fireAlert(String type, double confidence, {String? detectedWord}) {
    _lastAlertTime = DateTime.now();
    _alertController.add(AudioAlert(
      type: type,
      confidence: confidence,
      timestamp: DateTime.now(),
      detectedWord: detectedWord,
    ));
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // MFCC Feature Extraction
  // ═══════════════════════════════════════════════════════════════════════════

  List<List<double>> computeMfcc(List<double> audioSamples, {int targetFeatures = 13}) {
    final frames = _frameSignal(audioSamples);
    final mfccs = <List<double>>[];

    for (final frame in frames) {
      final windowed = _hammingWindow(frame);
      final powerSpectrum = _computePowerSpectrum(windowed);
      final melEnergies = _applyMelFilterbank(powerSpectrum);
      final logMel = melEnergies.map((e) => math.log(e + 1e-10)).toList();
      final mfcc = _dct(logMel);
      mfccs.add(mfcc.sublist(0, math.min(targetFeatures, mfcc.length)));
    }

    return mfccs;
  }

  List<List<double>> _frameSignal(List<double> signal) {
    const frameLength = 512;
    const step = 256;
    final frames = <List<double>>[];
    for (int i = 0; i + frameLength <= signal.length; i += step) {
      frames.add(signal.sublist(i, i + frameLength));
    }
    return frames;
  }

  List<double> _hammingWindow(List<double> frame) {
    final n = frame.length;
    return List.generate(n, (i) {
      final w = 0.54 - 0.46 * math.cos(2 * math.pi * i / (n - 1));
      return frame[i] * w;
    });
  }

  List<double> _computePowerSpectrum(List<double> frame) {
    final n = frame.length;
    final halfN = n ~/ 2 + 1;
    final fft = FFT(n);
    final freqs = fft.realFft(frame);

    final spectrum = List<double>.filled(halfN, 0.0);
    for (int k = 0; k < halfN && k < freqs.length; k++) {
      final c = freqs[k];
      spectrum[k] = (c.x * c.x + c.y * c.y) / n;
    }
    return spectrum;
  }

  List<double> _applyMelFilterbank(List<double> powerSpectrum) {
    const numFilters = 26;
    final filters = List<double>.filled(numFilters, 0.0);
    final binWidth = powerSpectrum.length / numFilters;
    for (int i = 0; i < numFilters; i++) {
      final start = (i * binWidth).round();
      final end = ((i + 1) * binWidth).round().clamp(0, powerSpectrum.length);
      double sum = 0.0;
      for (int j = start; j < end; j++) {
        sum += powerSpectrum[j];
      }
      filters[i] = sum;
    }
    return filters;
  }

  List<double> _dct(List<double> input) {
    final n = input.length;
    final output = List<double>.filled(n, 0.0);
    for (int k = 0; k < n; k++) {
      double sum = 0.0;
      for (int i = 0; i < n; i++) {
        sum += input[i] * math.cos(math.pi * k * (2 * i + 1) / (2 * n));
      }
      output[k] = sum;
    }
    return output;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Diagnostics
  // ═══════════════════════════════════════════════════════════════════════════

  Map<String, dynamic> get diagnostics => {
        'isListening': _isListening,
        'currentPhase': _currentPhase,
        'recorderReady': _recorderReady,
        'speechReady': _speechReady,
        'hasMicPermission': _hasMicPermission,
        'modelLoaded': _modelLoaded,
        'speechActive': _speechActive,
        'locale': _currentLocaleId,
        'lastRecognizedText': _lastRecognizedText,
        'lastSpeechError': _lastSpeechError,
        'lastAmplitudeDb': _lastAmplitudeDb,
        'bufferSize': _amplitudeBuffer.length,
        'lastAlert': _lastAlertTime?.toIso8601String(),
      };

  // ═══════════════════════════════════════════════════════════════════════════
  // Cleanup
  // ═══════════════════════════════════════════════════════════════════════════

  void dispose() {
    stopListening();
    _recorder.dispose();
    _interpreter?.close();
    _resultController.close();
    _alertController.close();
  }
}
