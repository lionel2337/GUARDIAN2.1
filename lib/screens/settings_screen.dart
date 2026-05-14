/// Settings screen — user profile, preferences, language, AI test, and diagnostics.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../l10n/app_localizations.dart';
import '../providers/alert_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/connectivity_provider.dart';
import '../providers/locale_provider.dart';
import '../utils/constants.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _movementDetection = true;
  bool _audioDetection = false;
  bool _camouflageMode = false;
  bool _showDiagnostics = false;

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final connectivity = ref.watch(connectivityProvider);
    final alertState = ref.watch(alertProvider);
    final locale = ref.watch(localeProvider);
    final localizations = AppLocalizations.of(context);

    final isFrench = locale.languageCode == 'fr';

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations?.settings ?? 'Settings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.darkGradient),
        child: ListView(
          padding: const EdgeInsets.all(AppDimens.paddingM),
          children: [
            // ── Profile section ──────────────────────────────────────────
            _sectionHeader(localizations?.profile ?? 'Profile'),
            Container(
              padding: const EdgeInsets.all(AppDimens.paddingM),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(AppDimens.radiusL),
              ),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: const BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        auth.user?.fullName.isNotEmpty == true
                            ? auth.user!.fullName[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          auth.user?.fullName ?? (localizations?.anonymous ?? 'Anonymous'),
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                        Text(
                          auth.user?.email ?? (localizations?.noEmail ?? 'No email'),
                          style: const TextStyle(
                              color: AppColors.textSecondary, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: connectivity.isOnline
                          ? AppColors.success.withOpacity(0.15)
                          : AppColors.danger.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      connectivity.isOnline
                          ? (localizations?.online ?? 'Online')
                          : (localizations?.offline ?? 'Offline'),
                      style: TextStyle(
                        color: connectivity.isOnline
                            ? AppColors.success
                            : AppColors.danger,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── Detection settings ──────────────────────────────────────
            _sectionHeader(localizations?.aiDetection ?? 'AI Detection'),
            _switchTile(
              Icons.directions_run_rounded,
              localizations?.movementDetection ?? 'Movement Detection',
              localizations?.movementDetectionDesc ??
                  'Detect falls, fights, and emergency running',
              _movementDetection,
              (v) {
                setState(() => _movementDetection = v);
                if (v) {
                  ref.read(alertProvider.notifier).startMovementDetection();
                } else {
                  ref.read(alertProvider.notifier).stopMovementDetection();
                }
              },
            ),
            _switchTile(
              Icons.mic_rounded,
              localizations?.audioDetection ?? 'Audio Detection',
              localizations?.audioDetectionDesc ??
                  'Detect screams and emergency keywords',
              _audioDetection,
              (v) {
                setState(() => _audioDetection = v);
                if (v) {
                  ref.read(alertProvider.notifier).startAudioDetection();
                } else {
                  ref.read(alertProvider.notifier).stopAudioDetection();
                }
              },
            ),

            const SizedBox(height: 24),

            // ── AI Test & Diagnostics ──────────────────────────────────
            _sectionHeader(localizations?.aiTestAndDiagnostics ?? 'AI Test & Diagnostics'),
            _navTile(
              Icons.science_rounded,
              localizations?.testAiModels ?? 'Test AI Models',
              localizations?.verifyAudioMovementModels ?? 'Verify audio & movement models',
              () => context.push('/ai-test'),
            ),
            _switchTile(
              Icons.monitor_heart_rounded,
              localizations?.showDiagnostics ?? 'Show Diagnostics',
              localizations?.displayRealTimeSensorStatus ?? 'Display real-time sensor status',
              _showDiagnostics,
              (v) => setState(() => _showDiagnostics = v),
            ),
            if (_showDiagnostics) ...[
              const SizedBox(height: 8),
              _buildDiagnosticsCard(alertState, localizations),
            ],

            const SizedBox(height: 24),

            // ── Notifications ──────────────────────────────────────────
            _sectionHeader(localizations?.notifications ?? 'Notifications'),
            _switchTile(
              Icons.notifications_rounded,
              localizations?.pushNotifications ?? 'Push Notifications',
              localizations?.receiveAlertsAndReminders ?? 'Receive alerts and reminders',
              _notificationsEnabled,
              (v) => setState(() => _notificationsEnabled = v),
            ),

            const SizedBox(height: 24),

            // ── Language ─────────────────────────────────────────────────
            _sectionHeader(localizations?.language ?? 'Language'),
            Container(
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(AppDimens.radiusM),
              ),
              child: Column(
                children: [
                  _languageOption('English', '🇬🇧', !isFrench),
                  const Divider(
                      color: AppColors.divider, height: 1, indent: 56),
                  _languageOption('Français', '🇫🇷', isFrench),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── Privacy & Safety ─────────────────────────────────────────
            _sectionHeader(localizations?.privacy ?? 'Privacy & Safety'),
            _switchTile(
              Icons.visibility_off_rounded,
              localizations?.camouflageMode ?? 'Camouflage Mode',
              localizations?.camouflageModeDesc ??
                  'Hide the app behind a calculator interface',
              _camouflageMode,
              (v) => setState(() => _camouflageMode = v),
            ),
            _navTile(
              Icons.router_rounded,
              localizations?.traceurDevices ?? 'Traceur Devices',
              localizations?.managePairedGpsTraceurs ?? 'Manage paired GPS traceurs',
              () => context.push('/traceur-pairing'),
            ),

            const SizedBox(height: 24),

            // ── About ────────────────────────────────────────────────────
            _sectionHeader(localizations?.about ?? 'About'),
            Container(
              padding: const EdgeInsets.all(AppDimens.paddingM),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(AppDimens.radiusM),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.info_outline,
                        color: AppColors.textSecondary),
                    title: Text(localizations?.version ?? 'Version'),
                    trailing: Text('1.0.0',
                        style: TextStyle(color: AppColors.textHint)),
                  ),
                  const Divider(
                      color: AppColors.divider, height: 1, indent: 56),
                  ListTile(
                    leading: const Icon(Icons.storage_rounded,
                        color: AppColors.textSecondary),
                    title: Text(localizations?.pendingSync ?? 'Pending Sync'),
                    trailing: Text(
                        '${connectivity.pendingSyncCount} items',
                        style: TextStyle(color: AppColors.textHint)),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── Sign out ────────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () async {
                  await ref.read(authProvider.notifier).signOut();
                  if (context.mounted) context.go('/onboarding');
                },
                icon: const Icon(Icons.logout_rounded),
                label: Text(localizations?.signOut ?? 'Sign Out'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.danger,
                  side: const BorderSide(color: AppColors.danger),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildDiagnosticsCard(AlertStateData alertState, AppLocalizations? localizations) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimens.radiusM),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Mouvement: ${alertState.movementDetectionActive ? (localizations?.active ?? 'Active') : (localizations?.inactive ?? 'Inactive')}',
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          Text(
            'Audio: ${alertState.audioDetectionActive ? (localizations?.active ?? 'Active') : (localizations?.inactive ?? 'Inactive')}',
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          if (alertState.countdown != null)
            Text(
              'Compte à rebours: ${alertState.countdown}s',
              style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.warning,
                  fontWeight: FontWeight.w600),
            ),
          Text(
            'Alertes actives: ${alertState.activeAlerts.length}',
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(title,
          style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textHint,
              letterSpacing: 1)),
    );
  }

  Widget _switchTile(IconData icon, String title, String subtitle, bool value,
      ValueChanged<bool> onChanged) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppDimens.radiusM),
      ),
      child: SwitchListTile(
        secondary: Icon(icon, color: AppColors.accent),
        title: Text(title, style: const TextStyle(fontSize: 14)),
        subtitle: Text(subtitle,
            style:
                const TextStyle(color: AppColors.textHint, fontSize: 12)),
        value: value,
        onChanged: onChanged,
        activeColor: AppColors.accent,
      ),
    );
  }

  Widget _navTile(
      IconData icon, String title, String subtitle, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppDimens.radiusM),
      ),
      child: ListTile(
        leading: Icon(icon, color: AppColors.accent),
        title: Text(title, style: const TextStyle(fontSize: 14)),
        subtitle: Text(subtitle,
            style:
                const TextStyle(color: AppColors.textHint, fontSize: 12)),
        trailing: const Icon(Icons.chevron_right, color: AppColors.textHint),
        onTap: onTap,
      ),
    );
  }

  Widget _languageOption(String name, String flag, bool isSelected) {
    return ListTile(
      leading: Text(flag, style: const TextStyle(fontSize: 24)),
      title: Text(name),
      trailing: isSelected
          ? const Icon(Icons.check_circle, color: AppColors.accent)
          : null,
      onTap: () {
        final newLocale = name == 'Français' ? const Locale('fr') : const Locale('en');
        ref.read(localeProvider.notifier).setLocale(newLocale);
      },
    );
  }
}
