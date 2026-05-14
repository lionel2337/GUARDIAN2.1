/// AI Test Screen — test TFLite models and simulate movement alerts.
///
/// Fully dynamic : reads model shapes at runtime so any compatible
/// .tflite file works without hard-coding dimensions.
library;

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

import '../l10n/app_localizations.dart';
import '../providers/alert_provider.dart';
import '../utils/constants.dart';

class AiTestScreen extends ConsumerStatefulWidget {
  const AiTestScreen({super.key});

  @override
  ConsumerState<AiTestScreen> createState() => _AiTestScreenState();
}

class _AiTestScreenState extends ConsumerState<AiTestScreen> {
  String _audioStatus = "Non testé";
  String _movementStatus = "Non testé";
  List<Map<String, dynamic>> _audioResults = [];
  List<Map<String, dynamic>> _movementResults = [];
  bool _isLoading = false;

  // Default labels — will be overridden if model metadata differs.
  List<String> _audioClasses = ["normal", "scream", "keyword"];
  List<String> _movementClasses = ["normal", "fall", "fight", "running"];

  /// Build a nested List structure that matches [shape].
  /// shape example : [1, 50, 6]  →  List.generate(1, (_) => List.generate(50, (_) => List.generate(6, (_) => rand)))
  dynamic _buildRandomInput(List<int> shape, {double min = -1, double max = 1}) {
    final random = Random();
    dynamic build(List<int> dims) {
      if (dims.isEmpty) return random.nextDouble() * (max - min) + min;
      return List.generate(dims.first, (_) => build(dims.sublist(1)));
    }
    return build(shape);
  }

  /// Build a flat or nested output buffer matching [shape].
  dynamic _buildOutputBuffer(List<int> shape) {
    dynamic build(List<int> dims) {
      if (dims.isEmpty) return 0.0;
      return List.generate(dims.first, (_) => build(dims.sublist(1)));
    }
    return build(shape);
  }

  /// Recursively flatten a nested list to List<double>.
  List<double> _flattenToDouble(dynamic value) {
    if (value is List) {
      return value.expand((e) => _flattenToDouble(e)).toList();
    }
    return [value is int ? value.toDouble() : value as double];
  }

  Future<void> _testAudioModel() async {
    setState(() {
      _audioStatus = "Test en cours...";
      _audioResults = [];
    });

    Interpreter? interpreter;
    try {
      final options = InterpreterOptions()
        ..threads = 2
        ..useNnApiForAndroid = false;
      interpreter = await Interpreter.fromAsset(
        'assets/ml/audio_model_float16.tflite',
        options: options,
      );

      final inputShape = interpreter.getInputTensor(0).shape;
      final outputShape = interpreter.getOutputTensor(0).shape;
      final inputType = interpreter.getInputTensor(0).type;
      final outputType = interpreter.getOutputTensor(0).type;

      // Generate random input that matches the model's exact shape.
      final input = _buildRandomInput(inputShape);
      final output = _buildOutputBuffer(outputShape);

      // CRITICAL: Interpreter.fromAsset already allocates tensors.
      // Calling allocateTensors() again causes "Bad state: failed precondition".
      // We run directly.
      interpreter.run(input, output);
      interpreter.close();
      interpreter = null;

      // Flatten output to probabilities.
      final flatOutput = _flattenToDouble(output);
      final probs = _softmax(List<double>.from(flatOutput));

      // Adapt class names to output size.
      if (probs.length == 2) {
        _audioClasses = ["normal", "danger"];
      } else if (probs.length == 3) {
        _audioClasses = ["normal", "scream", "keyword"];
      } else if (probs.length >= 4) {
        _audioClasses = List.generate(
          probs.length,
          (i) => i == 0 ? "normal" : "class_$i",
        );
      }

      setState(() {
        _audioStatus = "✅ Modèle fonctionnel\n"
            "Shape entrée : $inputShape\n"
            "Shape sortie : $outputShape\n"
            "Type entrée : $inputType / sortie : $outputType";
        _audioResults = List.generate(
          probs.length.clamp(0, 10),
          (i) => {"class": _audioClasses[i], "prob": probs[i]},
        );
      });
    } catch (e, st) {
      interpreter?.close();
      setState(() => _audioStatus = "❌ Erreur : $e\n$st");
    }
  }

  Future<void> _testMovementModel() async {
    setState(() {
      _movementStatus = "Test en cours...";
      _movementResults = [];
    });

    Interpreter? interpreter;
    try {
      final options = InterpreterOptions()
        ..threads = 2
        ..useNnApiForAndroid = false;
      interpreter = await Interpreter.fromAsset(
        'assets/ml/movement_model_float16.tflite',
        options: options,
      );

      final inputShape = interpreter.getInputTensor(0).shape;
      final outputShape = interpreter.getOutputTensor(0).shape;
      final inputType = interpreter.getInputTensor(0).type;
      final outputType = interpreter.getOutputTensor(0).type;

      // Generate random input that matches the model's exact shape.
      final input = _buildRandomInput(inputShape, min: -2, max: 2);
      final output = _buildOutputBuffer(outputShape);

      // CRITICAL: Do NOT call allocateTensors() after fromAsset.
      interpreter.run(input, output);
      interpreter.close();
      interpreter = null;

      final flatOutput = _flattenToDouble(output);
      final probs = _softmax(List<double>.from(flatOutput));

      // Adapt class names to output size.
      if (probs.length == 2) {
        _movementClasses = ["normal", "danger"];
      } else if (probs.length == 3) {
        _movementClasses = ["normal", "fall", "fight"];
      } else if (probs.length >= 4) {
        _movementClasses = ["normal", "fall", "fight", "running"];
        if (probs.length > 4) {
          _movementClasses = List.generate(
            probs.length,
            (i) => i == 0 ? "normal" : "class_$i",
          );
        }
      }

      setState(() {
        _movementStatus = "✅ Modèle fonctionnel\n"
            "Shape entrée : $inputShape\n"
            "Shape sortie : $outputShape\n"
            "Type entrée : $inputType / sortie : $outputType";
        _movementResults = List.generate(
          probs.length.clamp(0, 10),
          (i) => {"class": _movementClasses[i], "prob": probs[i]},
        );
      });
    } catch (e, st) {
      interpreter?.close();
      setState(() => _movementStatus = "❌ Erreur : $e\n$st");
    }
  }

  Future<void> _testAll() async {
    setState(() => _isLoading = true);
    await _testAudioModel();
    await _testMovementModel();
    setState(() => _isLoading = false);
  }

  List<double> _softmax(List<double> logits) {
    final maxVal = logits.reduce(max);
    final exps = logits.map((x) => exp(x - maxVal)).toList();
    final sum = exps.reduce((a, b) => a + b);
    return exps.map((e) => e / sum).toList();
  }

  void _simulateFall() {
    ref.read(alertProvider.notifier).simulateMovementFall();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)?.fallDetected ?? 'Fall simulation triggered',
          ),
        ),
      );
    }
  }

  void _simulateFight() {
    ref.read(alertProvider.notifier).simulateMovementFight();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Fight simulation triggered'),
        ),
      );
    }
  }

  void _simulateRunning() {
    ref.read(alertProvider.notifier).simulateMovementRunning();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Running simulation triggered')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final alertNotifier = ref.read(alertProvider.notifier);
    final audioDiag = alertNotifier.audioDiagnostics;
    final movementDiag = alertNotifier.movementDiagnostics;
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations?.settings ?? "Test Modèles IA"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Test All Button ───────────────────────────
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _testAll,
              icon: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.play_arrow),
              label: Text(_isLoading
                  ? "Test en cours..."
                  : "Tester les deux modèles"),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
            ),

            const SizedBox(height: 24),

            // ── Audio Model Card ─────────────────────────────
            _buildModelCard(
              title: "🎤 Modèle Audio",
              subtitle: "Détection cris & mots-clés",
              status: _audioStatus,
              results: _audioResults,
              onTest: _testAudioModel,
              color: Colors.blue,
            ),

            const SizedBox(height: 16),

            // ── Movement Model Card ─────────────────────────
            _buildModelCard(
              title: "📱 Modèle Mouvement",
              subtitle: "Détection chutes & bagarres",
              status: _movementStatus,
              results: _movementResults,
              onTest: _testMovementModel,
              color: Colors.orange,
            ),

            const SizedBox(height: 24),

            // ── Movement Simulation ─────────────────────────
            _sectionHeader("Simulation Mouvement"),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(AppDimens.radiusM),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Déclencher une alerte de test :",
                    style: TextStyle(
                        fontSize: 12, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _simulateFall,
                        icon: const Icon(Icons.person_off),
                        label: const Text("Chute"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.danger,
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: _simulateFight,
                        icon: const Icon(Icons.sports_martial_arts),
                        label: const Text("Bagarre"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.warning,
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: _simulateRunning,
                        icon: const Icon(Icons.directions_run),
                        label: const Text("Course"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.info,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── Diagnostics ─────────────────────────────────
            _sectionHeader("Diagnostics en temps réel"),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(AppDimens.radiusM),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDiagnosticTile("Audio", audioDiag),
                  const Divider(color: AppColors.divider, height: 16),
                  _buildDiagnosticTile("Mouvement", movementDiag),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── Explanation ────────────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppDimens.radiusM),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Comment interpréter les résultats ?",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "• Les probabilités doivent sommer à ~1.0\n"
                    "• Sur des données aléatoires, chaque classe\n"
                    "  devrait avoir ~33% (audio) ou ~25% (mouvement)\n"
                    "• Si une classe dépasse 90% sur données aléatoires\n"
                    "  → le modèle est biaisé, ré-entraîne-le\n"
                    "• Le test détecte automatiquement les shapes",
                    style: TextStyle(
                        fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.textHint,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _buildDiagnosticTile(String title, Map<String, dynamic> data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.accent)),
        const SizedBox(height: 4),
        ...data.entries.map((e) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 1),
            child: Text(
              "${e.key}: ${e.value}",
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
                fontFamily: 'monospace',
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildModelCard({
    required String title,
    required String subtitle,
    required String status,
    required List<Map<String, dynamic>> results,
    required VoidCallback onTest,
    required Color color,
  }) {
    final bool hasError = status.contains("❌");
    final bool isOk = status.contains("✅");

    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppDimens.radiusM),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textHint,
                    ),
                  ),
                ],
              ),
              TextButton(onPressed: onTest, child: const Text("Tester")),
            ],
          ),
          const Divider(color: AppColors.divider),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: hasError
                  ? AppColors.danger.withOpacity(0.1)
                  : isOk
                      ? AppColors.success.withOpacity(0.1)
                      : AppColors.surface,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              status,
              style: TextStyle(
                fontSize: 12,
                color: hasError
                    ? AppColors.danger
                    : isOk
                        ? AppColors.success
                        : AppColors.textSecondary,
                fontFamily: 'monospace',
              ),
            ),
          ),
          if (results.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text(
              "Probabilités (input aléatoire) :",
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            ...results.map((r) {
              final prob = (r["prob"] as double);
              final label = r["class"] as String;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    SizedBox(
                      width: 70,
                      child: Text(label,
                          style: const TextStyle(fontSize: 12)),
                    ),
                    Expanded(
                      child: LinearProgressIndicator(
                        value: prob,
                        backgroundColor: AppColors.surface,
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "${(prob * 100).toStringAsFixed(1)}%",
                      style: const TextStyle(
                          fontSize: 12, fontFamily: 'monospace'),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
}
