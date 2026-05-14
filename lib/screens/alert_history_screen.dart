/// Alert history screen — chronological list of past alerts.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../models/alert.dart';
import '../providers/alert_provider.dart';
import '../utils/constants.dart';

class AlertHistoryScreen extends ConsumerWidget {
  const AlertHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alertState = ref.watch(alertProvider);
    final history = alertState.history;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Alert History'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.darkGradient),
        child: history.isEmpty
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle_outline_rounded,
                        size: 64, color: AppColors.success.withOpacity(0.5)),
                    const SizedBox(height: 16),
                    const Text('No Alerts Yet',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary)),
                    const SizedBox(height: 8),
                    const Text("You're safe — no alerts recorded",
                        style: TextStyle(color: AppColors.textHint)),
                  ],
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(AppDimens.paddingM),
                itemCount: history.length,
                itemBuilder: (context, index) {
                  final alert = history[index];
                  return _AlertCard(alert: alert);
                },
              ),
      ),
    );
  }
}

class _AlertCard extends StatelessWidget {
  final Alert alert;
  const _AlertCard({required this.alert});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppDimens.radiusM),
        border: Border.all(
          color: _alertColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
            horizontal: AppDimens.paddingM, vertical: 4),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: _alertColor.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(_alertIcon, color: _alertColor, size: 22),
        ),
        title: Text(alert.label,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(
          DateFormat('MMM d, yyyy • HH:mm').format(alert.triggeredAt),
          style:
              const TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
        trailing: alert.isActive
            ? Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.danger.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('ACTIVE',
                    style: TextStyle(
                        color: AppColors.danger,
                        fontSize: 10,
                        fontWeight: FontWeight.w700)),
              )
            : Icon(Icons.check_circle,
                color: AppColors.success.withOpacity(0.5), size: 20),
      ),
    );
  }

  Color get _alertColor => switch (alert.alertType) {
        AlertType.sos => AppColors.danger,
        AlertType.fall => AppColors.warning,
        AlertType.fight => AppColors.danger,
        AlertType.scream => AppColors.danger,
        AlertType.keyword => const Color(0xFF9C27B0),
        AlertType.deviation => AppColors.warning,
        AlertType.deadManSwitch => AppColors.dangerDark,
        _ => AppColors.info,
      };

  IconData get _alertIcon => switch (alert.alertType) {
        AlertType.sos => Icons.sos_rounded,
        AlertType.fall => Icons.person_off_rounded,
        AlertType.fight => Icons.sports_mma_rounded,
        AlertType.scream => Icons.record_voice_over_rounded,
        AlertType.keyword => Icons.mic_rounded,
        AlertType.deviation => Icons.alt_route_rounded,
        AlertType.deadManSwitch => Icons.timer_off_rounded,
        AlertType.lowBattery => Icons.battery_alert_rounded,
        AlertType.emergencyRunning => Icons.directions_run_rounded,
        _ => Icons.warning_rounded,
      };
}
