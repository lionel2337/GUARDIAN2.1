/// Pin Setup Screen — Configure multi-level emergency PINs.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/pin_provider.dart';
import '../utils/constants.dart';

class PinSetupScreen extends ConsumerStatefulWidget {
  const PinSetupScreen({super.key});

  @override
  ConsumerState<PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends ConsumerState<PinSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _pin1Controller = TextEditingController();
  final _pin2Controller = TextEditingController();
  final _pin3Controller = TextEditingController();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Pre-fill if already configured
    final isConfigured = ref.read(pinProvider);
    if (isConfigured) {
      _pin1Controller.text = '****';
      _pin2Controller.text = '****';
      _pin3Controller.text = '****';
    }
  }

  Future<void> _savePins() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    await ref.read(pinProvider.notifier).savePins(
          pin1: _pin1Controller.text.trim(),
          pin2: _pin2Controller.text.trim(),
          pin3: _pin3Controller.text.trim(),
        );

    setState(() => _isLoading = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Codes de sécurité enregistrés avec succès.'),
          backgroundColor: AppColors.success,
        ),
      );
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sécurité & Codes PIN'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.darkGradient),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppDimens.paddingL),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Système de Codes Multi-Niveaux',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Configurez 3 codes PIN à 4 chiffres. En cas de danger, utilisez ces codes sur le pavé numérique d\'urgence selon la situation.',
                    style: TextStyle(fontSize: 16, color: AppColors.textHint),
                  ),
                  const SizedBox(height: 32),

                  // Niveau 1
                  _buildPinSection(
                    title: 'Niveau 1 : Faux Code',
                    description: 'Simule une erreur de déverrouillage (Ex: braquage).',
                    controller: _pin1Controller,
                    color: AppColors.textHint,
                    icon: Icons.error_outline,
                  ),

                  // Niveau 2
                  _buildPinSection(
                    title: 'Niveau 2 : Alerte Discrète',
                    description: 'Vous avez un doute. Alerte vos proches en silence sans prévenir la police.',
                    controller: _pin2Controller,
                    color: AppColors.accent,
                    icon: Icons.people_alt,
                  ),

                  // Niveau 3
                  _buildPinSection(
                    title: 'Niveau 3 : Sous la Contrainte',
                    description: 'Cas grave. Alerte immédiatement vos proches ET la Gendarmerie (117) en silence.',
                    controller: _pin3Controller,
                    color: AppColors.danger,
                    icon: Icons.local_police,
                  ),

                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _savePins,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: AppColors.success,
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            'Enregistrer les Codes',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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

  Widget _buildPinSection({
    required String title,
    required String description,
    required TextEditingController controller,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(description, style: const TextStyle(color: AppColors.textHint)),
          const SizedBox(height: 16),
          TextFormField(
            controller: controller,
            keyboardType: TextInputType.number,
            maxLength: 4,
            obscureText: true,
            style: const TextStyle(
              fontSize: 24,
              letterSpacing: 8,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
            decoration: InputDecoration(
              counterText: '',
              hintText: '----',
              filled: true,
              fillColor: AppColors.background,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
            ),
            validator: (value) {
              if (value == null || value.length != 4) {
                return 'Le code doit contenir 4 chiffres';
              }
              if (value == '****') return null; // Already configured
              if (int.tryParse(value) == null) {
                return 'Chiffres uniquement';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _pin1Controller.dispose();
    _pin2Controller.dispose();
    _pin3Controller.dispose();
    super.dispose();
  }
}
