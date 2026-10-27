import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hob_markdown_reader/models/document_model.dart';
import 'package:hob_markdown_reader/services/file_service.dart';
import 'package:hob_markdown_reader/state/reader_controller.dart';
import 'package:hob_markdown_reader/theme/app_theme.dart';
import 'package:hob_markdown_reader/ui/widgets/app_toolbar.dart';

class StubFileService extends FileService {
  bool saveCalled = false;

  @override
  Future<DocumentModel> saveFile(String filePath, String content) async {
    saveCalled = true;
    return buildDocumentFromContent(path: filePath, fileName: 'test.md', content: content);
  }
}

void main() {
  group('AppToolbar Widget Tests', () {
    late StubFileService stubService;
    late ReaderController controller;

    setUp(() {
      stubService = StubFileService();
      controller = ReaderController(fileService: stubService);
    });

    tearDown(() {
      controller.dispose();
    });

    Widget buildTestApp({bool isCompact = false}) {
      return MaterialApp(
        theme: AppTheme.lightTheme(),
        home: ListenableBuilder(
          listenable: controller,
          builder: (context, _) => Scaffold(
            appBar: AppToolbar(
              controller: controller,
              isCompact: isCompact,
              onToggleSidebar: () {},
            ),
          ),
        ),
      );
    }

    testWidgets('Help button is displayed and opens help window', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      final helpButton = find.byTooltip('Show help (⌘H)');
      expect(helpButton, findsOneWidget);
      expect(controller.isHelpWindowOpen, false);

      await tester.tap(helpButton);
      await tester.pumpAndSettle();

      expect(controller.isHelpWindowOpen, true);
    });

    testWidgets('shows dirty indicator dot and tonal Save button when document has unsaved edits', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      // Clean state
      expect(find.text('Welcome Guide.md'), findsOneWidget);
      expect(find.byTooltip('Save (⌘S)'), findsOneWidget);

      // Edit content to make dirty
      controller.updateContent('# Edited content');
      await tester.pumpAndSettle();

      // Dirty state
      expect(find.text('Welcome Guide.md •'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Save'), findsOneWidget);

      // Tapping save
      await tester.tap(find.widgetWithText(FilledButton, 'Save'));
      await tester.pumpAndSettle();
    });

    testWidgets('renders fallback HOB Markdown title and hides doc actions when document is null', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      controller.clearDocument();

      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      expect(find.text('HOB Markdown'), findsOneWidget);
      expect(find.byType(SegmentedButton<ViewMode>), findsNothing);
      expect(find.byTooltip('Save (⌘S)'), findsNothing);
      expect(find.byTooltip('Print rendered document (⌘P)'), findsNothing);
      expect(find.byTooltip('Search in document (⌘F)'), findsNothing);

      // General buttons still visible
      expect(find.byTooltip('Show help (⌘H)'), findsOneWidget);
      expect(find.text('Open'), findsOneWidget);
    });

    testWidgets('hides segmented button and zoom in compact mode', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(600, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTestApp(isCompact: true));
      await tester.pumpAndSettle();

      expect(find.byType(SegmentedButton<ViewMode>), findsNothing);
      expect(find.byTooltip('Zoom In (⌘+)'), findsNothing);
      expect(find.byTooltip('Zoom Out (⌘-)'), findsNothing);
    });

    testWidgets('segmented button switches view modes', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      expect(controller.viewMode, ViewMode.rendered);

      // Tap Split
      await tester.tap(find.text('Split'));
      await tester.pumpAndSettle();
      expect(controller.viewMode, ViewMode.split);

      // Tap Source
      await tester.tap(find.text('Source'));
      await tester.pumpAndSettle();
      expect(controller.viewMode, ViewMode.source);

      // Tap Render
      await tester.tap(find.text('Render'));
      await tester.pumpAndSettle();
      expect(controller.viewMode, ViewMode.rendered);
    });
  });
}
