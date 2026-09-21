import 'package:flutter/material.dart';
import '../models/document_model.dart';
import '../services/file_service.dart';
import '../services/markdown_parser_service.dart';

enum ViewMode {
  rendered,
  split,
  source,
}

class ReaderController extends ChangeNotifier {
  final FileService _fileService = FileService();

  DocumentModel? _currentDocument;
  ViewMode _viewMode = ViewMode.rendered;
  bool _isLoading = false;
  String? _errorMessage;
  double _textScaleFactor = 1.0;
  bool _isSidebarOpen = true;
  ThemeMode _themeMode = ThemeMode.system;
  bool _isDraggingOver = false;
  bool _autoReloadEnabled = true;
  final List<String> _recentFiles = [];
  bool _isSearching = false;
  String _searchQuery = '';
  bool _isDirty = false;

  // Getters
  DocumentModel? get currentDocument => _currentDocument;
  ViewMode get viewMode => _viewMode;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  double get textScaleFactor => _textScaleFactor;
  bool get isSidebarOpen => _isSidebarOpen;
  ThemeMode get themeMode => _themeMode;
  bool get isDraggingOver => _isDraggingOver;
  bool get autoReloadEnabled => _autoReloadEnabled;
  List<String> get recentFiles => List.unmodifiable(_recentFiles);
  bool get isSearching => _isSearching;
  String get searchQuery => _searchQuery;
  bool get isDirty => _isDirty;
  bool get hasDocument => _currentDocument != null;

  ReaderController() {
    // Initialise with sample guide document
    _currentDocument = _fileService.getSampleDocument();
  }

  void updateContent(String newContent) {
    if (_currentDocument == null || _currentDocument!.content == newContent) return;

    final headings = MarkdownParserService.extractHeadings(newContent);
    final wordCount = MarkdownParserService.countWords(newContent);
    final charCount = MarkdownParserService.countCharacters(newContent);
    final lineCount = MarkdownParserService.countLines(newContent);
    final readingTime = MarkdownParserService.calculateReadingTimeMinutes(wordCount);

    _currentDocument = _currentDocument!.copyWith(
      content: newContent,
      headings: headings,
      wordCount: wordCount,
      charCount: charCount,
      lineCount: lineCount,
      readingTimeMinutes: readingTime,
      byteSize: newContent.length,
    );
    _isDirty = true;
    notifyListeners();
  }

  Future<bool> saveCurrentFile() async {
    if (_currentDocument == null) return false;

    if (_currentDocument!.path == null) {
      return await saveFileAs();
    }

    try {
      final savedDoc = await _fileService.saveFile(
        _currentDocument!.path!,
        _currentDocument!.content,
      );
      _currentDocument = savedDoc;
      _isDirty = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to save file: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  Future<bool> saveFileAs() async {
    if (_currentDocument == null) return false;

    try {
      final suggested = _currentDocument!.fileName.endsWith('.md')
          ? _currentDocument!.fileName
          : '${_currentDocument!.fileName}.md';
      final path = await _fileService.pickSavePath(suggestedName: suggested);
      if (path != null) {
        final savedDoc = await _fileService.saveFile(path, _currentDocument!.content);
        _currentDocument = savedDoc;
        _isDirty = false;

        // Add to recent files
        _recentFiles.remove(path);
        _recentFiles.insert(0, path);

        if (_autoReloadEnabled) {
          _setupFileWatcher(path);
        }

        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _errorMessage = 'Failed to save file as: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  void setDragging(bool isDragging) {
    if (_isDraggingOver != isDragging) {
      _isDraggingOver = isDragging;
      notifyListeners();
    }
  }

  void toggleSidebar() {
    _isSidebarOpen = !_isSidebarOpen;
    notifyListeners();
  }

  void setSidebarOpen(bool isOpen) {
    if (_isSidebarOpen != isOpen) {
      _isSidebarOpen = isOpen;
      notifyListeners();
    }
  }

  void setViewMode(ViewMode mode) {
    if (_viewMode != mode) {
      _viewMode = mode;
      notifyListeners();
    }
  }

  void toggleTheme() {
    switch (_themeMode) {
      case ThemeMode.system:
        _themeMode = ThemeMode.dark;
        break;
      case ThemeMode.dark:
        _themeMode = ThemeMode.light;
        break;
      case ThemeMode.light:
        _themeMode = ThemeMode.system;
        break;
    }
    notifyListeners();
  }

  void setThemeMode(ThemeMode mode) {
    if (_themeMode != mode) {
      _themeMode = mode;
      notifyListeners();
    }
  }

  void zoomIn() {
    if (_textScaleFactor < 2.0) {
      _textScaleFactor = (_textScaleFactor + 0.1).clamp(0.7, 2.0);
      notifyListeners();
    }
  }

  void zoomOut() {
    if (_textScaleFactor > 0.7) {
      _textScaleFactor = (_textScaleFactor - 0.1).clamp(0.7, 2.0);
      notifyListeners();
    }
  }

  void resetZoom() {
    if (_textScaleFactor != 1.0) {
      _textScaleFactor = 1.0;
      notifyListeners();
    }
  }

  void toggleAutoReload() {
    _autoReloadEnabled = !_autoReloadEnabled;
    if (_autoReloadEnabled && _currentDocument?.path != null) {
      _setupFileWatcher(_currentDocument!.path!);
    } else {
      _fileService.stopWatchingFile();
    }
    notifyListeners();
  }

  void toggleSearching() {
    _isSearching = !_isSearching;
    if (!_isSearching) {
      _searchQuery = '';
    }
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void clearSearch() {
    _searchQuery = '';
    _isSearching = false;
    notifyListeners();
  }

  Future<void> openFile(String filePath) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final doc = await _fileService.loadFile(filePath);
      _currentDocument = doc;
      _isLoading = false;
      _isDirty = false;

      // Update recent files
      _recentFiles.remove(filePath);
      _recentFiles.insert(0, filePath);
      if (_recentFiles.length > 10) {
        _recentFiles.removeLast();
      }

      if (_autoReloadEnabled) {
        _setupFileWatcher(filePath);
      }

      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Failed to load file: ${e.toString()}';
      notifyListeners();
    }
  }

  Future<void> openFilePicker() async {
    final path = await _fileService.pickMarkdownFile();
    if (path != null) {
      await openFile(path);
    }
  }

  Future<void> reloadCurrentFile() async {
    if (_currentDocument?.path != null) {
      await openFile(_currentDocument!.path!);
    }
  }

  void newDocument() {
    _fileService.stopWatchingFile();
    _errorMessage = null;
    _isDirty = false;
    const initialContent = '# Untitled Document\n\nStart typing your markdown here...\n';
    final headings = MarkdownParserService.extractHeadings(initialContent);
    final wordCount = MarkdownParserService.countWords(initialContent);
    final charCount = MarkdownParserService.countCharacters(initialContent);
    final lineCount = MarkdownParserService.countLines(initialContent);
    final readingTime = MarkdownParserService.calculateReadingTimeMinutes(wordCount);

    _currentDocument = DocumentModel(
      path: null,
      fileName: 'Untitled.md',
      content: initialContent,
      byteSize: initialContent.length,
      headings: headings,
      wordCount: wordCount,
      charCount: charCount,
      lineCount: lineCount,
      readingTimeMinutes: readingTime,
      lastModified: DateTime.now(),
    );
    if (_viewMode == ViewMode.rendered) {
      _viewMode = ViewMode.split;
    }
    notifyListeners();
  }

  void loadSampleDocument() {
    _fileService.stopWatchingFile();
    _errorMessage = null;
    _isDirty = false;
    _currentDocument = _fileService.getSampleDocument();
    notifyListeners();
  }

  void clearDocument() {
    _fileService.stopWatchingFile();
    _currentDocument = null;
    _errorMessage = null;
    _isDirty = false;
    notifyListeners();
  }

  void removeRecentFile(String path) {
    _recentFiles.remove(path);
    notifyListeners();
  }

  void clearError() {
    if (_errorMessage != null) {
      _errorMessage = null;
      notifyListeners();
    }
  }

  void _setupFileWatcher(String filePath) {
    _fileService.startWatchingFile(filePath, () {
      reloadCurrentFile();
    });
  }

  @override
  void dispose() {
    _fileService.dispose();
    super.dispose();
  }
}
