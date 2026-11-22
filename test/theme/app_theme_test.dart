import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hob_markdown_reader/theme/app_theme.dart';

void main() {
  test('both themes use the bundled Inter family for all text', () {
    for (final theme in [AppTheme.lightTheme(), AppTheme.darkTheme()]) {
      expect(theme.textTheme.bodyMedium?.fontFamily, AppTheme.uiFontFamily);
      expect(theme.textTheme.titleSmall?.fontFamily, AppTheme.uiFontFamily);
    }
  });

  test('code style uses the bundled JetBrains Mono family', () {
    expect(AppTheme.codeStyle().fontFamily, AppTheme.codeFontFamily);
  });

  testWidgets('markdown headings are semibold', (tester) async {
    late final MarkdownStyleSheet sheet;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme(),
        home: Builder(
          builder: (context) {
            sheet = AppTheme.markdownStyleSheet(context, scaleFactor: 1);
            return const SizedBox();
          },
        ),
      ),
    );
    expect(sheet.h1?.fontWeight, FontWeight.w600);
    expect(sheet.h2?.fontWeight, FontWeight.w600);
    expect(sheet.code?.fontFamily, AppTheme.codeFontFamily);
  });
}
