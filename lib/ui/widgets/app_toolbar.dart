import 'package:flutter/material.dart';

import '../../services/window_service.dart';
import '../../state/reader_controller.dart';
import 'settings_dialog.dart';
import 'toolbar_controls.dart';

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
  static const double _modeLabelMinWidth = 920;

  /// Space between toolbar wells.
  static const double _wellGap = 8;

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
    // macOS has these in the menu bar, with shortcuts. Windows and Linux have
    // no menu bar, so the toolbar is their only way to reach them.
    final hasMenuBar = WindowService.usesCustomTitleBar;

    return AppBar(
      toolbarHeight: _height,
      leadingWidth: leftInset + (isCompact ? 56 : 48),
      leading: Padding(
        padding: EdgeInsets.only(left: leftInset),
        child: Center(
          child: ToolbarButton(
            icon: controller.isSidebarOpen && !isCompact
                ? Icons.menu_open_rounded
                : Icons.menu_rounded,
            tooltip: 'Toggle Table of Contents (⌘B)',
            onPressed: onToggleSidebar,
          ),
        ),
      ),
      titleSpacing: 4,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Document title, flat like a macOS window title.
          if (doc != null)
            Flexible(
              child: Tooltip(
                message: doc.path ?? 'Sample Document (In-memory)',
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.article_outlined,
                      size: 16,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        controller.isDirty ? '${doc.fileName} •' : doc.fileName,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Text(
              'HOB Markdown',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),

          if (!isCompact && doc != null) ...[
            const SizedBox(width: 14),
            ViewModeSwitch(
              value: controller.viewMode,
              onChanged: controller.setViewMode,
              showLabels: showModeLabels,
            ),
          ],
        ],
      ),
      // One centred row, so the wells keep their own height instead of
      // being stretched to the toolbar's.
      actions: [
        Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Document actions
              if (doc != null) ...[
                ToolbarWell(
                  children: [
                    ToolbarButton(
                      icon: controller.isDirty
                          ? Icons.save_rounded
                          : Icons.save_outlined,
                      tooltip: 'Save (⌘S)',
                      label: controller.isDirty ? 'Save' : null,
                      prominent: controller.isDirty,
                      onPressed: () => controller.saveCurrentFile(),
                    ),
                    ToolbarButton(
                      icon: Icons.print_outlined,
                      tooltip: 'Print rendered document (⌘P)',
                      onPressed: () => controller.printDocument(),
                    ),
                    if (!hasMenuBar && doc.path != null)
                      ToolbarButton(
                        icon: Icons.refresh_rounded,
                        tooltip: 'Reload File (⌘R)',
                        onPressed: () => controller.reloadCurrentFile(),
                      ),
                  ],
                ),
                const SizedBox(width: _wellGap),
              ],

              // Zoom (Windows and Linux only; macOS has it in the View menu)
              if (!hasMenuBar && !isCompact) ...[
                ToolbarWell(
                  children: [
                    ToolbarButton(
                      icon: Icons.zoom_out_rounded,
                      tooltip: 'Zoom Out (⌘-)',
                      onPressed: controller.zoomOut,
                    ),
                    ToolbarButton(
                      icon: Icons.zoom_in_rounded,
                      tooltip: 'Zoom In (⌘+)',
                      onPressed: controller.zoomIn,
                    ),
                  ],
                ),
                const SizedBox(width: _wellGap),
              ],

              // Tools that open a panel or overlay, shown as selected while open
              if (doc != null) ...[
                ToolbarWell(
                  children: [
                    ToolbarButton(
                      icon: Icons.search_rounded,
                      tooltip: 'Search in document (⌘F)',
                      selected: controller.isSearching,
                      onPressed: controller.toggleSearching,
                    ),
                    ToolbarButton(
                      icon: Icons.fact_check_outlined,
                      selectedIcon: Icons.fact_check,
                      selected: controller.isReviewing,
                      tooltip: controller.isReviewing
                          ? 'Hide readability review (⇧⌘R)'
                          : 'Readability review (⇧⌘R)',
                      onPressed: controller.toggleReview,
                    ),
                  ],
                ),
                const SizedBox(width: _wellGap),
              ],

              // App-level: Settings is also in the macOS app menu, but Windows and
              // Linux have no menu bar, so this is their way in.
              ToolbarWell(
                children: [
                  ToolbarButton(
                    icon: Icons.settings_outlined,
                    tooltip: 'Settings (⌘,)',
                    onPressed: () => showSettingsDialog(context, controller),
                  ),
                  ToolbarButton(
                    icon: Icons.help_outline_rounded,
                    tooltip: 'Show help',
                    onPressed: () => controller.showHelpWindow(),
                  ),
                ],
              ),
              const SizedBox(width: _wellGap),

              ToolbarWell(
                children: [
                  ToolbarButton(
                    icon: Icons.file_open_outlined,
                    tooltip: 'Open file (⌘O)',
                    label: 'Open',
                    onPressed: () => controller.openFilePicker(),
                  ),
                ],
              ),
              const SizedBox(width: 12),
            ],
          ),
        ),
      ],
    );
  }
}
