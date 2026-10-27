import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hob_markdown_reader/models/document_model.dart';
import 'package:hob_markdown_reader/services/file_service.dart';
import 'package:hob_markdown_reader/state/reader_controller.dart';
import 'package:hob_markdown_reader/theme/app_theme.dart';
import 'package:hob_markdown_reader/ui/widgets/empty_state_view.dart';

class MockEmptyFileService extends FileService {
  String? openedPath;
  bool pickCalled = false;

  @override
  Future<DocumentModel> loadFile(String filePath) async {
    openedPath = filePath;
    return buildDocumentFromContent(
      path: filePath,
      fileName: filePath.split('/').last,
      content: '# Document Content',
    );
  }

  @override
  Future<String?> pickMarkdownFile() async {
    pickCalled = true;
    return null;
  }
}

void main() {
  group('EmptyStateView Widget Tests', () {
    late MockEmptyFileService mockService;
    late ReaderController controller;

    setUp(() {
      mockService = MockEmptyFileService();
      controller = ReaderController(fileService: mockService);
    });

    tearDown(() {
      controller.dispose();
    });

    Widget buildTestWidget() {
      return MaterialApp(
        theme: AppTheme.lightTheme(),
        home: ListenableBuilder(
          listenable: controller,
          builder: (context, _) => Scaffold(
            body: EmptyStateView(controller: controller),
          ),
        ),
      );
    }

    testWidgets('renders action buttons and handles New File, Welcome Guide, Open File', (WidgetTester tester) async {
      controller.clearDocument();

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('No Markdown File Open'), findsOneWidget);
      expect(find.text('Recent Files'), findsNothing);

      // Tap New File
      await tester.tap(find.text('New File'));
      await tester.pumpAndSettle();
      expect(controller.currentDocument, isNotNull);
      expect(controller.currentDocument!.fileName, 'Untitled.md');

      // Clear again
      controller.clearDocument();
      await tester.pumpAndSettle();

      // Tap Welcome Guide
      await tester.tap(find.text('Welcome Guide'));
      await tester.pumpAndSettle();
      expect(controller.currentDocument, isNotNull);
      expect(controller.currentDocument!.fileName, 'Welcome Guide.md');

      // Clear again
      controller.clearDocument();
      await tester.pumpAndSettle();

      // Tap Open File
      await tester.tap(find.text('Open File'));
      await tester.pumpAndSettle();
      expect(mockService.pickCalled, true);
    });

    testWidgets('renders recent files list and handles opening and removing items', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await controller.openFile('/docs/notes.md');
      await controller.openFile('/docs/readme.md');
      controller.clearDocument();

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Recent Files'), findsOneWidget);
      expect(find.text('readme.md'), findsOneWidget);
      expect(find.text('/docs/readme.md'), findsOneWidget);
      expect(find.text('notes.md'), findsOneWidget);
      expect(find.text('/docs/notes.md'), findsOneWidget);

      // Tap to open a recent file
      await tester.tap(find.text('notes.md'));
      await tester.pumpAndSettle();

      expect(mockService.openedPath, '/docs/notes.md');

      // Clear doc and remove readme.md from recent files
      controller.clearDocument();
      await tester.pumpAndSettle();

      final removeButtons = find.byTooltip('Remove from history');
      expect(removeButtons, findsNWidgets(2));

      await tester.tap(removeButtons.first);
      await tester.pumpAndSettle();

      expect(controller.recentFiles.length, 1);
      expect(find.byTooltip('Remove from history'), findsOneWidget);
    });
  });
}
