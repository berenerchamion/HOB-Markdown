import 'dart:async';
import 'dart:io';
import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path/path.dart' as p;
import 'package:watcher/watcher.dart';

import '../models/document_model.dart';
import 'markdown_parser_service.dart';

class FileService {
  StreamSubscription<WatchEvent>? _watcherSubscription;
  Timer? _debounceTimer;
  String? _currentlyWatchedPath;

  /// Loads a Markdown document from the filesystem.
  Future<DocumentModel> loadFile(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw FileSystemException('File not found', filePath);
    }

    final bytes = await file.readAsBytes(); //protects against non UTF=8 files
    String content;
    try {
      content = utf8.decode(bytes);
    } on FormatException {
      content = latin1.decode(bytes); // legacy encodings; never throws
    }

    final stat = await file.stat();
    final fileName = p.basename(filePath);

    final headings = MarkdownParserService.extractHeadings(content);
    final wordCount = MarkdownParserService.countWords(content);
    final charCount = MarkdownParserService.countCharacters(content);
    final lineCount = MarkdownParserService.countLines(content);
    final readingTime = MarkdownParserService.calculateReadingTimeMinutes(
      wordCount,
    );

    return DocumentModel(
      path: filePath,
      fileName: fileName,
      content: content,
      byteSize: stat.size,
      headings: headings,
      wordCount: wordCount,
      charCount: charCount,
      lineCount: lineCount,
      readingTimeMinutes: readingTime,
      lastModified: stat.modified,
    );
  }

  /// Saves content to a file on disk and returns updated DocumentModel.
  Future<DocumentModel> saveFile(String filePath, String content) async {
    final file = File(filePath);
    await file.writeAsString(content);
    final stat = await file.stat();
    final fileName = p.basename(filePath);

    final headings = MarkdownParserService.extractHeadings(content);
    final wordCount = MarkdownParserService.countWords(content);
    final charCount = MarkdownParserService.countCharacters(content);
    final lineCount = MarkdownParserService.countLines(content);
    final readingTime = MarkdownParserService.calculateReadingTimeMinutes(
      wordCount,
    );

    return DocumentModel(
      path: filePath,
      fileName: fileName,
      content: content,
      byteSize: stat.size,
      headings: headings,
      wordCount: wordCount,
      charCount: charCount,
      lineCount: lineCount,
      readingTimeMinutes: readingTime,
      lastModified: stat.modified,
    );
  }

  /// Builds an updated DocumentModel by reading a file's current stats,
  /// without writing to it. Use when the content was already written
  /// elsewhere (e.g. by the save-file picker itself).
  Future<DocumentModel> buildDocumentModelFromDisk(
    String filePath,
    String content,
  ) async {
    final file = File(filePath);
    final stat = await file.stat();
    final fileName = p.basename(filePath);

    final headings = MarkdownParserService.extractHeadings(content);
    final wordCount = MarkdownParserService.countWords(content);
    final charCount = MarkdownParserService.countCharacters(content);
    final lineCount = MarkdownParserService.countLines(content);
    final readingTime = MarkdownParserService.calculateReadingTimeMinutes(
      wordCount,
    );

    return DocumentModel(
      path: filePath,
      fileName: fileName,
      content: content,
      byteSize: stat.size,
      headings: headings,
      wordCount: wordCount,
      charCount: charCount,
      lineCount: lineCount,
      readingTimeMinutes: readingTime,
      lastModified: stat.modified,
    );
  }

  /// Prompts user to pick a save location for a new file.
  Future<String?> pickSavePath({
    String suggestedName = 'document.md',
    required String content,
  }) async {
    final uri = await FilePicker.saveFile(
      dialogTitle: 'Save Markdown File',
      fileName: suggestedName,
      bytes: Uint8List.fromList(utf8.encode(content)),
    );
    return uri?.toFilePath();
  }

  /// Opens the native OS file picker to select a markdown file.
  Future<String?> pickMarkdownFile() async {
    final file = await FilePicker.pickFile(
      allowedExtensions: ['md', 'markdown', 'mdown', 'mkd', 'txt', 'text'],
    );
    return file?.path;
  }

  /// Watches a file for changes with debouncing to support auto-reload.
  void startWatchingFile(String filePath, VoidCallback onFileChanged) {
    if (_currentlyWatchedPath == filePath) return;
    stopWatchingFile();

    _currentlyWatchedPath = filePath;

    try {
      final watcher = FileWatcher(filePath);
      _watcherSubscription = watcher.events.listen(
        (event) {
          if (event.type == ChangeType.MODIFY || event.type == ChangeType.ADD) {
            _debounceTimer?.cancel();
            _debounceTimer = Timer(const Duration(milliseconds: 300), () {
              onFileChanged();
            });
          }
        },
        onError: (e) {
          debugPrint('File watcher error: $e');
        },
      );
    } catch (e) {
      debugPrint('Failed to watch file $filePath: $e');
    }
  }

  /// Stops watching the currently watched file.
  void stopWatchingFile() {
    _debounceTimer?.cancel();
    _debounceTimer = null;
    _watcherSubscription?.cancel();
    _watcherSubscription = null;
    _currentlyWatchedPath = null;
  }

  /// Path to the bundled welcome guide asset.
  static const String welcomeGuideAssetPath = 'assets/welcome_guide.md';

  /// Welcome guide text, filled once at startup by [preloadWelcomeGuide].
  static String? _welcomeGuideCache;

  /// Loads the welcome guide from the asset bundle. Call once before runApp()
  /// so the synchronous [getSampleDocument] has the real text available.
  static Future<void> preloadWelcomeGuide() async {
    try {
      _welcomeGuideCache = await rootBundle.loadString(welcomeGuideAssetPath);
    } catch (e) {
      debugPrint('Welcome guide asset failed to load, using built-in text: $e');
    }
  }

  /// Builds a [DocumentModel] from raw markdown content.
  DocumentModel buildDocumentFromContent({
    required String content,
    String fileName = 'Welcome Guide.md',
    String? path,
  }) {
    final headings = MarkdownParserService.extractHeadings(content);
    final wordCount = MarkdownParserService.countWords(content);
    final charCount = MarkdownParserService.countCharacters(content);
    final lineCount = MarkdownParserService.countLines(content);
    final readingTime = MarkdownParserService.calculateReadingTimeMinutes(
      wordCount,
    );

    return DocumentModel(
      path: path,
      fileName: fileName,
      content: content,
      byteSize: content.length,
      headings: headings,
      wordCount: wordCount,
      charCount: charCount,
      lineCount: lineCount,
      readingTimeMinutes: readingTime,
      lastModified: DateTime.now(),
    );
  }

  /// Returns the welcome guide text (cached, with a built-in fallback).
  Future<String> loadWelcomeGuideContent() async {
    if (_welcomeGuideCache == null) await preloadWelcomeGuide();
    return _welcomeGuideCache ?? _fallbackSampleContent;
  }

  /// Returns the built-in welcome / sample markdown document synchronously.
  DocumentModel getSampleDocument() {
    return buildDocumentFromContent(
      content: _welcomeGuideCache ?? _fallbackSampleContent,
    );
  }

  /// Asynchronously loads the sample document from the asset bundle.
  Future<DocumentModel> loadSampleDocument() async {
    final content = await loadWelcomeGuideContent();
    return buildDocumentFromContent(content: content);
  }

  static const String _fallbackSampleContent = '''# House of Beor Markdown

Welcome! The built-in guide couldn't be loaded, but the app is working.

Press **⌘ + O** or drag a `.md` file into this window to open a document.
''';

  void dispose() {
    stopWatchingFile();
  }
}
