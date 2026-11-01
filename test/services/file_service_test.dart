import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hob_markdown_reader/services/file_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late FileService fileService;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('file_service_test_');
    fileService = FileService();
  });

  tearDown(() async {
    fileService.dispose();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('FileService loadFile Tests', () {
    test('loads valid UTF-8 markdown file successfully', () async {
      final file = File('${tempDir.path}/test_utf8.md');
      await file.writeAsString('# UTF-8 Heading\n\nHello world!');

      final doc = await fileService.loadFile(file.path);

      expect(doc.path, file.path);
      expect(doc.fileName, 'test_utf8.md');
      expect(doc.content, '# UTF-8 Heading\n\nHello world!');
      expect(doc.headings.length, 1);
      expect(doc.headings.first.title, 'UTF-8 Heading');
      expect(doc.wordCount, 5);
      expect(doc.lineCount, 3);
      expect(doc.byteSize, greaterThan(0));
      expect(doc.lastModified, isNotNull);
    });

    test('decodes Latin-1 encoded file using fallback without throwing', () async {
      final file = File('${tempDir.path}/latin1_doc.md');
      // 0xE9 is é in Latin-1, which is invalid as a standalone UTF-8 lead byte
      final latin1Bytes = [
        0x23, 0x20, 0x43, 0x61, 0x66, 0xE9, // "# Café" in Latin-1
        0x0A, 0x0A,
        0x54, 0x65, 0x73, 0x74, 0x20, 0x74, 0x65, 0x78, 0x74, // "\n\nTest text"
      ];
      await file.writeAsBytes(latin1Bytes);

      final doc = await fileService.loadFile(file.path);

      expect(doc.fileName, 'latin1_doc.md');
      expect(doc.content, contains('# Café'));
      expect(doc.headings.first.title, 'Café');
    });

    test('throws FileSystemException when file does not exist', () {
      final nonExistentPath = '${tempDir.path}/does_not_exist.md';

      expect(
        () async => await fileService.loadFile(nonExistentPath),
        throwsA(isA<FileSystemException>()),
      );
    });
  });

  group('FileService saveFile & buildDocumentModel Tests', () {
    test('saveFile writes content to disk and returns updated DocumentModel', () async {
      final file = File('${tempDir.path}/saved.md');
      await file.writeAsString('Initial content');

      final updatedDoc = await fileService.saveFile(
        file.path,
        '# Saved Heading\n\nNew updated content with five words.',
      );

      expect(updatedDoc.path, file.path);
      expect(updatedDoc.fileName, 'saved.md');
      expect(updatedDoc.headings.length, 1);
      expect(updatedDoc.headings.first.title, 'Saved Heading');
      expect(updatedDoc.wordCount, 8);

      // Verify on disk
      final diskContent = await file.readAsString();
      expect(diskContent, '# Saved Heading\n\nNew updated content with five words.');
    });

    test('buildDocumentModelFromDisk creates model from existing file on disk', () async {
      final file = File('${tempDir.path}/disk_model.md');
      await file.writeAsString('# Model From Disk\n\nSome text here.');

      final doc = await fileService.buildDocumentModelFromDisk(
        file.path,
        '# Model From Disk\n\nSome text here.',
      );

      expect(doc.path, file.path);
      expect(doc.fileName, 'disk_model.md');
      expect(doc.headings.length, 1);
      expect(doc.headings.first.title, 'Model From Disk');
      expect(doc.wordCount, 6);
    });

    test('buildDocumentFromContent creates model without writing to disk', () {
      final doc = fileService.buildDocumentFromContent(
        content: '# Standalone Content\n\nTesting standalone builder.',
        fileName: 'Standalone.md',
      );

      expect(doc.path, isNull);
      expect(doc.fileName, 'Standalone.md');
      expect(doc.headings.length, 1);
      expect(doc.headings.first.title, 'Standalone Content');
      expect(doc.wordCount, 5);
      expect(doc.lastModified, isNotNull);
    });
  });

  group('FileService Watcher Tests', () {
    // Waits until [condition] is true (checked every 50 ms) or fails after
    // [timeout]. Watcher events arrive on the OS's schedule, not ours.
    Future<void> waitUntil(
      bool Function() condition, {
      Duration timeout = const Duration(seconds: 5),
    }) async {
      final deadline = DateTime.now().add(timeout);
      while (!condition()) {
        if (DateTime.now().isAfter(deadline)) {
          fail('Timed out waiting for the file watcher to report a change');
        }
        await Future.delayed(const Duration(milliseconds: 50));
      }
    }

    test('startWatchingFile notifies callback on file change and debounces', () async {
      final file = File('${tempDir.path}/watched.md');
      await file.writeAsString('# Initial content');

      int changeCount = 0;
      fileService.startWatchingFile(file.path, () {
        changeCount++;
      });

      // Give a polling watcher time to record the file's starting state.
      await Future.delayed(const Duration(milliseconds: 100));

      // Rapidly modify file
      await file.writeAsString('# Modified content 1');
      await Future.delayed(const Duration(milliseconds: 50));
      await file.writeAsString('# Modified content 2');

      // macOS and Linux report changes almost immediately, but on Windows the
      // watcher polls about once a second. Wait for the first notification
      // instead of assuming a fixed delay.
      await waitUntil(() => changeCount > 0);

      // Let the 300 ms debounce and any extra events settle: the rapid edits
      // above must have collapsed into a single callback.
      await Future.delayed(const Duration(milliseconds: 700));
      expect(changeCount, 1);

      // Calling stopWatchingFile prevents future notifications
      fileService.stopWatchingFile();
      await file.writeAsString('# Modified content 3');

      // Longer than one polling interval, so a watcher that was still active
      // would have fired by now.
      await Future.delayed(const Duration(milliseconds: 1500));

      expect(changeCount, 1);
    });
  });

  group('FileService Sample Document Tests', () {
    test('getSampleDocument returns valid document model', () {
      final sample = fileService.getSampleDocument();
      expect(sample.fileName, 'Welcome Guide.md');
      expect(sample.content, isNotEmpty);
      expect(sample.headings, isNotEmpty);
    });
  });
}
