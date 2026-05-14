/// Offline banner — persistent banner shown when no internet connection.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/connectivity_provider.dart';
import '../utils/constants.dart';

class OfflineBanner extends ConsumerWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(connectivityProvider);

    return Container(
      margin: const EdgeInsets.symmetric(
          horizontal: AppDimens.paddingM, vertical: AppDimens.paddingXS),
      padding: const EdgeInsets.symmetric(
          horizontal: AppDimens.paddingM, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.warningDark.withOpacity(0.95),
        borderRadius: BorderRadius.circular(AppDimens.radiusM),
        boxShadow: [
          BoxShadow(
            color: AppColors.warningDark.withOpacity(0.3),
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.wifi_off_rounded, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Offline Mode',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                Text(
                  'Last sync: ${state.lastSyncLabel} • AI still active ✓',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.sensors_rounded,
                    size: 12, color: AppColors.success),
                const SizedBox(width: 3),
                const Text('AI ON',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
