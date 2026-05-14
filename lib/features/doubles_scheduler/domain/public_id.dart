import 'dart:math';

const publicIdAlphabet = '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ';
const publicIdLength = 8;

final Random _secureRandom = Random.secure();

String generatePublicId({Random? random}) {
  final source = random ?? _secureRandom;

  return List.generate(
    publicIdLength,
    (_) => publicIdAlphabet[source.nextInt(publicIdAlphabet.length)],
  ).join();
}

bool isValidPublicId(String value) {
  return RegExp(r'^[0-9A-Z]{8}$').hasMatch(value);
}
