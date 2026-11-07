import 'package:flutter_test/flutter_test.dart';
import 'package:hob_markdown_reader/models/readability_settings.dart';
import 'package:hob_markdown_reader/services/readability_service.dart';

ReadabilityReport analyze(
  String text, [
  ReadabilitySettings settings = const ReadabilitySettings(),
]) => ReadabilityService.analyze(text, settings);

List<String> flagged(ReadabilityReport report, ReadabilityCheck check) => [
  for (final i in report.issues)
    if (i.check == check) report.source.substring(i.start, i.end),
];

String words(int n, [String word = 'word']) => List.filled(n, word).join(' ');

void main() {
  group('parsing', () {
    test('an empty document has no sentences and passes everything', () {
      final report = analyze('');
      expect(report.sentenceCount, 0);
      expect(report.issues, isEmpty);
      expect(report.results.every((r) => r.passed), isTrue);
    });

    test('splits sentences on . ! and ?', () {
      final report = analyze('One two. Three four! Five six? Seven');
      expect(report.sentenceCount, 4);
      expect(report.wordCount, 7);
    });

    test('does not split on abbreviations, initials or decimals', () {
      final report = analyze(
        'Dr. Smith met J. R. Tolkien, e.g. at 3.5 pm. Then he left.',
      );
      expect(report.sentenceCount, 2);
    });

    test('"I." still ends a sentence', () {
      expect(analyze('So did I. Then we went home.').sentenceCount, 2);
    });

    test('skips code, front matter, headings, tables and URLs', () {
      const text = '''---
title: Lots of words in the front matter that should not count at all
---

# A heading with several words in it

```dart
final thisIsCode = 'and should not count either';
```

| a table | with words |
|---|---|

Real prose with `inline code` and https://example.com/a/long/url here.
''';
      final report = analyze(text);
      // Only the last line is prose to check...
      expect(report.sentenceCount, 1);
      // ...but the word count, like the status bar's, includes the heading
      // (7 words) and the table (4) as well as the 5 prose words.
      expect(report.wordCount, 16);
    });

    test('the word count matches the status bar counter', () {
      const text = '# Heading\n\nDon\'t split UTF-8 or [links](https://x.y).';
      expect(ReadabilityService.countWords(text), 6);
      expect(analyze(text).wordCount, ReadabilityService.countWords(text));
    });

    test('drops GitHub alert markers', () {
      final report = analyze('> [!NOTE]\n> Keep this short.');
      expect(report.wordCount, 3);
    });

    test('keeps link text but drops the target', () {
      final report = analyze('Read [the guide](https://example.com/x) now.');
      expect(report.wordCount, 4);
    });

    test('each list item is its own paragraph', () {
      final settings = const ReadabilitySettings().withValue(
        ReadabilityThreshold.paragraphMaxWords,
        20,
      );
      final report = analyze(
        '- ${words(15)}\n- ${words(15)}\n- ${words(15)}',
        settings,
      );
      expect(
        report.resultFor(ReadabilityCheck.paragraphLength)!.passed,
        isTrue,
      );
    });
  });

  group('sentence length', () {
    test('flags sentences over the word limit, with source offsets', () {
      final long = '${words(25)}.';
      final report = analyze('Short one. $long');
      expect(flagged(report, ReadabilityCheck.sentenceLength), [long]);

      final result = report.resultFor(ReadabilityCheck.sentenceLength)!;
      expect(result.count, 1);
      expect(result.total, 2);
      expect(result.percent, 50);
      expect(result.passed, isFalse);
    });

    test('passes when long sentences stay under the percentage', () {
      final text = '${'Short sentence here. ' * 9}${words(25)}.';
      final result = analyze(text).resultFor(ReadabilityCheck.sentenceLength)!;
      expect(result.count, 1);
      expect(result.passed, isTrue);
    });

    test('uses the configured limit', () {
      final settings = const ReadabilitySettings().withValue(
        ReadabilityThreshold.sentenceMaxWords,
        30,
      );
      final report = analyze('${words(25)}.', settings);
      expect(flagged(report, ReadabilityCheck.sentenceLength), isEmpty);
    });
  });

  group('paragraph and section length', () {
    test('flags long paragraphs and reports their line', () {
      final report = analyze('Intro.\n\n${words(160)}.');
      final result = report.resultFor(ReadabilityCheck.paragraphLength)!;
      expect(result.passed, isFalse);
      expect(result.lines, [3]);
    });

    test('flags long stretches without a heading', () {
      final para = '${words(100)}.';
      final text =
          '# One\n\n$para\n\n$para\n\n$para\n\n$para\n\n# Two\n\nShort.';
      final result = analyze(text)
          .resultFor(ReadabilityCheck.subheadingDistribution)!;
      expect(result.passed, isFalse);
      expect(result.lines, [3]);
    });
  });

  group('passive voice', () {
    test('finds be + participle, including irregular ones', () {
      final report = analyze(
        'The file was saved. The book was written by her. She wrote it.',
      );
      expect(flagged(report, ReadabilityCheck.passiveVoice), [
        'was saved',
        'was written',
      ]);
      final result = report.resultFor(ReadabilityCheck.passiveVoice)!;
      expect(result.count, 2);
      expect(result.total, 3);
    });

    test('allows adverbs in between', () {
      final report = analyze('It was quickly and quietly removed.');
      expect(flagged(report, ReadabilityCheck.passiveVoice), isEmpty);
      expect(
        flagged(
          analyze('It was quietly removed.'),
          ReadabilityCheck.passiveVoice,
        ),
        ['was quietly removed'],
      );
    });

    test('ignores common -ed words that are not participles', () {
      final report = analyze('That is indeed true. I was tired.');
      expect(flagged(report, ReadabilityCheck.passiveVoice), isEmpty);
    });
  });

  group('repeated sentence openings', () {
    test('flags a run of sentences starting with the same word', () {
      final report = analyze(
        'The cat sat. The dog ran. The bird flew. A fish.',
      );
      expect(flagged(report, ReadabilityCheck.consecutiveSentences), [
        'The',
        'The',
        'The',
      ]);
      expect(report.resultFor(ReadabilityCheck.consecutiveSentences)!.count, 1);
    });

    test('a shorter run than the limit is fine', () {
      final report = analyze('The cat sat. The dog ran. A bird flew.');
      expect(
        report.resultFor(ReadabilityCheck.consecutiveSentences)!.passed,
        isTrue,
      );
    });
  });

  group('transition words', () {
    test('counts sentences with transition words and phrases', () {
      final report = analyze(
        'We left. However, it rained. For example, the road flooded. '
        'It was cold.',
      );
      final result = report.resultFor(ReadabilityCheck.transitionWords)!;
      expect(result.count, 2);
      expect(result.total, 4);
      expect(result.passed, isTrue);
    });

    test('fails below the minimum', () {
      final report = analyze('We left. It rained. The road flooded.');
      expect(
        report.resultFor(ReadabilityCheck.transitionWords)!.passed,
        isFalse,
      );
    });
  });

  group('reading ease', () {
    test('simple text scores high, dense text scores low', () {
      final easy = analyze('The cat sat on the mat. It was a good day.');
      final hard = analyze(
        'Institutional considerations necessitate comprehensive '
        'organisational restructuring notwithstanding operational '
        'complexities.',
      );
      expect(
        easy.resultFor(ReadabilityCheck.readingEase)!.score,
        greaterThan(80),
      );
      expect(hard.resultFor(ReadabilityCheck.readingEase)!.score, lessThan(30));
      expect(hard.resultFor(ReadabilityCheck.readingEase)!.passed, isFalse);
    });

    test('syllable counts are close for common words', () {
      expect(ReadabilityService.countSyllables('cat'), 1);
      expect(ReadabilityService.countSyllables('make'), 1);
      expect(ReadabilityService.countSyllables('jumped'), 1);
      expect(ReadabilityService.countSyllables('wanted'), 2);
      expect(ReadabilityService.countSyllables('boxes'), 2);
      expect(ReadabilityService.countSyllables('table'), 2);
      expect(ReadabilityService.countSyllables('readability'), 5);
    });
  });

  test('disabled checks give no result and no issues', () {
    final settings = const ReadabilitySettings().withCheckEnabled(
      ReadabilityCheck.passiveVoice,
      false,
    );
    final report = analyze('The file was saved.', settings);
    expect(report.resultFor(ReadabilityCheck.passiveVoice), isNull);
    expect(flagged(report, ReadabilityCheck.passiveVoice), isEmpty);
  });
}
