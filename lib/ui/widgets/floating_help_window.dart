import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../state/reader_controller.dart';
import '../../theme/app_theme.dart';
import 'code_block_builder.dart';

class FloatingHelpWindow extends StatefulWidget {
  final ReaderController controller;

  const FloatingHelpWindow({super.key, required this.controller});

  @override
  State<FloatingHelpWindow> createState() => _FloatingHelpWindowState();
}

class _FloatingHelpWindowState extends State<FloatingHelpWindow> {
  static const double minWindowWidth = 360.0;
  static const double minWindowHeight = 260.0;

  Offset? _offset;
  double? _width;
  double? _height;
  bool _isMinimized = false;
  bool _isMaximized = false;

  Offset? _preMaximizeOffset;
  double? _preMaximizeWidth;
  double? _preMaximizeHeight;

  late String _markdownContent;

  @override
  void initState() {
    super.initState();
    // Synchronously initialize with cached/fallback sample content for instant display
    _markdownContent =
        widget.controller.fileService.getSampleDocument().content;

    // Asynchronously load asset content if newer
    widget.controller.fileService.loadWelcomeGuideContent().then((content) {
      if (mounted && content.isNotEmpty && content != _markdownContent) {
        setState(() {
          _markdownContent = content;
        });
      }
    });
  }

  void _toggleMaximize(BoxConstraints constraints) {
    setState(() {
      if (_isMaximized) {
        _isMaximized = false;
        _offset = _preMaximizeOffset;
        _width = _preMaximizeWidth;
        _height = _preMaximizeHeight;
      } else {
        _preMaximizeOffset = _offset;
        _preMaximizeWidth = _width;
        _preMaximizeHeight = _height;
        _isMaximized = true;
        _isMinimized = false;
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

    return Positioned.fill(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final double windowWidth;
          final double windowHeight;
          final Offset clampedOffset;

          if (_isMaximized) {
            windowWidth = math.max(minWindowWidth, constraints.maxWidth - 32.0);
            windowHeight =
                math.max(minWindowHeight, constraints.maxHeight - 32.0);
            clampedOffset = const Offset(16.0, 16.0);
          } else {
            final defaultWidth =
                math.min(560.0, constraints.maxWidth - 32.0);
            final defaultHeight =
                math.min(620.0, constraints.maxHeight - 48.0);

            windowWidth = (_width ?? defaultWidth).clamp(
              minWindowWidth,
              math.max(minWindowWidth, constraints.maxWidth),
            );
            windowHeight = (_height ?? defaultHeight).clamp(
              minWindowHeight,
              math.max(minWindowHeight, constraints.maxHeight),
            );

            final currentHeight = _isMinimized ? 50.0 : windowHeight;
            final maxX = math.max(0.0, constraints.maxWidth - windowWidth);
            final maxY = math.max(0.0, constraints.maxHeight - currentHeight);

            final initialOffset = Offset(
              math.max(16.0, constraints.maxWidth - windowWidth - 32.0),
              24.0,
            );
            final currentOffset = _offset ?? initialOffset;

            clampedOffset = Offset(
              currentOffset.dx.clamp(0.0, maxX),
              currentOffset.dy.clamp(0.0, maxY),
            );
          }

          final maxX = math.max(0.0, constraints.maxWidth - windowWidth);
          final maxY = math.max(
            0.0,
            constraints.maxHeight - (_isMinimized ? 50.0 : windowHeight),
          );

          final styleSheet = AppTheme.markdownStyleSheet(
            context,
            scaleFactor: 0.95,
          );

          return Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: clampedOffset.dx,
                top: clampedOffset.dy,
                width: windowWidth,
                child: Material(
                  elevation: 8,
                  shadowColor: Colors.black38,
                  borderRadius: BorderRadius.circular(16),
                  clipBehavior: Clip.antiAlias,
                  color: colorScheme.surfaceContainerLow,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color:
                            colorScheme.outlineVariant.withValues(alpha: 0.6),
                        width: 1.5,
                      ),
                    ),
                    child: Stack(
                      children: [
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Title Bar / Drag Handle
                            GestureDetector(
                              onDoubleTap: () => _toggleMaximize(constraints),
                              onPanUpdate: _isMaximized
                                  ? null
                                  : (details) {
                                      setState(() {
                                        final newX = (clampedOffset.dx +
                                                details.delta.dx)
                                            .clamp(0.0, maxX);
                                        final newY = (clampedOffset.dy +
                                                details.delta.dy)
                                            .clamp(0.0, maxY);
                                        _offset = Offset(newX, newY);
                                      });
                                    },
                              child: Container(
                                height: 50,
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 14),
                                color: colorScheme.surfaceContainerHighest,
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
                                        style: theme.textTheme.titleSmall
                                            ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: colorScheme.onSurface,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    IconButton(
                                      icon: Icon(
                                        _isMinimized
                                            ? Icons.expand_more_rounded
                                            : Icons.expand_less_rounded,
                                        size: 18,
                                      ),
                                      tooltip:
                                          _isMinimized ? 'Expand' : 'Minimize',
                                      visualDensity: VisualDensity.compact,
                                      onPressed: () {
                                        setState(() {
                                          _isMinimized = !_isMinimized;
                                          if (_isMinimized) {
                                            _isMaximized = false;
                                          }
                                        });
                                      },
                                    ),
                                    IconButton(
                                      icon: Icon(
                                        _isMaximized
                                            ? Icons.fullscreen_exit_rounded
                                            : Icons.fullscreen_rounded,
                                        size: 18,
                                      ),
                                      tooltip: _isMaximized
                                          ? 'Restore'
                                          : 'Maximize',
                                      visualDensity: VisualDensity.compact,
                                      onPressed: _isMinimized
                                          ? null
                                          : () =>
                                              _toggleMaximize(constraints),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.close_rounded,
                                          size: 18),
                                      tooltip: 'Close',
                                      visualDensity: VisualDensity.compact,
                                      onPressed: () =>
                                          widget.controller.hideHelpWindow(),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            // Window Content
                            if (!_isMinimized)
                              SizedBox(
                                height: windowHeight - 50,
                                child: SelectionArea(
                                  child: Markdown(
                                    data: _markdownContent,
                                    selectable: false,
                                    styleSheet: styleSheet,
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

                        // Resize Handles (only active when not maximized and not minimized)
                        if (!_isMaximized && !_isMinimized) ...[
                          // Right Edge Handle
                          Positioned(
                            top: 50,
                            right: 0,
                            bottom: 20,
                            width: 8,
                            child: MouseRegion(
                              cursor: SystemMouseCursors.resizeLeftRight,
                              child: GestureDetector(
                                behavior: HitTestBehavior.translucent,
                                onPanUpdate: (details) {
                                  setState(() {
                                    final maxAllowedWidth =
                                        constraints.maxWidth - clampedOffset.dx;
                                    _width = (windowWidth + details.delta.dx)
                                        .clamp(minWindowWidth, maxAllowedWidth);
                                  });
                                },
                              ),
                            ),
                          ),

                          // Bottom Edge Handle
                          Positioned(
                            left: 16,
                            right: 20,
                            bottom: 0,
                            height: 8,
                            child: MouseRegion(
                              cursor: SystemMouseCursors.resizeUpDown,
                              child: GestureDetector(
                                behavior: HitTestBehavior.translucent,
                                onPanUpdate: (details) {
                                  setState(() {
                                    final maxAllowedHeight =
                                        constraints.maxHeight - clampedOffset.dy;
                                    _height = (windowHeight + details.delta.dy)
                                        .clamp(minWindowHeight, maxAllowedHeight);
                                  });
                                },
                              ),
                            ),
                          ),

                          // Bottom-Right Corner Grip Handle
                          Positioned(
                            right: 0,
                            bottom: 0,
                            width: 24,
                            height: 24,
                            child: MouseRegion(
                              cursor: SystemMouseCursors.resizeDownRight,
                              child: GestureDetector(
                                behavior: HitTestBehavior.translucent,
                                onPanUpdate: (details) {
                                  setState(() {
                                    final maxAllowedWidth =
                                        constraints.maxWidth - clampedOffset.dx;
                                    final maxAllowedHeight =
                                        constraints.maxHeight - clampedOffset.dy;
                                    _width = (windowWidth + details.delta.dx)
                                        .clamp(minWindowWidth, maxAllowedWidth);
                                    _height = (windowHeight + details.delta.dy)
                                        .clamp(minWindowHeight, maxAllowedHeight);
                                  });
                                },
                                child: Container(
                                  alignment: Alignment.bottomRight,
                                  padding: const EdgeInsets.only(
                                    right: 4,
                                    bottom: 4,
                                  ),
                                  child: Icon(
                                    Icons.south_east_rounded,
                                    size: 13,
                                    color: colorScheme.onSurfaceVariant
                                        .withValues(alpha: 0.45),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
