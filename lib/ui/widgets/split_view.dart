import 'package:flutter/material.dart';
import '../../models/document_model.dart';
import '../../models/toc_item.dart';
import 'markdown_view.dart';
import 'raw_markdown_view.dart';

class SplitView extends StatelessWidget {
  final DocumentModel document;
  final double scaleFactor;
  final ScrollController scrollController;
  final ValueChanged<TocItem>? onNavigateToHeading;
  final ValueChanged<String>? onContentChanged;

  const SplitView({
    super.key,
    required this.document,
    required this.scaleFactor,
    required this.scrollController,
    this.onNavigateToHeading,
    this.onContentChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Raw Source View on Left
        Expanded(
          flex: 1,
          child: Container(
            color: colorScheme.surfaceContainerLowest,
            child: RawMarkdownView(
              document: document,
              scaleFactor: scaleFactor,
              onChanged: onContentChanged,
            ),
          ),
        ),

        // Vertical Divider
        VerticalDivider(
          width: 1,
          thickness: 1,
          color: colorScheme.outlineVariant,
        ),

        // Rendered Markdown View on Right
        Expanded(
          flex: 1,
          child: Container(
            color: theme.scaffoldBackgroundColor,
            child: MarkdownView(
              document: document,
              scaleFactor: scaleFactor,
              scrollController: scrollController,
              onNavigateToHeading: onNavigateToHeading,
            ),
          ),
        ),
      ],
    );
  }
}
