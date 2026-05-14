/// Alert banner — appears at the top when an alert is active.
library;

import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/alert.dart';
import '../utils/constants.dart';

class AlertBanner extends StatelessWidget {
  final Alert alert;
  final int? countdown;
  final VoidCallback onDismiss;
  final VoidCallback onCancel;

  const AlertBanner({
    super.key,
    required this.alert,
    this.countdown,
    required this.onDismiss,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(
          horizontal: AppDimens.paddingM, vertical: AppDimens.paddingS),
      padding: const EdgeInsets.all(AppDimens.paddingM),
      decoration: BoxDecoration(
        color: _backgroundColor,
        borderRadius: BorderRadius.circular(AppDimens.radiusL),
        boxShadow: [
          BoxShadow(
            color: _backgroundColor.withOpacity(0.4),
            blurRadius: 16,
            spreadRadius: 2,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              // Icon
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(_alertIcon, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              // Message
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      alert.label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    if (countdown != null && countdown! > 0)
                      Text(
                        localizations?.alertingContactsInSeconds(countdown!) ??
                            'Alerting contacts in $countdown seconds...',
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 12),
                      ),
                  ],
                ),
              ),
              // Countdown badge
              if (countdown != null && countdown! > 0)
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '$countdown',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onCancel,
                  icon: const Icon(Icons.check_circle_outline, size: 18),
                  label: Text(localizations?.imOkay ?? "I'm OK"),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white54),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onDismiss,
                  icon: const Icon(Icons.emergency_rounded, size: 18),
                  label: Text(localizations?.sendHelp ?? 'Send Help'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: _backgroundColor,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color get _backgroundColor => switch (alert.alertType) {
        AlertType.sos => AppColors.danger,
        AlertType.fall => AppColors.warningDark,
        AlertType.fight => AppColors.danger,
        AlertType.scream => AppColors.danger,
        AlertType.keyword => const Color(0xFF9C27B0),
        AlertType.deviation => AppColors.warning,
        _ => AppColors.danger,
      };

  IconData get _alertIcon => switch (alert.alertType) {
        AlertType.sos => Icons.sos_rounded,
        AlertType.fall => Icons.person_off_rounded,
        AlertType.fight => Icons.sports_mma_rounded,
        AlertType.scream => Icons.record_voice_over_rounded,
        AlertType.keyword => Icons.mic_rounded,
        AlertType.deviation => Icons.alt_route_rounded,
        _ => Icons.warning_rounded,
      };
}
