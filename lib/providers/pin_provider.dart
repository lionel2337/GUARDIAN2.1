/// Pin Provider — Manages state for PIN configuration.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/pin_service.dart';

class PinNotifier extends StateNotifier<bool> {
  PinNotifier() : super(false) {
    _checkSetup();
  }

  final _service = PinService.instance;

  Future<void> _checkSetup() async {
    state = await _service.arePinsConfigured();
  }

  Future<void> savePins({
    required String pin1,
    required String pin2,
    required String pin3,
  }) async {
    await _service.savePins(pinLevel1: pin1, pinLevel2: pin2, pinLevel3: pin3);
    state = true;
  }

  Future<void> clearPins() async {
    await _service.clearPins();
    state = false;
  }
}

final pinProvider = StateNotifierProvider<PinNotifier, bool>((ref) {
  return PinNotifier();
});
