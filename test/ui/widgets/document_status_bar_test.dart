import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hob_markdown_reader/models/document_model.dart';
import 'package:hob_markdown_reader/state/reader_controller.dart';
import 'package:hob_markdown_reader/theme/app_theme.dart';
import 'package:hob_markdown_reader/ui/widgets/document_status_bar.dart';

void main() {
  group('DocumentStatusBar Widget Tests', () {
    late ReaderController controller;

    setUp(() {
      controller = ReaderController();
    });

    tearDown(() {
      controller.dispose();
    });

    testWidgets('renders document metrics accurately', (WidgetTester tester) async {
      final doc = DocumentModel(
        path: '/docs/example.md',
        fileName: 'example.md',
        content: '# Heading',
        byteSize: 1536,
        headings: const [],
        wordCount: 85,
        charCount: 450,
        lineCount: 22,
        readingTimeMinutes: 0.5,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme(),
          home: Scaffold(
            bottomNavigationBar: DocumentStatusBar(
              document: doc,
              controller: controller,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('85 words'), findsOneWidget);
      expect(find.text('30 sec read'), findsOneWidget);
      expect(find.text('22 lines'), findsOneWidget);
      expect(find.text('1.5 KB'), findsOneWidget);
      expect(find.text('100%'), findsOneWidget);
    });

    testWidgets('shows Live Watcher indicator when path is non-null and toggles on tap', (WidgetTester tester) async {
      final docWithFile = DocumentModel(
        path: '/docs/real_file.md',
        fileName: 'real_file.md',
        content: 'Content',
        byteSize: 100,
        headings: const [],
        wordCount: 1,
        charCount: 7,
        lineCount: 1,
        readingTimeMinutes: 0.1,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme(),
          home: ListenableBuilder(
            listenable: controller,
            builder: (context, _) => Scaffold(
              bottomNavigationBar: DocumentStatusBar(
                document: docWithFile,
                controller: controller,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Live Watcher On'), findsOneWidget);
      expect(controller.autoReloadEnabled, true);

      // Tap to toggle
      await tester.tap(find.text('Live Watcher On'));
      await tester.pumpAndSettle();

      expect(controller.autoReloadEnabled, false);
      expect(find.text('Live Watcher Off'), findsOneWidget);
    });

    testWidgets('does not show Live Watcher when document has no disk path', (WidgetTester tester) async {
      final inMemoryDoc = DocumentModel(
        path: null,
        fileName: 'Untitled.md',
        content: 'Content',
        byteSize: 100,
        headings: const [],
        wordCount: 1,
        charCount: 7,
        lineCount: 1,
        readingTimeMinutes: 0.1,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme(),
          home: Scaffold(
            bottomNavigationBar: DocumentStatusBar(
              document: inMemoryDoc,
              controller: controller,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Live Watcher On'), findsNothing);
      expect(find.text('Live Watcher Off'), findsNothing);
    });

    testWidgets('tapping zoom resets zoom factor to 100%', (WidgetTester tester) async {
      controller.zoomIn();
      controller.zoomIn();
      expect(controller.textScaleFactor, closeTo(1.2, 0.001));

      final doc = DocumentModel(
        path: null,
        fileName: 'doc.md',
        content: 'Content',
        byteSize: 100,
        headings: const [],
        wordCount: 1,
        charCount: 7,
        lineCount: 1,
        readingTimeMinutes: 0.1,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme(),
          home: ListenableBuilder(
            listenable: controller,
            builder: (context, _) => Scaffold(
              bottomNavigationBar: DocumentStatusBar(
                document: doc,
                controller: controller,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('120%'), findsOneWidget);

      await tester.tap(find.text('120%'));
      await tester.pumpAndSettle();

      expect(controller.textScaleFactor, 1.0);
      expect(find.text('100%'), findsOneWidget);
    });
  });
}
