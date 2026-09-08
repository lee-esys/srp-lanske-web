import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

class ConfirmationCodeIssue {
  const ConfirmationCodeIssue({
    required this.displayCode,
    required this.hash,
  });

  final String displayCode;
  final String hash;
}

class ConfirmationCodeIssuer {
  ConfirmationCodeIssuer({Random? random})
      : _random = random ?? Random.secure();

  static const _alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  static const _prefix = 'LSK';

  final Random _random;

  ConfirmationCodeIssue issue() {
    final first = _randomPart(4);
    final second = _randomPart(4);
    final displayCode = '$_prefix-$first-$second';
    return ConfirmationCodeIssue(
      displayCode: displayCode,
      hash: hash(displayCode),
    );
  }

  String hash(String code) {
    final normalized = normalize(code);
    return sha256.convert(utf8.encode(normalized)).toString();
  }

  String normalize(String code) {
    return code.trim().toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
  }

  String _randomPart(int length) {
    final buffer = StringBuffer();
    for (var index = 0; index < length; index++) {
      buffer.write(_alphabet[_random.nextInt(_alphabet.length)]);
    }
    return buffer.toString();
  }
}
