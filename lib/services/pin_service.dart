/// Pin Service — Secure storage for multi-level PIN codes.
library;

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class PinService {
  PinService._();
  static final PinService instance = PinService._();

  final _storage = const FlutterSecureStorage();

  static const String _keyLevel1 = 'pin_level_1'; // Fake PIN
  static const String _keyLevel2 = 'pin_level_2'; // Warning PIN (Proches)
  static const String _keyLevel3 = 'pin_level_3'; // Duress PIN (Police + Proches)

  /// Sauvegarder les codes PIN
  Future<void> savePins({
    required String pinLevel1,
    required String pinLevel2,
    required String pinLevel3,
  }) async {
    await _storage.write(key: _keyLevel1, value: pinLevel1);
    await _storage.write(key: _keyLevel2, value: pinLevel2);
    await _storage.write(key: _keyLevel3, value: pinLevel3);
  }

  /// Vérifie si les codes PIN sont configurés
  Future<bool> arePinsConfigured() async {
    final p1 = await _storage.read(key: _keyLevel1);
    final p2 = await _storage.read(key: _keyLevel2);
    final p3 = await _storage.read(key: _keyLevel3);
    return p1 != null && p2 != null && p3 != null;
  }

  /// Vérifie un PIN entré et retourne son niveau de gravité (0 si invalide)
  /// 0 = Invalide (ou pas configuré)
  /// 1 = Fake (Erreur simulée)
  /// 2 = Warning (Alerte Proches)
  /// 3 = Duress (Alerte Police + Proches)
  Future<int> verifyPin(String enteredPin) async {
    final p1 = await _storage.read(key: _keyLevel1);
    final p2 = await _storage.read(key: _keyLevel2);
    final p3 = await _storage.read(key: _keyLevel3);

    if (enteredPin == p3) return 3;
    if (enteredPin == p2) return 2;
    if (enteredPin == p1) return 1;

    return 0; // Mauvais code
  }

  /// Supprime tous les codes (Réinitialisation)
  Future<void> clearPins() async {
    await _storage.delete(key: _keyLevel1);
    await _storage.delete(key: _keyLevel2);
    await _storage.delete(key: _keyLevel3);
  }
}
