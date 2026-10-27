import 'package:flutter_test/flutter_test.dart';
import 'package:hob_markdown_reader/models/document_model.dart';
import 'package:hob_markdown_reader/models/toc_item.dart';

void main() {
  group('DocumentModel Tests', () {
    test('formattedFileSize formats B, KB, and MB correctly', () {
      const docBytes = DocumentModel(
        fileName: 'test.md',
        content: 'content',
        byteSize: 500,
        headings: [],
        wordCount: 1,
        charCount: 7,
        lineCount: 1,
        readingTimeMinutes: 0.1,
      );
      expect(docBytes.formattedFileSize, '500 B');

      final docKb = docBytes.copyWith(byteSize: 1536);
      expect(docKb.formattedFileSize, '1.5 KB');

      final docMb = docBytes.copyWith(byteSize: 2 * 1024 * 1024 + 512 * 1024);
      expect(docMb.formattedFileSize, '2.50 MB');
    });

    test('formattedReadingTime formats seconds and minutes correctly', () {
      const docSec = DocumentModel(
        fileName: 'test.md',
        content: 'content',
        byteSize: 10,
        headings: [],
        wordCount: 10,
        charCount: 10,
        lineCount: 1,
        readingTimeMinutes: 0.5, // 30 seconds
      );
      expect(docSec.formattedReadingTime, '30 sec read');

      final docMin = docSec.copyWith(readingTimeMinutes: 1.0);
      expect(docMin.formattedReadingTime, '1 min read');

      final docMultiMin = docSec.copyWith(readingTimeMinutes: 3.2);
      expect(docMultiMin.formattedReadingTime, '4 min read');
    });

    test('copyWith preserves unchanged properties and updates specified properties', () {
      final now = DateTime.now();
      const heading = TocItem(level: 1, title: 'Title', lineNumber: 1, anchor: 'title');

      final original = DocumentModel(
        path: '/path/doc.md',
        fileName: 'doc.md',
        content: '# Title',
        byteSize: 7,
        headings: const [heading],
        wordCount: 1,
        charCount: 7,
        lineCount: 1,
        readingTimeMinutes: 0.05,
        lastModified: now,
      );

      final updated = original.copyWith(
        fileName: 'new_doc.md',
        wordCount: 5,
        content: '# Title\n\nMore words here.',
      );

      expect(updated.path, '/path/doc.md');
      expect(updated.fileName, 'new_doc.md');
      expect(updated.content, '# Title\n\nMore words here.');
      expect(updated.byteSize, 7);
      expect(updated.headings, [heading]);
      expect(updated.wordCount, 5);
      expect(updated.charCount, 7);
      expect(updated.lineCount, 1);
      expect(updated.readingTimeMinutes, 0.05);
      expect(updated.lastModified, now);
    });
  });

  group('TocItem Tests', () {
    test('equality and hashCode work properly', () {
      const item1 = TocItem(level: 2, title: 'Section', lineNumber: 15, anchor: 'section');
      const item2 = TocItem(level: 2, title: 'Section', lineNumber: 15, anchor: 'section-other');
      const item3 = TocItem(level: 3, title: 'Section', lineNumber: 15, anchor: 'section');

      // item1 and item2 have same level, title, lineNumber -> should be equal according to operator ==
      expect(item1, equals(item2));
      expect(item1.hashCode, equals(item2.hashCode));

      // item1 and item3 differ in level -> not equal
      expect(item1, isNot(equals(item3)));
    });

    test('toString returns readable format', () {
      const item = TocItem(level: 1, title: 'Heading One', lineNumber: 5, anchor: 'heading-one');
      expect(item.toString(), 'TocItem(H1: "Heading One" at L5)');
    });
  });
}
