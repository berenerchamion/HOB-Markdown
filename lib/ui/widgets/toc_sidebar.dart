import 'package:flutter/material.dart';
import '../../models/toc_item.dart';

class TocSidebar extends StatefulWidget {
  final List<TocItem> headings;
  final ValueChanged<TocItem> onHeadingSelected;
  final VoidCallback? onClose;

  const TocSidebar({
    super.key,
    required this.headings,
    required this.onHeadingSelected,
    this.onClose,
  });

  @override
  State<TocSidebar> createState() => _TocSidebarState();
}

class _TocSidebarState extends State<TocSidebar> {
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

    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        border: Border(
          right: BorderSide(color: colorScheme.outlineVariant, width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Sidebar Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 12, 12),
            child: Row(
              children: [
                Icon(
                  Icons.format_list_bulleted_rounded,
                  size: 20,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Outline',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${widget.headings.length}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const Spacer(),
                if (widget.onClose != null)
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 18),
                    onPressed: widget.onClose,
                    tooltip: 'Close outline',
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
          ),

          // Search / Filter Input (if more than 4 headings)
          if (widget.headings.length > 4)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
              child: TextField(
                controller: _searchController,
                onChanged: (value) => setState(() => _filter = value),
                style: theme.textTheme.bodyMedium,
                decoration: InputDecoration(
                  hintText: 'Filter headings...',
                  hintStyle: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                  ),
                  prefixIcon: Icon(Icons.search_rounded, size: 16, color: colorScheme.onSurfaceVariant),
                  suffixIcon: _filter.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 14),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _filter = '');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),

          const Divider(height: 1),

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
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: filteredHeadings.length,
                        itemBuilder: (context, index) {
                          final item = filteredHeadings[index];
                          final indent = ((item.level - 1) * 12.0).clamp(0.0, 48.0);

                          return InkWell(
                            onTap: () => widget.onHeadingSelected(item),
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              padding: EdgeInsets.fromLTRB(indent + 8, 8, 8, 8),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: item.level == 1
                                          ? colorScheme.primaryContainer
                                          : colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      'H${item.level}',
                                      style: theme.textTheme.labelSmall?.copyWith(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: item.level == 1
                                            ? colorScheme.onPrimaryContainer
                                            : colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      item.title,
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        fontWeight: item.level <= 2 ? FontWeight.w600 : FontWeight.normal,
                                        color: colorScheme.onSurface,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
