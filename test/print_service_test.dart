import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hob_markdown_reader/models/document_model.dart';
import 'package:hob_markdown_reader/services/print_service.dart';
import 'package:hob_markdown_reader/state/reader_controller.dart';
import 'package:hob_markdown_reader/theme/app_theme.dart';
import 'package:hob_markdown_reader/ui/reader_screen.dart';
import 'package:hob_markdown_reader/ui/widgets/app_toolbar.dart';

class MockPrintService extends PrintService {
  bool printDocumentCalled = false;
  DocumentModel? lastPrintedDocument;
  bool shouldThrow = false;

  @override
  Future<bool> printDocument(DocumentModel document) async {
    printDocumentCalled = true;
    lastPrintedDocument = document;
    if (shouldThrow) {
      throw Exception('Printer offline');
    }
    return true;
  }
}

DocumentModel createTestDoc({
  required String fileName,
  required String content,
}) {
  return DocumentModel(
    fileName: fileName,
    content: content,
    byteSize: content.length,
    headings: const [],
    wordCount: 10,
    charCount: content.length,
    lineCount: 5,
    readingTimeMinutes: 1.0,
  );
}

void main() {
  group('PrintService HTML Generation Tests', () {
    const printService = PrintService();

    test('generates valid HTML document with correct title and doctype', () {
      final doc = createTestDoc(
        fileName: 'Project Notes <2026>.md',
        content: '# Title\n\nSome paragraph text.',
      );

      final html = printService.generateHtml(doc);

      expect(html, contains('<!DOCTYPE html>'));
      expect(html, contains('<title>Project Notes &lt;2026&gt;.md</title>'));
      expect(html, contains('<h1>Title</h1>'));
      expect(html, contains('<p>Some paragraph text.</p>'));
      expect(html, contains('@page'));
      expect(html, contains('font-family'));
    });

    test('renders GitHub Flavored Markdown tables and code blocks into HTML', () {
      final doc = createTestDoc(
        fileName: 'table_test.md',
        content: '''
| Feature | Supported |
| :--- | :--- |
| Print | Yes |

```dart
void main() => print("hello");
```
''',
      );

      final html = printService.generateHtml(doc);

      expect(html, contains('<table>'));
      expect(html, contains('>Feature</th>'));
      expect(html, contains('>Print</td>'));
      expect(html, contains('<pre>'));
      expect(html, contains('<code'));
      expect(html, contains('void main() =&gt; print(&quot;hello&quot;);'));
    });

    test('includes print-optimized CSS rules for page breaks', () {
      final doc = createTestDoc(
        fileName: 'css_test.md',
        content: '# Heading\n\nContent',
      );

      final html = printService.generateHtml(doc);

      expect(html, contains('page-break-after: avoid;'));
      expect(html, contains('page-break-inside: avoid;'));
    });
  });

  group('ReaderController Print Tests', () {
    test('printDocument calls PrintService with current document', () async {
      final mockPrintService = MockPrintService();
      final controller = ReaderController(printService: mockPrintService);

      expect(mockPrintService.printDocumentCalled, false);

      await controller.printDocument();

      expect(mockPrintService.printDocumentCalled, true);
      expect(mockPrintService.lastPrintedDocument, isNotNull);
      expect(mockPrintService.lastPrintedDocument!.fileName, 'Welcome Guide.md');
      expect(controller.errorMessage, isNull);

      controller.dispose();
    });

    test('printDocument sets errorMessage when printing fails', () async {
      final mockPrintService = MockPrintService()..shouldThrow = true;
      final controller = ReaderController(printService: mockPrintService);

      await controller.printDocument();

      expect(mockPrintService.printDocumentCalled, true);
      expect(controller.errorMessage, contains('Failed to print document'));

      controller.dispose();
    });
  });

  group('Print Toolbar UI and Shortcut Tests', () {
    testWidgets('Print button is displayed in AppToolbar between Save and Search', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final mockPrintService = MockPrintService();
      final controller = ReaderController(printService: mockPrintService);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme(),
          home: Scaffold(
            appBar: AppToolbar(
              controller: controller,
              isCompact: false,
              onToggleSidebar: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final printButton = find.byTooltip('Print rendered document (⌘P)');
      expect(printButton, findsOneWidget);

      // Verify clicking print button calls mock print service
      await tester.tap(printButton);
      await tester.pumpAndSettle();

      expect(mockPrintService.printDocumentCalled, true);

      controller.dispose();
    });

    testWidgets('Pressing Cmd+P triggers printDocument', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final mockPrintService = MockPrintService();
      final controller = ReaderController(printService: mockPrintService);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme(),
          home: ReaderScreen(controller: controller),
        ),
      );
      await tester.pumpAndSettle();

      expect(mockPrintService.printDocumentCalled, false);

      // Simulate Cmd+P
      await tester.sendKeyDownEvent(LogicalKeyboardKey.meta);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyP);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.meta);
      await tester.pumpAndSettle();

      expect(mockPrintService.printDocumentCalled, true);

      controller.dispose();
    });
  });
}
