/// Pin Lock Screen — Emergency numpad for multi-level PIN input.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/alert_provider.dart';
import '../services/pin_service.dart';
import '../utils/constants.dart';

class PinLockScreen extends ConsumerStatefulWidget {
  const PinLockScreen({super.key});

  @override
  ConsumerState<PinLockScreen> createState() => _PinLockScreenState();
}

class _PinLockScreenState extends ConsumerState<PinLockScreen> {
  String _enteredPin = '';
  bool _isError = false;
  bool _isLoading = false;

  void _onDigitPressed(String digit) {
    if (_enteredPin.length < 4) {
      setState(() {
        _enteredPin += digit;
        _isError = false;
      });

      if (_enteredPin.length == 4) {
        _verifyPin();
      }
    }
  }

  void _onDeletePressed() {
    if (_enteredPin.isNotEmpty) {
      setState(() {
        _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
        _isError = false;
      });
    }
  }

  Future<void> _verifyPin() async {
    setState(() => _isLoading = true);
    
    // Slight artificial delay to simulate "processing" and not give away
    // immediately that it was a fake/real pin.
    await Future.delayed(const Duration(milliseconds: 500));

    final level = await PinService.instance.verifyPin(_enteredPin);

    if (!mounted) return;

    if (level == 0) {
      // Mauvais code
      _showError();
    } else if (level == 1) {
      // Niveau 1 : Faux Code
      // Simulons une erreur pour tromper l'agresseur.
      _showError();
    } else if (level == 2) {
      // Niveau 2 : Alerte Discrète (Proches)
      ref.read(alertProvider.notifier).triggerWarning();
      // On affiche une fausse erreur pour ne pas éveiller les soupçons,
      // ou on retourne à l'accueil selon l'UX voulue. Optons pour retourner à l'accueil discrètement.
      context.go('/');
    } else if (level == 3) {
      // Niveau 3 : Contrainte (Police + Proches)
      ref.read(alertProvider.notifier).triggerDuress();
      // On affiche une erreur système pour faire croire à l'agresseur que l'app a planté ou 
      // que le code n'est pas le bon.
      _showError();
    }
  }

  void _showError() {
    setState(() {
      _isError = true;
      _enteredPin = '';
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Dark/discreet background
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white54),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_outline, size: 48, color: Colors.white54),
            const SizedBox(height: 24),
            Text(
              'Saisir le code PIN',
              style: const TextStyle(
                fontSize: 20,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 32),
            
            // Pin Indicators
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (index) {
                final isFilled = index < _enteredPin.length;
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isFilled ? Colors.white : Colors.transparent,
                    border: Border.all(
                      color: _isError ? AppColors.danger : Colors.white54,
                      width: 2,
                    ),
                  ),
                );
              }),
            ),
            
            const SizedBox(height: 24),
            
            // Error Message
            SizedBox(
              height: 24,
              child: _isError
                  ? const Text(
                      'Code PIN incorrect. Veuillez réessayer.',
                      style: TextStyle(color: AppColors.danger, fontSize: 14),
                    )
                  : const SizedBox(),
            ),

            const SizedBox(height: 48),

            // Numpad
            if (_isLoading)
              const Center(child: CircularProgressIndicator(color: Colors.white54))
            else
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 48),
                child: Column(
                  children: [
                    _buildRow(['1', '2', '3']),
                    const SizedBox(height: 16),
                    _buildRow(['4', '5', '6']),
                    const SizedBox(height: 16),
                    _buildRow(['7', '8', '9']),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        const SizedBox(width: 72, height: 72), // Empty space
                        _buildDigitButton('0'),
                        _buildDeleteButton(),
                      ],
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(List<String> digits) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: digits.map((d) => _buildDigitButton(d)).toList(),
    );
  }

  Widget _buildDigitButton(String digit) {
    return InkWell(
      onTap: () => _onDigitPressed(digit),
      borderRadius: BorderRadius.circular(36),
      child: Container(
        width: 72,
        height: 72,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: 0.1),
        ),
        child: Text(
          digit,
          style: const TextStyle(fontSize: 28, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildDeleteButton() {
    return InkWell(
      onTap: _onDeletePressed,
      borderRadius: BorderRadius.circular(36),
      child: Container(
        width: 72,
        height: 72,
        alignment: Alignment.center,
        child: const Icon(Icons.backspace_outlined, color: Colors.white54, size: 28),
      ),
    );
  }
}
