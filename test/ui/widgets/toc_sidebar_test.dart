import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hob_markdown_reader/models/toc_item.dart';
import 'package:hob_markdown_reader/theme/app_theme.dart';
import 'package:hob_markdown_reader/ui/widgets/toc_sidebar.dart';

void main() {
  group('TocSidebar Widget Tests', () {
    testWidgets('shows empty placeholder when document has no headings', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme(),
          home: Scaffold(
            body: TocSidebar(
              headings: const [],
              onHeadingSelected: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Outline'), findsOneWidget);
      expect(find.text('0'), findsOneWidget);
      expect(find.text('No headings found in this document.'), findsOneWidget);
    });

    testWidgets('renders list of headings and handles selection and close', (WidgetTester tester) async {
      final headings = [
        const TocItem(level: 1, title: 'Introduction', lineNumber: 1, anchor: 'introduction'),
        const TocItem(level: 2, title: 'Getting Started', lineNumber: 10, anchor: 'getting-started'),
        const TocItem(level: 3, title: 'Configuration', lineNumber: 25, anchor: 'configuration'),
      ];

      TocItem? selectedItem;
      bool closed = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme(),
          home: Scaffold(
            body: TocSidebar(
              headings: headings,
              onHeadingSelected: (item) => selectedItem = item,
              onClose: () => closed = true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('3'), findsOneWidget);
      expect(find.text('Introduction'), findsOneWidget);
      expect(find.text('H1'), findsOneWidget);
      expect(find.text('Getting Started'), findsOneWidget);
      expect(find.text('H2'), findsOneWidget);
      expect(find.text('Configuration'), findsOneWidget);
      expect(find.text('H3'), findsOneWidget);

      // Filter input is NOT shown for <= 4 headings
      expect(find.byType(TextField), findsNothing);

      // Tap heading
      await tester.tap(find.text('Getting Started'));
      await tester.pumpAndSettle();
      expect(selectedItem, equals(headings[1]));

      // Tap close button
      final closeButton = find.byTooltip('Close outline');
      expect(closeButton, findsOneWidget);
      await tester.tap(closeButton);
      await tester.pumpAndSettle();
      expect(closed, true);
    });

    testWidgets('shows filter input for > 4 headings, filters correctly, and handles clear', (WidgetTester tester) async {
      final headings = [
        const TocItem(level: 1, title: 'Apple Overview', lineNumber: 1, anchor: 'apple-overview'),
        const TocItem(level: 2, title: 'Banana Guide', lineNumber: 10, anchor: 'banana-guide'),
        const TocItem(level: 2, title: 'Cherry Setup', lineNumber: 20, anchor: 'cherry-setup'),
        const TocItem(level: 3, title: 'Date Details', lineNumber: 30, anchor: 'date-details'),
        const TocItem(level: 1, title: 'Elderberry Summary', lineNumber: 40, anchor: 'elderberry-summary'),
      ];

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme(),
          home: Scaffold(
            body: TocSidebar(
              headings: headings,
              onHeadingSelected: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Filter input should be visible
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Apple Overview'), findsOneWidget);
      expect(find.text('Elderberry Summary'), findsOneWidget);

      // Enter filter for "berry"
      await tester.enterText(find.byType(TextField), 'berry');
      await tester.pumpAndSettle();

      expect(find.text('Elderberry Summary'), findsOneWidget);
      expect(find.text('Apple Overview'), findsNothing);
      expect(find.text('Banana Guide'), findsNothing);

      // Enter filter for non-existent heading
      await tester.enterText(find.byType(TextField), 'xyz_non_existent');
      await tester.pumpAndSettle();

      expect(find.text('No matching headings'), findsOneWidget);

      // Tap clear suffix button
      final clearButton = find.byIcon(Icons.clear_rounded);
      expect(clearButton, findsOneWidget);
      await tester.tap(clearButton);
      await tester.pumpAndSettle();

      // All headings restored
      expect(find.text('Apple Overview'), findsOneWidget);
      expect(find.text('Banana Guide'), findsOneWidget);
      expect(find.text('Cherry Setup'), findsOneWidget);
      expect(find.text('Date Details'), findsOneWidget);
      expect(find.text('Elderberry Summary'), findsOneWidget);
    });
  });
}
