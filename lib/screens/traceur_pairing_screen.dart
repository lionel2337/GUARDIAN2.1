/// Traceur pairing screen — pair, rename, and manage ESP32 GPS traceurs.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/device_provider.dart';
import '../models/device.dart';
import '../utils/constants.dart';

class TraceurPairingScreen extends ConsumerStatefulWidget {
  const TraceurPairingScreen({super.key});

  @override
  ConsumerState<TraceurPairingScreen> createState() =>
      _TraceurPairingScreenState();
}

class _TraceurPairingScreenState extends ConsumerState<TraceurPairingScreen> {
  final _pairingController = TextEditingController();
  bool _isPairing = false;

  @override
  Widget build(BuildContext context) {
    final deviceState = ref.watch(deviceProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Traceur Devices'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.darkGradient),
        child: Column(
          children: [
            // ── Pairing section ──────────────────────────────────────────
            Container(
              margin: const EdgeInsets.all(AppDimens.paddingM),
              padding: const EdgeInsets.all(AppDimens.paddingM),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(AppDimens.radiusL),
                border: Border.all(color: AppColors.accent.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.bluetooth_connected_rounded,
                          color: AppColors.accent),
                      SizedBox(width: 8),
                      Text('Pair New Traceur',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _pairingController,
                    textCapitalization: TextCapitalization.characters,
                    decoration: const InputDecoration(
                      hintText: 'Enter pairing code',
                      prefixIcon:
                          Icon(Icons.qr_code_rounded, color: AppColors.textHint),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isPairing ? null : _pairDevice,
                      child: _isPairing
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('Pair Device'),
                    ),
                  ),
                  if (deviceState.error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(deviceState.error!,
                          style: const TextStyle(
                              color: AppColors.danger, fontSize: 13)),
                    ),
                ],
              ),
            ),

            // ── Device list ──────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppDimens.paddingM),
              child: Row(
                children: [
                  const Text('Paired Devices',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textHint)),
                  const SizedBox(width: 8),
                  Text('(${deviceState.devices.length})',
                      style: const TextStyle(color: AppColors.textHint)),
                ],
              ),
            ),
            const SizedBox(height: 8),

            Expanded(
              child: deviceState.devices.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.router_outlined,
                              size: 48,
                              color: AppColors.textHint.withOpacity(0.5)),
                          const SizedBox(height: 8),
                          const Text('No traceurs paired',
                              style: TextStyle(color: AppColors.textHint)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppDimens.paddingM),
                      itemCount: deviceState.devices.length,
                      itemBuilder: (context, index) {
                        final device = deviceState.devices[index];
                        return _TraceurCard(device: device);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pairDevice() async {
    final code = _pairingController.text.trim();
    if (code.isEmpty) return;

    setState(() => _isPairing = true);
    final success = await ref.read(deviceProvider.notifier).pairDevice(code);
    setState(() => _isPairing = false);

    if (success && mounted) {
      _pairingController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Traceur paired successfully!'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  @override
  void dispose() {
    _pairingController.dispose();
    super.dispose();
  }
}

class _TraceurCard extends ConsumerWidget {
  final Device device;
  const _TraceurCard({required this.device});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final batteryColor = _batteryColor(device.lastBattery);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppDimens.radiusM),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
            horizontal: AppDimens.paddingM, vertical: 4),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: device.isActive
                ? AppColors.success.withOpacity(0.15)
                : AppColors.textHint.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.router_rounded,
            color: device.isActive ? AppColors.success : AppColors.textHint,
          ),
        ),
        title: Text(device.deviceName,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Row(
          children: [
            Icon(Icons.battery_std_rounded, size: 14, color: batteryColor),
            const SizedBox(width: 4),
            Text(device.batteryLabel,
                style: TextStyle(color: batteryColor, fontSize: 12)),
            const SizedBox(width: 12),
            Icon(
              device.isActive
                  ? Icons.wifi_rounded
                  : Icons.wifi_off_rounded,
              size: 14,
              color: device.isActive
                  ? AppColors.success
                  : AppColors.textHint,
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) async {
            switch (value) {
              case 'beep':
                await ref
                    .read(deviceProvider.notifier)
                    .sendCommand(device.id, 'beep');
                break;
              case 'rename':
                _showRenameDialog(context, ref, device);
                break;
              case 'remove':
                await ref
                    .read(deviceProvider.notifier)
                    .removeDevice(device.id);
                break;
            }
          },
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'beep', child: Text('📢 Beep')),
            PopupMenuItem(value: 'rename', child: Text('✏️ Rename')),
            PopupMenuItem(value: 'remove', child: Text('🗑️ Remove')),
          ],
        ),
      ),
    );
  }

  Color _batteryColor(int? level) {
    if (level == null) return AppColors.textHint;
    if (level > 60) return AppColors.success;
    if (level > 20) return AppColors.warning;
    return AppColors.danger;
  }

  void _showRenameDialog(
      BuildContext context, WidgetRef ref, Device device) {
    final controller = TextEditingController(text: device.deviceName);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Rename Traceur'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'New name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                ref
                    .read(deviceProvider.notifier)
                    .renameDevice(device.id, name);
                Navigator.pop(ctx);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
