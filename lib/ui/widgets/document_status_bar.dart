import 'package:flutter/material.dart';
import '../../models/document_model.dart';
import '../../state/reader_controller.dart';

class DocumentStatusBar extends StatelessWidget {
  final DocumentModel document;
  final ReaderController controller;

  const DocumentStatusBar({
    super.key,
    required this.document,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        border: Border(
          top: BorderSide(color: colorScheme.outlineVariant, width: 1),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            // Auto reload indicator
            if (document.path != null) ...[
              InkWell(
                onTap: controller.toggleAutoReload,
                borderRadius: BorderRadius.circular(4),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: controller.autoReloadEnabled ? Colors.green : colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        controller.autoReloadEnabled ? 'Live Watcher On' : 'Live Watcher Off',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              _buildDivider(colorScheme),
            ],

            // Words & Reading Time
            _buildStatusItem(
              icon: Icons.text_fields_rounded,
              text: '${document.wordCount} words',
              theme: theme,
              colorScheme: colorScheme,
            ),
            _buildDivider(colorScheme),

            _buildStatusItem(
              icon: Icons.timer_outlined,
              text: document.formattedReadingTime,
              theme: theme,
              colorScheme: colorScheme,
            ),
            _buildDivider(colorScheme),

            // Line count
            _buildStatusItem(
              icon: Icons.format_list_numbered_rounded,
              text: '${document.lineCount} lines',
              theme: theme,
              colorScheme: colorScheme,
            ),
            _buildDivider(colorScheme),

            // File size
            _buildStatusItem(
              icon: Icons.data_usage_rounded,
              text: document.formattedFileSize,
              theme: theme,
              colorScheme: colorScheme,
            ),
            _buildDivider(colorScheme),

            // Zoom indicator
            InkWell(
              onTap: controller.resetZoom,
              borderRadius: BorderRadius.circular(4),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.zoom_in_rounded, size: 14, color: colorScheme.onSurfaceVariant),
                    const SizedBox(width: 4),
                    Text(
                      '${(controller.textScaleFactor * 100).round()}%',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusItem({
    required IconData icon,
    required String text,
    required ThemeData theme,
    required ColorScheme colorScheme,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7)),
          const SizedBox(width: 5),
          Text(
            text,
            style: theme.textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider(ColorScheme colorScheme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      height: 12,
      width: 1,
      color: colorScheme.outlineVariant,
    );
  }
}
