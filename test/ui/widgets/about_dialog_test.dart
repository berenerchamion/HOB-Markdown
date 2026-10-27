import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hob_markdown_reader/theme/app_theme.dart';
import 'package:hob_markdown_reader/ui/widgets/about_dialog.dart';

void main() {
  group('AboutDialog Widget Tests', () {
    testWidgets('shows custom license dialog with actions', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme(),
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () => showAppAboutDialog(context),
                  child: const Text('Open License'),
                );
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open License'));
      await tester.pumpAndSettle();

      expect(find.text('HOB Markdown License'), findsOneWidget);
      expect(find.text('A fast, native markdown reader and editor.'), findsOneWidget);
      expect(find.text('Third-party licenses'), findsOneWidget);
      expect(find.text('Close'), findsOneWidget);

      // Tap Close
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();

      expect(find.text('HOB Markdown License'), findsNothing);
    });
  });
}
