import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/document_model.dart';

class RawMarkdownView extends StatefulWidget {
  final DocumentModel document;
  final double scaleFactor;
  final ScrollController? scrollController;
  final ValueChanged<String>? onChanged;

  const RawMarkdownView({
    super.key,
    required this.document,
    required this.scaleFactor,
    this.scrollController,
    this.onChanged,
  });

  @override
  State<RawMarkdownView> createState() => _RawMarkdownViewState();
}

class _RawMarkdownViewState extends State<RawMarkdownView> {
  late final TextEditingController _textController;
  final FocusNode _focusNode = FocusNode();
  final ScrollController _internalScrollController = ScrollController();
  Timer? _debounceTimer;
  bool _copied = false;
  int _lineCount = 1;

  ScrollController get _effectiveScrollController =>
      widget.scrollController ?? _internalScrollController;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.document.content);
    _lineCount = _calculateLineCount(widget.document.content);
    _textController.addListener(_handleTextChange);
  }

  @override
  void didUpdateWidget(RawMarkdownView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If the document content was updated externally (e.g. file reload/open)
    if (widget.document.content != _textController.text &&
        widget.document.path != oldWidget.document.path) {
      final cursor = _textController.selection;
      _textController.text = widget.document.content;
      if (cursor.isValid && cursor.end <= widget.document.content.length) {
        _textController.selection = cursor;
      }
      setState(() {
        _lineCount = _calculateLineCount(widget.document.content);
      });
    }
  }

  int _calculateLineCount(String text) {
    if (text.isEmpty) return 1;
    return text.split('\n').length;
  }

  void _handleTextChange() {
    final text = _textController.text;
    final lines = _calculateLineCount(text);
    if (lines != _lineCount) {
      setState(() => _lineCount = lines);
    }

    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 150), () {
      if (mounted && widget.onChanged != null) {
        widget.onChanged!(text);
      }
    });
  }

  Future<void> _copyAll() async {
    await Clipboard.setData(ClipboardData(text: _textController.text));
    if (mounted) {
      setState(() => _copied = true);
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() => _copied = false);
        }
      });
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _textController.removeListener(_handleTextChange);
    _textController.dispose();
    _focusNode.dispose();
    _internalScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final codeFont = GoogleFonts.jetBrainsMono(
      fontSize: 13.5 * widget.scaleFactor,
      height: 1.6,
      color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF1E293B),
    );

    final gutterFont = GoogleFonts.jetBrainsMono(
      fontSize: 13.5 * widget.scaleFactor,
      height: 1.6,
      color: colorScheme.onSurfaceVariant.withValues(alpha: 0.45),
    );

    return Stack(
      children: [
        SingleChildScrollView(
          controller: _effectiveScrollController,
          padding: const EdgeInsets.fromLTRB(16, 20, 24, 40),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Line Numbers Gutter
              Container(
                padding: const EdgeInsets.only(right: 14),
                margin: const EdgeInsets.only(right: 14),
                decoration: BoxDecoration(
                  border: Border(
                    right: BorderSide(color: colorScheme.outlineVariant, width: 1),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: List.generate(
                    _lineCount,
                    (index) => Text('${index + 1}', style: gutterFont),
                  ),
                ),
              ),

              // Interactive Source Code Editor
              Expanded(
                child: TextField(
                  controller: _textController,
                  focusNode: _focusNode,
                  maxLines: null,
                  keyboardType: TextInputType.multiline,
                  style: codeFont,
                  cursorColor: colorScheme.primary,
                  cursorWidth: 2,
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    border: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    enabledBorder: InputBorder.none,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Floating Copy All Action
        Positioned(
          top: 14,
          right: 20,
          child: FilledButton.tonalIcon(
            onPressed: _copyAll,
            icon: Icon(_copied ? Icons.check_rounded : Icons.copy_rounded, size: 15),
            label: Text(_copied ? 'Copied' : 'Copy All'),
            style: FilledButton.styleFrom(
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            ),
          ),
        ),
      ],
    );
  }
}
