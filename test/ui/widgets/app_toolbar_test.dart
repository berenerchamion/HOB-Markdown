import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hob_markdown_reader/models/document_model.dart';
import 'package:hob_markdown_reader/services/file_service.dart';
import 'package:hob_markdown_reader/state/reader_controller.dart';
import 'package:hob_markdown_reader/theme/app_theme.dart';
import 'package:hob_markdown_reader/ui/widgets/app_toolbar.dart';
import 'package:hob_markdown_reader/ui/widgets/toolbar_controls.dart';

class StubFileService extends FileService {
  bool saveCalled = false;

  @override
  Future<String?> pickSavePath({
    String suggestedName = 'document.md',
    required String content,
  }) async {
    return '/test/saved_doc.md';
  }

  @override
  Future<DocumentModel> buildDocumentModelFromDisk(
    String filePath,
    String content,
  ) async {
    saveCalled = true;
    return buildDocumentFromContent(
      path: filePath,
      fileName: 'test.md',
      content: content,
    );
  }

  @override
  Future<DocumentModel> loadFile(String filePath) async {
    return buildDocumentFromContent(
      path: filePath,
      fileName: 'doc.md',
      content: '# Doc',
    );
  }

  @override
  Future<DocumentModel> saveFile(String filePath, String content) async {
    saveCalled = true;
    return buildDocumentFromContent(
      path: filePath,
      fileName: 'test.md',
      content: content,
    );
  }

  // Widget tests shouldn't start real OS file watchers. On Windows the real
  // watcher polls using a periodic timer that is still pending when the test
  // ends, which fails with "A Timer is still pending even after the widget
  // tree was disposed". (tearDown runs too late to cancel it.)
  @override
  void startWatchingFile(String filePath, VoidCallback onFileChanged) {}

  @override
  void stopWatchingFile() {}
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

    testWidgets('Help button is displayed and opens help window', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      final helpButton = find.byTooltip('Show help');
      expect(helpButton, findsOneWidget);
      expect(controller.isHelpWindowOpen, false);

      await tester.tap(helpButton);
      await tester.pumpAndSettle();

      expect(controller.isHelpWindowOpen, true);
    });

    testWidgets(
      'shows dirty indicator dot and labelled Save button when document has unsaved edits',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(1200, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(buildTestApp());
        await tester.pumpAndSettle();

        // Clean state
        expect(find.text('Welcome Guide.md'), findsOneWidget);
        expect(find.byTooltip('Save (⌘S)'), findsOneWidget);
        expect(find.text('Save'), findsNothing); // icon only while clean

        // Edit content to make dirty
        controller.updateContent('# Edited content');
        await tester.pumpAndSettle();

        // Dirty state
        expect(find.text('Welcome Guide.md •'), findsOneWidget);
        expect(find.text('Save'), findsOneWidget);

        // Tapping save
        await tester.tap(find.text('Save'));
        await tester.pumpAndSettle();
        expect(stubService.saveCalled, true);
      },
    );

    testWidgets(
      'renders fallback HOB Markdown title and hides doc actions when document is null',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(1200, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        controller.clearDocument();

        await tester.pumpWidget(buildTestApp());
        await tester.pumpAndSettle();

        expect(find.text('HOB Markdown'), findsOneWidget);
        expect(find.byType(ViewModeSwitch), findsNothing);
        expect(find.byTooltip('Save (⌘S)'), findsNothing);
        expect(find.byTooltip('Print rendered document (⌘P)'), findsNothing);
        expect(find.byTooltip('Search in document (⌘F)'), findsNothing);

        // General buttons still visible
        expect(find.byTooltip('Show help'), findsOneWidget);
        expect(find.text('Open'), findsOneWidget);
      },
    );

    testWidgets('hides view switch and zoom in compact mode', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(600, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTestApp(isCompact: true));
      await tester.pumpAndSettle();

      expect(find.byType(ViewModeSwitch), findsNothing);
      expect(find.byTooltip('Zoom In (⌘+)'), findsNothing);
      expect(find.byTooltip('Zoom Out (⌘-)'), findsNothing);
    });

    testWidgets('view switch changes view modes', (WidgetTester tester) async {
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

    testWidgets('shows zoom and reload on Windows and Linux, not macOS', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await controller.openFile('/test/doc.md');

      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();
      expect(find.byTooltip('Zoom In (⌘+)'), findsOneWidget);
      expect(find.byTooltip('Reload File (⌘R)'), findsOneWidget);

      debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();
      expect(find.byTooltip('Zoom In (⌘+)'), findsNothing);
      expect(find.byTooltip('Reload File (⌘R)'), findsNothing);
      debugDefaultTargetPlatformOverride = null;
    });

    testWidgets('search and review buttons show as selected while open', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      ToolbarButton button(String tooltip) => tester.widget<ToolbarButton>(
        find.ancestor(
          of: find.byTooltip(tooltip),
          matching: find.byType(ToolbarButton),
        ),
      );
      expect(button('Search in document (⌘F)').selected, isFalse);

      await tester.tap(find.byTooltip('Search in document (⌘F)'));
      await tester.pumpAndSettle();
      expect(controller.isSearching, isTrue);
      expect(button('Search in document (⌘F)').selected, isTrue);

      await tester.tap(find.byTooltip('Readability review (⇧⌘R)'));
      await tester.pumpAndSettle();
      expect(button('Hide readability review (⇧⌘R)').selected, isTrue);
    });

    for (final width in [840.0, 1000.0]) {
      testWidgets('toolbar fits at ${width.toInt()}px on macOS when dirty', (
        WidgetTester tester,
      ) async {
        tester.view.physicalSize = Size(width, 600);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);
        debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
        addTearDown(() => debugDefaultTargetPlatformOverride = null);
        controller.updateContent('# Edited');

        await tester.pumpWidget(buildTestApp());
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull); // no overflow
        expect(find.text('Save'), findsOneWidget);
        expect(
          find.text('Split'),
          width >= 1000 ? findsOneWidget : findsNothing,
        );
        debugDefaultTargetPlatformOverride = null;
      });
    }
  });
}
