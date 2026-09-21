import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hob_markdown_reader/main.dart';
import 'package:hob_markdown_reader/ui/reader_screen.dart';
import 'package:hob_markdown_reader/ui/widgets/markdown_view.dart';

void main() {
  testWidgets('MarkdownReaderApp launches and displays ReaderScreen', (WidgetTester tester) async {
    await tester.pumpWidget(const MarkdownReaderApp());
    await tester.pumpAndSettle();

    expect(find.byType(ReaderScreen), findsOneWidget);
    expect(find.text('Welcome Guide.md'), findsOneWidget);
  });

  testWidgets('MarkdownReaderApp launches and loads file in view mode when initialFilePath provided', (WidgetTester tester) async {
    final tempDir = await Directory.systemTemp.createTemp('md_widget_test_');
    final testFile = File('${tempDir.path}/custom_document.md');
    await testFile.writeAsString('# Custom Title\n\nDirectly opened from Finder.');

    await tester.pumpWidget(MarkdownReaderApp(initialFilePath: testFile.path));
    await tester.pumpAndSettle();

    expect(find.byType(ReaderScreen), findsOneWidget);
    expect(find.text('custom_document.md'), findsOneWidget);
    expect(find.byType(MarkdownView), findsOneWidget);

    await tempDir.delete(recursive: true);
  });
}

