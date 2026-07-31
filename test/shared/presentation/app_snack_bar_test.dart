import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:srp_lanske/shared/presentation/app_message_type.dart';
import 'package:srp_lanske/shared/presentation/app_snack_bar.dart';

void main() {
  Future<BuildContext> pumpHost(
    WidgetTester tester, {
    Size size = const Size(390, 844),
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = size;
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      tester.view.resetDevicePixelRatio();
      tester.view.resetPhysicalSize();
    });

    late BuildContext messageContext;
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
          useMaterial3: true,
        ),
        home: Builder(
          builder: (context) {
            messageContext = context;
            return const Scaffold(body: SizedBox.expand());
          },
        ),
      ),
    );

    return messageContext;
  }

  testWidgets('shows type-specific icon, duration, and close rule',
      (tester) async {
    final context = await pumpHost(tester);
    final expectedDurations = <AppMessageType, Duration>{
      AppMessageType.success: const Duration(seconds: 3),
      AppMessageType.info: const Duration(seconds: 4),
      AppMessageType.warning: const Duration(seconds: 6),
      AppMessageType.error: const Duration(seconds: 8),
    };

    for (final type in AppMessageType.values) {
      AppSnackBar.show(
        context,
        message: type.name,
        type: type,
      );
      await tester.pump();

      expect(
        find.byKey(ValueKey<String>('app-snack-bar-${type.name}-icon')),
        findsOneWidget,
      );

      final snackBar = tester.widget<SnackBar>(
        find.byKey(const ValueKey<String>('app-snack-bar')),
      );
      expect(snackBar.duration, expectedDurations[type]);
      expect(
        snackBar.showCloseIcon,
        type == AppMessageType.warning || type == AppMessageType.error,
      );

      ScaffoldMessenger.of(context).removeCurrentSnackBar();
      await tester.pump();
    }
  });

  testWidgets('supports title, custom duration, and action', (tester) async {
    final context = await pumpHost(tester);
    var actionCount = 0;

    AppSnackBar.show(
      context,
      title: 'Network error',
      message: 'Try again.',
      duration: const Duration(seconds: 12),
      actionLabel: 'Retry',
      onAction: () {
        actionCount += 1;
      },
    );
    await tester.pump();

    expect(find.text('Network error'), findsOneWidget);
    expect(find.text('Try again.'), findsOneWidget);

    final snackBar = tester.widget<SnackBar>(
      find.byKey(const ValueKey<String>('app-snack-bar')),
    );
    expect(snackBar.duration, const Duration(seconds: 12));
    expect(snackBar.action?.label, 'Retry');

    snackBar.action!.onPressed();
    expect(actionCount, 1);
  });

  testWidgets('suppresses the same notification shown consecutively',
      (tester) async {
    final context = await pumpHost(tester);

    AppSnackBar.show(context, message: 'same message');
    await tester.pump();
    final firstSnackBar = tester.widget<SnackBar>(
      find.byKey(const ValueKey<String>('app-snack-bar')),
    );

    AppSnackBar.show(context, message: 'same message');
    await tester.pump();
    final secondSnackBar = tester.widget<SnackBar>(
      find.byKey(const ValueKey<String>('app-snack-bar')),
    );

    expect(identical(firstSnackBar, secondSnackBar), isTrue);
    expect(find.text('same message'), findsOneWidget);
  });

  testWidgets('keeps a persistent warning instead of lightweight messages',
      (tester) async {
    final context = await pumpHost(tester);

    AppSnackBar.show(
      context,
      message: 'persistent warning',
      type: AppMessageType.warning,
      persistent: true,
    );
    await tester.pump();

    AppSnackBar.show(
      context,
      message: 'lightweight info',
      type: AppMessageType.info,
    );
    await tester.pump();

    expect(find.text('persistent warning'), findsOneWidget);
    expect(find.text('lightweight info'), findsNothing);

    final snackBar = tester.widget<SnackBar>(
      find.byKey(const ValueKey<String>('app-snack-bar')),
    );
    expect(snackBar.showCloseIcon, isTrue);
  });

  testWidgets('replaces a persistent warning with a new error', (tester) async {
    final context = await pumpHost(tester);

    AppSnackBar.show(
      context,
      message: 'persistent warning',
      type: AppMessageType.warning,
      persistent: true,
    );
    await tester.pump();

    AppSnackBar.show(
      context,
      message: 'new error',
      type: AppMessageType.error,
      persistent: true,
    );
    await tester.pump();

    expect(find.text('persistent warning'), findsNothing);
    expect(find.text('new error'), findsOneWidget);
  });

  testWidgets('uses margins on mobile and fixed width on desktop',
      (tester) async {
    var context = await pumpHost(tester);

    AppSnackBar.show(context, message: 'mobile message');
    await tester.pump();
    var snackBar = tester.widget<SnackBar>(
      find.byKey(const ValueKey<String>('app-snack-bar')),
    );
    expect(snackBar.margin, isNotNull);
    expect(snackBar.width, isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    context = await pumpHost(tester, size: const Size(1200, 900));

    AppSnackBar.show(context, message: 'desktop message');
    await tester.pump();
    snackBar = tester.widget<SnackBar>(
      find.byKey(const ValueKey<String>('app-snack-bar')),
    );
    expect(snackBar.margin, isNull);
    expect(snackBar.width, 560);
  });

  testWidgets('requires action label and callback together', (tester) async {
    final context = await pumpHost(tester);

    expect(
      () => AppSnackBar.show(
        context,
        message: 'invalid action',
        actionLabel: 'Retry',
      ),
      throwsArgumentError,
    );
  });
}
