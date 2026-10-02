import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hob_markdown_reader/main.dart';
import 'package:hob_markdown_reader/services/file_open_service.dart';
import 'package:hob_markdown_reader/ui/reader_screen.dart';
import 'package:hob_markdown_reader/ui/widgets/markdown_view.dart';

void main() {
  tearDown(() {
    FileOpenService.resetListenerForTesting();
  });

  testWidgets('MarkdownReaderApp launches and displays ReaderScreen', (WidgetTester tester) async {
    await tester.pumpWidget(const MarkdownReaderApp());
    await tester.pumpAndSettle();

    expect(find.byType(ReaderScreen), findsOneWidget);
    expect(find.text('Welcome Guide.md'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('MarkdownReaderApp launches and loads file in view mode when initialFilePath provided', (WidgetTester tester) async {
    final tempDir = Directory.systemTemp.createTempSync('md_widget_test_');
    final testFile = File('${tempDir.path}/custom_document.md');
    testFile.writeAsStringSync('# Custom Title\n\nDirectly opened from Finder.');

    await tester.pumpWidget(MarkdownReaderApp(initialFilePath: testFile.path));

    await tester.runAsync(() async {
      var attempts = 0;
      while (find.text('custom_document.md').evaluate().isEmpty && attempts < 50) {
        await Future<void>.delayed(const Duration(milliseconds: 20));
        await tester.pump();
        attempts++;
      }
    });
    await tester.pump();

    expect(find.byType(ReaderScreen), findsOneWidget);
    expect(find.text('custom_document.md'), findsOneWidget);
    expect(find.byType(MarkdownView), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    tempDir.deleteSync(recursive: true);
  });
}
