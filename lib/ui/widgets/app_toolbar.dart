import 'package:flutter/material.dart';
import '../../state/reader_controller.dart';

class AppToolbar extends StatelessWidget implements PreferredSizeWidget {
  final ReaderController controller;
  final bool isCompact;
  final VoidCallback onToggleSidebar;

  const AppToolbar({
    super.key,
    required this.controller,
    required this.isCompact,
    required this.onToggleSidebar,
  });

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final doc = controller.currentDocument;

    return AppBar(
      leadingWidth: isCompact ? 56 : 48,
      leading: IconButton(
        icon: Icon(
          controller.isSidebarOpen && !isCompact
              ? Icons.menu_open_rounded
              : Icons.menu_rounded,
          color: colorScheme.onSurface,
        ),
        tooltip: 'Toggle Table of Contents (⌘B)',
        onPressed: onToggleSidebar,
      ),
      titleSpacing: 0,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Document Title Chip
          if (doc != null)
            Flexible(
              child: Tooltip(
                message: doc.path ?? 'Sample Document (In-memory)',
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHigh.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.article_outlined,
                        size: 16,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          controller.isDirty ? '${doc.fileName} •' : doc.fileName,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: controller.isDirty ? colorScheme.primary : colorScheme.onSurface,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            Text(
              'HOB Markdown',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),

          // View Mode Segmented Controls (Render / Split / Source)
          if (!isCompact && doc != null) ...[
            const SizedBox(width: 12),
            SegmentedButton<ViewMode>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment<ViewMode>(
                  value: ViewMode.rendered,
                  icon: Icon(Icons.auto_stories_outlined, size: 16),
                  label: Text('Render'),
                ),
                ButtonSegment<ViewMode>(
                  value: ViewMode.split,
                  icon: Icon(Icons.vertical_split_outlined, size: 16),
                  label: Text('Split'),
                ),
                ButtonSegment<ViewMode>(
                  value: ViewMode.source,
                  icon: Icon(Icons.code_rounded, size: 16),
                  label: Text('Source'),
                ),
              ],
              selected: {controller.viewMode},
              onSelectionChanged: (newSelection) {
                controller.setViewMode(newSelection.first);
              },
            ),
          ],
        ],
      ),
      actions: [
        // Save Button (⌘S)
        if (doc != null)
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: controller.isDirty
                ? FilledButton.tonalIcon(
                    onPressed: () => controller.saveCurrentFile(),
                    icon: const Icon(Icons.save_rounded, size: 16),
                    label: const Text('Save'),
                    style: FilledButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    ),
                  )
                : IconButton(
                    icon: const Icon(Icons.save_outlined, size: 20),
                    tooltip: 'Save (⌘S)',
                    onPressed: () => controller.saveCurrentFile(),
                  ),
          ),
        // Search Button
        if (doc != null)
          IconButton(
            icon: Icon(
              controller.isSearching ? Icons.search_off_rounded : Icons.search_rounded,
              size: 20,
            ),
            tooltip: 'Search in document (⌘F)',
            onPressed: controller.toggleSearching,
          ),

        // Zoom Out
        if (!isCompact)
          IconButton(
            icon: const Icon(Icons.zoom_out_rounded, size: 20),
            tooltip: 'Zoom Out (⌘-)',
            onPressed: controller.zoomOut,
          ),

        // Zoom In
        if (!isCompact)
          IconButton(
            icon: const Icon(Icons.zoom_in_rounded, size: 20),
            tooltip: 'Zoom In (⌘+)',
            onPressed: controller.zoomIn,
          ),

        // Reload File
        if (doc?.path != null)
          IconButton(
            icon: const Icon(Icons.refresh_rounded, size: 20),
            tooltip: 'Reload File (⌘R)',
            onPressed: () => controller.reloadCurrentFile(),
          ),

        // Theme Toggle Button
        IconButton(
          icon: Icon(
            controller.themeMode == ThemeMode.dark
                ? Icons.dark_mode_rounded
                : controller.themeMode == ThemeMode.light
                    ? Icons.light_mode_rounded
                    : Icons.brightness_auto_rounded,
            size: 20,
          ),
          tooltip: 'Theme: ${controller.themeMode.name.toUpperCase()} (⌘T)',
          onPressed: controller.toggleTheme,
        ),

        const SizedBox(width: 8),

        // Open File Button
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: FilledButton.icon(
            onPressed: () => controller.openFilePicker(),
            icon: const Icon(Icons.file_open_outlined, size: 16),
            label: const Text('Open'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ),
      ],
    );
  }
}
