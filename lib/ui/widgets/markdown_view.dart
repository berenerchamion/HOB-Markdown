import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/document_model.dart';
import '../../models/toc_item.dart';
import '../../theme/app_theme.dart';
import 'code_block_builder.dart';

class MarkdownView extends StatelessWidget {
  final DocumentModel document;
  final double scaleFactor;
  final ScrollController scrollController;
  final ValueChanged<TocItem>? onNavigateToHeading;

  const MarkdownView({
    super.key,
    required this.document,
    required this.scaleFactor,
    required this.scrollController,
    this.onNavigateToHeading,
  });

  Future<void> _handleLinkTap(String? url) async {
    if (url == null || url.isEmpty) return;

    // Handle local in-document heading links (e.g. #key-features)
    if (url.startsWith('#') && onNavigateToHeading != null) {
      final anchor = url.substring(1).toLowerCase();
      final match = document.headings.firstWhere(
        (h) => h.anchor == anchor,
        orElse: () => document.headings.firstWhere(
          (h) => h.title.toLowerCase().replaceAll(' ', '-') == anchor,
          orElse: () => const TocItem(level: 1, title: '', lineNumber: 0, anchor: ''),
        ),
      );
      if (match.title.isNotEmpty) {
        onNavigateToHeading!(match);
        return;
      }
    }

    final uri = Uri.tryParse(url);
    if (uri != null) {
      try {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } catch (e) {
        debugPrint('Could not launch url: $url, error: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final styleSheet = AppTheme.markdownStyleSheet(context, scaleFactor: scaleFactor);

    return SelectionArea(
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 880),
          child: Markdown(
            controller: scrollController,
            data: document.content,
            selectable: false, // Selection is handled cleanly by outer SelectionArea
            styleSheet: styleSheet,
            onTapLink: (text, href, title) => _handleLinkTap(href),
            builders: {
              'code': CodeBlockBuilder(
                context: context,
                scaleFactor: scaleFactor,
              ),
            },
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
          ),
        ),
      ),
    );
  }
}
