import 'package:flutter_test/flutter_test.dart';
import 'package:guardians_ai/utils/constants.dart';

void main() {
  group('AppColors', () {
    test('primary colors are defined', () {
      expect(AppColors.primary, isNotNull);
      expect(AppColors.accent, isNotNull);
      expect(AppColors.danger, isNotNull);
      expect(AppColors.background, isNotNull);
    });

    test('risk zone colors have alpha for map overlays', () {
      expect(AppColors.riskLow.a, lessThan(1.0));
      expect(AppColors.riskMedium.a, lessThan(1.0));
      expect(AppColors.riskHigh.a, lessThan(1.0));
      expect(AppColors.riskCritical.a, lessThan(1.0));
    });
  });

  group('AppGeo', () {
    test('Yaoundé center is valid coordinates', () {
      expect(AppGeo.yaoundeCenter.latitude, closeTo(3.848, 0.01));
      expect(AppGeo.yaoundeCenter.longitude, closeTo(11.502, 0.01));
    });

    test('maxDeviationMeters is positive', () {
      expect(AppGeo.maxDeviationMeters, greaterThan(0));
    });

    test('reportExpiry is 2 hours', () {
      expect(AppGeo.reportExpiry.inHours, 2);
    });
  });

  group('AlertTypes', () {
    test('all alert types are defined', () {
      expect(AlertTypes.sos, 'SOS');
      expect(AlertTypes.fall, 'FALL');
      expect(AlertTypes.fight, 'FIGHT');
      expect(AlertTypes.scream, 'SCREAM');
      expect(AlertTypes.keyword, 'KEYWORD');
      expect(AlertTypes.deviation, 'DEVIATION');
      expect(AlertTypes.deadManSwitch, 'DEAD_MAN_SWITCH');
    });
  });

  group('ReportTypes', () {
    test('all report types are in the list', () {
      expect(ReportTypes.all, contains(ReportTypes.harassment));
      expect(ReportTypes.all, contains(ReportTypes.assault));
      expect(ReportTypes.all, contains(ReportTypes.theft));
      expect(ReportTypes.all, contains(ReportTypes.other));
      expect(ReportTypes.all.length, 7);
    });
  });

  group('SyncConfig', () {
    test('sync interval is 15 minutes', () {
      expect(SyncConfig.syncIntervalMinutes, 15);
    });

    test('max retry is 10', () {
      expect(SyncConfig.maxRetryAttempts, 10);
    });

    test('dead man switch timeout > heartbeat interval', () {
      expect(SyncConfig.deadManSwitchTimeoutSeconds,
          greaterThan(SyncConfig.heartbeatIntervalSeconds));
    });
  });

  group('MapTiles', () {
    test('OSM URL contains valid tile placeholders', () {
      expect(MapTiles.osmUrl, contains('{z}'));
      expect(MapTiles.osmUrl, contains('{x}'));
      expect(MapTiles.osmUrl, contains('{y}'));
    });

    test('Dark URL contains valid tile placeholders', () {
      expect(MapTiles.darkUrl, contains('{z}'));
      expect(MapTiles.darkUrl, contains('{x}'));
      expect(MapTiles.darkUrl, contains('{y}'));
    });
  });
}
