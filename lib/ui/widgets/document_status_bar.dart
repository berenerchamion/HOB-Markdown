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

    // A quiet strip in the window's own background colour with no top rule,
    // like a macOS status bar, so it reads as the floor of the window rather
    // than a separate panel.
    return Container(
      height: 26,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      color: theme.scaffoldBackgroundColor,
      alignment: Alignment.centerLeft,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            // Auto reload indicator
            if (document.path != null) ...[
              _StatusAction(
                onTap: controller.toggleAutoReload,
                tooltip: controller.autoReloadEnabled
                    ? 'Stop reloading when the file changes on disk'
                    : 'Reload automatically when the file changes on disk',
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: controller.autoReloadEnabled
                            ? Colors.green
                            : colorScheme.onSurfaceVariant.withValues(
                                alpha: 0.5,
                              ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      controller.autoReloadEnabled
                          ? 'Live Watcher On'
                          : 'Live Watcher Off',
                      style: _labelStyle(theme, colorScheme),
                    ),
                  ],
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
            _StatusAction(
              onTap: controller.resetZoom,
              tooltip: 'Reset zoom (⌘0)',
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.zoom_in_rounded,
                    size: 13,
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${(controller.textScaleFactor * 100).round()}%',
                    style: _labelStyle(theme, colorScheme),
                  ),
                ],
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
          Icon(
            icon,
            size: 13,
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
          ),
          const SizedBox(width: 5),
          Text(text, style: _labelStyle(theme, colorScheme)),
        ],
      ),
    );
  }

  TextStyle? _labelStyle(ThemeData theme, ColorScheme colorScheme) =>
      theme.textTheme.labelSmall?.copyWith(
        color: colorScheme.onSurfaceVariant,
        fontWeight: FontWeight.w500,
      );

  Widget _buildDivider(ColorScheme colorScheme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 6),
      height: 10,
      width: 1,
      color: colorScheme.outlineVariant.withValues(alpha: 0.7),
    );
  }
}

/// A clickable status item: a soft rounded highlight on hover, no ripple.
class _StatusAction extends StatefulWidget {
  final VoidCallback onTap;
  final String tooltip;
  final Widget child;

  const _StatusAction({
    required this.onTap,
    required this.tooltip,
    required this.child,
  });

  @override
  State<_StatusAction> createState() => _StatusActionState();
}

class _StatusActionState extends State<_StatusAction> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Tooltip(
      message: widget.tooltip,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 100),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: _hovered
                  ? colorScheme.onSurface.withValues(alpha: 0.07)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(5),
            ),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
