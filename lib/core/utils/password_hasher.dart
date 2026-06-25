import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

abstract final class PasswordHasher {
  static final Random _secureRandom = Random.secure();

  static String hashPassword(String password) {
    final salt = List<int>.generate(16, (_) => _secureRandom.nextInt(256));
    final saltText = base64UrlEncode(salt);
    final digest = sha256
        .convert(utf8.encode('$saltText:$password'))
        .toString();
    return '$saltText:$digest';
  }

  static bool verifyPassword(String password, String encodedHash) {
    final parts = encodedHash.split(':');
    if (parts.length != 2) {
      return false;
    }
    final digest = sha256
        .convert(utf8.encode('${parts[0]}:$password'))
        .toString();
    return digest == parts[1];
  }

  static String hashOneWay(String value) {
    return sha256.convert(utf8.encode(value)).toString();
  }
}
