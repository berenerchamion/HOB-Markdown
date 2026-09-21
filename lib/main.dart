import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;

import 'services/file_open_service.dart';
import 'state/reader_controller.dart';
import 'theme/app_theme.dart';
import 'ui/reader_screen.dart';
import 'ui/widgets/app_menu_bar.dart';
import 'ui/widgets/unsaved_changes_dialog.dart';

void main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();
  LicenseRegistry.addLicense(() async* {
    final license = await rootBundle.loadString('assets/LICENSE-2.0.txt');
    yield LicenseEntryWithLineBreaks(['House of Beor Markdown'], license);
  });

  String? initialFilePath;
  try {
    initialFilePath = await FileOpenService.getInitialFile();
  } catch (_) {
    // Ignore channel errors on unsupported platforms
  }

  if (initialFilePath == null && args.isNotEmpty) {
    for (final arg in args) {
      if (!arg.startsWith('-')) {
        initialFilePath = arg;
        break;
      }
    }
  }

  runApp(MarkdownReaderApp(initialFilePath: initialFilePath));
}

class MarkdownReaderApp extends StatefulWidget {
  final String? initialFilePath;

  const MarkdownReaderApp({super.key, this.initialFilePath});

  @override
  State<MarkdownReaderApp> createState() => _MarkdownReaderAppState();
}

class _MarkdownReaderAppState extends State<MarkdownReaderApp> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  late final ReaderController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ReaderController(initialFilePath: widget.initialFilePath);

    FileOpenService.setFileOpenListener((filePath) async {
      await _handleIncomingFile(filePath);
    });
  }

  Future<void> _handleIncomingFile(String filePath) async {
    if (!mounted) return;

    if (_controller.isDirty) {
      final context = _navigatorKey.currentContext;
      if (context != null) {
        final action = await UnsavedChangesDialog.show(
          context,
          currentDocumentName:
              _controller.currentDocument?.fileName ?? 'Untitled',
          newDocumentName: p.basename(filePath),
        );

        if (action == UnsavedChangesAction.save) {
          final saved = await _controller.saveCurrentFile();
          if (saved) {
            await _controller.openFile(filePath);
          }
        } else if (action == UnsavedChangesAction.discard) {
          await _controller.openFile(filePath);
        }
        // If cancel or dismissed, keep existing document & edits
        return;
      }
    }

    await _controller.openFile(filePath);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        final title = _controller.currentDocument?.fileName != null
            ? '${_controller.currentDocument!.fileName} — HOB Markdown'
            : 'HOB Markdown';

        return MaterialApp(
          navigatorKey: _navigatorKey,
          title: title,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme(),
          darkTheme: AppTheme.darkTheme(),
          themeMode: _controller.themeMode,
          home: AppMenuBar(
            controller: _controller,
            child: ReaderScreen(controller: _controller),
          ),
        );
      },
    );
  }
}

