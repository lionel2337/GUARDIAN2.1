/// Community report button — FAB that opens a bottom sheet for submitting geolocated reports.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:uuid/uuid.dart';

import '../models/community_report.dart';
import '../providers/auth_provider.dart';
import '../providers/map_provider.dart';
import '../services/local_database_service.dart';
import '../services/supabase_service.dart';
import '../utils/constants.dart';

class CommunityReportButton extends ConsumerWidget {
  final LatLng? currentPosition;

  const CommunityReportButton({super.key, this.currentPosition});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FloatingActionButton.small(
      heroTag: 'community_report',
      backgroundColor: AppColors.warning,
      onPressed: () => _showReportSheet(context, ref),
      child: const Icon(Icons.report_problem_rounded,
          color: Colors.white, size: 20),
    );
  }

  void _showReportSheet(BuildContext context, WidgetRef ref) {
    final descController = TextEditingController();
    String? selectedType;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppDimens.radiusXL)),
      ),
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: AppDimens.paddingL,
                right: AppDimens.paddingL,
                top: AppDimens.paddingL,
                bottom: MediaQuery.of(context).viewInsets.bottom +
                    AppDimens.paddingL,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.divider,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Report an Incident',
                    style: TextStyle(
                        fontSize: 20, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Your report will appear on the map for 2 hours',
                    style: TextStyle(
                        color: AppColors.textSecondary, fontSize: 13),
                  ),
                  const SizedBox(height: 20),

                  // Report type selection
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: ReportTypes.all.map((type) {
                      final isSelected = selectedType == type;
                      return ChoiceChip(
                        label: Text(_typeLabel(type)),
                        selected: isSelected,
                        onSelected: (v) {
                          setSheetState(() => selectedType = v ? type : null);
                        },
                        selectedColor: AppColors.accent,
                        backgroundColor: AppColors.surfaceLight,
                        labelStyle: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : AppColors.textSecondary,
                          fontSize: 12,
                        ),
                        avatar: Icon(
                          _typeIcon(type),
                          size: 16,
                          color: isSelected
                              ? Colors.white
                              : AppColors.textHint,
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),

                  // Description
                  TextField(
                    controller: descController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      hintText: 'Describe the incident (optional)',
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Submit
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: selectedType == null
                          ? null
                          : () => _submitReport(
                                ctx,
                                ref,
                                selectedType!,
                                descController.text.trim(),
                              ),
                      icon: const Icon(Icons.send_rounded),
                      label: const Text('Submit Report'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.warning,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _submitReport(
    BuildContext context,
    WidgetRef ref,
    String type,
    String description,
  ) async {
    final pos = currentPosition ?? AppGeo.yaoundeCenter;
    final userId = ref.read(currentUserIdProvider) ?? 'anonymous';
    final now = DateTime.now();

    final report = CommunityReport(
      id: const Uuid().v4(),
      userId: userId,
      lat: pos.latitude,
      lng: pos.longitude,
      reportType: type,
      description: description.isNotEmpty ? description : null,
      expiresAt: now.add(AppGeo.reportExpiry),
      createdAt: now,
    );

    // Save locally.
    await LocalDatabaseService.instance.insertCommunityReport(report);

    // Sync to Supabase.
    await SupabaseService.instance.insertCommunityReport(report);

    // Add to map.
    ref.read(mapProvider.notifier).addCommunityReport(report);

    if (context.mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Report submitted — visible for 2 hours'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  String _typeLabel(String type) => switch (type) {
        'harassment' => 'Harassment',
        'assault' => 'Assault',
        'theft' => 'Theft',
        'poor_lighting' => 'Poor Lighting',
        'suspicious_activity' => 'Suspicious',
        'road_block' => 'Road Block',
        'other' => 'Other',
        _ => type,
      };

  IconData _typeIcon(String type) => switch (type) {
        'harassment' => Icons.report_rounded,
        'assault' => Icons.dangerous_rounded,
        'theft' => Icons.shopping_bag_rounded,
        'poor_lighting' => Icons.lightbulb_outline_rounded,
        'suspicious_activity' => Icons.visibility_rounded,
        'road_block' => Icons.block_rounded,
        'other' => Icons.more_horiz_rounded,
        _ => Icons.warning_rounded,
      };
}
