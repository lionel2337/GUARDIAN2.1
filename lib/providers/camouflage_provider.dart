/// Camouflage Provider — Manages the state of the app's camouflage mode.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class CamouflageNotifier extends StateNotifier<bool> {
  CamouflageNotifier() : super(false) {
    _loadState();
  }

  final _storage = const FlutterSecureStorage();
  static const _key = 'is_camouflage_enabled';

  Future<void> _loadState() async {
    final value = await _storage.read(key: _key);
    state = value == 'true';
  }

  Future<void> toggle(bool isEnabled) async {
    await _storage.write(key: _key, value: isEnabled.toString());
    state = isEnabled;
  }
}

final camouflageProvider =
    StateNotifierProvider<CamouflageNotifier, bool>((ref) {
  return CamouflageNotifier();
});
