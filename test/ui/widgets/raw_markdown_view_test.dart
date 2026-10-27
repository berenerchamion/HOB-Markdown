import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hob_markdown_reader/models/document_model.dart';
import 'package:hob_markdown_reader/theme/app_theme.dart';
import 'package:hob_markdown_reader/ui/widgets/raw_markdown_view.dart';

void main() {
  group('RawMarkdownView Widget Tests', () {
    testWidgets('renders line numbers gutter and text editor', (WidgetTester tester) async {
      final doc = DocumentModel(
        path: '/test/lines.md',
        fileName: 'lines.md',
        content: 'Line 1\nLine 2\nLine 3',
        byteSize: 20,
        headings: const [],
        wordCount: 6,
        charCount: 20,
        lineCount: 3,
        readingTimeMinutes: 0.1,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme(),
          home: Scaffold(
            body: RawMarkdownView(
              document: doc,
              scaleFactor: 1.0,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('1'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
      expect(find.text('Line 1\nLine 2\nLine 3'), findsOneWidget);
    });

    testWidgets('editing text calls onChanged after debounce', (WidgetTester tester) async {
      final doc = DocumentModel(
        path: '/test/edit.md',
        fileName: 'edit.md',
        content: '# Original',
        byteSize: 10,
        headings: const [],
        wordCount: 2,
        charCount: 10,
        lineCount: 1,
        readingTimeMinutes: 0.1,
      );

      String? lastChangedText;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme(),
          home: Scaffold(
            body: RawMarkdownView(
              document: doc,
              scaleFactor: 1.0,
              onChanged: (text) => lastChangedText = text,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Enter new text
      await tester.enterText(find.byType(TextField), '# New Text');

      // Before debounce fires
      expect(lastChangedText, isNull);

      // Advance debounce timer (150ms)
      await tester.pump(const Duration(milliseconds: 200));

      expect(lastChangedText, '# New Text');
    });

    testWidgets('Copy All copies text to clipboard and toggles button label', (WidgetTester tester) async {
      String? copiedClipboardText;

      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (MethodCall methodCall) async {
          if (methodCall.method == 'Clipboard.setData') {
            final Map<dynamic, dynamic> args = methodCall.arguments as Map<dynamic, dynamic>;
            copiedClipboardText = args['text'] as String?;
            return null;
          }
          return null;
        },
      );

      final doc = DocumentModel(
        path: '/test/copy.md',
        fileName: 'copy.md',
        content: '# Copy Me',
        byteSize: 9,
        headings: const [],
        wordCount: 2,
        charCount: 9,
        lineCount: 1,
        readingTimeMinutes: 0.1,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme(),
          home: Scaffold(
            body: RawMarkdownView(
              document: doc,
              scaleFactor: 1.0,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final copyAllButton = find.text('Copy All');
      expect(copyAllButton, findsOneWidget);

      await tester.tap(copyAllButton);
      await tester.pumpAndSettle();

      expect(find.text('Copied'), findsOneWidget);
      expect(copiedClipboardText, '# Copy Me');

      // Advance timer for 2 seconds
      await tester.pump(const Duration(seconds: 2));
      expect(find.text('Copied'), findsNothing);
      expect(find.text('Copy All'), findsOneWidget);
    });

    testWidgets('didUpdateWidget updates text when document changes with a new path', (WidgetTester tester) async {
      final doc1 = DocumentModel(
        path: '/test/file1.md',
        fileName: 'file1.md',
        content: 'Content 1',
        byteSize: 9,
        headings: const [],
        wordCount: 2,
        charCount: 9,
        lineCount: 1,
        readingTimeMinutes: 0.1,
      );

      final doc2 = DocumentModel(
        path: '/test/file2.md',
        fileName: 'file2.md',
        content: 'Line A\nLine B',
        byteSize: 13,
        headings: const [],
        wordCount: 4,
        charCount: 13,
        lineCount: 2,
        readingTimeMinutes: 0.1,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme(),
          home: Scaffold(
            body: RawMarkdownView(
              document: doc1,
              scaleFactor: 1.0,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Content 1'), findsOneWidget);

      // Rebuild with doc2
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme(),
          home: Scaffold(
            body: RawMarkdownView(
              document: doc2,
              scaleFactor: 1.0,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Line A\nLine B'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
    });
  });
}
