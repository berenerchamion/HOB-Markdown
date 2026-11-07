import '../models/readability_settings.dart';

/// One place in the document that a check flagged, as character offsets into
/// the markdown source. Offsets point at the source, not at rendered text, so
/// the editor can highlight them directly.
class ReadabilityIssue {
  final ReadabilityCheck check;
  final int start;
  final int end;

  const ReadabilityIssue(this.check, this.start, this.end);

  @override
  bool operator ==(Object other) =>
      other is ReadabilityIssue &&
      other.check == check &&
      other.start == start &&
      other.end == end;

  @override
  int get hashCode => Object.hash(check, start, end);

  @override
  String toString() => 'ReadabilityIssue(${check.name}, $start-$end)';
}

/// The outcome of one check. Only numbers: the UI turns them into words.
class ReadabilityResult {
  final ReadabilityCheck check;
  final bool passed;

  /// How many things were flagged (sentences, paragraphs, sections or runs).
  final int count;

  /// What [count] is out of, for checks reported as a percentage.
  final int total;

  /// The Flesch score, for [ReadabilityCheck.readingEase] only.
  final double? score;

  /// 1-based line numbers of flagged paragraphs or sections.
  final List<int> lines;

  const ReadabilityResult({
    required this.check,
    required this.passed,
    this.count = 0,
    this.total = 0,
    this.score,
    this.lines = const [],
  });

  int get percent => total == 0 ? 0 : (count * 100 / total).round();
}

class ReadabilityReport {
  /// The exact text that was analysed. Issue offsets are only valid for it.
  final String source;

  /// Every word a reader sees, headings and tables included. Matches the
  /// status bar, so it can be more than the words in [sentenceCount]'s
  /// sentences.
  final int wordCount;
  final int sentenceCount;
  final List<ReadabilityResult> results;
  final List<ReadabilityIssue> issues;

  const ReadabilityReport({
    required this.source,
    required this.wordCount,
    required this.sentenceCount,
    required this.results,
    required this.issues,
  });

  ReadabilityResult? resultFor(ReadabilityCheck check) {
    for (final r in results) {
      if (r.check == check) return r;
    }
    return null;
  }
}

/// Readability checks modelled on Yoast and Hemingway, for English prose.
///
/// Pure Dart with no Flutter imports, so it is quick to test and could run in
/// an isolate later if documents get big enough to need it. Everything is
/// heuristic: there's no dictionary or grammar parser, so expect the odd
/// false positive, which is why highlighting is opt-in.
class ReadabilityService {
  const ReadabilityService._();

  static ReadabilityReport analyze(
    String source,
    ReadabilitySettings settings,
  ) {
    final mask = _mask(source);
    final doc = _group(mask.masked, mask.kinds, mask.lines);
    final results = <ReadabilityResult>[];
    final issues = <ReadabilityIssue>[];
    final sentences = [for (final p in doc.paragraphs) ...p.sentences];
    final total = sentences.length;

    int lineOf(int offset) {
      var line = 1;
      for (var i = 0; i < offset && i < source.length; i++) {
        if (source.codeUnitAt(i) == 0x0A) line++;
      }
      return line;
    }

    bool on(ReadabilityCheck c) => settings.isEnabled(c);

    if (on(ReadabilityCheck.sentenceLength)) {
      final max = settings.valueOf(ReadabilityThreshold.sentenceMaxWords);
      final limit = settings.valueOf(
        ReadabilityThreshold.longSentenceMaxPercent,
      );
      var long = 0;
      for (final s in sentences) {
        if (s.words.length > max) {
          long++;
          issues.add(
            ReadabilityIssue(ReadabilityCheck.sentenceLength, s.start, s.end),
          );
        }
      }
      results.add(
        ReadabilityResult(
          check: ReadabilityCheck.sentenceLength,
          passed: total == 0 || long * 100 <= limit * total,
          count: long,
          total: total,
        ),
      );
    }

    if (on(ReadabilityCheck.paragraphLength)) {
      final max = settings.valueOf(ReadabilityThreshold.paragraphMaxWords);
      final lines = <int>[];
      for (final p in doc.paragraphs) {
        if (p.wordCount > max) {
          lines.add(lineOf(p.start));
          issues.add(
            ReadabilityIssue(ReadabilityCheck.paragraphLength, p.start, p.end),
          );
        }
      }
      results.add(
        ReadabilityResult(
          check: ReadabilityCheck.paragraphLength,
          passed: lines.isEmpty,
          count: lines.length,
          total: doc.paragraphs.length,
          lines: lines,
        ),
      );
    }

    if (on(ReadabilityCheck.subheadingDistribution)) {
      final max = settings.valueOf(ReadabilityThreshold.sectionMaxWords);
      final lines = <int>[];
      for (final section in doc.sections) {
        if (section.isEmpty) continue;
        final words = section.fold<int>(0, (n, p) => n + p.wordCount);
        if (words > max) {
          lines.add(lineOf(section.first.start));
          issues.add(
            ReadabilityIssue(
              ReadabilityCheck.subheadingDistribution,
              section.first.start,
              section.last.end,
            ),
          );
        }
      }
      results.add(
        ReadabilityResult(
          check: ReadabilityCheck.subheadingDistribution,
          passed: lines.isEmpty,
          count: lines.length,
          total: doc.sections.where((s) => s.isNotEmpty).length,
          lines: lines,
        ),
      );
    }

    if (on(ReadabilityCheck.passiveVoice)) {
      final limit = settings.valueOf(ReadabilityThreshold.passiveMaxPercent);
      var passive = 0;
      for (final s in sentences) {
        final found = _findPassive(s.words);
        if (found.isNotEmpty) passive++;
        for (final (start, end) in found) {
          issues.add(
            ReadabilityIssue(ReadabilityCheck.passiveVoice, start, end),
          );
        }
      }
      results.add(
        ReadabilityResult(
          check: ReadabilityCheck.passiveVoice,
          passed: total == 0 || passive * 100 <= limit * total,
          count: passive,
          total: total,
        ),
      );
    }

    if (on(ReadabilityCheck.consecutiveSentences)) {
      final run = settings.valueOf(ReadabilityThreshold.consecutiveMaxRun);
      var runs = 0;
      var flagged = 0;
      for (final p in doc.paragraphs) {
        final ss = p.sentences;
        var i = 0;
        while (i < ss.length) {
          final first = ss[i].firstWord;
          var j = i + 1;
          while (first != null && j < ss.length && ss[j].firstWord == first) {
            j++;
          }
          if (first != null && j - i >= run) {
            runs++;
            for (var k = i; k < j; k++) {
              flagged++;
              final w = ss[k].words.first;
              issues.add(
                ReadabilityIssue(
                  ReadabilityCheck.consecutiveSentences,
                  w.start,
                  w.end,
                ),
              );
            }
          }
          i = j;
        }
      }
      results.add(
        ReadabilityResult(
          check: ReadabilityCheck.consecutiveSentences,
          passed: runs == 0,
          count: runs,
          total: flagged,
        ),
      );
    }

    if (on(ReadabilityCheck.transitionWords)) {
      final limit = settings.valueOf(ReadabilityThreshold.transitionMinPercent);
      var withTransition = 0;
      for (final s in sentences) {
        if (_hasTransition(s.words)) withTransition++;
      }
      results.add(
        ReadabilityResult(
          check: ReadabilityCheck.transitionWords,
          passed: total == 0 || withTransition * 100 >= limit * total,
          count: withTransition,
          total: total,
        ),
      );
    }

    if (on(ReadabilityCheck.readingEase)) {
      final limit = settings.valueOf(ReadabilityThreshold.readingEaseMinScore);
      final words = [for (final s in sentences) ...s.words];
      double? score;
      if (words.isNotEmpty) {
        final syllables = words.fold<int>(
          0,
          (n, w) => n + countSyllables(w.lower),
        );
        score =
            (206.835 -
                    1.015 * (words.length / total) -
                    84.6 * (syllables / words.length))
                .clamp(0.0, 100.0);
      }
      results.add(
        ReadabilityResult(
          check: ReadabilityCheck.readingEase,
          passed: score == null || score >= limit,
          score: score,
        ),
      );
    }

    issues.sort((a, b) => a.start.compareTo(b.start));
    return ReadabilityReport(
      source: source,
      wordCount: _word.allMatches(mask.counted).length,
      sentenceCount: total,
      results: results,
      issues: issues,
    );
  }

  // ---------------------------------------------------------------------------
  // Parsing: markdown source -> paragraphs -> sentences -> words, keeping
  // every offset pointing into the original source.
  // ---------------------------------------------------------------------------

  static final RegExp _fence = RegExp(r'^\s{0,3}(```|~~~)');
  static final RegExp _heading = RegExp(r'^\s{0,3}#{1,6}(\s|$)');
  static final RegExp _rule = RegExp(r'^\s{0,3}([-*_])(\s*\1){2,}\s*$');
  static final RegExp _listMarker = RegExp(
    r'^(\s*(?:>\s*)*)([-*+]|\d{1,9}[.)])\s+(\[[ xX]\]\s+)?',
  );
  static final RegExp _quoteMarker = RegExp(r'^\s*(>\s?)+');
  static final RegExp _headingMarks = RegExp(r'^\s{0,3}#{1,6}|\s#+\s*$');
  static final RegExp _tableDivider = RegExp(r'^[\s|:\-]+$');

  // Inline markdown that isn't prose. Each match is blanked to spaces so the
  // offsets of everything around it don't move.
  static final List<RegExp> _inlineNoise = [
    RegExp(r'`[^`\n]*`'), // inline code
    RegExp(r'!\[[^\]\n]*\]\([^)\n]*\)'), // images
    RegExp(r'\]\([^)\n]*\)'), // link targets: keep the link text
    RegExp(r'\]\[[^\]\n]*\]'), // reference link labels
    RegExp(r'\[\^[^\]\n]*\]'), // footnote references
    RegExp(r'\[![A-Za-z]+\]'), // GitHub alerts such as [!NOTE]
    RegExp(r'<[^>\n]+>'), // inline HTML and autolinks
    RegExp(r'https?://\S+'), // bare URLs
    RegExp(r'[\[\]*_~]'), // emphasis and link brackets
  ];

  static final RegExp _word = RegExp(
    r"[\p{L}\p{N}]+(?:['’\-][\p{L}\p{N}]+)*",
    unicode: true,
  );

  /// Counts the words a reader would see: prose, headings, list items, quotes
  /// and table cells, plus link text. Code, front matter, URLs, HTML and
  /// markdown syntax don't count. The status bar uses this too, so its count
  /// always matches the review panel's.
  static int countWords(String source) =>
      _word.allMatches(_mask(source).counted).length;

  /// Blanks everything that isn't prose to spaces, keeping every offset.
  ///
  /// Returns two versions of the text: `masked` is the prose the checks read
  /// (no headings or tables, since those aren't sentences), and `counted`
  /// also keeps heading and table text, for the word count.
  static ({
    String masked,
    String counted,
    List<_LineKind> kinds,
    List<(int, int)> lines,
  })
  _mask(String source) {
    final masked = source.codeUnits.toList();
    final counted = source.codeUnits.toList();
    void blankIn(List<int> units, int from, int to) {
      for (var i = from; i < to; i++) {
        if (units[i] != 0x0A) units[i] = 0x20;
      }
    }

    void blank(int from, int to) {
      blankIn(masked, from, to);
      blankIn(counted, from, to);
    }

    void blankNoise(List<int> units, int start, int end) {
      final line = source.substring(start, end);
      for (final pattern in _inlineNoise) {
        for (final m in pattern.allMatches(line)) {
          blankIn(units, start + m.start, start + m.end);
        }
      }
    }

    // Line spans, as [start, end) offsets without the newline.
    final lines = <(int, int)>[];
    var lineStart = 0;
    for (var i = 0; i <= source.length; i++) {
      if (i == source.length || source.codeUnitAt(i) == 0x0A) {
        lines.add((lineStart, i));
        lineStart = i + 1;
      }
    }

    // Classify each line: prose, a list item that starts a new paragraph, a
    // heading, or something that isn't prose at all.
    final kinds = List<_LineKind>.filled(lines.length, _LineKind.blank);
    var inFence = false;
    String? fenceMarker;
    var inFrontMatter = lines.isNotEmpty && _text(source, lines[0]) == '---';
    for (var n = 0; n < lines.length; n++) {
      final (start, end) = lines[n];
      final text = source.substring(start, end);
      final trimmed = text.trim();

      if (inFrontMatter) {
        blank(start, end);
        kinds[n] = _LineKind.other;
        if (n > 0 && (trimmed == '---' || trimmed == '...')) {
          inFrontMatter = false;
        }
        continue;
      }

      final fence = _fence.firstMatch(text);
      if (inFence || fence != null) {
        blank(start, end);
        kinds[n] = _LineKind.other;
        if (!inFence) {
          inFence = true;
          fenceMarker = fence!.group(1);
        } else if (fence != null && fence.group(1) == fenceMarker) {
          inFence = false;
        }
        continue;
      }

      if (trimmed.isEmpty) {
        kinds[n] = _LineKind.blank;
      } else if (_heading.hasMatch(text)) {
        blankIn(masked, start, end);
        for (final m in _headingMarks.allMatches(text)) {
          blankIn(counted, start + m.start, start + m.end);
        }
        blankNoise(counted, start, end);
        kinds[n] = _LineKind.heading;
      } else if (trimmed.startsWith('|')) {
        blankIn(masked, start, end);
        if (_tableDivider.hasMatch(text)) {
          blankIn(counted, start, end);
        } else {
          for (var i = start; i < end; i++) {
            if (source.codeUnitAt(i) == 0x7C) counted[i] = 0x20; // |
          }
          blankNoise(counted, start, end);
        }
        kinds[n] = _LineKind.other;
      } else if (_rule.hasMatch(text) ||
          trimmed.startsWith('<') ||
          RegExp(r'^\s{0,3}\[[^\]]+\]:\s').hasMatch(text)) {
        // Rules, block HTML, and link reference definitions.
        blank(start, end);
        kinds[n] = _LineKind.other;
      } else {
        final list = _listMarker.firstMatch(text);
        if (list != null) {
          blank(start, start + list.end);
          kinds[n] = _LineKind.listItem;
        } else {
          final quote = _quoteMarker.firstMatch(text);
          if (quote != null) blank(start, start + quote.end);
          kinds[n] = _LineKind.prose;
        }
        blankNoise(masked, start, end);
        blankNoise(counted, start, end);
      }
    }

    return (
      masked: String.fromCharCodes(masked),
      counted: String.fromCharCodes(counted),
      kinds: kinds,
      lines: lines,
    );
  }

  /// Groups the masked lines into paragraphs and heading sections.
  static _ParsedDocument _group(
    String maskedText,
    List<_LineKind> kinds,
    List<(int, int)> lines,
  ) {
    // Group lines into paragraphs, and paragraphs into heading sections.
    final paragraphs = <_Paragraph>[];
    final sections = <List<_Paragraph>>[[]];
    int? paraStart;
    int paraEnd = 0;
    void closeParagraph() {
      if (paraStart != null) {
        final p = _Paragraph.build(maskedText, paraStart!, paraEnd);
        if (p.wordCount > 0) {
          paragraphs.add(p);
          sections.last.add(p);
        }
      }
      paraStart = null;
    }

    for (var n = 0; n < lines.length; n++) {
      final (start, end) = lines[n];
      switch (kinds[n]) {
        case _LineKind.blank:
        case _LineKind.other:
          closeParagraph();
        case _LineKind.heading:
          closeParagraph();
          sections.add([]);
        case _LineKind.listItem:
          closeParagraph();
          paraStart = start;
          paraEnd = end;
        case _LineKind.prose:
          paraStart ??= start;
          paraEnd = end;
      }
    }
    closeParagraph();

    return _ParsedDocument(paragraphs, sections);
  }

  static String _text(String source, (int, int) span) =>
      source.substring(span.$1, span.$2).trim();

  // ---------------------------------------------------------------------------
  // Passive voice: a form of "to be", up to two adverbs, then a past
  // participle. The same rough approach Yoast uses for English.
  // ---------------------------------------------------------------------------

  static const Set<String> _beForms = {
    'am', 'is', 'are', 'was', 'were', 'be', 'been', 'being', //
    "isn't", "aren't", "wasn't", "weren't", 'isn’t', 'aren’t', 'wasn’t',
    'weren’t',
  };

  static const Set<String> _inBetween = {
    'not',
    'never',
    'also',
    'always',
    'often',
    'just',
    'still',
    'already',
    'usually',
    'then',
    'being',
    'been',
  };

  static const Set<String> _notParticiples = {
    'need',
    'needed',
    'speed',
    'feed',
    'seed',
    'bleed',
    'breed',
    'proceed',
    'succeed',
    'exceed',
    'indeed',
    'red',
    'bed',
    'shed',
    'hundred',
    'naked',
    'wicked',
    'sacred',
    'kindred',
    'rugged',
    'ragged',
    'jagged',
    'beloved',
    'learned',
    'aged',
    'blessed',
    'crooked',
    'dogged',
    'wretched',
    'tired',
    'interested',
    'excited',
    'bored',
    'worried',
    'scared',
    'supposed',
    'used',
  };

  static const Set<String> _irregularParticiples = {
    'arisen',
    'awoken',
    'beaten',
    'begun',
    'bent',
    'bitten',
    'bled',
    'blown',
    'broken',
    'bred',
    'brought',
    'built',
    'burnt',
    'bought',
    'caught',
    'chosen',
    'dealt',
    'done',
    'drawn',
    'driven',
    'eaten',
    'fallen',
    'fed',
    'felt',
    'fought',
    'found',
    'fled',
    'flown',
    'forbidden',
    'forgotten',
    'forgiven',
    'frozen',
    'given',
    'ground',
    'grown',
    'hung',
    'heard',
    'hidden',
    'held',
    'hurt',
    'kept',
    'known',
    'laid',
    'led',
    'lent',
    'lost',
    'made',
    'meant',
    'met',
    'paid',
    'said',
    'seen',
    'sought',
    'sold',
    'sent',
    'shaken',
    'shot',
    'shown',
    'shut',
    'sung',
    'sunk',
    'slain',
    'spoken',
    'spent',
    'spun',
    'spread',
    'stolen',
    'stuck',
    'stung',
    'struck',
    'sworn',
    'swept',
    'taken',
    'taught',
    'torn',
    'told',
    'thought',
    'thrown',
    'understood',
    'woken',
    'worn',
    'woven',
    'won',
    'withdrawn',
    'written',
  };

  static bool _isParticiple(String w) {
    if (_notParticiples.contains(w)) return false;
    if (_irregularParticiples.contains(w)) return true;
    return w.length > 4 && w.endsWith('ed');
  }

  static List<(int, int)> _findPassive(List<_Word> words) {
    final found = <(int, int)>[];
    for (var i = 0; i < words.length; i++) {
      if (!_beForms.contains(words[i].lower)) continue;
      for (var j = i + 1; j < words.length && j <= i + 3; j++) {
        final w = words[j].lower;
        if (_isParticiple(w)) {
          found.add((words[i].start, words[j].end));
          i = j;
          break;
        }
        if (!(_inBetween.contains(w) || w.endsWith('ly'))) break;
      }
    }
    return found;
  }

  // ---------------------------------------------------------------------------
  // Transition words.
  // ---------------------------------------------------------------------------

  static const Set<String> _transitionWords = {
    'accordingly',
    'additionally',
    'afterward',
    'afterwards',
    'also',
    'although',
    'because',
    'besides',
    'consequently',
    'conversely',
    'eventually',
    'finally',
    'firstly',
    'secondly',
    'thirdly',
    'furthermore',
    'hence',
    'however',
    'indeed',
    'instead',
    'lastly',
    'likewise',
    'meanwhile',
    'moreover',
    'nevertheless',
    'nonetheless',
    'notably',
    'otherwise',
    'overall',
    'similarly',
    'specifically',
    'subsequently',
    'therefore',
    'thus',
    'though',
    'ultimately',
    'unless',
    'whereas',
    'while',
    'yet',
    'but',
    'so',
    'then',
    'next',
    'first',
    'second',
    'since',
  };

  static const List<List<String>> _transitionPhrases = [
    ['as', 'a', 'result'],
    ['for', 'example'],
    ['for', 'instance'],
    ['in', 'addition'],
    ['in', 'contrast'],
    ['in', 'fact'],
    ['in', 'other', 'words'],
    ['in', 'conclusion'],
    ['in', 'short'],
    ['in', 'particular'],
    ['on', 'the', 'other', 'hand'],
    ['even', 'though'],
    ['to', 'sum', 'up'],
    ['after', 'all'],
    ['at', 'the', 'same', 'time'],
    ['because', 'of'],
    ['due', 'to'],
    ['such', 'as'],
    ['so', 'that'],
    ['as', 'long', 'as'],
    ['first', 'of', 'all'],
    ['above', 'all'],
    ['of', 'course'],
  ];

  static bool _hasTransition(List<_Word> words) {
    for (var i = 0; i < words.length; i++) {
      if (_transitionWords.contains(words[i].lower)) return true;
      for (final phrase in _transitionPhrases) {
        if (i + phrase.length > words.length) continue;
        var match = true;
        for (var k = 0; k < phrase.length; k++) {
          if (words[i + k].lower != phrase[k]) {
            match = false;
            break;
          }
        }
        if (match) return true;
      }
    }
    return false;
  }

  // ---------------------------------------------------------------------------
  // Syllables, for the Flesch score. A heuristic: count vowel groups, then
  // allow for a silent final "e" and "-ed"/"-es" endings.
  // ---------------------------------------------------------------------------

  static final RegExp _vowelGroups = RegExp(r'[aeiouy]+');

  static int countSyllables(String word) {
    var w = word.toLowerCase().replaceAll(RegExp(r'[^a-z]'), '');
    if (w.isEmpty) return 1;
    if (w.length <= 3) return 1;
    if (w.endsWith('es') || w.endsWith('ed')) {
      // "boxes" and "wanted" keep the syllable; "makes" and "jumped" don't.
      final keep =
          RegExp(r'(ss|x|z|ch|sh|ce|ge|se|t|d)(es|ed)$').hasMatch(w) &&
          !(w.endsWith('ed') && RegExp(r'[^td]ed$').hasMatch(w));
      if (!keep) w = w.substring(0, w.length - 2);
    } else if (w.endsWith('e') && !w.endsWith('le')) {
      w = w.substring(0, w.length - 1);
    }
    final count = _vowelGroups.allMatches(w).length;
    return count < 1 ? 1 : count;
  }
}

enum _LineKind { blank, prose, listItem, heading, other }

class _ParsedDocument {
  final List<_Paragraph> paragraphs;
  final List<List<_Paragraph>> sections;

  _ParsedDocument(this.paragraphs, this.sections);
}

class _Word {
  final int start;
  final int end;
  final String lower;

  _Word(this.start, this.end, this.lower);
}

class _Sentence {
  final int start;
  final int end;
  final List<_Word> words;

  _Sentence(this.start, this.end, this.words);

  String? get firstWord => words.isEmpty ? null : words.first.lower;
}

class _Paragraph {
  final int start;
  final int end;
  final List<_Sentence> sentences;

  _Paragraph(this.start, this.end, this.sentences);

  int get wordCount => sentences.fold(0, (n, s) => n + s.words.length);

  static const Set<String> _abbreviations = {
    'mr',
    'mrs',
    'ms',
    'dr',
    'prof',
    'sr',
    'jr',
    'st',
    'vs',
    'etc',
    'eg',
    'ie',
    'inc',
    'ltd',
    'co',
    'no',
    'fig',
    'approx',
    'dept',
    'e.g',
    'i.e',
  };

  /// The run of non-space text just before [at], lowercased, so "e.g" and
  /// "i.e" are seen whole.
  static String _tokenBefore(String masked, int at) {
    var k = at;
    while (k > 0 && masked[k - 1] != ' ' && masked[k - 1] != '\n') {
      k--;
    }
    return masked
        .substring(k, at)
        .toLowerCase()
        .replaceAll(RegExp('^[("“‘\']+'), '');
  }

  /// A single capital letter, as in "J. R. R. Tolkien". "I" is left out
  /// because "So did I." really does end a sentence.
  static bool _isInitial(String masked, _Word word) {
    if (word.end - word.start != 1) return false;
    final c = masked[word.start];
    return c != 'I' && c.toUpperCase() == c && c.toLowerCase() != c;
  }

  /// Splits the masked text of one paragraph into sentences.
  static _Paragraph build(String masked, int start, int end) {
    final words = <_Word>[
      for (final m in ReadabilityService._word.allMatches(
        masked.substring(start, end),
      ))
        _Word(start + m.start, start + m.end, m[0]!.toLowerCase()),
    ];

    final sentences = <_Sentence>[];
    var sentenceWords = <_Word>[];
    var wordIndex = 0;
    var sentenceStart = -1;

    void finish(int at) {
      if (sentenceWords.isNotEmpty) {
        sentences.add(_Sentence(sentenceStart, at, sentenceWords));
      }
      sentenceWords = <_Word>[];
      sentenceStart = -1;
    }

    var i = start;
    while (i < end) {
      // Pick up every word that starts here.
      while (wordIndex < words.length && words[wordIndex].start == i) {
        if (sentenceStart < 0) sentenceStart = i;
        sentenceWords.add(words[wordIndex]);
        i = words[wordIndex].end;
        wordIndex++;
      }
      if (i >= end) break;

      final c = masked[i];
      if (c == '.' || c == '!' || c == '?' || c == '…') {
        var j = i + 1;
        while (j < end && '.!?…"\'”’)'.contains(masked[j])) {
          j++;
        }
        final atBoundary = j >= end || masked[j] == ' ' || masked[j] == '\n';
        final previous = sentenceWords.isEmpty ? null : sentenceWords.last;
        final isAbbreviation =
            c == '.' &&
            previous != null &&
            previous.end == i &&
            (_abbreviations.contains(_tokenBefore(masked, i)) ||
                _isInitial(masked, previous));
        if (atBoundary && !isAbbreviation && sentenceWords.isNotEmpty) {
          finish(j);
        }
        i = j;
      } else {
        i++;
      }
    }
    if (sentenceWords.isNotEmpty) {
      finish(sentenceWords.last.end);
    }

    return _Paragraph(
      sentences.isEmpty ? start : sentences.first.start,
      sentences.isEmpty ? end : sentences.last.end,
      sentences,
    );
  }
}
