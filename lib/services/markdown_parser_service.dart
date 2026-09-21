import '../models/toc_item.dart';

class MarkdownParserService {
  /// Extracts headings (H1-H6) from markdown content while ignoring code blocks.
  static List<TocItem> extractHeadings(String markdown) {
    final List<TocItem> items = [];
    final lines = markdown.split('\n');
    bool inCodeBlock = false;

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      final trimmed = line.trim();

      // Track fenced code blocks
      if (trimmed.startsWith('```') || trimmed.startsWith('~~~')) {
        inCodeBlock = !inCodeBlock;
        continue;
      }

      if (inCodeBlock) continue;

      // ATX Headings: # H1, ## H2, etc.
      final atxMatch = RegExp(r'^(#{1,6})\s+(.+)$').firstMatch(trimmed);
      if (atxMatch != null) {
        final level = atxMatch.group(1)!.length;
        var rawTitle = atxMatch.group(2)!.trim();
        // Remove trailing #'s if any (e.g. ## Title ##)
        rawTitle = rawTitle.replaceAll(RegExp(r'\s+#+$'), '');
        // Clean markdown formatting inside title (links, bold, etc.)
        final cleanTitle = _cleanMarkdownInline(rawTitle);

        items.add(TocItem(
          level: level,
          title: cleanTitle,
          lineNumber: i + 1,
          anchor: _slugify(cleanTitle),
        ));
        continue;
      }

      // Setext Headings: Underlined with === (H1) or --- (H2)
      if (i > 0 && lines[i - 1].trim().isNotEmpty) {
        final prevLine = lines[i - 1].trim();
        if (RegExp(r'^={2,}\s*$').hasMatch(trimmed)) {
          final cleanTitle = _cleanMarkdownInline(prevLine);
          items.add(TocItem(
            level: 1,
            title: cleanTitle,
            lineNumber: i,
            anchor: _slugify(cleanTitle),
          ));
        } else if (RegExp(r'^-{2,}\s*$').hasMatch(trimmed)) {
          final cleanTitle = _cleanMarkdownInline(prevLine);
          items.add(TocItem(
            level: 2,
            title: cleanTitle,
            lineNumber: i,
            anchor: _slugify(cleanTitle),
          ));
        }
      }
    }

    return items;
  }

  /// Calculates word count in the markdown content.
  static int countWords(String content) {
    if (content.trim().isEmpty) return 0;
    // Remove code blocks and markdown symbols for more accurate word counting
    final cleaned = content
        .replaceAll(RegExp(r'```[\s\S]*?```'), '')
        .replaceAll(RegExp(r'#+\s'), '')
        .replaceAll(RegExp(r'[*_~`\[\]()]'), ' ');
    final matches = RegExp(r'\b\w+\b').allMatches(cleaned);
    return matches.length;
  }

  /// Calculates character count (excluding extra whitespace).
  static int countCharacters(String content) {
    return content.length;
  }

  /// Calculates number of lines.
  static int countLines(String content) {
    if (content.isEmpty) return 0;
    return content.split('\n').length;
  }

  /// Estimated reading time (average 200 words per minute).
  static double calculateReadingTimeMinutes(int wordCount) {
    return wordCount / 200.0;
  }

  static String _cleanMarkdownInline(String text) {
    return text
        .replaceAll(RegExp(r'\[(.*?)\]\(.*?\)'), r'$1') // [text](url) -> text
        .replaceAll(RegExp(r'[*_~`^]'), '') // bold, italic, code
        .replaceAll(RegExp(r'<[^>]*>'), '') // html tags
        .trim();
  }

  static String _slugify(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\s-]'), '')
        .replaceAll(RegExp(r'\s+'), '-')
        .trim();
  }
}
