import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hob_markdown_reader/theme/app_theme.dart';
import 'package:hob_markdown_reader/ui/widgets/search_bar_overlay.dart';

void main() {
  group('SearchBarOverlay Widget Tests', () {
    testWidgets('entering text invokes onSearchChanged and shows match count badge', (WidgetTester tester) async {
      String currentQuery = '';
      bool closeCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme(),
          home: Scaffold(
            body: SearchBarOverlay(
              matchCount: 4,
              onSearchChanged: (q) => currentQuery = q,
              onClose: () => closeCalled = true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('4 found'), findsNothing); // Hidden until text entered

      // Enter search query
      await tester.enterText(find.byType(TextField), 'Markdown');
      await tester.pumpAndSettle();

      expect(currentQuery, 'Markdown');
      expect(find.text('4 found'), findsOneWidget);

      // Clear button should now be visible
      final clearButton = find.byTooltip('Clear search');
      expect(clearButton, findsOneWidget);

      // Tap clear button
      await tester.tap(clearButton);
      await tester.pumpAndSettle();

      expect(currentQuery, '');
      expect(find.text('4 found'), findsNothing);

      // Tap close button
      final closeButton = find.byTooltip('Close (Esc)');
      expect(closeButton, findsOneWidget);
      await tester.tap(closeButton);
      await tester.pumpAndSettle();

      expect(closeCalled, true);
    });
  });
}
