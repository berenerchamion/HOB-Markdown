import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hob_markdown_reader/models/readability_settings.dart';
import 'package:hob_markdown_reader/services/settings_service.dart';
import 'package:hob_markdown_reader/state/reader_controller.dart';
import 'package:hob_markdown_reader/theme/app_theme.dart';
import 'package:hob_markdown_reader/ui/widgets/settings_dialog.dart';

void main() {
  late ReaderController controller;

  setUp(() {
    controller = ReaderController(
      settingsService: SettingsService(store: MemorySettingsStore()),
    );
  });

  tearDown(() {
    controller.dispose();
  });

  Future<void> openDialog(WidgetTester tester) async {
    // Tall enough that the whole dialog is on screen without scrolling.
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme(),
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => showSettingsDialog(context, controller),
              child: const Text('Open settings'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open settings'));
    await tester.pumpAndSettle();
  }

  Finder field(ReadabilityThreshold t) =>
      find.byKey(ValueKey('threshold-${t.name}'));

  Future<void> scrollTo(WidgetTester tester, Finder finder) =>
      tester.ensureVisible(finder);

  testWidgets('shows every check and threshold', (tester) async {
    await openDialog(tester);

    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Sentence length'), findsOneWidget);
    for (final t in ReadabilityThreshold.values) {
      await scrollTo(tester, field(t));
      expect(field(t), findsOneWidget, reason: t.name);
    }
    expect(find.text('Reading ease'), findsOneWidget);
  });

  testWidgets('choosing a theme updates the controller', (tester) async {
    await openDialog(tester);

    await tester.tap(find.text('Dark'));
    await tester.pumpAndSettle();

    expect(controller.themeMode, ThemeMode.dark);
  });

  testWidgets('the live reload switch updates the controller', (tester) async {
    await openDialog(tester);
    expect(controller.autoReloadEnabled, isTrue);

    await tester.tap(find.text('Live reload'));
    await tester.pumpAndSettle();

    expect(controller.autoReloadEnabled, isFalse);
  });

  testWidgets('a valid threshold is applied', (tester) async {
    await openDialog(tester);

    await tester.enterText(field(ReadabilityThreshold.sentenceMaxWords), '25');
    await tester.pump();

    expect(
      controller.settings.readability.valueOf(
        ReadabilityThreshold.sentenceMaxWords,
      ),
      25,
    );
  });

  testWidgets('an out-of-range threshold shows the range and is not applied', (
    tester,
  ) async {
    await openDialog(tester);

    await tester.enterText(field(ReadabilityThreshold.sentenceMaxWords), '2');
    await tester.pump();

    expect(find.text('5–100'), findsOneWidget);
    expect(
      controller.settings.readability.valueOf(
        ReadabilityThreshold.sentenceMaxWords,
      ),
      20,
    );
  });

  testWidgets('turning a check off disables its fields', (tester) async {
    await openDialog(tester);

    await scrollTo(tester, find.text('Passive voice'));
    await tester.tap(find.text('Passive voice'));
    await tester.pumpAndSettle();

    expect(
      controller.settings.readability.isEnabled(ReadabilityCheck.passiveVoice),
      isFalse,
    );
    final textField = tester.widget<TextField>(
      field(ReadabilityThreshold.passiveMaxPercent),
    );
    expect(textField.enabled, isFalse);
  });

  testWidgets('Restore defaults resets values and fields', (tester) async {
    await openDialog(tester);

    await scrollTo(tester, field(ReadabilityThreshold.paragraphMaxWords));
    await tester.enterText(
      field(ReadabilityThreshold.paragraphMaxWords),
      '200',
    );
    await tester.pump();
    expect(controller.settings.readability.isDefault, isFalse);

    await scrollTo(tester, find.text('Restore readability defaults'));
    await tester.tap(find.text('Restore readability defaults'));
    await tester.pumpAndSettle();

    expect(controller.settings.readability.isDefault, isTrue);
    await scrollTo(tester, field(ReadabilityThreshold.paragraphMaxWords));
    final textField = tester.widget<TextField>(
      field(ReadabilityThreshold.paragraphMaxWords),
    );
    expect(textField.controller!.text, '150');
  });

  testWidgets('the close button closes the dialog', (tester) async {
    await openDialog(tester);

    await tester.tap(find.byTooltip('Close'));
    await tester.pumpAndSettle();

    expect(find.text('Settings'), findsNothing);
  });
}
