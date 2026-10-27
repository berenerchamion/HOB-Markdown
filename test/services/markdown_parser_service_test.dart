import 'package:flutter_test/flutter_test.dart';
import 'package:hob_markdown_reader/services/markdown_parser_service.dart';

void main() {
  group('MarkdownParserService Extended Tests', () {
    test('extractHeadings cleans inline markdown links, formatting, and HTML tags', () {
      const markdown = '''
# [Welcome Guide](https://example.com)
Intro text.

## **Important** *Notes* & `Code`
Some text.

### <span class="tag">Release</span> 2.0 Notes ###
More text.

~~~~
# Heading inside tilde code block
def bar():
    pass
~~~~

## Final Thoughts
The end.
''';

      final headings = MarkdownParserService.extractHeadings(markdown);

      expect(headings.length, 4);

      // Link cleaned
      expect(headings[0].level, 1);
      expect(headings[0].title, 'Welcome Guide');
      expect(headings[0].anchor, 'welcome-guide');
      expect(headings[0].lineNumber, 1);

      // Bold, italic, code cleaned
      expect(headings[1].level, 2);
      expect(headings[1].title, 'Important Notes & Code');
      expect(headings[1].anchor, 'important-notes-code');
      expect(headings[1].lineNumber, 4);

      // HTML tags and trailing hashes cleaned
      expect(headings[2].level, 3);
      expect(headings[2].title, 'Release 2.0 Notes');
      expect(headings[2].anchor, 'release-20-notes');
      expect(headings[2].lineNumber, 7);

      // Heading inside tilde code block ignored, final heading captured
      expect(headings[3].level, 2);
      expect(headings[3].title, 'Final Thoughts');
      expect(headings[3].anchor, 'final-thoughts');
    });

    test('extractHeadings handles Setext headings with inline markdown', () {
      const markdown = '''
**Setext Title**
================

*Setext Subtitle*
-----------------
''';

      final headings = MarkdownParserService.extractHeadings(markdown);

      expect(headings.length, 2);
      expect(headings[0].level, 1);
      expect(headings[0].title, 'Setext Title');
      expect(headings[0].anchor, 'setext-title');

      expect(headings[1].level, 2);
      expect(headings[1].title, 'Setext Subtitle');
      expect(headings[1].anchor, 'setext-subtitle');
    });

    test('countWords accurately ignores code blocks and markdown symbols', () {
      expect(MarkdownParserService.countWords(''), 0);
      expect(MarkdownParserService.countWords('   \n\t  '), 0);

      const content = '''
# Heading One

This is a paragraph with seven words here.

```json
{
  "key": "value",
  "ignored": true
}
```

Final sentence with four words.
''';
      // Heading One: 2 words
      // paragraph: 8 words
      // code block: 0 words (ignored)
      // Final sentence: 5 words
      final words = MarkdownParserService.countWords(content);
      expect(words, 15);
    });

    test('countCharacters and countLines handle empty and multiline strings', () {
      expect(MarkdownParserService.countCharacters(''), 0);
      expect(MarkdownParserService.countCharacters('abc\n123'), 7);

      expect(MarkdownParserService.countLines(''), 0);
      expect(MarkdownParserService.countLines('one line'), 1);
      expect(MarkdownParserService.countLines('line 1\nline 2\nline 3'), 3);
    });

    test('calculateReadingTimeMinutes calculates 200 WPM accurately', () {
      expect(MarkdownParserService.calculateReadingTimeMinutes(0), 0.0);
      expect(MarkdownParserService.calculateReadingTimeMinutes(200), 1.0);
      expect(MarkdownParserService.calculateReadingTimeMinutes(100), 0.5);
      expect(MarkdownParserService.calculateReadingTimeMinutes(350), 1.75);
    });
  });
}
