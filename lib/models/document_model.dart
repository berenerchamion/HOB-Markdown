import 'toc_item.dart';

class DocumentModel {
  final String? path;
  final String fileName;
  final String content;
  final int byteSize;
  final List<TocItem> headings;
  final int wordCount;
  final int charCount;
  final int lineCount;
  final double readingTimeMinutes;
  final DateTime? lastModified;

  const DocumentModel({
    this.path,
    required this.fileName,
    required this.content,
    required this.byteSize,
    required this.headings,
    required this.wordCount,
    required this.charCount,
    required this.lineCount,
    required this.readingTimeMinutes,
    this.lastModified,
  });

  String get formattedFileSize {
    if (byteSize < 1024) return '$byteSize B';
    if (byteSize < 1024 * 1024) return '${(byteSize / 1024).toStringAsFixed(1)} KB';
    return '${(byteSize / (1024 * 1024)).toStringAsFixed(2)} MB';
  }

  String get formattedReadingTime {
    if (readingTimeMinutes < 1) {
      final seconds = (readingTimeMinutes * 60).round();
      return '$seconds sec read';
    }
    return '${readingTimeMinutes.ceil()} min read';
  }

  DocumentModel copyWith({
    String? path,
    String? fileName,
    String? content,
    int? byteSize,
    List<TocItem>? headings,
    int? wordCount,
    int? charCount,
    int? lineCount,
    double? readingTimeMinutes,
    DateTime? lastModified,
  }) {
    return DocumentModel(
      path: path ?? this.path,
      fileName: fileName ?? this.fileName,
      content: content ?? this.content,
      byteSize: byteSize ?? this.byteSize,
      headings: headings ?? this.headings,
      wordCount: wordCount ?? this.wordCount,
      charCount: charCount ?? this.charCount,
      lineCount: lineCount ?? this.lineCount,
      readingTimeMinutes: readingTimeMinutes ?? this.readingTimeMinutes,
      lastModified: lastModified ?? this.lastModified,
    );
  }
}
