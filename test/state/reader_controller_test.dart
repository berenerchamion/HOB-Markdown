import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hob_markdown_reader/models/document_model.dart';
import 'package:hob_markdown_reader/services/file_service.dart';
import 'package:hob_markdown_reader/state/reader_controller.dart';

class FakeFileService extends FileService {
  String? savePathToReturn;
  String? pickFilePathToReturn;
  bool shouldThrowOnSave = false;
  bool shouldThrowOnPick = false;
  String? lastSavedPath;
  String? lastSavedContent;
  String? lastWatchedPath;
  bool watcherStopped = false;

  @override
  Future<String?> pickSavePath({
    String suggestedName = 'document.md',
    required String content,
  }) async {
    if (shouldThrowOnSave) {
      throw Exception('Pick save path error');
    }
    return savePathToReturn;
  }

  @override
  Future<String?> pickMarkdownFile() async {
    if (shouldThrowOnPick) {
      throw Exception('Picker crash');
    }
    return pickFilePathToReturn;
  }

  @override
  Future<DocumentModel> saveFile(String filePath, String content) async {
    if (shouldThrowOnSave) {
      throw Exception('Disk full');
    }
    lastSavedPath = filePath;
    lastSavedContent = content;
    return buildDocumentFromContent(
      path: filePath,
      fileName: filePath.split('/').last,
      content: content,
    );
  }

  @override
  Future<DocumentModel> buildDocumentModelFromDisk(
    String filePath,
    String content,
  ) async {
    return buildDocumentFromContent(
      path: filePath,
      fileName: filePath.split('/').last,
      content: content,
    );
  }

  @override
  Future<DocumentModel> loadFile(String filePath) async {
    if (filePath == '/invalid/crash.md') {
      throw const FileSystemException('Not found');
    }
    return buildDocumentFromContent(
      path: filePath,
      fileName: filePath.split('/').last,
      content: '# Loaded File\n\nContent of $filePath',
    );
  }

  @override
  void startWatchingFile(String filePath, VoidCallback onFileChanged) {
    lastWatchedPath = filePath;
    watcherStopped = false;
  }

  @override
  void stopWatchingFile() {
    watcherStopped = true;
  }
}

void main() {
  group('ReaderController Save & Recent Files Tests', () {
    late FakeFileService fakeService;
    late ReaderController controller;

    setUp(() {
      fakeService = FakeFileService();
      controller = ReaderController(fileService: fakeService);
    });

    tearDown(() {
      controller.dispose();
    });

    test('saveCurrentFile returns false when no document is open', () async {
      controller.clearDocument();
      expect(controller.hasDocument, false);

      final result = await controller.saveCurrentFile();
      expect(result, false);
    });

    test('saveCurrentFile delegates to saveFileAs when document has no path', () async {
      controller.newDocument();
      expect(controller.currentDocument!.path, isNull);

      fakeService.savePathToReturn = '/users/test/new_doc.md';
      final result = await controller.saveCurrentFile();

      expect(result, true);
      expect(controller.currentDocument!.path, '/users/test/new_doc.md');
      expect(controller.isDirty, false);
      expect(controller.recentFiles.first, '/users/test/new_doc.md');
    });

    test('saveCurrentFile saves directly when document has a path', () async {
      await controller.openFile('/users/test/existing.md');
      controller.updateContent('# Edited content');
      expect(controller.isDirty, true);

      final result = await controller.saveCurrentFile();

      expect(result, true);
      expect(controller.isDirty, false);
      expect(fakeService.lastSavedPath, '/users/test/existing.md');
      expect(fakeService.lastSavedContent, '# Edited content');
    });

    test('saveCurrentFile sets errorMessage and returns false on failure', () async {
      await controller.openFile('/users/test/existing.md');
      fakeService.shouldThrowOnSave = true;

      final result = await controller.saveCurrentFile();

      expect(result, false);
      expect(controller.errorMessage, contains('Failed to save file'));
    });

    test('saveFileAs returns false and keeps dirty state when user cancels save dialog', () async {
      controller.newDocument();
      controller.updateContent('# Edited without save');
      fakeService.savePathToReturn = null; // User cancelled

      final result = await controller.saveFileAs();

      expect(result, false);
      expect(controller.isDirty, true);
      expect(controller.currentDocument!.path, isNull);
    });

    test('saveFileAs sets errorMessage on error', () async {
      controller.newDocument();
      fakeService.shouldThrowOnSave = true;

      final result = await controller.saveFileAs();

      expect(result, false);
      expect(controller.errorMessage, contains('Failed to save file as'));
    });

    test('recentFiles maintains MRU order and max capacity of 10 items', () async {
      for (int i = 1; i <= 12; i++) {
        await controller.openFile('/docs/file_$i.md');
      }

      expect(controller.recentFiles.length, 10);
      expect(controller.recentFiles.first, '/docs/file_12.md');
      expect(controller.recentFiles.contains('/docs/file_1.md'), false);
      expect(controller.recentFiles.contains('/docs/file_2.md'), false);

      // Reopening an older file moves it to the top without duplicates
      await controller.openFile('/docs/file_5.md');
      expect(controller.recentFiles.first, '/docs/file_5.md');
      expect(controller.recentFiles.where((p) => p == '/docs/file_5.md').length, 1);

      // Removing a recent file
      controller.removeRecentFile('/docs/file_5.md');
      expect(controller.recentFiles.contains('/docs/file_5.md'), false);
      expect(controller.recentFiles.length, 9);
    });

    test('toggleAutoReload enables and disables watcher', () async {
      await controller.openFile('/docs/watched_doc.md');
      expect(controller.autoReloadEnabled, true);
      expect(fakeService.lastWatchedPath, '/docs/watched_doc.md');

      // Toggle off
      controller.toggleAutoReload();
      expect(controller.autoReloadEnabled, false);
      expect(fakeService.watcherStopped, true);

      // Toggle back on
      fakeService.watcherStopped = false;
      controller.toggleAutoReload();
      expect(controller.autoReloadEnabled, true);
      expect(fakeService.lastWatchedPath, '/docs/watched_doc.md');
    });

    test('openFilePicker opens file when selected and sets error on exception', () async {
      fakeService.pickFilePathToReturn = '/picked/file.md';
      await controller.openFilePicker();

      expect(controller.currentDocument!.path, '/picked/file.md');
      expect(controller.errorMessage, isNull);

      // Simulate picker exception
      fakeService.shouldThrowOnPick = true;
      await controller.openFilePicker();

      expect(controller.errorMessage, contains('Could not open the file picker'));
    });

    test('UI state toggles: setDragging, setSidebarOpen, toggleSidebar, setThemeMode, clearError', () {
      expect(controller.isDraggingOver, false);
      controller.setDragging(true);
      expect(controller.isDraggingOver, true);
      controller.setDragging(false);
      expect(controller.isDraggingOver, false);

      expect(controller.isSidebarOpen, true);
      controller.setSidebarOpen(false);
      expect(controller.isSidebarOpen, false);
      controller.toggleSidebar();
      expect(controller.isSidebarOpen, true);

      controller.setThemeMode(ThemeMode.dark);
      expect(controller.themeMode, ThemeMode.dark);
      controller.setThemeMode(ThemeMode.light);
      expect(controller.themeMode, ThemeMode.light);

      controller.clearError();
      expect(controller.errorMessage, isNull);
    });
  });
}
