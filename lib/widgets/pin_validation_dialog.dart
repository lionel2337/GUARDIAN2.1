/// Pin Validation Dialog — Used for Duress Dismissal
library;

import 'package:flutter/material.dart';
import '../services/pin_service.dart';
import '../utils/constants.dart';

class PinValidationDialog extends StatefulWidget {
  const PinValidationDialog({super.key});

  /// Displays the dialog and returns the security level of the entered PIN.
  /// Returns null if the dialog is dismissed without a valid PIN.
  static Future<int?> show(BuildContext context) {
    return showDialog<int>(
      context: context,
      barrierDismissible: false, // Force PIN entry
      builder: (context) => const PinValidationDialog(),
    );
  }

  @override
  State<PinValidationDialog> createState() => _PinValidationDialogState();
}

class _PinValidationDialogState extends State<PinValidationDialog> {
  String _pin = '';
  bool _isChecking = false;
  String? _error;

  void _onKeyPressed(String key) async {
    if (_isChecking) return;

    setState(() {
      _error = null;
      if (key == '<') {
        if (_pin.isNotEmpty) {
          _pin = _pin.substring(0, _pin.length - 1);
        }
      } else {
        if (_pin.length < 4) {
          _pin += key;
        }
      }
    });

    if (_pin.length == 4) {
      setState(() {
        _isChecking = true;
      });

      final level = await PinService.instance.verifyPin(_pin);
      
      if (!mounted) return;

      if (level == 0) {
        // Invalid PIN
        setState(() {
          _pin = '';
          _error = 'Invalid PIN';
          _isChecking = false;
        });
      } else {
        // Return the security level (1, 2, or 3)
        Navigator.of(context).pop(level);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimens.radiusL)),
      child: Padding(
        padding: const EdgeInsets.all(AppDimens.paddingL),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock_outline_rounded, size: 48, color: AppColors.primary),
            const SizedBox(height: AppDimens.paddingM),
            const Text(
              'Enter PIN to dismiss',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppDimens.paddingL),
            
            // PIN Display
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (index) {
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: index < _pin.length ? AppColors.primary : Colors.white24,
                  ),
                );
              }),
            ),
            
            if (_error != null) ...[
              const SizedBox(height: 16),
              Text(
                _error!,
                style: const TextStyle(color: AppColors.danger, fontSize: 14),
              ),
            ] else ...[
              const SizedBox(height: 30),
            ],

            // Keypad
            SizedBox(
              width: 240,
              child: GridView.count(
                shrinkWrap: true,
                crossAxisCount: 3,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  for (var i = 1; i <= 9; i++) _buildKey(i.toString()),
                  const SizedBox.shrink(),
                  _buildKey('0'),
                  _buildKey('<'),
                ],
              ),
            ),
            
            const SizedBox(height: AppDimens.paddingM),
            
            // Cancel button (optional, but good if they didn't mean to press I'm OK)
            TextButton(
              onPressed: () => Navigator.of(context).pop(null),
              child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKey(String text) {
    return InkWell(
      onTap: () => _onKeyPressed(text),
      borderRadius: BorderRadius.circular(36),
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          shape: BoxShape.circle,
        ),
        child: text == '<'
            ? const Icon(Icons.backspace_outlined, color: Colors.white)
            : Text(
                text,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }
}
