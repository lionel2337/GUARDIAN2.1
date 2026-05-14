/// Device marker widget — shows a family member or traceur on the map.
library;

import 'package:flutter/material.dart';

import '../models/device.dart';
import '../providers/map_provider.dart';
import '../utils/constants.dart';

class DeviceMarkerWidget extends StatelessWidget {
  final DeviceMarkerInfo info;

  const DeviceMarkerWidget({super.key, required this.info});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Name label
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.surface.withOpacity(0.9),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            info.deviceName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 9,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(height: 2),
        // Marker icon
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: _markerColor,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2.5),
                boxShadow: [
                  BoxShadow(
                    color: _markerColor.withOpacity(0.4),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Icon(_markerIcon, size: 18, color: Colors.white),
            ),
            // Battery indicator
            if (info.battery != null)
              Positioned(
                right: -4,
                bottom: -4,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                  decoration: BoxDecoration(
                    color: _batteryColor,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.surface, width: 1),
                  ),
                  child: Text(
                    '${info.battery}%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 7,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Color get _markerColor => switch (info.deviceType) {
        DeviceType.traceur => AppColors.accent,
        DeviceType.watch => AppColors.primary,
        DeviceType.mobile => AppColors.info,
      };

  IconData get _markerIcon => switch (info.deviceType) {
        DeviceType.traceur => Icons.router_rounded,
        DeviceType.watch => Icons.watch_rounded,
        DeviceType.mobile => Icons.phone_android_rounded,
      };

  Color get _batteryColor {
    if (info.battery == null) return AppColors.textHint;
    if (info.battery! > 60) return AppColors.success;
    if (info.battery! > 20) return AppColors.warning;
    return AppColors.danger;
  }
}
