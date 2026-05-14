/// SOS button — floating action button with pulse animation and long-press activation.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../utils/constants.dart';

class SosButton extends StatefulWidget {
  final VoidCallback onSosTriggered;

  const SosButton({super.key, required this.onSosTriggered});

  @override
  State<SosButton> createState() => _SosButtonState();
}

class _SosButtonState extends State<SosButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: AppAnimations.pulseInterval,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _isPressed ? 0.9 : _pulseAnimation.value,
          child: child,
        );
      },
      child: GestureDetector(
        onLongPressStart: (_) {
          setState(() => _isPressed = true);
          HapticFeedback.heavyImpact();
        },
        onLongPressEnd: (_) {
          setState(() => _isPressed = false);
          HapticFeedback.heavyImpact();
          widget.onSosTriggered();
        },
        onLongPressCancel: () {
          setState(() => _isPressed = false);
        },
        child: Container(
          width: AppDimens.sosButtonSize,
          height: AppDimens.sosButtonSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: _isPressed
                ? AppColors.dangerGradient
                : const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFE53935), Color(0xFFB71C1C)],
                  ),
            boxShadow: [
              BoxShadow(
                color: AppColors.danger.withOpacity(
                    _isPressed ? 0.6 : 0.3),
                blurRadius: _isPressed ? 24 : 16,
                spreadRadius: _isPressed ? 4 : 2,
              ),
            ],
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.sos_rounded,
                  size: 28,
                  color: Colors.white.withOpacity(0.95),
                ),
                const Text(
                  'HOLD',
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w800,
                    color: Colors.white70,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Same AnimatedBuilder as splash_screen (reusable).
class AnimatedBuilder extends AnimatedWidget {
  final Widget Function(BuildContext, Widget?) builder;
  final Widget? child;

  const AnimatedBuilder({
    super.key,
    required Animation<double> animation,
    required this.builder,
    this.child,
  }) : super(listenable: animation);

  @override
  Widget build(BuildContext context) {
    return builder(context, child);
  }
}
