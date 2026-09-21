import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'state/reader_controller.dart';
import 'theme/app_theme.dart';
import 'ui/reader_screen.dart';
import 'ui/widgets/app_menu_bar.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  LicenseRegistry.addLicense(() async* {
    final license = await rootBundle.loadString('assets/LICENSE-2.0.txt');
    yield LicenseEntryWithLineBreaks(['House of Beor Markdown'], license);
  });
  runApp(const MarkdownReaderApp());
}

class MarkdownReaderApp extends StatefulWidget {
  const MarkdownReaderApp({super.key});

  @override
  State<MarkdownReaderApp> createState() => _MarkdownReaderAppState();
}

class _MarkdownReaderAppState extends State<MarkdownReaderApp> {
  late final ReaderController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ReaderController();
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
