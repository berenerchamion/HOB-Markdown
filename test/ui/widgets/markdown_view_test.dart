import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hob_markdown_reader/models/document_model.dart';
import 'package:hob_markdown_reader/models/toc_item.dart';
import 'package:hob_markdown_reader/theme/app_theme.dart';
import 'package:hob_markdown_reader/ui/widgets/markdown_view.dart';

void main() {
  group('MarkdownView Widget Tests', () {
    testWidgets('renders markdown and navigates to heading on anchor link tap', (WidgetTester tester) async {
      const heading = TocItem(
        level: 2,
        title: 'Key Features',
        lineNumber: 10,
        anchor: 'key-features',
      );

      final doc = DocumentModel(
        path: '/docs/doc.md',
        fileName: 'doc.md',
        content: '''
# Main Title

Jump to [Key Features](#key-features) section.

## Key Features
Details here.
''',
        byteSize: 100,
        headings: const [heading],
        wordCount: 12,
        charCount: 100,
        lineCount: 8,
        readingTimeMinutes: 0.1,
      );

      final scrollController = ScrollController();
      TocItem? navigatedItem;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme(),
          home: Scaffold(
            body: MarkdownView(
              document: doc,
              scaleFactor: 1.0,
              scrollController: scrollController,
              onNavigateToHeading: (item) => navigatedItem = item,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Main Title'), findsOneWidget);
      expect(find.text('Key Features'), findsOneWidget);

      expect(find.byType(Markdown), findsOneWidget);

      // Invoke onTapLink on Markdown widget
      final markdown = tester.widget<Markdown>(find.byType(Markdown));
      markdown.onTapLink?.call('Key Features', '#key-features', 'Key Features');
      await tester.pumpAndSettle();

      expect(navigatedItem, equals(heading));

      scrollController.dispose();
    });
  });
}
