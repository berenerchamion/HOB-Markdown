import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  testWidgets('MarkdownReaderApp handles warm start incoming file when clean', (WidgetTester tester) async {
    final tempDir = Directory.systemTemp.createTempSync('md_warm_start_clean_');
    final incomingFile = File('${tempDir.path}/incoming_clean.md');
    incomingFile.writeAsStringSync('# Clean Incoming\n\nDirect open.');

    await tester.pumpWidget(const MarkdownReaderApp());
    await tester.pumpAndSettle();

    expect(find.text('Welcome Guide.md'), findsOneWidget);

    // Simulate OS warm start opening incoming file
    const codec = StandardMethodCodec();
    final data = codec.encodeMethodCall(
      MethodCall('onFileOpened', incomingFile.path),
    );
    await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .handlePlatformMessage('com.hob.markdown/file_open', data, (_) {});

    await tester.runAsync(() async {
      var attempts = 0;
      while (find.text('incoming_clean.md').evaluate().isEmpty && attempts < 50) {
        await Future<void>.delayed(const Duration(milliseconds: 20));
        await tester.pump();
        attempts++;
      }
    });
    await tester.pumpAndSettle();

    expect(find.text('incoming_clean.md'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    tempDir.deleteSync(recursive: true);
  });

  testWidgets('MarkdownReaderApp prompts with UnsavedChangesDialog on warm start when dirty', (WidgetTester tester) async {
    final tempDir = Directory.systemTemp.createTempSync('md_warm_start_dirty_');
    final incomingFile = File('${tempDir.path}/incoming_dirty.md');
    incomingFile.writeAsStringSync('# Incoming File\n\nContent.');

    await tester.pumpWidget(const MarkdownReaderApp());
    await tester.pumpAndSettle();

    // Make active document dirty by switching to split and typing
    final readerScreen = tester.widget<ReaderScreen>(find.byType(ReaderScreen));
    readerScreen.controller.updateContent('# Edited Guide Content');
    await tester.pumpAndSettle();

    expect(readerScreen.controller.isDirty, true);
    expect(find.text('Welcome Guide.md •'), findsOneWidget);

    // Send warm start file open event
    const codec = StandardMethodCodec();
    final data = codec.encodeMethodCall(
      MethodCall('onFileOpened', incomingFile.path),
    );
    await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .handlePlatformMessage('com.hob.markdown/file_open', data, (_) {});
    await tester.pumpAndSettle();

    // Verify UnsavedChangesDialog appeared
    expect(find.text('Unsaved Changes'), findsOneWidget);
    expect(find.textContaining('incoming_dirty.md'), findsOneWidget);

    // Tap Cancel -> should stay on dirty document
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(find.text('Welcome Guide.md •'), findsOneWidget);
    expect(readerScreen.controller.isDirty, true);

    // Send file open event again
    await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .handlePlatformMessage('com.hob.markdown/file_open', data, (_) {});
    await tester.pumpAndSettle();

    expect(find.text('Unsaved Changes'), findsOneWidget);

    // Tap Discard Changes -> should open incoming file
    await tester.tap(find.text('Discard Changes'));
    await tester.runAsync(() async {
      var attempts = 0;
      while (find.text('incoming_dirty.md').evaluate().isEmpty && attempts < 50) {
        await Future<void>.delayed(const Duration(milliseconds: 20));
        await tester.pump();
        attempts++;
      }
    });
    await tester.pumpAndSettle();

    expect(find.text('incoming_dirty.md'), findsOneWidget);
    expect(readerScreen.controller.isDirty, false);

    await tester.pumpWidget(const SizedBox());
    tempDir.deleteSync(recursive: true);
  });
}
