import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:srp_lanske/features/external_identity/domain/confirmation_code.dart';

void main() {
  test('issues a copy-friendly code and stores only a SHA-256 hash', () {
    final issuer = ConfirmationCodeIssuer(random: Random(42));

    final issue = issuer.issue();

    expect(issue.displayCode, matches(RegExp(r'^LSK-[A-Z2-9]{4}-[A-Z2-9]{4}$')));
    expect(issue.hash, matches(RegExp(r'^[0-9a-f]{64}$')));
    expect(issue.hash, issuer.hash(issue.displayCode));
  });

  test('hash comparison ignores separators, case, and surrounding spaces', () {
    final issuer = ConfirmationCodeIssuer(random: Random(1));

    expect(
      issuer.hash(' LSK-abcd-2345 '),
      issuer.hash('lsk abcd 2345'),
    );
  });
}
