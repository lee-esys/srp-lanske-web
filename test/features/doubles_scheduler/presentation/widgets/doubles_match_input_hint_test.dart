import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:srp_lanske/features/doubles_scheduler/presentation/widgets/doubles_match_card.dart';

void main() {
  testWidgets('shows the match input guidance once', (tester) async {
    const message = 'この対戦表を採用すると、試合情報を入力できます。';

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: DoublesMatchInputHint(message: message),
        ),
      ),
    );

    expect(find.byKey(const ValueKey('doubles-match-input-hint')), findsOneWidget);
    expect(find.text(message), findsOneWidget);
    expect(find.byIcon(Icons.info_outline), findsOneWidget);
  });
}
