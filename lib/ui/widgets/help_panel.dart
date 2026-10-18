import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../state/reader_controller.dart';
import '../../theme/app_theme.dart';
import 'code_block_builder.dart';

/// A slide-over panel for help/welcome content, anchored to the right edge.
/// Replaces the old floating pseudo-window: no drag, no resize, no
/// minimize/maximize — just open, read, close.
class HelpPanel extends StatefulWidget {
  final ReaderController controller;
  final bool isOpen;

  const HelpPanel({super.key, required this.controller, required this.isOpen});

  @override
  State<HelpPanel> createState() => _HelpPanelState();
}

class _HelpPanelState extends State<HelpPanel> {
  static const double panelWidth = 420.0;

  late String _markdownContent;

  @override
  void initState() {
    super.initState();
    _markdownContent = widget.controller.fileService
        .getSampleDocument()
        .content;

    widget.controller.fileService.loadWelcomeGuideContent().then((content) {
      if (mounted && content.isNotEmpty && content != _markdownContent) {
        setState(() {
          _markdownContent = content;
        });
      }
    });
  }

  Future<void> _handleLinkTap(String? url) async {
    if (url == null || url.isEmpty) return;
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return IgnorePointer(
      ignoring: !widget.isOpen,
      child: Stack(
        children: [
          // Backdrop — dims the document and closes the panel on tap.
          AnimatedOpacity(
            opacity: widget.isOpen ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            child: GestureDetector(
              onTap: () => widget.controller.hideHelpWindow(),
              child: Container(color: Colors.black.withValues(alpha: 0.25)),
            ),
          ),

          // The panel itself, slid in from the right.
          AnimatedPositioned(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            top: 0,
            bottom: 0,
            right: widget.isOpen ? 0 : -panelWidth,
            width: panelWidth,
            child: Material(
              elevation: 4,
              color: colorScheme.surfaceContainerLow,
              child: SafeArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header
                    Container(
                      height: 56,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: colorScheme.outlineVariant.withValues(
                              alpha: 0.5,
                            ),
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.auto_stories_rounded,
                            size: 18,
                            color: colorScheme.primary,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Welcome Guide & Shortcuts',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onSurface,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded, size: 20),
                            tooltip: 'Close',
                            visualDensity: VisualDensity.compact,
                            onPressed: () => widget.controller.hideHelpWindow(),
                          ),
                        ],
                      ),
                    ),

                    // Content
                    Expanded(
                      child: SelectionArea(
                        child: Markdown(
                          data: _markdownContent,
                          selectable: false,
                          styleSheet: AppTheme.markdownStyleSheet(
                            context,
                            scaleFactor: 0.95,
                          ),
                          padding: const EdgeInsets.all(20),
                          onTapLink: (text, href, title) =>
                              _handleLinkTap(href),
                          builders: {
                            'code': CodeBlockBuilder(
                              context: context,
                              scaleFactor: 0.95,
                            ),
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
