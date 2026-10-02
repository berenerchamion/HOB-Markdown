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

    final content = await file.readAsString();
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
      type: FileType.custom,
      allowedExtensions: ['md', 'markdown', 'txt'],
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

  /// Loads the welcome guide markdown text from asset or disk fallback.
  Future<String> loadWelcomeGuideContent() async {
    try {
      return await rootBundle.loadString(welcomeGuideAssetPath);
    } catch (_) {
      try {
        final file = File(welcomeGuideAssetPath);
        if (await file.exists()) {
          return await file.readAsString();
        }
      } catch (_) {}
      return _fallbackSampleContent;
    }
  }

  /// Returns the built-in welcome / sample markdown document synchronously.
  DocumentModel getSampleDocument() {
    String sampleContent = _fallbackSampleContent;
    try {
      final file = File(welcomeGuideAssetPath);
      if (file.existsSync()) {
        sampleContent = file.readAsStringSync();
      }
    } catch (_) {}

    return buildDocumentFromContent(content: sampleContent);
  }

  /// Asynchronously loads the sample document from the asset bundle.
  Future<DocumentModel> loadSampleDocument() async {
    final content = await loadWelcomeGuideContent();
    return buildDocumentFromContent(content: content);
  }

  static const String _fallbackSampleContent = '''# ✨ House of Beor Markdown

Welcome to modern and lightweight macOS **House of Beor Markdown** designed with **Material Design 3 (Material You)** aesthetics!

This application is built with Google's Flutter SDK for cross-platform portability. It is optimized for Apple's macOS.

> [!TIP]
> **Drag and drop** any `.md` or `.markdown` file directly into this window from Finder to open it immediately, or press **⌘ + O** to browse your files.

---

## 🚀 Key Features

* **macOS Drag & Drop**: Drop markdown files anywhere on the app.
* **Material Design 3**: Modern color tokens, tonal elevation, and smooth typography.
* **Auto-Reload**: Automatically detects and reloads when your file is saved in external editors (VS Code, Obsidian, etc.).
* **Table of Contents (TOC)**: Collapsible sidebar with heading hierarchy and smooth scroll navigation.
* **Multi-View Modes**: Switch between **Rendered View**, **Split View**, and **Raw Source**.
* **Rich Code Highlighting**: Syntax-highlighted code blocks with 1-click copy action.
* **In-Document Search**: Press **⌘ + F** to find text.
* **Full Keyboard Shortcuts**: macOS command shortcuts for seamless workflow.

---

## ⌨️ macOS Keyboard Shortcuts

| Shortcut | Action |
| :--- | :--- |
| **⌘ + O** | Open file dialog |
| **⌘ + R** | Reload current file |
| **⌘ + B** | Toggle Table of Contents sidebar |
| **⌘ + T** | Toggle Light / Dark theme |
| **⌘ + F** | Search within document |
| **⌘ + =** | Zoom In (increase font scale) |
| **⌘ + -** | Zoom Out (decrease font scale) |
| **⌘ + 0** | Reset zoom to 100% |
| **⌘ + 1** | Switch to Rendered View |
| **⌘ + 2** | Switch to Split View |
| **⌘ + 3** | Switch to Raw Source View |

---

## 💻 Syntax Highlighting Examples

### Dart / Flutter
```dart
import 'package:flutter/material.dart';

void main() {
  runApp(const MaterialApp(
    title: 'MD Reader',
    home: Scaffold(
      body: Center(child: Text('Hello Material 3!')),
    ),
  ));
}
```

### TypeScript / React
```typescript
interface DocumentProps {
  title: string;
  wordCount: number;
  isFavorite?: boolean;
}

export const DocumentCard: React.FC<DocumentProps> = ({ title, wordCount }) => {
  return (
    <div className="p-4 rounded-xl bg-surface-container shadow-sm">
      <h3 className="font-bold text-lg">{title}</h3>
      <p className="text-sm text-slate-500">{wordCount} words</p>
    </div>
  );
};
```

### Python
```python
def calculate_read_time(word_count: int, wpm: int = 200) -> str:
    minutes = word_count / wpm
    if minutes < 1:
        return f"{round(minutes * 60)} sec read"
    return f"{round(minutes)} min read"
```

---

## 📊 Document Stats & Callouts

> [!NOTE]
> Material 3 uses subtle surface containers and high-contrast accents to make reading effortless and pleasing in both light and dark environments.

### Task Checklist
- [x] macOS native drag-and-drop support
- [x] Material Design 3 typography & theme tokens
- [x] Auto-reload file watcher
- [x] Split view & source view
- [x] Interactive Table of Contents sidebar

---

*Enjoy reading and editing your Markdown files!*
''';

  void dispose() {
    stopWatchingFile();
  }
}
