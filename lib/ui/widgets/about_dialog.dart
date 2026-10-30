// lib/widgets/about_dialog.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../../app_info.dart';

Future<String> _loadLicenseText() {
  return rootBundle.loadString('assets/LICENSE-2.0.txt');
}

void showAppAboutDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('House of Beor Markdown - License Agreement'),
      content: SizedBox(
        width: 600,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('A fast, native markdown reader and editor.'),
              const SizedBox(height: 16),
              FutureBuilder<String>(
                future: _loadLicenseText(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Text('Could not load license: ${snapshot.error}');
                  }
                  if (!snapshot.hasData) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  return Text(snapshot.data!);
                },
              ),
            ],
          ),
        ),
      ),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            showLicensePage(
              context: context,
              applicationName: 'House of. Beor Markdown',
              applicationVersion: AppInfo.version,
            );
          },
          child: const Text('Third-party licenses'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    ),
  );
}
