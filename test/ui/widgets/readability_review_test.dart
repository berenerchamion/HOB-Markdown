import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hob_markdown_reader/models/readability_settings.dart';
import 'package:hob_markdown_reader/state/reader_controller.dart';
import 'package:hob_markdown_reader/theme/app_theme.dart';
import 'package:hob_markdown_reader/ui/reader_screen.dart';
import 'package:hob_markdown_reader/ui/widgets/readability_panel.dart';

final String longSentence = '${List.filled(30, 'word').join(' ')}.';
final String text = '# Title\n\nThe file was saved. $longSentence Short one.\n';

void main() {
  late ReaderController controller;

  setUp(() {
    controller = ReaderController();
    controller.newDocument();
    controller.updateContent(text);
  });

  tearDown(() => controller.dispose());

  group('ReaderController review', () {
    test('is off by default and gives no report', () {
      expect(controller.isReviewing, isFalse);
      expect(controller.readabilityReport, isNull);
    });

    test('turning it on analyses the document and caches the result', () {
      controller.toggleReview();
      final report = controller.readabilityReport;
      expect(report, isNotNull);
      expect(report!.source, text);
      expect(identical(controller.readabilityReport, report), isTrue);
    });

    test('a content or settings change gives a fresh report', () {
      controller.toggleReview();
      final first = controller.readabilityReport;

      controller.updateContent('$text\nAnother sentence.');
      final second = controller.readabilityReport;
      expect(identical(first, second), isFalse);

      controller.updateSettings(
        controller.settings.copyWith(
          readability: const ReadabilitySettings().withCheckEnabled(
            ReadabilityCheck.passiveVoice,
            false,
          ),
        ),
      );
      final third = controller.readabilityReport!;
      expect(third.resultFor(ReadabilityCheck.passiveVoice), isNull);
    });
  });

  group('review UI', () {
    Future<void> pumpScreen(WidgetTester tester) async {
      tester.view.physicalSize = const Size(1400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme(),
          home: ReaderScreen(controller: controller),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('the toolbar button opens and the panel closes the review', (
      tester,
    ) async {
      await pumpScreen(tester);
      expect(find.byType(ReadabilityPanel), findsNothing);

      await tester.tap(find.byTooltip('Readability review (⇧⌘R)'));
      await tester.pumpAndSettle();
      expect(find.byType(ReadabilityPanel), findsOneWidget);
      expect(find.text('Sentence length'), findsOneWidget);
      expect(find.textContaining('1 of 3 sentences (33%) is over'), findsOne);

      await tester.tap(find.byTooltip('Close review'));
      await tester.pumpAndSettle();
      expect(controller.isReviewing, isFalse);
      expect(find.byType(ReadabilityPanel), findsNothing);
    });

    testWidgets('the source editor highlights flagged text', (tester) async {
      controller.setViewMode(ViewMode.source);
      await pumpScreen(tester);

      List<String> highlighted() {
        final span = tester
            .state<EditableTextState>(find.byType(EditableText))
            .buildTextSpan();
        return [
          for (final child in span.children ?? const <InlineSpan>[])
            if (child is TextSpan && child.style?.backgroundColor != null)
              child.text!,
        ];
      }

      expect(highlighted(), isEmpty);

      controller.toggleReview();
      await tester.pumpAndSettle();
      expect(highlighted(), containsAll(['was saved', longSentence]));

      controller.toggleReview();
      await tester.pumpAndSettle();
      expect(highlighted(), isEmpty);
    });

    testWidgets('typing hides highlights until a 5 second pause', (
      tester,
    ) async {
      controller.setViewMode(ViewMode.source);
      controller.toggleReview();
      await pumpScreen(tester);

      bool hasHighlights() {
        final span = tester
            .state<EditableTextState>(find.byType(EditableText))
            .buildTextSpan();
        return (span.children ?? const <InlineSpan>[]).any(
          (c) => c is TextSpan && c.style?.backgroundColor != null,
        );
      }

      expect(hasHighlights(), isTrue);

      await tester.enterText(find.byType(TextField), '$text More words.');
      await tester.pump(const Duration(seconds: 1));
      // The document has caught up with the edit by now, but the
      // highlights stay hidden.
      expect(controller.readabilityReport!.source, '$text More words.');
      expect(hasHighlights(), isFalse);

      await tester.pump(const Duration(seconds: 3));
      expect(hasHighlights(), isFalse);

      await tester.pump(const Duration(seconds: 2));
      expect(hasHighlights(), isTrue);
    });

    testWidgets('moving the cursor does not hide highlights', (tester) async {
      controller.setViewMode(ViewMode.source);
      controller.toggleReview();
      await pumpScreen(tester);

      final field = tester.widget<TextField>(find.byType(TextField));
      field.controller!.selection = const TextSelection.collapsed(offset: 3);
      await tester.pump();

      final span = tester
          .state<EditableTextState>(find.byType(EditableText))
          .buildTextSpan();
      expect(
        (span.children ?? const <InlineSpan>[]).any(
          (c) => c is TextSpan && c.style?.backgroundColor != null,
        ),
        isTrue,
      );
    });

    testWidgets('in rendered view the panel says where highlights are', (
      tester,
    ) async {
      // A new document opens in Split view, so switch back to Rendered.
      controller.setViewMode(ViewMode.rendered);
      await pumpScreen(tester);
      controller.toggleReview();
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Highlights show in the Source and Split views'),
        findsOneWidget,
      );
    });
  });
}
