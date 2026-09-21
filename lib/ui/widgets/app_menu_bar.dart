import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../state/reader_controller.dart';
import 'about_dialog.dart';

class AppMenuBar extends StatelessWidget {
  final ReaderController controller;
  final Widget child;

  const AppMenuBar({super.key, required this.controller, required this.child});

  @override
  Widget build(BuildContext context) {
    return PlatformMenuBar(
      menus: <PlatformMenuItem>[
        // Application Menu (HOB Markdown)
        PlatformMenu(
          label: 'HOB Markdown',
          menus: <PlatformMenuItem>[
            PlatformMenuItem(
              label: 'About HOB Markdown',
              onSelected: () {
                showAboutDialog(
                  context: context,
                  applicationName: 'House of Beor Markdown',
                  applicationVersion: '1.0.1',
                  applicationIcon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Image.asset(
                      'assets/icon/master_icon.png',
                      width: 32,
                      height: 32,
                      fit: BoxFit.cover,
                    ),
                  ),
                  applicationLegalese:
                      '© 2026 House of Beor. All rights reserved.',
                  children: const [
                    SizedBox(height: 16),
                    Text(
                      'A modern Markdown viewer and editor built with Material Design 3 and Flutter.',
                    ),
                  ],
                );
              },
            ),
            PlatformMenuItem(
              label: "HOB Markdown License",
              onSelected: () {
                showAppAboutDialog(context);
              },
            ),
            if (PlatformProvidedMenuItem.hasMenu(
              PlatformProvidedMenuItemType.servicesSubmenu,
            ))
              const PlatformProvidedMenuItem(
                type: PlatformProvidedMenuItemType.servicesSubmenu,
              ),
            if (PlatformProvidedMenuItem.hasMenu(
              PlatformProvidedMenuItemType.hide,
            ))
              const PlatformProvidedMenuItem(
                type: PlatformProvidedMenuItemType.hide,
              ),
            if (PlatformProvidedMenuItem.hasMenu(
              PlatformProvidedMenuItemType.hideOtherApplications,
            ))
              const PlatformProvidedMenuItem(
                type: PlatformProvidedMenuItemType.hideOtherApplications,
              ),
            if (PlatformProvidedMenuItem.hasMenu(
              PlatformProvidedMenuItemType.showAllApplications,
            ))
              const PlatformProvidedMenuItem(
                type: PlatformProvidedMenuItemType.showAllApplications,
              ),
            if (PlatformProvidedMenuItem.hasMenu(
              PlatformProvidedMenuItemType.quit,
            ))
              const PlatformProvidedMenuItem(
                type: PlatformProvidedMenuItemType.quit,
              ),
          ],
        ),

        // File Menu
        PlatformMenu(
          label: 'File',
          menus: <PlatformMenuItem>[
            PlatformMenuItem(
              label: 'New Document',
              shortcut: const SingleActivator(
                LogicalKeyboardKey.keyN,
                meta: true,
              ),
              onSelected: () => controller.newDocument(),
            ),
            PlatformMenuItem(
              label: 'Open…',
              shortcut: const SingleActivator(
                LogicalKeyboardKey.keyO,
                meta: true,
              ),
              onSelected: () => controller.openFilePicker(),
            ),
            PlatformMenuItem(
              label: 'Save',
              shortcut: const SingleActivator(
                LogicalKeyboardKey.keyS,
                meta: true,
              ),
              onSelected: controller.hasDocument
                  ? () => controller.saveCurrentFile()
                  : null,
            ),
            PlatformMenuItem(
              label: 'Save As…',
              shortcut: const SingleActivator(
                LogicalKeyboardKey.keyS,
                meta: true,
                shift: true,
              ),
              onSelected: controller.hasDocument
                  ? () => controller.saveFileAs()
                  : null,
            ),
            PlatformMenuItem(
              label: 'Reload File',
              shortcut: const SingleActivator(
                LogicalKeyboardKey.keyR,
                meta: true,
              ),
              onSelected: controller.currentDocument?.path != null
                  ? () => controller.reloadCurrentFile()
                  : null,
            ),
            PlatformMenuItem(
              label: 'Close Document',
              shortcut: const SingleActivator(
                LogicalKeyboardKey.keyW,
                meta: true,
              ),
              onSelected: controller.hasDocument
                  ? () => controller.clearDocument()
                  : null,
            ),
          ],
        ),

        // Edit Menu
        PlatformMenu(
          label: 'Edit',
          menus: <PlatformMenuItem>[
            PlatformMenuItem(
              label: 'Find in Document…',
              shortcut: const SingleActivator(
                LogicalKeyboardKey.keyF,
                meta: true,
              ),
              onSelected: controller.hasDocument
                  ? () => controller.toggleSearching()
                  : null,
            ),
          ],
        ),

        // View Menu
        PlatformMenu(
          label: 'View',
          menus: <PlatformMenuItem>[
            PlatformMenuItem(
              label: 'Rendered View',
              shortcut: const SingleActivator(
                LogicalKeyboardKey.digit1,
                meta: true,
              ),
              onSelected: () => controller.setViewMode(ViewMode.rendered),
            ),
            PlatformMenuItem(
              label: 'Split View',
              shortcut: const SingleActivator(
                LogicalKeyboardKey.digit2,
                meta: true,
              ),
              onSelected: () => controller.setViewMode(ViewMode.split),
            ),
            PlatformMenuItem(
              label: 'Source View',
              shortcut: const SingleActivator(
                LogicalKeyboardKey.digit3,
                meta: true,
              ),
              onSelected: () => controller.setViewMode(ViewMode.source),
            ),
            PlatformMenuItem(
              label: 'Zoom In',
              shortcut: const SingleActivator(
                LogicalKeyboardKey.equal,
                meta: true,
              ),
              onSelected: () => controller.zoomIn(),
            ),
            PlatformMenuItem(
              label: 'Zoom Out',
              shortcut: const SingleActivator(
                LogicalKeyboardKey.minus,
                meta: true,
              ),
              onSelected: () => controller.zoomOut(),
            ),
            PlatformMenuItem(
              label: 'Actual Size (Reset Zoom)',
              shortcut: const SingleActivator(
                LogicalKeyboardKey.digit0,
                meta: true,
              ),
              onSelected: () => controller.resetZoom(),
            ),
            PlatformMenuItem(
              label: 'Toggle Outline Sidebar',
              shortcut: const SingleActivator(
                LogicalKeyboardKey.keyB,
                meta: true,
              ),
              onSelected: () => controller.toggleSidebar(),
            ),
            PlatformMenuItem(
              label: 'Toggle Theme (Light / Dark)',
              shortcut: const SingleActivator(
                LogicalKeyboardKey.keyT,
                meta: true,
              ),
              onSelected: () => controller.toggleTheme(),
            ),
          ],
        ),

        // Help Menu
        PlatformMenu(
          label: 'Help',
          menus: <PlatformMenuItem>[
            PlatformMenuItem(
              label: 'Welcome Guide & Shortcuts',
              onSelected: () => controller.loadSampleDocument(),
            ),
          ],
        ),
      ],
      child: child,
    );
  }
}
