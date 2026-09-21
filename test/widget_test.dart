import 'package:flutter_test/flutter_test.dart';
import 'package:hob_markdown_reader/main.dart';
import 'package:hob_markdown_reader/ui/reader_screen.dart';

void main() {
  testWidgets('MarkdownReaderApp launches and displays ReaderScreen', (WidgetTester tester) async {
    await tester.pumpWidget(const MarkdownReaderApp());
    await tester.pumpAndSettle();

    expect(find.byType(ReaderScreen), findsOneWidget);
    expect(find.text('Welcome Guide.md'), findsOneWidget);
  });
}
