import 'package:flutter/material.dart';

import '../../services/window_service.dart';
import '../../state/reader_controller.dart';
import 'settings_dialog.dart';

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
  Size get preferredSize => Size.fromHeight(_height);

  /// Below this window width (plus any traffic-light inset) the view-mode
  /// buttons drop their labels.
  static const double _modeLabelMinWidth = 1000;

  static double get _height =>
      WindowService.usesCustomTitleBar ? WindowService.titleBarHeight : 56;

  @override
  Widget build(BuildContext context) {
    if (!WindowService.usesCustomTitleBar) {
      return _buildAppBar(context, leftInset: 0);
    }
    // On macOS the toolbar doubles as the title bar: leave room for the
    // traffic lights (except in full screen, where they're hidden), and let
    // empty space drag the window and double-click to zoom.
    return ValueListenableBuilder<bool>(
      valueListenable: WindowService.isFullScreen,
      builder: (context, isFullScreen, _) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanStart: (_) => WindowService.startDrag(),
        onDoubleTap: WindowService.titleBarDoubleClicked,
        child: _buildAppBar(
          context,
          leftInset: isFullScreen ? 0 : WindowService.trafficLightInset,
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, {required double leftInset}) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final doc = controller.currentDocument;
    final showModeLabels =
        MediaQuery.sizeOf(context).width >= _modeLabelMinWidth + leftInset;

    return AppBar(
      toolbarHeight: _height,
      leadingWidth: leftInset + (isCompact ? 56 : 48),
      leading: Padding(
        padding: EdgeInsets.only(left: leftInset),
        child: IconButton(
          icon: Icon(
            controller.isSidebarOpen && !isCompact
                ? Icons.menu_open_rounded
                : Icons.menu_rounded,
            color: colorScheme.onSurface,
          ),
          tooltip: 'Toggle Table of Contents (⌘B)',
          onPressed: onToggleSidebar,
        ),
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHigh.withValues(
                      alpha: 0.5,
                    ),
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
                          controller.isDirty
                              ? '${doc.fileName} •'
                              : doc.fileName,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: controller.isDirty
                                ? colorScheme.primary
                                : colorScheme.onSurface,
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
              segments: [
                for (final (mode, icon, label) in const [
                  (ViewMode.rendered, Icons.auto_stories_outlined, 'Render'),
                  (ViewMode.split, Icons.vertical_split_outlined, 'Split'),
                  (ViewMode.source, Icons.code_rounded, 'Source'),
                ])
                  ButtonSegment<ViewMode>(
                    value: mode,
                    icon: Icon(icon, size: 16),
                    // Narrow windows show icons only so the toolbar fits.
                    label: showModeLabels ? Text(label) : null,
                    tooltip: showModeLabels ? null : label,
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                    ),
                  )
                : IconButton(
                    icon: const Icon(Icons.save_outlined, size: 20),
                    tooltip: 'Save (⌘S)',
                    onPressed: () => controller.saveCurrentFile(),
                  ),
          ),

        // Print Button (⌘P)
        if (doc != null)
          IconButton(
            icon: const Icon(Icons.print_outlined, size: 20),
            tooltip: 'Print rendered document (⌘P)',
            onPressed: () => controller.printDocument(),
          ),

        // Search Button
        if (doc != null)
          IconButton(
            icon: Icon(
              controller.isSearching
                  ? Icons.search_off_rounded
                  : Icons.search_rounded,
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

        // Readability review
        if (doc != null)
          IconButton(
            icon: const Icon(Icons.fact_check_outlined, size: 20),
            selectedIcon: const Icon(Icons.fact_check, size: 20),
            isSelected: controller.isReviewing,
            tooltip: controller.isReviewing
                ? 'Hide readability review (⇧⌘R)'
                : 'Readability review (⇧⌘R)',
            onPressed: controller.toggleReview,
          ),

        // Settings. Also in the app menu on macOS, but Windows and Linux
        // have no native menu bar, so this is their way in.
        IconButton(
          icon: const Icon(Icons.settings_outlined, size: 20),
          tooltip: 'Settings (⌘,)',
          onPressed: () => showSettingsDialog(context, controller),
        ),

        // Open Help
        IconButton(
          icon: const Icon(Icons.help, size: 20),
          tooltip: 'Show help',
          onPressed: () => controller.showHelpWindow(),
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
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
