import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hob_markdown_reader/models/document_model.dart';
import 'package:hob_markdown_reader/theme/app_theme.dart';
import 'package:hob_markdown_reader/ui/widgets/markdown_view.dart';

void main() {
  testWidgets('GitHub alerts render with a title, not the [!TIP] marker', (
    tester,
  ) async {
    const content = '> [!TIP]\n> Press the button.\n\n> Just a quote.';
    final doc = DocumentModel(
      fileName: 'alert.md',
      content: content,
      byteSize: content.length,
      headings: const [],
      wordCount: 6,
      charCount: content.length,
      lineCount: 4,
      readingTimeMinutes: 0.1,
    );
    final scroll = ScrollController();
    addTearDown(scroll.dispose);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme(),
        home: Scaffold(
          body: MarkdownView(
            document: doc,
            scaleFactor: 1.0,
            scrollController: scroll,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('[!TIP]', findRichText: true), findsNothing);
    expect(find.text('Tip', findRichText: true), findsOneWidget);
    expect(
      find.textContaining('Press the button.', findRichText: true),
      findsOneWidget,
    );
    expect(
      find.textContaining('Just a quote.', findRichText: true),
      findsOneWidget,
    );
  });
}
