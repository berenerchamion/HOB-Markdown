import 'package:flutter/material.dart';

class SearchBarOverlay extends StatefulWidget {
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onClose;
  final int matchCount;

  const SearchBarOverlay({
    super.key,
    required this.onSearchChanged,
    required this.onClose,
    this.matchCount = 0,
  });

  @override
  State<SearchBarOverlay> createState() => _SearchBarOverlayState();
}

class _SearchBarOverlayState extends State<SearchBarOverlay> {
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: 320,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.search_rounded, size: 20, color: colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _textController,
              focusNode: _focusNode,
              onChanged: widget.onSearchChanged,
              style: theme.textTheme.bodyMedium,
              decoration: InputDecoration(
                hintText: 'Search in document...',
                hintStyle: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                ),
                isDense: true,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 6),
              ),
            ),
          ),
          if (_textController.text.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '${widget.matchCount} found',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.w600,
                  fontSize: 10,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.clear_rounded, size: 16),
              tooltip: 'Clear search',
              onPressed: () {
                _textController.clear();
                widget.onSearchChanged('');
              },
              visualDensity: VisualDensity.compact,
            ),
          ],
          IconButton(
            icon: const Icon(Icons.close_rounded, size: 18),
            tooltip: 'Close (Esc)',
            onPressed: widget.onClose,
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}
