import 'package:flutter/material.dart';

import '../../state/reader_controller.dart';

/// Size of a toolbar button and the gap around buttons inside a well. Kept
/// small and flat, like macOS toolbar controls.
const double _buttonSize = 28;
const double _wellPadding = 2;
const double _wellRadius = 9;
const double _buttonRadius = 7;

/// A rounded, lightly filled container that groups related toolbar buttons,
/// like the button groups in Safari's or Xcode's toolbar.
class ToolbarWell extends StatelessWidget {
  final List<Widget> children;

  const ToolbarWell({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      height: _buttonSize + _wellPadding * 2,
      padding: const EdgeInsets.all(_wellPadding),
      decoration: BoxDecoration(
        // A translucent tint rather than a fixed colour, so the well stands
        // out from whatever the toolbar background is in either theme.
        color: colorScheme.onSurface.withValues(alpha: isDark ? 0.07 : 0.05),
        borderRadius: BorderRadius.circular(_wellRadius),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.8),
          width: 0.5,
        ),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: children),
    );
  }
}

/// A flat toolbar button: no ripple, a soft background on hover and press,
/// and a tinted background when [selected] or [prominent].
///
/// It stays keyboard-focusable and activates with Enter or Space, so
/// Windows and Linux keyboard users can still reach it.
class ToolbarButton extends StatefulWidget {
  final IconData icon;
  final IconData? selectedIcon;
  final String tooltip;
  final String? label;
  final VoidCallback? onPressed;
  final bool selected;

  /// Draws the button in the accent colour, for the one action that needs
  /// attention (Save when there are unsaved edits).
  final bool prominent;

  const ToolbarButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.selectedIcon,
    this.label,
    this.selected = false,
    this.prominent = false,
  });

  @override
  State<ToolbarButton> createState() => _ToolbarButtonState();
}

class _ToolbarButtonState extends State<ToolbarButton> {
  bool _hovered = false;
  bool _pressed = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final enabled = widget.onPressed != null;
    final accent = widget.selected || widget.prominent;

    final foreground = !enabled
        ? colorScheme.onSurface.withValues(alpha: 0.38)
        : accent
        ? colorScheme.primary
        : colorScheme.onSurfaceVariant;

    final overlay = !enabled
        ? 0.0
        : _pressed
        ? 0.16
        : _hovered
        ? 0.08
        : 0.0;
    final background = accent
        ? colorScheme.primary.withValues(alpha: 0.14 + overlay)
        : colorScheme.onSurface.withValues(alpha: overlay);

    final icon = Icon(
      widget.selected && widget.selectedIcon != null
          ? widget.selectedIcon
          : widget.icon,
      size: 17,
      color: foreground,
    );

    return Tooltip(
      message: widget.tooltip,
      child: Semantics(
        button: true,
        enabled: enabled,
        selected: widget.selected,
        label: widget.label ?? widget.tooltip,
        excludeSemantics: true,
        child: FocusableActionDetector(
          enabled: enabled,
          mouseCursor: enabled
              ? SystemMouseCursors.basic
              : SystemMouseCursors.forbidden,
          onShowHoverHighlight: (v) => setState(() => _hovered = v),
          onShowFocusHighlight: (v) => setState(() => _focused = v),
          actions: <Type, Action<Intent>>{
            ActivateIntent: CallbackAction<ActivateIntent>(
              onInvoke: (_) {
                widget.onPressed?.call();
                return null;
              },
            ),
          },
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
            onTapUp: enabled ? (_) => setState(() => _pressed = false) : null,
            onTapCancel: enabled
                ? () => setState(() => _pressed = false)
                : null,
            onTap: widget.onPressed,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 90),
              height: _buttonSize,
              constraints: const BoxConstraints(minWidth: _buttonSize),
              padding: EdgeInsets.symmetric(
                horizontal: widget.label == null ? 0 : 8,
              ),
              decoration: BoxDecoration(
                color: background,
                borderRadius: BorderRadius.circular(_buttonRadius),
                border: _focused
                    ? Border.all(color: colorScheme.primary, width: 1.5)
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  icon,
                  if (widget.label != null) ...[
                    const SizedBox(width: 5),
                    Text(
                      widget.label!,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: foreground,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Render / Split / Source as one joined control, drawn like a macOS
/// segmented control: the selected segment is a raised tile inside a well.
class ViewModeSwitch extends StatelessWidget {
  final ViewMode value;
  final ValueChanged<ViewMode> onChanged;

  /// False in narrow windows, where the segments show icons only.
  final bool showLabels;

  const ViewModeSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.showLabels = true,
  });

  static const _segments = [
    (ViewMode.rendered, Icons.auto_stories_outlined, 'Render', '⌘1'),
    (ViewMode.split, Icons.vertical_split_outlined, 'Split', '⌘2'),
    (ViewMode.source, Icons.code_rounded, 'Source', '⌘3'),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return ToolbarWell(
      children: [
        for (final (mode, icon, label, shortcut) in _segments)
          _Segment(
            selected: mode == value,
            tooltip: '$label view ($shortcut)',
            onTap: () => onChanged(mode),
            selectedColor: isDark
                ? colorScheme.surfaceContainerHigh
                : colorScheme.surfaceContainerLowest,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 16,
                  color: mode == value
                      ? colorScheme.onSurface
                      : colorScheme.onSurfaceVariant,
                ),
                if (showLabels) ...[
                  const SizedBox(width: 5),
                  Text(
                    label,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: mode == value
                          ? colorScheme.onSurface
                          : colorScheme.onSurfaceVariant,
                      fontWeight: mode == value
                          ? FontWeight.w600
                          : FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

class _Segment extends StatefulWidget {
  final bool selected;
  final String tooltip;
  final VoidCallback onTap;
  final Color selectedColor;
  final Widget child;

  const _Segment({
    required this.selected,
    required this.tooltip,
    required this.onTap,
    required this.selectedColor,
    required this.child,
  });

  @override
  State<_Segment> createState() => _SegmentState();
}

class _SegmentState extends State<_Segment> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Tooltip(
      message: widget.tooltip,
      child: Semantics(
        button: true,
        selected: widget.selected,
        label: widget.tooltip,
        child: FocusableActionDetector(
          onShowHoverHighlight: (v) => setState(() => _hovered = v),
          onShowFocusHighlight: (v) => setState(() => _focused = v),
          actions: <Type, Action<Intent>>{
            ActivateIntent: CallbackAction<ActivateIntent>(
              onInvoke: (_) {
                widget.onTap();
                return null;
              },
            ),
          },
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: widget.onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              height: _buttonSize,
              constraints: const BoxConstraints(minWidth: 34),
              padding: const EdgeInsets.symmetric(horizontal: 9),
              decoration: BoxDecoration(
                color: widget.selected
                    ? widget.selectedColor
                    : _hovered
                    ? colorScheme.onSurface.withValues(alpha: 0.06)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(_buttonRadius),
                border: _focused
                    ? Border.all(color: colorScheme.primary, width: 1.5)
                    : null,
                boxShadow: widget.selected
                    ? [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.12),
                          blurRadius: 2,
                          offset: const Offset(0, 0.5),
                        ),
                      ]
                    : null,
              ),
              alignment: Alignment.center,
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
}
