import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hob_markdown_reader/theme/app_theme.dart';
import 'package:hob_markdown_reader/ui/widgets/drop_target_zone.dart';

void main() {
  group('DropTargetZone Widget Tests', () {
    testWidgets('renders child widget and handles drag callbacks', (WidgetTester tester) async {
      String? droppedPath;
      bool? isDragging;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme(),
          home: Scaffold(
            body: DropTargetZone(
              onFileDropped: (path) => droppedPath = path,
              onDraggingChanged: (dragging) => isDragging = dragging,
              child: const Text('Inner Content'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Inner Content'), findsOneWidget);
      expect(find.text('Drop Markdown file here'), findsNothing);

      // Locate DropTarget
      final dropTargetFinder = find.byType(DropTarget);
      expect(dropTargetFinder, findsOneWidget);
      final DropTarget dropTarget = tester.widget<DropTarget>(dropTargetFinder);

      // Simulate onDragEntered
      dropTarget.onDragEntered?.call(DropEventDetails(
        localPosition: Offset.zero,
        globalPosition: Offset.zero,
      ));
      await tester.pump();

      expect(isDragging, true);
      expect(find.text('Drop Markdown file here'), findsOneWidget);

      // Simulate onDragExited
      dropTarget.onDragExited?.call(DropEventDetails(
        localPosition: Offset.zero,
        globalPosition: Offset.zero,
      ));
      await tester.pump();

      expect(isDragging, false);
      expect(find.text('Drop Markdown file here'), findsNothing);

      // Simulate onDragDone with file
      final dropItem = DropItemFile('/path/to/dragged.md');
      dropTarget.onDragDone?.call(DropDoneDetails(
        localPosition: Offset.zero,
        globalPosition: Offset.zero,
        files: [dropItem],
      ));
      await tester.pump();

      expect(isDragging, false);
      expect(droppedPath, '/path/to/dragged.md');
    });
  });
}
