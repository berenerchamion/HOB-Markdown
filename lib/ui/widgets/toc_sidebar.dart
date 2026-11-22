import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../models/toc_item.dart';
import 'toolbar_controls.dart';

class TocSidebar extends StatefulWidget {
  final List<TocItem> headings;
  final ValueChanged<TocItem> onHeadingSelected;
  final VoidCallback? onClose;

  /// The heading currently in view, highlighted in the list. Optional so the
  /// sidebar still works without scroll tracking (tests, the drawer).
  final ValueListenable<TocItem?>? activeHeading;

  const TocSidebar({
    super.key,
    required this.headings,
    required this.onHeadingSelected,
    this.onClose,
    this.activeHeading,
  });

  @override
  State<TocSidebar> createState() => _TocSidebarState();
}

class _TocSidebarState extends State<TocSidebar> {
  static final ValueNotifier<TocItem?> _noActiveHeading = ValueNotifier(null);
  String _filter = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final filteredHeadings = widget.headings.where((item) {
      if (_filter.isEmpty) return true;
      return item.title.toLowerCase().contains(_filter.toLowerCase());
    }).toList();

    // A tinted panel with no hard right border, like a macOS sidebar: the
    // tint alone separates it from the document.
    return Container(
      width: 260,
      color: colorScheme.surfaceContainerLow,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Section header: small and muted, as in Finder or Xcode.
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 10, 6),
            child: SizedBox(
              height: 28,
              child: Row(
                children: [
                  Text(
                    'Outline',
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${widget.headings.length}',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant.withValues(
                        alpha: 0.7,
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (widget.onClose != null)
                    ToolbarButton(
                      icon: Icons.close_rounded,
                      tooltip: 'Close outline',
                      onPressed: widget.onClose,
                    ),
                ],
              ),
            ),
          ),

          // Filter field (only worth showing with more than 4 headings)
          if (widget.headings.length > 4)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 6),
              child: TextField(
                controller: _searchController,
                onChanged: (value) => setState(() => _filter = value),
                style: theme.textTheme.bodySmall,
                decoration: InputDecoration(
                  hintText: 'Filter',
                  hintStyle: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                  ),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    size: 15,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  prefixIconConstraints: const BoxConstraints(
                    minWidth: 30,
                    minHeight: 28,
                  ),
                  suffixIcon: _filter.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 14),
                          tooltip: 'Clear filter',
                          visualDensity: VisualDensity.compact,
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _filter = '');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: colorScheme.onSurface.withValues(alpha: 0.06),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 7,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(7),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),

          // Headings List
          Expanded(
            child: widget.headings.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'No headings found in this document.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                : filteredHeadings.isEmpty
                ? Center(
                    child: Text(
                      'No matching headings',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  )
                : ValueListenableBuilder<TocItem?>(
                    valueListenable: widget.activeHeading ?? _noActiveHeading,
                    builder: (context, active, _) => ListView.builder(
                      padding: const EdgeInsets.fromLTRB(8, 2, 8, 12),
                      itemCount: filteredHeadings.length,
                      itemBuilder: (context, index) {
                        final item = filteredHeadings[index];
                        return _HeadingRow(
                          item: item,
                          active: item == active,
                          onTap: () => widget.onHeadingSelected(item),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

/// One outline entry: a level badge, indented by level, with a rounded
/// highlight on hover
/// and for the heading currently in view, instead of a full-width block.
class _HeadingRow extends StatefulWidget {
  final TocItem item;
  final bool active;
  final VoidCallback onTap;

  const _HeadingRow({
    required this.item,
    required this.active,
    required this.onTap,
  });

  @override
  State<_HeadingRow> createState() => _HeadingRowState();
}

class _HeadingRowState extends State<_HeadingRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final item = widget.item;
    final indent = ((item.level - 1) * 12.0).clamp(0.0, 48.0);

    return Semantics(
      button: true,
      selected: widget.active,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 100),
            margin: const EdgeInsets.symmetric(vertical: 1),
            padding: EdgeInsets.fromLTRB(indent + 8, 5, 10, 5),
            decoration: BoxDecoration(
              color: widget.active
                  ? colorScheme.primary.withValues(alpha: 0.14)
                  : _hovered
                  ? colorScheme.onSurface.withValues(alpha: 0.06)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Heading level badge: small and muted so it labels the row
                // without competing with the title.
                Container(
                  margin: const EdgeInsets.only(top: 1),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: widget.active
                        ? colorScheme.primary.withValues(alpha: 0.18)
                        : colorScheme.onSurface.withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'H${item.level}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontSize: 9.5,
                      height: 1.3,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.2,
                      color: widget.active
                          ? colorScheme.primary
                          : colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    item.title,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 13,
                      height: 1.3,
                      fontWeight: item.level == 1 || widget.active
                          ? FontWeight.w600
                          : FontWeight.w400,
                      color: widget.active
                          ? colorScheme.primary
                          : item.level <= 2
                          ? colorScheme.onSurface
                          : colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
