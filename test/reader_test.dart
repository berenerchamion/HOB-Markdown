import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hob_markdown_reader/services/markdown_parser_service.dart';
import 'package:hob_markdown_reader/state/reader_controller.dart';
import 'package:hob_markdown_reader/theme/app_theme.dart';
import 'package:hob_markdown_reader/ui/reader_screen.dart';
import 'package:hob_markdown_reader/ui/widgets/empty_state_view.dart';
import 'package:hob_markdown_reader/ui/widgets/markdown_view.dart';
import 'package:hob_markdown_reader/ui/widgets/raw_markdown_view.dart';
import 'package:hob_markdown_reader/ui/widgets/split_view.dart';

void main() {
  group('MarkdownParserService Tests', () {
    test('extracts ATX headings correctly and ignores code blocks', () {
      const markdown = '''
# Heading 1
Intro text here.

```python
# This is a python comment, not a markdown heading
def foo():
    pass
```

## Subheading 2
Some more text.

### Nested Subheading 3 ###
Trailing hashes.
''';

      final headings = MarkdownParserService.extractHeadings(markdown);

      expect(headings.length, 3);
      expect(headings[0].level, 1);
      expect(headings[0].title, 'Heading 1');
      expect(headings[1].level, 2);
      expect(headings[1].title, 'Subheading 2');
      expect(headings[2].level, 3);
      expect(headings[2].title, 'Nested Subheading 3');
    });

    test('extracts Setext headings (=== and ---)', () {
      const markdown = '''
Setext Level 1
==============

Setext Level 2
--------------
''';

      final headings = MarkdownParserService.extractHeadings(markdown);

      expect(headings.length, 2);
      expect(headings[0].level, 1);
      expect(headings[0].title, 'Setext Level 1');
      expect(headings[1].level, 2);
      expect(headings[1].title, 'Setext Level 2');
    });

    test('calculates document metrics correctly', () {
      const content = 'Hello world! This is a simple test document with ten words.';
      final words = MarkdownParserService.countWords(content);
      final chars = MarkdownParserService.countCharacters(content);
      final lines = MarkdownParserService.countLines(content);
      final readTime = MarkdownParserService.calculateReadingTimeMinutes(words);

      expect(words, 11);
      expect(chars, content.length);
      expect(lines, 1);
      expect(readTime, 11 / 200.0);
    });
  });

  group('ReaderController State Tests', () {
    late ReaderController controller;

    setUp(() {
      controller = ReaderController();
    });

    tearDown(() {
      controller.dispose();
    });

    test('initializes with sample guide document', () {
      expect(controller.currentDocument, isNotNull);
      expect(controller.currentDocument!.fileName, 'Welcome Guide.md');
      expect(controller.viewMode, ViewMode.rendered);
      expect(controller.textScaleFactor, 1.0);
      expect(controller.isSidebarOpen, true);
    });

    test('zoomIn, zoomOut, resetZoom update textScaleFactor within bounds', () {
      controller.zoomIn();
      expect(controller.textScaleFactor, closeTo(1.1, 0.001));

      controller.zoomOut();
      expect(controller.textScaleFactor, closeTo(1.0, 0.001));

      controller.zoomOut();
      expect(controller.textScaleFactor, closeTo(0.9, 0.001));

      controller.resetZoom();
      expect(controller.textScaleFactor, 1.0);
    });

    test('toggleTheme cycles through theme modes', () {
      expect(controller.themeMode, ThemeMode.system);
      controller.toggleTheme();
      expect(controller.themeMode, ThemeMode.dark);
      controller.toggleTheme();
      expect(controller.themeMode, ThemeMode.light);
      controller.toggleTheme();
      expect(controller.themeMode, ThemeMode.system);
    });

    test('setViewMode changes viewMode correctly', () {
      controller.setViewMode(ViewMode.split);
      expect(controller.viewMode, ViewMode.split);
      controller.setViewMode(ViewMode.source);
      expect(controller.viewMode, ViewMode.source);
      controller.setViewMode(ViewMode.rendered);
      expect(controller.viewMode, ViewMode.rendered);
    });

    test('clearDocument and loadSampleDocument work correctly', () {
      controller.clearDocument();
      expect(controller.currentDocument, isNull);
      expect(controller.hasDocument, false);

      controller.loadSampleDocument();
      expect(controller.currentDocument, isNotNull);
      expect(controller.hasDocument, true);
    });

    test('newDocument creates untitled document ready for editing', () {
      controller.newDocument();
      expect(controller.currentDocument, isNotNull);
      expect(controller.currentDocument!.fileName, 'Untitled.md');
      expect(controller.currentDocument!.path, isNull);
      expect(controller.isDirty, false);
      expect(controller.viewMode, ViewMode.split);
    });

    test('updateContent recalculates metrics and marks document dirty', () {
      expect(controller.isDirty, false);

      controller.updateContent('# New Edited Heading\n\nThis is new content with six words.');

      expect(controller.isDirty, true);
      expect(controller.currentDocument!.headings.length, 1);
      expect(controller.currentDocument!.headings.first.title, 'New Edited Heading');
      expect(controller.currentDocument!.wordCount, 10);
    });

    test('search query management', () {
      expect(controller.isSearching, false);
      controller.toggleSearching();
      expect(controller.isSearching, true);

      controller.setSearchQuery('Material');
      expect(controller.searchQuery, 'Material');

      controller.clearSearch();
      expect(controller.searchQuery, '');
      expect(controller.isSearching, false);
    });
  });

  group('Widget UI Tests', () {
    testWidgets('renders ReaderScreen with Material 3 and sample document', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final controller = ReaderController();

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme(),
          darkTheme: AppTheme.darkTheme(),
          home: ReaderScreen(controller: controller),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Toolbar and Title
      expect(find.text('Welcome Guide.md'), findsOneWidget);
      expect(find.byType(MarkdownView), findsOneWidget);

      // Verify outline sidebar
      expect(find.text('Outline'), findsOneWidget);

      controller.dispose();
    });

    testWidgets('switches to Split and Source views', (WidgetTester tester) async {
      final controller = ReaderController();

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme(),
          home: ReaderScreen(controller: controller),
        ),
      );
      await tester.pumpAndSettle();

      // Switch to Split View
      controller.setViewMode(ViewMode.split);
      await tester.pumpAndSettle();
      expect(find.byType(SplitView), findsOneWidget);

      // Switch to Source View
      controller.setViewMode(ViewMode.source);
      await tester.pumpAndSettle();
      expect(find.byType(RawMarkdownView), findsOneWidget);

      controller.dispose();
    });

    testWidgets('shows EmptyStateView when no document is open', (WidgetTester tester) async {
      final controller = ReaderController();
      controller.clearDocument();

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme(),
          home: ReaderScreen(controller: controller),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(EmptyStateView), findsOneWidget);
      expect(find.text('No Markdown File Open'), findsOneWidget);
      expect(find.text('New File'), findsOneWidget);
      expect(find.text('Open File'), findsOneWidget);
      expect(find.text('Welcome Guide'), findsOneWidget);

      controller.dispose();
    });
  });
}
