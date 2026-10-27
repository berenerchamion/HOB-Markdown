import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hob_markdown_reader/theme/app_theme.dart';
import 'package:hob_markdown_reader/ui/widgets/code_block_builder.dart';

void main() {
  group('CodeBlockBuilder Widget Tests', () {
    testWidgets('renders language badge and handles copy button', (WidgetTester tester) async {
      String? copiedClipboardText;

      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (MethodCall methodCall) async {
          if (methodCall.method == 'Clipboard.setData') {
            final Map<dynamic, dynamic> args = methodCall.arguments as Map<dynamic, dynamic>;
            copiedClipboardText = args['text'] as String?;
            return null;
          }
          return null;
        },
      );

      const markdown = '''
```dart
void greet() {
  print("Hello, world!");
}
```

```
Plain text code block
```
''';

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme(),
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return Markdown(
                  data: markdown,
                  builders: {
                    'code': CodeBlockBuilder(
                      context: context,
                      scaleFactor: 1.0,
                    ),
                  },
                );
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Badges
      expect(find.text('DART'), findsOneWidget);
      expect(find.text('CODE'), findsOneWidget);

      // Copy button
      final copyButtons = find.text('Copy');
      expect(copyButtons, findsNWidgets(2));

      // Tap the first Copy button
      await tester.tap(copyButtons.first);
      await tester.pumpAndSettle();

      expect(find.text('Copied'), findsOneWidget);
      expect(copiedClipboardText, contains('void greet()'));
      expect(copiedClipboardText, contains('Hello, world!'));

      // Advance past the 2-second reset timer
      await tester.pump(const Duration(seconds: 2));
      expect(find.text('Copied'), findsNothing);
      expect(find.text('Copy'), findsNWidgets(2));
    });
  });
}
