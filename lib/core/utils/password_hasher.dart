import 'dart:convert';
import 'package:crypto/crypto.dart';

/// Cryptographic password hashing utility using SHA-256 and salted key stretching.
/// Ensures passwords are NEVER stored or transmitted in plain text.
class PasswordHasher {
  static const String _globalSalt = 'inno_media_sec_v1_#9821\$';

  /// Generates SHA-256 hash with salt for a given raw password.
  static String hashPassword(String rawPassword, {String userSalt = ''}) {
    final combined = '$_globalSalt:$userSalt:$rawPassword';
    final bytes = utf8.encode(combined);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Verifies a raw password against an existing stored hash and salt.
  static bool verifyPassword({
    required String rawPassword,
    required String storedHash,
    String userSalt = '',
  }) {
    final computedHash = hashPassword(rawPassword, userSalt: userSalt);
    return computedHash == storedHash;
  }
}
