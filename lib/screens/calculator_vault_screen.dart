/// Calculator Vault Screen — Fake calculator interface for Camouflage Mode.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:math_expressions/math_expressions.dart';

import '../providers/alert_provider.dart';
import '../services/pin_service.dart';

class CalculatorVaultScreen extends ConsumerStatefulWidget {
  const CalculatorVaultScreen({super.key});

  @override
  ConsumerState<CalculatorVaultScreen> createState() =>
      _CalculatorVaultScreenState();
}

class _CalculatorVaultScreenState extends ConsumerState<CalculatorVaultScreen> {
  String _expression = '';
  String _result = '0';

  void _onButtonPressed(String text) {
    setState(() {
      if (text == 'C') {
        _expression = '';
        _result = '0';
      } else if (text == '⌫') {
        if (_expression.isNotEmpty) {
          _expression = _expression.substring(0, _expression.length - 1);
        }
      } else if (text == '=') {
        _evaluateOrUnlock();
      } else {
        _expression += text;
      }
    });
  }

  Future<void> _evaluateOrUnlock() async {
    final input = _expression.trim();
    
    // 1. Check Master Unlock Code
    if (input == '5555') {
      if (mounted) context.go('/home'); // Unlock and go home
      return;
    }

    // 2. Check Duress PINs
    final level = await PinService.instance.verifyPin(input);
    if (level == 1) {
      // Fake Error
      setState(() => _result = 'Error');
      _expression = '';
      return;
    } else if (level == 2) {
      // Warning
      ref.read(alertProvider.notifier).triggerWarning();
      setState(() => _result = '0');
      _expression = '';
      return;
    } else if (level == 3) {
      // Duress (Police)
      ref.read(alertProvider.notifier).triggerDuress();
      setState(() => _result = 'Error');
      _expression = '';
      return;
    }

    // 3. Normal Math Evaluation
    try {
      // Replace x and ÷ for the math parser
      final cleanExpression =
          input.replaceAll('×', '*').replaceAll('÷', '/');
      Parser p = Parser();
      Expression exp = p.parse(cleanExpression);
      ContextModel cm = ContextModel();
      double eval = exp.evaluate(EvaluationType.REAL, cm);
      
      setState(() {
        _result = eval.toString();
        // Remove .0 if it's an integer
        if (_result.endsWith('.0')) {
          _result = _result.substring(0, _result.length - 2);
        }
        _expression = _result; // Set expression to result for next operation
      });
    } catch (e) {
      setState(() {
        _result = 'Error';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // A completely generic calculator UI to avoid any suspicion.
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // Display Area
            Expanded(
              flex: 2,
              child: Container(
                padding: const EdgeInsets.all(24),
                alignment: Alignment.bottomRight,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _expression,
                      style: const TextStyle(fontSize: 32, color: Colors.white54),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _result,
                      style: const TextStyle(
                        fontSize: 64,
                        fontWeight: FontWeight.w300,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
            
            // Keypad Area
            Expanded(
              flex: 5,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildRow(['C', '⌫', '%', '÷'], isTop: true),
                    _buildRow(['7', '8', '9', '×']),
                    _buildRow(['4', '5', '6', '-']),
                    _buildRow(['1', '2', '3', '+']),
                    _buildRow(['0', '.', '=']),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(List<String> buttons, {bool isTop = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: buttons.map((text) {
        if (text == '0') {
          return _buildButton(text, width: 160);
        }
        return _buildButton(text,
            isOperator: ['+', '-', '×', '÷', '='].contains(text),
            isTopOperator: isTop && text != '÷');
      }).toList(),
    );
  }

  Widget _buildButton(
    String text, {
    double width = 72,
    bool isOperator = false,
    bool isTopOperator = false,
  }) {
    Color bgColor = const Color(0xFF333333);
    Color textColor = Colors.white;

    if (isOperator) {
      bgColor = const Color(0xFFFF9F0A); // iOS Orange
    } else if (isTopOperator) {
      bgColor = const Color(0xFFA5A5A5); // iOS Light Gray
      textColor = Colors.black;
    }

    return InkWell(
      onTap: () => _onButtonPressed(text),
      borderRadius: BorderRadius.circular(36),
      child: Container(
        width: width,
        height: 72,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(36),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w400,
            color: textColor,
          ),
        ),
      ),
    );
  }
}
