import 'dart:ui';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';

class DropTargetZone extends StatefulWidget {
  final Widget child;
  final ValueChanged<String> onFileDropped;
  final ValueChanged<bool>? onDraggingChanged;

  const DropTargetZone({
    super.key,
    required this.child,
    required this.onFileDropped,
    this.onDraggingChanged,
  });

  @override
  State<DropTargetZone> createState() => _DropTargetZoneState();
}

class _DropTargetZoneState extends State<DropTargetZone> with SingleTickerProviderStateMixin {
  bool _isDragging = false;
  late final AnimationController _pulseController;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _scaleAnimation = Tween<double>(begin: 0.96, end: 1.02).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _setDragging(bool isDragging) {
    if (_isDragging != isDragging) {
      setState(() => _isDragging = isDragging);
      if (isDragging) {
        _pulseController.repeat(reverse: true);
      } else {
        _pulseController.stop();
        _pulseController.reset();
      }
      widget.onDraggingChanged?.call(isDragging);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return DropTarget(
      onDragEntered: (_) => _setDragging(true),
      onDragExited: (_) => _setDragging(false),
      onDragDone: (details) {
        _setDragging(false);
        if (details.files.isNotEmpty) {
          final path = details.files.first.path;
          widget.onFileDropped(path);
        }
      },
      child: Stack(
        children: [
          widget.child,
          if (_isDragging)
            Positioned.fill(
              child: AnimatedOpacity(
                opacity: _isDragging ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 200),
                child: ClipRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                    child: Container(
                      color: theme.scaffoldBackgroundColor.withValues(alpha: 0.85),
                      padding: const EdgeInsets.all(32),
                      child: Center(
                        child: ScaleTransition(
                          scale: _scaleAnimation,
                          child: Container(
                            constraints: const BoxConstraints(maxWidth: 480, maxHeight: 300),
                            padding: const EdgeInsets.all(32),
                            decoration: BoxDecoration(
                              color: colorScheme.surfaceContainerHigh,
                              borderRadius: BorderRadius.circular(28),
                              border: Border.all(
                                color: colorScheme.primary,
                                width: 3,
                                strokeAlign: BorderSide.strokeAlignCenter,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: colorScheme.primary.withValues(alpha: 0.25),
                                  blurRadius: 30,
                                  spreadRadius: 4,
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: colorScheme.primaryContainer,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.file_download_outlined,
                                    size: 48,
                                    color: colorScheme.onPrimaryContainer,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                Text(
                                  'Drop Markdown file here',
                                  style: theme.textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.onSurface,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Release to instantly render in Material 3',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
