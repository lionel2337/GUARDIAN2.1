/// Encryption utilities — AES encryption for sensitive data.
library;

import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

class EncryptionUtils {
  EncryptionUtils._();

  /// Generate a SHA-256 hash of a string.
  static String sha256Hash(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Generate a random token of given length.
  static String generateToken({int length = 32}) {
    const chars =
        'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz0123456789';
    final random = Random.secure();
    return List.generate(length, (_) => chars[random.nextInt(chars.length)])
        .join();
  }

  /// Generate a random pairing code for traceur devices.
  static String generatePairingCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // Avoid confusing chars.
    final random = Random.secure();
    return List.generate(6, (_) => chars[random.nextInt(chars.length)]).join();
  }

  /// Create an HMAC-SHA256 signature for data verification.
  static String hmacSign(String data, String secretKey) {
    final key = utf8.encode(secretKey);
    final bytes = utf8.encode(data);
    final hmacSha256 = Hmac(sha256, key);
    final digest = hmacSha256.convert(bytes);
    return digest.toString();
  }

  /// Obfuscate a phone number for display (e.g., +237 6XX XXX X89).
  static String obfuscatePhone(String phone) {
    if (phone.length < 6) return phone;
    final prefix = phone.substring(0, 4);
    final suffix = phone.substring(phone.length - 2);
    final middle = 'X' * (phone.length - 6);
    return '$prefix $middle $suffix';
  }

  /// Obfuscate an email for display (e.g., u***@gmail.com).
  static String obfuscateEmail(String email) {
    final parts = email.split('@');
    if (parts.length != 2) return email;
    final name = parts[0];
    final domain = parts[1];
    if (name.length <= 2) return email;
    return '${name[0]}${'*' * (name.length - 2)}${name[name.length - 1]}@$domain';
  }
}
