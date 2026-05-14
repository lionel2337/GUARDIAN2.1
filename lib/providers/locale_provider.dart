/// Locale provider — manages application language (English / French).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const _storageKey = 'app_locale';
const _defaultLocale = Locale('fr');

class LocaleNotifier extends StateNotifier<Locale> {
  LocaleNotifier() : super(_defaultLocale) {
    _loadSavedLocale();
  }

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  Future<void> _loadSavedLocale() async {
    try {
      final saved = await _storage.read(key: _storageKey);
      if (saved == 'en') {
        state = const Locale('en');
      } else if (saved == 'fr') {
        state = const Locale('fr');
      }
    } catch (_) {
      // Default already set.
    }
  }

  Future<void> setLocale(Locale locale) async {
    state = locale;
    try {
      await _storage.write(key: _storageKey, value: locale.languageCode);
    } catch (_) {
      // Ignore write errors.
    }
  }
}

final localeProvider = StateNotifierProvider<LocaleNotifier, Locale>(
  (ref) => LocaleNotifier(),
);
